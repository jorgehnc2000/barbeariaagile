-- Permite que administradores do tenant criem e atualizem barbearia_info.

alter table public.barbearia_info enable row level security;

drop policy if exists barbearia_info_admin_insert on public.barbearia_info;
create policy barbearia_info_admin_insert
  on public.barbearia_info
  for insert
  to authenticated
  with check (public.is_admin_for_tenant(barbershop_id));

drop policy if exists barbearia_info_admin_update on public.barbearia_info;
create policy barbearia_info_admin_update
  on public.barbearia_info
  for update
  to authenticated
  using (public.is_admin_for_tenant(barbershop_id))
  with check (public.is_admin_for_tenant(barbershop_id));
