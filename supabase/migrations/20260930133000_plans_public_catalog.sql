-- O catálogo VIP (planos ativos e já sincronizados) precisa aparecer
-- antes do login. A assinatura continua só pela Edge Function autenticada.

drop policy if exists plans_public_catalog on public.plans;
create policy plans_public_catalog
  on public.plans
  for select
  to anon, authenticated
  using (active = true and mp_status = 'synchronized');
