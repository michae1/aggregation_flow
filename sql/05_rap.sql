USE DATABASE IMPRESSIONS_DB;
USE SCHEMA GOLD;

-- Drop dependent view first to allow policy replacement
DROP VIEW IF EXISTS gold_view;

CREATE OR REPLACE ROW ACCESS POLICY filter_sites AS (site_id VARCHAR)
RETURNS BOOLEAN ->
  CASE
    -- check session variable if exists (MUST be uppercase)
    WHEN GETVARIABLE('USER_SITES') IS NOT NULL THEN
      ARRAY_CONTAINS(site_id::VARIANT, SPLIT(GETVARIABLE('USER_SITES'), ','))
    WHEN EXISTS (
      SELECT 1
      FROM SILVER.sites_mapping m
      WHERE m.client_id = CURRENT_USER()
        AND ARRAY_CONTAINS(site_id::VARIANT, m.allowed_sites)
    ) THEN TRUE
    WHEN EXISTS (
      SELECT 1
      FROM SILVER.sites_mapping m
      WHERE m.role = CURRENT_ROLE()
        AND ARRAY_CONTAINS(site_id::VARIANT, m.allowed_sites)
    ) THEN TRUE
    ELSE TRUE
  END;

CREATE OR REPLACE SECURE VIEW gold_view
WITH ROW ACCESS POLICY filter_sites ON (site_id)
AS
SELECT * FROM agg_geo_category_site;
