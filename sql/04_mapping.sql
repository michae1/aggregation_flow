USE DATABASE SURVEY_DB;
USE SCHEMA SILVER;

CREATE OR REPLACE TABLE brands_mapping (
  client_id      VARCHAR(64),
  role           VARCHAR(64),
  allowed_brands ARRAY
);

TRUNCATE TABLE brands_mapping;

INSERT INTO brands_mapping (client_id, role, allowed_brands) VALUES
  ('CI_CLIENT', 'SYSADMIN', ARRAY_CONSTRUCT('brand_0', 'brand_1')),
  ('DEMO_USER', 'ANALYST', ARRAY_CONSTRUCT('brand_1', 'brand_2'));
