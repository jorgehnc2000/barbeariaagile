import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { fetchLastAuthorizedPayment } from "../_shared/mp_payments.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function bearerToken(req: Request) {
  return (req.headers.get("Authorization") ?? "")
    .match(/^Bearer\s+(.+)$/i)?.[1]?.trim() ?? "";
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

function normalizeMpStatus(raw: unknown): string {
  const status = String(raw ?? "").trim().toLowerCase();
  if (!status) return "pending";
  if (status === "cancelled" || status === "cancelado") return "canceled";
  return status;
}

type SubscriptionRow = {
  id: string;
  user_id: string;
  barbershop_id: string;
  mp_preapproval_id: string | null;
  status: string;
  next_payment_date?: string | null;
  last_payment_status?: string | null;
};

async function syncOne(
  supabase: ReturnType<typeof createClient>,
  subscription: SubscriptionRow,
  accessToken: string,
) {
  const preapprovalId = String(subscription.mp_preapproval_id ?? "").trim();
  if (!preapprovalId) {
    return {
      subscription_id: subscription.id,
      updated: false,
      error: "Assinatura sem mp_preapproval_id.",
      previous_status: subscription.status,
      status: subscription.status,
    };
  }

  const mercadoPagoResponse = await fetch(
    `https://api.mercadopago.com/preapproval/${preapprovalId}`,
    {
      method: "GET",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
    },
  );
  const mercadoPagoData = await parseJson(mercadoPagoResponse);
  if (!mercadoPagoResponse.ok) {
    return {
      subscription_id: subscription.id,
      updated: false,
      error: "Falha ao consultar o Mercado Pago.",
      status_code: mercadoPagoResponse.status,
      details: mercadoPagoData,
      previous_status: subscription.status,
      status: subscription.status,
    };
  }

  const mpStatus = normalizeMpStatus(mercadoPagoData.status);
  const previous = normalizeMpStatus(subscription.status);
  const autoRecurring =
    mercadoPagoData.auto_recurring &&
    typeof mercadoPagoData.auto_recurring === "object"
      ? (mercadoPagoData.auto_recurring as Record<string, unknown>)
      : null;
  const nextPaymentDate =
    mercadoPagoData.next_payment_date ??
    autoRecurring?.next_payment_date ??
    null;

  const lastPayment = await fetchLastAuthorizedPayment(
    accessToken,
    preapprovalId,
  );

  const patch: Record<string, unknown> = {
    status: mpStatus,
    updated_at: new Date().toISOString(),
  };
  if (nextPaymentDate) {
    patch.next_payment_date = nextPaymentDate;
  }
  if (lastPayment.status) {
    patch.last_payment_status = lastPayment.status;
    if (lastPayment.paidAt) {
      patch.last_payment_at = lastPayment.paidAt;
    }
  }
  if (
    ["canceled", "cancelled", "expired"].includes(mpStatus) &&
    !subscription.status.toLowerCase().includes("cancel")
  ) {
    patch.cancelled_at = new Date().toISOString();
  }

  if (
    mpStatus === previous &&
    !nextPaymentDate &&
    !lastPayment.status &&
    normalizeMpStatus(subscription.last_payment_status ?? "") === ""
  ) {
    return {
      subscription_id: subscription.id,
      updated: false,
      previous_status: previous,
      status: mpStatus,
      mp_preapproval_id: preapprovalId,
      last_payment_status: lastPayment.status,
    };
  }

  const previousPayment = normalizeMpStatus(
    subscription.last_payment_status ?? "",
  );
  const nextPayment = normalizeMpStatus(lastPayment.status ?? "");

  const { error: updateError } = await supabase
    .from("subscriptions")
    .update(patch)
    .eq("id", subscription.id)
    .eq("barbershop_id", subscription.barbershop_id);

  if (updateError) {
    return {
      subscription_id: subscription.id,
      updated: false,
      error: "Status obtido no MP, mas falhou ao salvar no Supabase.",
      details: updateError.message,
      previous_status: previous,
      status: mpStatus,
    };
  }

  return {
    subscription_id: subscription.id,
    updated: mpStatus !== previous || nextPayment !== previousPayment,
    previous_status: previous,
    status: mpStatus,
    mp_preapproval_id: preapprovalId,
    last_payment_status: lastPayment.status,
  };
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
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
    const token = bearerToken(req);
    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse({ error: "Configuração do Supabase ausente." }, 500);
    }
    if (!token) return jsonResponse({ error: "JWT ausente." }, 401);

    const body = await req.json().catch(() => ({}));
    const subscriptionId = String(body.subscription_id ?? "").trim();
    const syncAll = body.sync_all === true;

    if (!subscriptionId && !syncAll) {
      return jsonResponse({
        error: "Informe subscription_id ou sync_all: true.",
      }, 400);
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

    const { data: profile, error: profileError } = await supabase
      .from("users")
      .select("id, role, barbershop_id")
      .eq("id", authData.user.id)
      .maybeSingle();
    if (profileError || !profile) {
      return jsonResponse({ error: "Perfil do usuário não encontrado." }, 403);
    }

    const isAdmin = String(profile.role ?? "").toLowerCase() === "admin";
    const tenantId = String(profile.barbershop_id ?? "");

    let subscriptions: SubscriptionRow[] = [];

    if (syncAll) {
      if (!isAdmin) {
        return jsonResponse({
          error: "Somente admin pode sincronizar todas as assinaturas.",
        }, 403);
      }
      const { data, error } = await supabase
        .from("subscriptions")
        .select(
          "id, user_id, barbershop_id, mp_preapproval_id, status, next_payment_date, last_payment_status",
        )
        .eq("barbershop_id", tenantId);
      if (error) {
        return jsonResponse({
          error: "Não foi possível listar assinaturas.",
          details: error.message,
        }, 500);
      }
      subscriptions = (data ?? []) as SubscriptionRow[];
    } else {
      const { data: subscription, error: subscriptionError } = await supabase
        .from("subscriptions")
        .select(
          "id, user_id, barbershop_id, mp_preapproval_id, status, next_payment_date, last_payment_status",
        )
        .eq("id", subscriptionId)
        .maybeSingle();
      if (subscriptionError) {
        return jsonResponse({
          error: "Não foi possível carregar a assinatura.",
          details: subscriptionError.message,
        }, 500);
      }
      if (!subscription) {
        return jsonResponse({ error: "Assinatura não encontrada." }, 404);
      }

      const isOwner = subscription.user_id === authData.user.id;
      const isTenantAdmin =
        isAdmin && String(subscription.barbershop_id) === tenantId;
      if (!isOwner && !isTenantAdmin) {
        return jsonResponse({
          error: "Assinatura pertence a outro usuário ou tenant.",
        }, 403);
      }
      subscriptions = [subscription as SubscriptionRow];
    }

    if (subscriptions.length === 0) {
      return jsonResponse({ success: true, results: [], updated_count: 0 });
    }

    const barbershopId = String(subscriptions[0].barbershop_id);
    const { data: barbershop, error: barbershopError } = await supabase
      .from("barbershops")
      .select("mp_access_token")
      .eq("id", barbershopId)
      .maybeSingle();
    if (barbershopError) {
      return jsonResponse({
        error: "Não foi possível carregar as credenciais do tenant.",
        details: barbershopError.message,
      }, 500);
    }
    const accessToken = String(barbershop?.mp_access_token ?? "").trim();
    if (!accessToken) {
      return jsonResponse({
        error: "Access Token do Mercado Pago não configurado nesta barbearia.",
      }, 422);
    }

    const results = [];
    for (const subscription of subscriptions) {
      results.push(await syncOne(supabase, subscription, accessToken));
    }

    const updatedCount = results.filter((item) => item.updated).length;
    return jsonResponse({
      success: true,
      updated_count: updatedCount,
      results,
      ...(results.length === 1
        ? {
          subscription_id: results[0].subscription_id,
          status: results[0].status,
          previous_status: results[0].previous_status,
          updated: results[0].updated,
          last_payment_status: results[0].last_payment_status,
        }
        : {}),
    });
  } catch (error) {
    return jsonResponse({
      error: "Erro interno na Edge Function.",
      details: error instanceof Error ? error.message : String(error),
    }, 500);
  }
});
