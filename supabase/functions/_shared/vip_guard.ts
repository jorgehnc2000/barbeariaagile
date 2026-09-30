import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export async function assertVipEnabledForBarbershop(
  supabase: ReturnType<typeof createClient>,
  barbershopId: string,
): Promise<{ ok: true } | { ok: false; status: number; body: Record<string, unknown> }> {
  const { data, error } = await supabase
    .from("barbershops")
    .select("vip_enabled")
    .eq("id", barbershopId)
    .maybeSingle();

  if (error) {
    return {
      ok: false,
      status: 500,
      body: {
        error: "Não foi possível validar o Clube VIP da barbearia.",
        details: error.message,
      },
    };
  }

  if (data?.vip_enabled !== true) {
    return {
      ok: false,
      status: 422,
      body: {
        error: "O Clube VIP não está habilitado nesta barbearia.",
      },
    };
  }

  return { ok: true };
}
