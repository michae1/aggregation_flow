USE ROLE ACCOUNTADMIN;
USE DATABASE survey_agg_demo;
USE SCHEMA survey_agg;

TRUNCATE TABLE IF EXISTS brands_mapping;
TRUNCATE TABLE IF EXISTS surveys_raw;
TRUNCATE TABLE IF EXISTS brands_raw;

INSERT INTO brands_raw (id, name)
SELECT 'brand_' || TO_VARCHAR(seq) AS id,
       'Brand ' || INITCAP(CASE WHEN MOD(seq,2)=0 THEN 'fast' ELSE 'premium' END) AS name
FROM (
  SELECT SEQ4() AS seq
  FROM TABLE(GENERATOR(ROWCOUNT => 5))
);

WITH mock_surveys AS (
  SELECT
    MD5(TO_VARCHAR(seq)) AS id,
    TO_GEOGRAPHY(
      'POINT(' ||
      TO_VARCHAR(-74.0 + MOD(seq, 6) * 0.5) || ' ' ||
      TO_VARCHAR(40.0 + MOD(FLOOR(seq / 6), 6) * 0.3) ||
      ')'
    ) AS geo_point,
    CASE MOD(seq, 4)
      WHEN 0 THEN 'Retail'
      WHEN 1 THEN 'Enterprise'
      WHEN 2 THEN 'Travel'
      ELSE 'Health'
    END AS sector,
    CASE MOD(seq, 3)
      WHEN 0 THEN 'brand_0'
      WHEN 1 THEN 'brand_1'
      ELSE 'brand_2'
    END AS brand_id,
    (MOD(seq, 40) + 10) / 5.0 AS response_score,
    DATEADD('day', -MOD(seq, 30), DATE '2026-02-24') AS response_date
  FROM (
    SELECT seq4() AS seq
    FROM TABLE(GENERATOR(ROWCOUNT => 900))
  ) gen
)
INSERT INTO surveys_raw (id, geo_point, sector, brand_id, response_score, response_date)
SELECT * FROM mock_surveys;

INSERT INTO brands_mapping (client_id, role, allowed_brands)
SELECT CURRENT_CLIENT(), CURRENT_ROLE(), ARRAY_CONSTRUCT('brand_0', 'brand_1')
WHERE NOT EXISTS (
  SELECT 1 FROM brands_mapping WHERE client_id = CURRENT_CLIENT()
);

INSERT INTO brands_mapping (client_id, role, allowed_brands)
SELECT 'legacy_tool', 'ANALYST', ARRAY_CONSTRUCT('brand_1', 'brand_2')
WHERE NOT EXISTS (
  SELECT 1 FROM brands_mapping WHERE client_id = 'legacy_tool' AND role = 'ANALYST'
);

ALTER DYNAMIC TABLE agg_geo_sector_brand REFRESH;

CALL test_pipeline();

ALTER SESSION SET TAG user_brands = 'brand_0';

SELECT CASE
  WHEN (SELECT COUNT(*) FROM gold_view) =
       (SELECT COUNT(*) FROM agg_geo_sector_brand WHERE brand_id = 'brand_0') THEN 'rap-filter-passed'
  ELSE (SELECT 1/0)
END AS rap_status;

ALTER SESSION UNSET TAG user_brands;

SELECT CASE
  WHEN (SELECT COUNT(*) FROM gold_view) =
       (SELECT COUNT(*) FROM agg_geo_sector_brand) THEN 'rap-default-passed'
  ELSE (SELECT 1/0)
END AS rap_default;
