CREATE OR REPLACE VIEW v_avaliacao_tabelas AS 
SELECT n.nspname as "Schema",
  c.relname as "Tabela",
  pg_catalog.pg_size_pretty(pg_table_size(c.oid)) as "Tamanho",
  pg_catalog.pg_size_pretty(pg_total_relation_size(c.oid)) as "Tamanho total",
  CASE WHEN pg_table_size(c.oid) > 1073741824 THEN 'MAIS DE 1 GB' ELSE 'MENOS DE 1 GB' END as avaliacao
FROM pg_catalog.pg_class c
     LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r','')
      AND n.nspname <> 'pg_catalog'
      AND n.nspname <> 'information_schema'
      AND n.nspname !~ '^pg_toast'
      AND pg_catalog.pg_table_is_visible(c.oid)
ORDER BY pg_table_size(c.oid) DESC,1,2;