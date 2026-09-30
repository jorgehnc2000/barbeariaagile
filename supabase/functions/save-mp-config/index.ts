import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { assertVipEnabledForBarbershop } from "../_shared/vip_guard.ts";

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
    const barbershopId = String(body.barbershop_id ?? "").trim();
    const publicKey = String(body.mp_public_key ?? "").trim();
    const accessToken = String(body.mp_access_token ?? "").trim();
    if (!barbershopId || !publicKey || !accessToken) {
      return jsonResponse({
        error: "Informe barbershop_id, mp_public_key e mp_access_token.",
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
      .select("role, barbershop_id")
      .eq("id", authData.user.id)
      .maybeSingle();
    if (profileError) {
      return jsonResponse({
        error: "Não foi possível validar o administrador.",
        details: profileError.message,
      }, 500);
    }
    if (
      !profile ||
      String(profile.role ?? "").toLowerCase() !== "admin" ||
      String(profile.barbershop_id) !== barbershopId
    ) {
      return jsonResponse({
        error: "Administrador não pertence ao tenant informado.",
      }, 403);
    }

    const vipCheck = await assertVipEnabledForBarbershop(supabase, barbershopId);
    if (!vipCheck.ok) {
      return jsonResponse(vipCheck.body, vipCheck.status);
    }

    const { data: updatedRows, error: updateError } = await supabase
      .from("barbershops")
      .update({
        mp_public_key: publicKey,
        mp_access_token: accessToken,
      })
      .eq("id", barbershopId)
      .select("id");
    if (updateError) {
      return jsonResponse({
        error: "Não foi possível salvar as credenciais.",
        details: updateError.message,
      }, 500);
    }
    if (!updatedRows?.length) {
      return jsonResponse({ error: "Barbearia não encontrada." }, 404);
    }

    return jsonResponse({
      success: true,
      barbershop_id: barbershopId,
      configured: true,
    });
  } catch (error) {
    return jsonResponse({
      error: "Erro interno na Edge Function.",
      details: error instanceof Error ? error.message : String(error),
    }, 500);
  }
});
