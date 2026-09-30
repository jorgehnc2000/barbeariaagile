export const APP_PRODUCTION_ORIGIN =
  Deno.env.get("APP_BASE_URL")?.trim() || "https://barbeariaagile.vercel.app";

export const MP_SUBSCRIPTION_SUCCESS_URL =
  `${APP_PRODUCTION_ORIGIN}/sucesso-assinatura`;
