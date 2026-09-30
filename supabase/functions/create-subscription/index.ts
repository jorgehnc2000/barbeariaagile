import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { fetchLastAuthorizedPayment } from "../_shared/mp_payments.ts";
import { MP_SUBSCRIPTION_SUCCESS_URL } from "../_shared/app_urls.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const BACK_URL = MP_SUBSCRIPTION_SUCCESS_URL;

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function bearerToken(req: Request) {
  const authorization = req.headers.get("Authorization") ?? "";
  return authorization.match(/^Bearer\s+(.+)$/i)?.[1]?.trim() ?? "";
}

async function parseJson(response: Response): Promise<Record<string, unknown>> {
  const text = await response.text();
  if (!text) return {};
  try {
    return JSON.parse(text);
  } catch {
    return { message: text };
  }
}

async function setMpStatus(
  accessToken: string,
  preapprovalId: string,
  status: "canceled",
) {
  return await fetch(
    `https://api.mercadopago.com/preapproval/${preapprovalId}`,
    {
      method: "PUT",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ status }),
    },
  );
}

async function idempotencyKey(value: string) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Método não permitido." }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
    const serviceRoleKey = Deno.env
      .get("SUPABASE_SERVICE_ROLE_KEY")
      ?.trim();
    const token = bearerToken(req);
    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse(
        { error: "Configuração do Supabase ausente." },
        500,
      );
    }
    if (!token) {
      return jsonResponse({ error: "JWT ausente." }, 401);
    }

    const body = await req.json();
    const requestedUserId = String(body.user_id ?? "").trim();
    const requestedBarbershopId = String(body.barbershop_id ?? "").trim();
    const localPlanId = String(body.plan_id ?? "").trim();
    const cardTokenId = String(body.card_token_id ?? "").trim();
    const requestedEmail = String(body.email ?? "").trim().toLowerCase();

    if (!localPlanId || !cardTokenId) {
      return jsonResponse(
        {
          error: "Dados obrigatórios ausentes: plan_id ou card_token_id.",
        },
        400,
      );
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: authData, error: authError } = await supabase.auth.getUser(
      token,
    );
    if (authError || !authData.user) {
      return jsonResponse({ error: "JWT inválido ou expirado." }, 401);
    }
    const userId = authData.user.id;
    const email = String(authData.user.email ?? "").trim().toLowerCase();
    if (!email) {
      return jsonResponse(
        { error: "O usuário autenticado não possui e-mail." },
        422,
      );
    }
    if (requestedUserId && requestedUserId !== userId) {
      return jsonResponse({ error: "user_id diverge do JWT." }, 403);
    }
    if (requestedEmail && requestedEmail !== email) {
      return jsonResponse({ error: "email diverge do JWT." }, 403);
    }

    const [{ data: profile, error: profileError }, {
      data: plan,
      error: planError,
    }] = await Promise.all([
      supabase
        .from("users")
        .select("id, barbershop_id")
        .eq("id", userId)
        .maybeSingle(),
      supabase
        .from("plans")
        .select("id, barbershop_id, mp_plan_id, active, mp_status")
        .eq("id", localPlanId)
        .maybeSingle(),
    ]);
    if (profileError || planError) {
      return jsonResponse({
        error: "Não foi possível validar usuário e plano.",
        details: profileError?.message ?? planError?.message,
      }, 500);
    }
    if (!profile) {
      return jsonResponse({ error: "Perfil do usuário não encontrado." }, 403);
    }
    if (!plan || !plan.active) {
      return jsonResponse({ error: "Plano ativo não encontrado." }, 404);
    }
    if (String(plan.mp_status ?? "").toLowerCase() !== "synchronized") {
      return jsonResponse({
        error: "Este plano ainda não está sincronizado com o Mercado Pago.",
      }, 422);
    }
    const barbershopId = String(plan.barbershop_id);
    if (
      String(profile.barbershop_id) !== barbershopId ||
      (requestedBarbershopId && requestedBarbershopId !== barbershopId)
    ) {
      return jsonResponse({ error: "Plano pertence a outro tenant." }, 403);
    }

    const { data: barbershop, error: barbershopError } = await supabase
      .from("barbershops")
      .select("mp_access_token, vip_enabled")
      .eq("id", barbershopId)
      .maybeSingle();

    if (barbershopError) {
      return jsonResponse(
        {
          error: "Não foi possível carregar a configuração da barbearia.",
          details: barbershopError.message,
        },
        500,
      );
    }

    if (!barbershop) {
      return jsonResponse(
        { error: "Barbearia não encontrada." },
        404,
      );
    }

    if (barbershop.vip_enabled !== true) {
      return jsonResponse(
        { error: "O Clube VIP não está habilitado nesta barbearia." },
        422,
      );
    }

    const accessToken = String(barbershop.mp_access_token ?? "").trim();
    const mpPlanId = String(plan.mp_plan_id ?? "").trim();

    if (!accessToken || !mpPlanId) {
      return jsonResponse(
        {
          error: "A barbearia ou o plano não possui configuração Mercado Pago.",
        },
        422,
      );
    }

    const { data: currentSubscription, error: currentError } = await supabase
      .from("subscriptions")
      .select(
        "id, user_id, barbershop_id, plan_id, mp_preapproval_id, status, next_payment_date, last_payment_status",
      )
      .eq("user_id", userId)
      .eq("barbershop_id", barbershopId)
      .maybeSingle();
    if (currentError) {
      return jsonResponse({
        error: "Não foi possível consultar a assinatura atual.",
        details: currentError.message,
      }, 500);
    }
    // Só reutiliza se for o mesmo plano, autorizado e sem pendência de pagamento.
    // Troca de plano / regularização de cartão sempre cria novo preapproval no MP.
    const lastPayment = String(
      currentSubscription?.last_payment_status ?? "",
    ).toLowerCase();
    const paymentHealthy = lastPayment === "" || lastPayment === "approved";
    if (
      currentSubscription?.plan_id === localPlanId &&
      String(currentSubscription.status ?? "").toLowerCase() === "authorized" &&
      paymentHealthy
    ) {
      return jsonResponse({
        success: true,
        reused: true,
        subscription: currentSubscription,
      });
    }

    const mercadoPagoResponse = await fetch(
      "https://api.mercadopago.com/preapproval",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
          "X-Idempotency-Key": await idempotencyKey(
            `${userId}:${localPlanId}:${cardTokenId}`,
          ),
        },
        body: JSON.stringify({
          preapproval_plan_id: mpPlanId,
          payer_email: email,
          card_token_id: cardTokenId,
          status: "authorized",
          external_reference: `${barbershopId}:${userId}`,
          back_url: Deno.env.get("MP_BACK_URL")?.trim() || BACK_URL,
        }),
      },
    );

    const mercadoPagoData = await parseJson(mercadoPagoResponse);

    const newPreapprovalId = String(mercadoPagoData.id ?? "").trim();
    if (!mercadoPagoResponse.ok || !newPreapprovalId) {
      return jsonResponse(
        {
          error: "Erro no Mercado Pago.",
          status: mercadoPagoResponse.status,
          details: mercadoPagoData,
        },
        mercadoPagoResponse.status,
      );
    }

    const previousPreapprovalId = String(
      currentSubscription?.mp_preapproval_id ?? "",
    ).trim();
    if (previousPreapprovalId) {
      const cancellation = await setMpStatus(
        accessToken,
        previousPreapprovalId,
        "canceled",
      );
      if (!cancellation.ok) {
        await setMpStatus(accessToken, newPreapprovalId, "canceled");
        return jsonResponse({
          error: "A assinatura anterior não pôde ser cancelada.",
          details: await parseJson(cancellation),
        }, 502);
      }
    }

    const { data: savedSubscription, error: databaseError } = await supabase
      .from("subscriptions")
      .upsert(
        {
          user_id: userId,
          barbershop_id: barbershopId,
          plan_id: localPlanId,
          mp_plan_id: mpPlanId,
          mp_preapproval_id: newPreapprovalId,
          status: String(mercadoPagoData.status ?? "authorized"),
          next_payment_date: mercadoPagoData.next_payment_date ?? null,
          last_payment_status: "approved",
          last_payment_at: new Date().toISOString(),
          cancelled_at: null,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id,barbershop_id" },
      )
      .select(
        "id, user_id, barbershop_id, plan_id, mp_preapproval_id, status, next_payment_date, last_payment_status",
      )
      .single();

    if (databaseError) {
      await setMpStatus(accessToken, newPreapprovalId, "canceled");
      return jsonResponse(
        {
          error: "Assinatura criada, mas não foi salva no banco.",
          details: databaseError.message,
        },
        500,
      );
    }

    // Refina status do último pagamento com a API de authorized_payments.
    const lastPayment = await fetchLastAuthorizedPayment(
      accessToken,
      newPreapprovalId,
    );
    if (lastPayment.status) {
      await supabase
        .from("subscriptions")
        .update({
          last_payment_status: lastPayment.status,
          last_payment_at: lastPayment.paidAt ?? new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq("id", savedSubscription.id)
        .eq("barbershop_id", barbershopId);
    }

    return jsonResponse({
      success: true,
      message: "Assinatura criada com sucesso.",
      subscription: savedSubscription,
    });
  } catch (error) {
    return jsonResponse(
      {
        error: "Erro interno na Edge Function.",
        details: error instanceof Error ? error.message : String(error),
      },
      500,
    );
  }
});
