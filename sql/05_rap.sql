USE DATABASE SURVEY_DB;
USE SCHEMA survey_agg;

CREATE OR REPLACE ROW ACCESS POLICY filter_brands AS (brand_id VARCHAR)
RETURNS BOOLEAN ->
  CASE
    WHEN CURRENT_TAG('user_brands') IS NOT NULL THEN
      ARRAY_CONTAINS(SPLIT(CURRENT_TAG('user_brands'), ','), brand_id)
    WHEN EXISTS (
      SELECT 1
      FROM brands_mapping m
      WHERE m.client_id = CURRENT_CLIENT()
        AND ARRAY_CONTAINS(m.allowed_brands, brand_id)
    ) THEN TRUE
    WHEN EXISTS (
      SELECT 1
      FROM brands_mapping m
      WHERE m.role = CURRENT_ROLE()
        AND ARRAY_CONTAINS(m.allowed_brands, brand_id)
    ) THEN TRUE
    ELSE TRUE
  END;

CREATE OR REPLACE SECURE VIEW gold_view
WITH ROW ACCESS POLICY filter_brands ON (brand_id)
AS
SELECT * FROM agg_geo_sector_brand;
