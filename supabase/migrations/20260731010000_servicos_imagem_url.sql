-- Imagem pública do serviço (URL ImgBB ou CDN).
alter table public.servicos
  add column if not exists imagem_url text;

comment on column public.servicos.imagem_url is
  'URL pública da imagem do serviço (ex.: ImgBB).';
