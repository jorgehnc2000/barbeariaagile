-- Permite que o cliente cancele seus próprios agendamentos futuros.
create or replace function public.cancel_user_booking(p_booking_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_row public.agendamentos%rowtype;
begin
  if v_user_id is null then
    raise exception using errcode = '28000', message = 'Usuário não autenticado.';
  end if;

  select *
    into v_row
    from public.agendamentos a
   where a.id = p_booking_id
     and a.cliente_id = v_user_id
   for update;

  if not found then
    raise exception using errcode = '42501', message = 'Agendamento não encontrado.';
  end if;

  if lower(v_row.status::text) in ('cancelado', 'canceled', 'cancelled') then
    raise exception using errcode = '22023', message = 'Este agendamento já foi cancelado.';
  end if;

  if v_row.data_inicio <= now() then
    raise exception using errcode = '22023', message = 'Não é possível cancelar agendamentos passados.';
  end if;

  update public.agendamentos
     set status = 'cancelado'
   where id = p_booking_id;
end;
$$;

grant execute on function public.cancel_user_booking(uuid) to authenticated;
