-- ============================================================
-- DDL: barbearia_info + extensões de schema relacionadas
-- Execute no SQL Editor do Supabase
-- ============================================================

-- Tabela principal de informações institucionais da barbearia
CREATE TABLE IF NOT EXISTS public.barbearia_info (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    endereco TEXT NOT NULL,
    telefone TEXT,
    instagram_url TEXT,
    foto_capa_url TEXT,
    horarios_funcionamento JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.barbearia_info IS 'Informações institucionais da barbearia (singleton)';
COMMENT ON COLUMN public.barbearia_info.horarios_funcionamento IS
    'Horários em JSONB. Ex: {"Segunda a Sexta": "09h às 20h", "Sábado": "09h às 18h", "Domingo": "Fechado"}';

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_barbearia_info_updated_at ON public.barbearia_info;
CREATE TRIGGER trg_barbearia_info_updated_at
    BEFORE UPDATE ON public.barbearia_info
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- Coluna de disponibilidade nos barbeiros (caso ainda não exista)
ALTER TABLE public.barbeiros
    ADD COLUMN IF NOT EXISTS disponivel BOOLEAN NOT NULL DEFAULT true;

-- Extensão da tabela users para perfil completo
ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS email TEXT,
    ADD COLUMN IF NOT EXISTS telefone TEXT,
    ADD COLUMN IF NOT EXISTS foto_url TEXT;

-- RLS: leitura pública das informações da barbearia
ALTER TABLE public.barbearia_info ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Leitura pública barbearia_info" ON public.barbearia_info;
CREATE POLICY "Leitura pública barbearia_info"
    ON public.barbearia_info
    FOR SELECT
    USING (true);

-- RLS: usuário autenticado pode ler e atualizar seu próprio perfil
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuário lê próprio perfil" ON public.users;
CREATE POLICY "Usuário lê próprio perfil"
    ON public.users
    FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Usuário atualiza próprio perfil" ON public.users;
CREATE POLICY "Usuário atualiza próprio perfil"
    ON public.users
    FOR UPDATE
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Usuário insere próprio perfil" ON public.users;
CREATE POLICY "Usuário insere próprio perfil"
    ON public.users
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- RLS: usuário autenticado vê apenas seus agendamentos
ALTER TABLE public.agendamentos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cliente lê próprios agendamentos" ON public.agendamentos;
CREATE POLICY "Cliente lê próprios agendamentos"
    ON public.agendamentos
    FOR SELECT
    USING (auth.uid() = cliente_id);

-- Dados de exemplo (singleton)
INSERT INTO public.barbearia_info (
    nome,
    endereco,
    telefone,
    instagram_url,
    foto_capa_url,
    horarios_funcionamento
) VALUES (
    'Barbearia Agile',
    'Rua das Palmeiras, 123 — Centro, São Paulo — SP',
    '(11) 99999-0000',
    'https://instagram.com/barbeariaagile',
    'https://images.unsplash.com/photo-1585747860715-2ba37c788b70?w=800',
    '{
        "Segunda a Sexta": "09h às 20h",
        "Sábado": "09h às 18h",
        "Domingo": "Fechado"
    }'::jsonb
)
ON CONFLICT DO NOTHING;
