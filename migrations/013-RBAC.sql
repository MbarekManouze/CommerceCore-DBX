-- Base roles
CREATE ROLE app_readonly;
CREATE ROLE app_readwrite;
CREATE ROLE app_admin;


-- Application DB user that your Node.js app will use
CREATE USER myapp_app WITH PASSWORD 'myapp_app_password';

-- Read-only/reporting user (for analytics, BI, etc.)
CREATE USER myapp_reporting WITH PASSWORD 'myapp_reporting_password';


GRANT app_readwrite TO myapp_app;
GRANT app_admin     TO myapp_app;      -- preferred in dev mode
GRANT app_readonly  TO myapp_reporting;


-- Allow them to connect to the db
GRANT CONNECT ON DATABASE myapp TO app_readwrite, app_readonly;

-- Allow usage of the public schema
GRANT USAGE ON SCHEMA public TO app_readwrite, app_readonly;


-- Read/write role: full Data Manipulation Language (DML) on all current tables
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA public
TO app_readwrite;

-- Read-only role: only SELECT
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO app_readonly;


-- Any table created in future in this schema: read/write
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_readwrite;

-- Future tables: read-only SELECT
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO app_readonly;


