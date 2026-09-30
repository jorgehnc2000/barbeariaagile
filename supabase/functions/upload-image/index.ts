import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MAX_BYTES = 5 * 1024 * 1024;
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

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
  return (req.headers.get("Authorization") ?? "")
    .match(/^Bearer\s+(.+)$/i)?.[1]?.trim() ?? "";
}

function decodeBase64(value: string): Uint8Array | null {
  const normalized = value.replace(
    /^data:image\/[a-z0-9.+-]+;base64,/i,
    "",
  );
  try {
    const binary = atob(normalized);
    if (binary.length > MAX_BYTES) return null;
    return Uint8Array.from(binary, (character) => character.charCodeAt(0));
  } catch {
    return null;
  }
}

function hasImageSignature(bytes: Uint8Array) {
  if (bytes.length >= 3 &&
      bytes[0] === 0xff &&
      bytes[1] === 0xd8 &&
      bytes[2] === 0xff) {
    return true;
  }
  if (bytes.length >= 8 &&
      bytes[0] === 0x89 &&
      bytes[1] === 0x50 &&
      bytes[2] === 0x4e &&
      bytes[3] === 0x47) {
    return true;
  }
  if (bytes.length >= 6 &&
      bytes[0] === 0x47 &&
      bytes[1] === 0x49 &&
      bytes[2] === 0x46) {
    return true;
  }
  if (bytes.length >= 12 &&
      bytes[0] === 0x52 &&
      bytes[1] === 0x49 &&
      bytes[2] === 0x46 &&
      bytes[3] === 0x46 &&
      bytes[8] === 0x57 &&
      bytes[9] === 0x45 &&
      bytes[10] === 0x42 &&
      bytes[11] === 0x50) {
    return true;
  }
  return bytes.length >= 2 && bytes[0] === 0x42 && bytes[1] === 0x4d;
}

function safeImageName(value: unknown) {
  const name = String(value ?? "image")
    .trim()
    .replace(/\.[a-z0-9]+$/i, "")
    .replace(/[^a-z0-9_-]+/gi, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80);
  return name || "image";
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
    const imgbbApiKey = Deno.env.get("IMGBB_API_KEY")?.trim();
    const token = bearerToken(req);

    if (!supabaseUrl || !serviceRoleKey || !imgbbApiKey) {
      return jsonResponse(
        { error: "Configuração do upload não encontrada." },
        500,
      );
    }
    if (!token) {
      return jsonResponse({ error: "JWT ausente." }, 401);
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
    if (profileError || !profile) {
      return jsonResponse({ error: "Perfil do usuário não encontrado." }, 403);
    }
    if (String(profile.role ?? "").trim().toLowerCase() !== "admin") {
      return jsonResponse(
        { error: "Acesso restrito a administradores." },
        403,
      );
    }

    const body = await req.json().catch(() => null);
    const encoded = String(body?.image_base64 ?? "").trim();
    if (!encoded) {
      return jsonResponse({ error: "Imagem ausente." }, 400);
    }
    if (encoded.length > Math.ceil(MAX_BYTES / 3) * 4 + 8) {
      return jsonResponse(
        { error: "A imagem ultrapassa 5 MB." },
        413,
      );
    }

    const bytes = decodeBase64(encoded);
    if (!bytes || bytes.length === 0 || bytes.length > MAX_BYTES) {
      return jsonResponse(
        { error: "A imagem é inválida ou ultrapassa 5 MB." },
        400,
      );
    }
    if (!hasImageSignature(bytes)) {
      return jsonResponse(
        { error: "Arquivo inválido. Envie uma imagem válida." },
        400,
      );
    }

    const form = new FormData();
    form.append("image", encoded.replace(/^data:image\/[^;]+;base64,/i, ""));
    form.append("name", safeImageName(body?.file_name));

    const response = await fetch(
      `https://api.imgbb.com/1/upload?key=${encodeURIComponent(imgbbApiKey)}`,
      {
        method: "POST",
        body: form,
      },
    );
    const result = await response.json().catch(() => null);
    const url = result?.data?.url;
    if (!response.ok || result?.success !== true || typeof url !== "string") {
      return jsonResponse(
        { error: "O provedor de imagens recusou o upload." },
        502,
      );
    }

    return jsonResponse({ url: url.trim() });
  } catch (_) {
    return jsonResponse(
      { error: "Não foi possível concluir o upload." },
      500,
    );
  }
});
