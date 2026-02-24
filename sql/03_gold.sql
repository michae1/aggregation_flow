USE DATABASE SURVEY_DB;
USE SCHEMA GOLD;

CREATE OR REPLACE DYNAMIC TABLE agg_geo_sector_brand
  TARGET_LAG = '1 day'
  WAREHOUSE = survey_agg_wh
AS
SELECT
  H3_FROMGEOG(geo_point, 6) AS geo_h3,
  CASE
    WHEN ST_INTERSECTS(geo_point, ST_GEOGFROMTEXT('POLYGON((-180 45, -180 90, 180 90, 180 45, -180 45))')) THEN 'north'
    WHEN ST_INTERSECTS(geo_point, ST_GEOGFROMTEXT('POLYGON((-180 -90, -180 45, 180 45, 180 -90, -180 -90))')) THEN 'global'
    ELSE 'unknown'
  END AS geo_region,
  normalized_sector AS sector,
  brand_id,
  COUNT(*) AS response_count,
  AVG(response_score) AS avg_score
FROM SILVER.surveys_clean
GROUP BY geo_h3, geo_region, sector, brand_id;
