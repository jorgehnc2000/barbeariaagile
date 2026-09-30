-- =============================================================================
-- DIAGNÓSTICO: top 5 consultas por I/O e tempo (pg_stat_statements)
-- Execute no SQL Editor do Supabase (Dashboard → SQL → New query).
--
-- Pré-requisito: extensão pg_stat_statements habilitada (padrão no Supabase).
-- Se a view não existir, ative em Database → Extensions → pg_stat_statements.
-- =============================================================================

-- Por blocos lidos em disco (shared + local) — melhor proxy de Disk I/O
select
  left(query, 200) as query_preview,
  calls,
  round(total_exec_time::numeric, 2) as total_ms,
  round(mean_exec_time::numeric, 2) as mean_ms,
  rows,
  shared_blks_read,
  shared_blks_hit,
  local_blks_read,
  temp_blks_read,
  round(
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0),
    2
  ) as cache_hit_pct
from pg_stat_statements
where query not ilike '%pg_stat_statements%'
  and query not ilike '%analyze%'
order by (shared_blks_read + local_blks_read + temp_blks_read) desc
limit 5;

-- ---------------------------------------------------------------------------
-- Alternativa: top 5 por tempo total acumulado (útil se I/O estiver em cache)
-- ---------------------------------------------------------------------------
/*
select
  left(query, 200) as query_preview,
  calls,
  round(total_exec_time::numeric, 2) as total_ms,
  round(mean_exec_time::numeric, 2) as mean_ms,
  rows,
  shared_blks_read,
  shared_blks_hit
from pg_stat_statements
where query not ilike '%pg_stat_statements%'
order by total_exec_time desc
limit 5;
*/

-- ---------------------------------------------------------------------------
-- Reset opcional após deploy de índices (aguardar tráfico real antes)
-- ---------------------------------------------------------------------------
-- select pg_stat_statements_reset();
