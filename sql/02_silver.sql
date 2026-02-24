USE DATABASE SURVEY_DB;
USE SCHEMA survey_agg;

CREATE OR REPLACE VIEW surveys_clean AS
SELECT
  id,
  geo_point,
  sector,
  brand_id,
  response_score,
  response_date,
  TO_VARIANT(geo_point) AS geo_variant,
  TRIM(UPPER(sector)) AS normalized_sector
FROM surveys_raw
WHERE sector IS NOT NULL
  AND response_score BETWEEN 0 AND 10;

CREATE OR REPLACE VIEW brands_clean AS
SELECT
  id,
  INITCAP(name) AS display_name
FROM brands_raw;
