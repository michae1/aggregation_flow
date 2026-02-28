USE DATABASE IMPRESSIONS_DB;
USE SCHEMA SILVER;

CREATE OR REPLACE VIEW impressions_clean AS
SELECT
  id,
  geo_point,
  category,
  site_id,
  view_count,
  event_date,
  ST_ASWKB(geo_point) AS geo_variant,
  TRIM(UPPER(category)) AS normalized_category
FROM BRONZE.impressions_raw
WHERE category IS NOT NULL
  AND view_count > 0;

CREATE OR REPLACE VIEW sites_clean AS
SELECT
  id,
  INITCAP(name) AS display_name
FROM BRONZE.sites_raw;
