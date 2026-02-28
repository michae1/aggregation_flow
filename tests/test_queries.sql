USE DATABASE IMPRESSIONS_DB;
USE SCHEMA GOLD;

TRUNCATE TABLE IF EXISTS SILVER.sites_mapping;
TRUNCATE TABLE IF EXISTS BRONZE.impressions_raw;
TRUNCATE TABLE IF EXISTS BRONZE.sites_raw;

INSERT INTO BRONZE.sites_raw (id, name)
SELECT 'site_' || TO_VARCHAR(seq) AS id,
       'Site ' || INITCAP(CASE WHEN MOD(seq,2)=0 THEN 'news' ELSE 'blog' END) AS name
FROM (
  SELECT SEQ4() AS seq
  FROM TABLE(GENERATOR(ROWCOUNT => 5))
);

INSERT INTO BRONZE.impressions_raw (id, geo_point, category, site_id, view_count, event_date)
WITH mock_impressions AS (
  SELECT
    MD5(TO_VARCHAR(seq)) AS id,
    TO_GEOGRAPHY(
      'POINT(' ||
      TO_VARCHAR(-74.0 + MOD(seq, 6) * 0.5) || ' ' ||
      TO_VARCHAR(40.0 + MOD(FLOOR(seq / 6), 6) * 0.3) ||
      ')'
    ) AS geo_point,
    CASE MOD(seq, 4)
      WHEN 0 THEN 'Tech'
      WHEN 1 THEN 'Finance'
      WHEN 2 THEN 'Sports'
      ELSE 'Entertainment'
    END AS category,
    CASE MOD(seq, 3)
      WHEN 0 THEN 'site_0'
      WHEN 1 THEN 'site_1'
      ELSE 'site_2'
    END AS site_id,
    MOD(seq, 100) + 1 AS view_count,
    DATEADD('day', -MOD(seq, 30), DATE '2026-02-24') AS event_date
  FROM (
    SELECT seq4() AS seq
    FROM TABLE(GENERATOR(ROWCOUNT => 900))
  ) gen
)
SELECT * FROM mock_impressions;

INSERT INTO SILVER.sites_mapping (client_id, role, allowed_sites)
SELECT CURRENT_USER(), CURRENT_ROLE(), ARRAY_CONSTRUCT('site_0', 'site_1')
WHERE NOT EXISTS (
  SELECT 1 FROM SILVER.sites_mapping WHERE client_id = CURRENT_USER()
);

INSERT INTO SILVER.sites_mapping (client_id, role, allowed_sites)
SELECT 'legacy_tool', 'ANALYST', ARRAY_CONSTRUCT('site_1', 'site_2')
WHERE NOT EXISTS (
  SELECT 1 FROM SILVER.sites_mapping WHERE client_id = 'legacy_tool' AND role = 'ANALYST'
);

ALTER DYNAMIC TABLE GOLD.agg_geo_category_site REFRESH;

CALL GOLD.test_pipeline();

SET user_sites = 'site_0';

SELECT CASE
  WHEN (SELECT COUNT(*) FROM GOLD.gold_view) =
       (SELECT COUNT(*) FROM GOLD.agg_geo_category_site WHERE site_id = 'site_0') THEN 1
  ELSE (SELECT 1/0)
END AS rap_filter_status;

UNSET user_sites;

SELECT CASE
  WHEN (SELECT COUNT(*) FROM GOLD.gold_view) =
       (SELECT COUNT(*) FROM GOLD.agg_geo_category_site) THEN 1
  ELSE (SELECT 1/0)
END AS rap_default_status;
