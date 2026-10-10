-- Parâmetros do clube de pontos definidos pela barbearia.
-- O cliente continua sem permissão de escrever saldo.

alter table public.loyalty_settings
  add column if not exists enabled boolean not null default true,
  add column if not exists reward_name text not null default '',
  add column if not exists reward_service_id uuid;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'loyalty_settings_reward_service_fk'
  ) then
    alter table public.loyalty_settings
      add constraint loyalty_settings_reward_service_fk
      foreign key (reward_service_id) references public.servicos (id) on delete set null;
  end if;
end
$$;

create or replace function public.loyalty_settings_same_shop()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.reward_service_id is null then
    return new;
  end if;
  if not exists (
    select 1
      from public.servicos s
     where s.id = new.reward_service_id
       and s.barbershop_id = new.barbershop_id
  ) then
    raise exception 'O serviço da recompensa precisa ser desta barbearia.';
  end if;
  return new;
end;
$$;

drop trigger if exists loyalty_settings_same_shop on public.loyalty_settings;
create trigger loyalty_settings_same_shop
  before insert or update of reward_service_id, barbershop_id
  on public.loyalty_settings
  for each row
  execute function public.loyalty_settings_same_shop();

grant select on public.loyalty_settings to anon, authenticated;
grant insert, update on public.loyalty_settings to authenticated;

create or replace function public.award_loyalty_for_booking()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_points integer;
  v_enabled boolean;
  v_status text := lower(coalesce(new.status::text, ''));
begin
  if v_status not in ('confirmado', 'concluido', 'completed', 'finalizado') then
    return new;
  end if;
  if new.cliente_id is null or new.barbershop_id is null or new.id is null then
    return new;
  end if;

  select s.enabled, s.points_per_completed_visit
    into v_enabled, v_points
    from public.loyalty_settings s
   where s.barbershop_id = new.barbershop_id;

  if coalesce(v_enabled, true) is not true then
    return new;
  end if;
  v_points := coalesce(v_points, 50);
  if v_points <= 0 then
    return new;
  end if;

  insert into public.loyalty_accounts (user_id, barbershop_id, points, member_since)
  values (new.cliente_id, new.barbershop_id, 0, current_date)
  on conflict (user_id, barbershop_id) do nothing;

  insert into public.loyalty_events (barbershop_id, user_id, agendamento_id, points)
  values (new.barbershop_id, new.cliente_id, new.id, v_points)
  on conflict (agendamento_id) do nothing;

  if found then
    update public.loyalty_accounts
       set points = points + v_points,
           updated_at = now()
     where user_id = new.cliente_id
       and barbershop_id = new.barbershop_id;
  end if;

  return new;
exception
  when foreign_key_violation then
    return new;
end;
$$;
