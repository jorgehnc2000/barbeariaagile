-- ============================================================
-- Ajustes para o schema REAL do Supabase (Barbearia Moura)
-- Execute no SQL Editor do Supabase
-- ============================================================

-- 1. Permitir leitura pública da barbearia_info (RLS bloqueava o app)
ALTER TABLE public.barbearia_info ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Leitura pública barbearia_info" ON public.barbearia_info;
CREATE POLICY "Leitura pública barbearia_info"
    ON public.barbearia_info
    FOR SELECT
    USING (true);

-- 2. Adicionar coluna de horários (JSONB) se ainda não existir
ALTER TABLE public.barbearia_info
    ADD COLUMN IF NOT EXISTS horarios_funcionamento JSONB NOT NULL DEFAULT '{
        "Segunda a Sexta": "09h às 20h",
        "Sábado": "09h às 18h",
        "Domingo": "Fechado"
    }'::jsonb;

-- 3. Adicionar coluna de foto de capa (opcional)
ALTER TABLE public.barbearia_info
    ADD COLUMN IF NOT EXISTS foto_capa_url TEXT;

-- 4. Atualizar horários do registro existente (id = 3)
UPDATE public.barbearia_info
SET horarios_funcionamento = '{
    "Segunda a Sexta": "09h às 20h",
    "Sábado": "09h às 18h",
    "Domingo": "Fechado"
}'::jsonb
WHERE horarios_funcionamento IS NULL
   OR horarios_funcionamento = '{}'::jsonb;
