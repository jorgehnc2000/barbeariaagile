import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

    const body = await req.json();
    const subscriptionId = String(body.subscription_id ?? "").trim();
    if (!subscriptionId) {
      return jsonResponse({ error: "Informe subscription_id." }, 400);
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
      data: subscription,
      error: subscriptionError,
    }] = await Promise.all([
      supabase
        .from("users")
        .select("id, role, barbershop_id")
        .eq("id", authData.user.id)
        .maybeSingle(),
      supabase
        .from("subscriptions")
        .select("id, user_id, barbershop_id, mp_preapproval_id, status")
        .eq("id", subscriptionId)
        .maybeSingle(),
    ]);
    if (profileError || subscriptionError) {
      return jsonResponse({
        error: "Não foi possível validar a solicitação.",
        details: profileError?.message ?? subscriptionError?.message,
      }, 500);
    }
    if (!profile) {
      return jsonResponse({ error: "Perfil do usuário não encontrado." }, 403);
    }
    if (!subscription) {
      return jsonResponse({ error: "Assinatura não encontrada." }, 404);
    }

    const isOwner = subscription.user_id === authData.user.id;
    const isTenantAdmin =
      String(profile.role ?? "").toLowerCase() === "admin" &&
      String(profile.barbershop_id) === String(subscription.barbershop_id);
    if (!isOwner && !isTenantAdmin) {
      return jsonResponse({
        error: "Assinatura pertence a outro usuário ou tenant.",
      }, 403);
    }
    if (
      isOwner &&
      String(profile.barbershop_id) !== String(subscription.barbershop_id)
    ) {
      return jsonResponse(
        { error: "Assinatura pertence a outro tenant." },
        403,
      );
    }
    if (
      ["canceled", "cancelled", "cancelado"].includes(
        String(subscription.status),
      )
    ) {
      return jsonResponse({ success: true, already_cancelled: true });
    }

    const { data: barbershop, error: barbershopError } = await supabase
      .from("barbershops")
      .select("mp_access_token")
      .eq("id", subscription.barbershop_id)
      .maybeSingle();
    if (barbershopError) {
      return jsonResponse({
        error: "Não foi possível carregar as credenciais do tenant.",
        details: barbershopError.message,
      }, 500);
    }
    const accessToken = String(barbershop?.mp_access_token ?? "").trim();
    const preapprovalId = String(subscription.mp_preapproval_id ?? "").trim();
    if (!accessToken || !preapprovalId) {
      return jsonResponse({
        error: "Assinatura sem Access Token ou preapproval do Mercado Pago.",
      }, 422);
    }

    const mercadoPagoResponse = await fetch(
      `https://api.mercadopago.com/preapproval/${preapprovalId}`,
      {
        method: "PUT",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ status: "canceled" }),
      },
    );
    const mercadoPagoData = await parseJson(mercadoPagoResponse);
    if (!mercadoPagoResponse.ok) {
      return jsonResponse({
        error: "O Mercado Pago não confirmou o cancelamento.",
        status: mercadoPagoResponse.status,
        details: mercadoPagoData,
      }, mercadoPagoResponse.status || 502);
    }

    const cancelledAt = new Date().toISOString();
    const { error: updateError } = await supabase
      .from("subscriptions")
      .update({
        status: "canceled",
        cancelled_at: cancelledAt,
        updated_at: cancelledAt,
      })
      .eq("id", subscription.id)
      .eq("barbershop_id", subscription.barbershop_id);
    if (updateError) {
      return jsonResponse({
        error:
          "Cancelamento confirmado no Mercado Pago, mas não salvo localmente.",
        details: updateError.message,
        reconciliation_required: true,
      }, 500);
    }

    return jsonResponse({
      success: true,
      subscription_id: subscription.id,
      status: "canceled",
      cancelled_at: cancelledAt,
    });
  } catch (error) {
    return jsonResponse({
      error: "Erro interno na Edge Function.",
      details: error instanceof Error ? error.message : String(error),
    }, 500);
  }
});
