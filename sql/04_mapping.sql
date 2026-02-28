USE DATABASE IMPRESSIONS_DB;
USE SCHEMA SILVER;

CREATE OR REPLACE TABLE sites_mapping (
  client_id     VARCHAR(64),
  role          VARCHAR(64),
  allowed_sites ARRAY
);

TRUNCATE TABLE sites_mapping;

INSERT INTO sites_mapping (client_id, role, allowed_sites)
SELECT 'CI_CLIENT', 'SYSADMIN', ARRAY_CONSTRUCT('site_0', 'site_1')
UNION ALL
SELECT 'DEMO_USER', 'ANALYST', ARRAY_CONSTRUCT('site_1', 'site_2');
