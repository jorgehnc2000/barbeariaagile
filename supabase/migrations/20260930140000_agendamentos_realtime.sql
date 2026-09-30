-- A home do cliente escuta mudanças do próprio agendamento.
alter table public.agendamentos replica identity full;

do $$
begin
  if not exists (
    select 1
      from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'agendamentos'
  ) then
    alter publication supabase_realtime add table public.agendamentos;
  end if;
end $$;
