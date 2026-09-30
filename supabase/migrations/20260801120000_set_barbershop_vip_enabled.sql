-- Toggle seguro do Clube VIP por admin do tenant.
-- Evita update silencioso bloqueado por RLS na tabela barbershops.

create or replace function public.set_barbershop_vip_enabled(p_enabled boolean)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_barbershop_id uuid;
  v_new_value boolean;
begin
  if auth.uid() is null then
    raise exception using errcode = '28000', message = 'Usuário não autenticado.';
  end if;

  select u.barbershop_id
    into v_barbershop_id
    from public.users u
   where u.id = auth.uid()
     and lower(u.role::text) = 'admin'
   limit 1;

  if v_barbershop_id is null then
    raise exception using errcode = '42501',
      message = 'Acesso negado: apenas administradores podem alterar o Clube VIP.';
  end if;

  update public.barbershops
     set vip_enabled = coalesce(p_enabled, false)
   where id = v_barbershop_id
  returning vip_enabled into v_new_value;

  if not found then
    raise exception using errcode = 'P0002', message = 'Barbearia não encontrada.';
  end if;

  return v_new_value;
end;
$$;

revoke all on function public.set_barbershop_vip_enabled(boolean) from public;
grant execute on function public.set_barbershop_vip_enabled(boolean) to authenticated;
