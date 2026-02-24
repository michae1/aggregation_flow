USE DATABASE SURVEY_DB;
USE SCHEMA GOLD;

CREATE OR REPLACE ROW ACCESS POLICY filter_brands AS (brand_id VARCHAR)
RETURNS BOOLEAN ->
  CASE
    -- check session variable if exists
    WHEN SYSTEM$GET_SESSION_VARIABLE('user_brands') IS NOT NULL THEN
      ARRAY_CONTAINS(brand_id::VARIANT, SPLIT(SYSTEM$GET_SESSION_VARIABLE('user_brands'), ','))
    WHEN EXISTS (
      SELECT 1
      FROM SILVER.brands_mapping m
      WHERE m.client_id = CURRENT_USER()
        AND ARRAY_CONTAINS(brand_id::VARIANT, m.allowed_brands)
    ) THEN TRUE
    WHEN EXISTS (
      SELECT 1
      FROM SILVER.brands_mapping m
      WHERE m.role = CURRENT_ROLE()
        AND ARRAY_CONTAINS(brand_id::VARIANT, m.allowed_brands)
    ) THEN TRUE
    ELSE TRUE
  END;

CREATE OR REPLACE SECURE VIEW gold_view
WITH ROW ACCESS POLICY filter_brands ON (brand_id)
AS
SELECT * FROM agg_geo_sector_brand;
