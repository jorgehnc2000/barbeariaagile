import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { MP_SUBSCRIPTION_SUCCESS_URL } from "../_shared/app_urls.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type JsonObject = Record<string, unknown>;

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
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  return match?.[1]?.trim() ?? "";
}

async function parseJson(response: Response): Promise<JsonObject> {
  const text = await response.text();
  if (!text) return {};
  try {
    return JSON.parse(text);
  } catch {
    return { message: text };
  }
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
    const localPlanId = String(body.plan_id ?? "").trim();

    if (!localPlanId) {
      return jsonResponse(
        { error: "Informe plan_id (UUID local)." },
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

    const [{ data: profile, error: profileError }, {
      data: plan,
      error: planError,
    }] = await Promise.all([
      supabase
        .from("users")
        .select("id, role, barbershop_id")
        .eq("id", authData.user.id)
        .maybeSingle(),
      supabase
        .from("plans")
        .select(
          "id, barbershop_id, name, monthly_amount, frequency, active, mp_plan_id",
        )
        .eq("id", localPlanId)
        .maybeSingle(),
    ]);

    if (profileError || planError) {
      return jsonResponse({
        error: "Não foi possível validar usuário e plano.",
        details: profileError?.message ?? planError?.message,
      }, 500);
    }
    if (!profile || String(profile.role ?? "").toLowerCase() !== "admin") {
      return jsonResponse({ error: "Acesso restrito a administradores." }, 403);
    }
    if (!plan) {
      return jsonResponse({ error: "Plano não encontrado." }, 404);
    }
    if (
      String(profile.barbershop_id) !== String(plan.barbershop_id)
    ) {
      return jsonResponse({ error: "Plano pertence a outro tenant." }, 403);
    }

    const { data: barbershop, error: barbershopError } = await supabase
      .from("barbershops")
      .select("id, mp_access_token, vip_enabled")
      .eq("id", plan.barbershop_id)
      .maybeSingle();
    if (barbershopError) {
      return jsonResponse(
        {
          error: "Não foi possível carregar as credenciais do tenant.",
          details: barbershopError.message,
        },
        500,
      );
    }
    if (barbershop?.vip_enabled !== true) {
      return jsonResponse(
        { error: "O Clube VIP não está habilitado nesta barbearia." },
        422,
      );
    }
    const accessToken = String(barbershop?.mp_access_token ?? "").trim();
    if (!accessToken) {
      return jsonResponse(
        { error: "Access Token do Mercado Pago não configurado." },
        422,
      );
    }

    const periods: Record<string, number> = {
      monthly: 1,
      quarterly: 3,
      yearly: 12,
    };
    const frequency = periods[String(plan.frequency)];
    const monthlyAmount = Number(plan.monthly_amount);
    const transactionAmount = Number((monthlyAmount * frequency).toFixed(2));
    if (
      !frequency || !Number.isFinite(transactionAmount) ||
      transactionAmount <= 0
    ) {
      return jsonResponse(
        { error: "Frequência ou valor mensal inválido no plano." },
        422,
      );
    }

    const currentMpPlanId = String(plan.mp_plan_id ?? "").trim();
    const endpoint = currentMpPlanId
      ? `https://api.mercadopago.com/preapproval_plan/${currentMpPlanId}`
      : "https://api.mercadopago.com/preapproval_plan";
    const mercadoPagoResponse = await fetch(endpoint, {
      method: currentMpPlanId ? "PUT" : "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        ...(currentMpPlanId ? {} : { "X-Idempotency-Key": localPlanId }),
      },
      body: JSON.stringify({
        reason: String(plan.name),
        external_reference: localPlanId,
        back_url: Deno.env.get("MP_BACK_URL")?.trim() ||
          MP_SUBSCRIPTION_SUCCESS_URL,
        auto_recurring: {
          frequency,
          frequency_type: "months",
          currency_id: "BRL",
          transaction_amount: transactionAmount,
        },
      }),
    });
    const mercadoPagoData = await parseJson(mercadoPagoResponse);
    const mercadoPagoPlanId = String(
      mercadoPagoData.id ?? currentMpPlanId,
    ).trim();
    if (!mercadoPagoResponse.ok || !mercadoPagoPlanId) {
      return jsonResponse({
        error: currentMpPlanId
          ? "Não foi possível atualizar o plano no Mercado Pago."
          : "Não foi possível criar o plano no Mercado Pago.",
        status: mercadoPagoResponse.status,
        details: mercadoPagoData,
      }, mercadoPagoResponse.status || 502);
    }

    // Sync bem-sucedido: libera o plano (active) sem exigir segundo clique no admin.
    const { data: updatedPlan, error: updateError } = await supabase
      .from("plans")
      .update({
        mp_plan_id: mercadoPagoPlanId,
        mp_status: "synchronized",
        active: true,
        updated_at: new Date().toISOString(),
      })
      .eq("id", localPlanId)
      .eq("barbershop_id", plan.barbershop_id)
      .select("id, mp_status, mp_plan_id, active")
      .maybeSingle();

    if (updateError || !updatedPlan) {
      return jsonResponse(
        {
          error: "Plano criado, mas não foi salvo no Supabase.",
          details: updateError?.message ?? "Plano local não encontrado.",
          mp_plan_id: mercadoPagoPlanId,
        },
        500,
      );
    }

    return jsonResponse({
      success: true,
      plan_id: localPlanId,
      mp_plan_id: mercadoPagoPlanId,
      mp_status: "synchronized",
      active: true,
      frequency_months: frequency,
      transaction_amount: transactionAmount,
      operation: currentMpPlanId ? "updated" : "created",
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
