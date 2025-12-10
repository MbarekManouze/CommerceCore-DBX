CREATE EXTENSION IF NOT EXISTS pg_stat_statements;


-- Then in postgresql.conf :
    -- / shared_preload_libraries = 'pg_stat_statements'
    -- / pg_stat_statements.track = all
