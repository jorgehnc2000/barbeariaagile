-- Descrição textual do serviço (usada no admin e no app do cliente).
alter table public.servicos
  add column if not exists descricao text;

comment on column public.servicos.descricao is
  'Descrição opcional do serviço exibida no catálogo.';
