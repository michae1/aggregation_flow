USE DATABASE IMPRESSIONS_DB;
USE SCHEMA GOLD;

CREATE OR REPLACE DYNAMIC TABLE agg_geo_category_site
  TARGET_LAG = '1 day'
  WAREHOUSE = test_wh
AS
SELECT
  H3_POINT_TO_CELL(geo_point, 6) AS geo_h3,
  CASE
    WHEN ST_INTERSECTS(geo_point, ST_GEOGFROMTEXT('POLYGON((-180 45, -180 90, 180 90, 180 45, -180 45))')) THEN 'north'
    WHEN ST_INTERSECTS(geo_point, ST_GEOGFROMTEXT('POLYGON((-180 -90, -180 45, 180 45, 180 -90, -180 -90))')) THEN 'global'
    ELSE 'unknown'
  END AS geo_region,
  normalized_category AS category,
  site_id,
  COUNT(*) AS impression_count,
  SUM(view_count) AS total_views
FROM SILVER.impressions_clean
GROUP BY 1, 2, 3, 4;
