USE DATABASE SURVEY_DB;
USE SCHEMA GOLD;

TRUNCATE TABLE IF EXISTS SILVER.brands_mapping;
TRUNCATE TABLE IF EXISTS BRONZE.surveys_raw;
TRUNCATE TABLE IF EXISTS BRONZE.brands_raw;

INSERT INTO BRONZE.brands_raw (id, name)
SELECT 'brand_' || TO_VARCHAR(seq) AS id,
       'Brand ' || INITCAP(CASE WHEN MOD(seq,2)=0 THEN 'fast' ELSE 'premium' END) AS name
FROM (
  SELECT SEQ4() AS seq
  FROM TABLE(GENERATOR(ROWCOUNT => 5))
);

INSERT INTO BRONZE.surveys_raw (id, geo_point, sector, brand_id, response_score, response_date)
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
SELECT * FROM mock_surveys;

INSERT INTO SILVER.brands_mapping (client_id, role, allowed_brands)
SELECT CURRENT_USER(), CURRENT_ROLE(), ARRAY_CONSTRUCT('brand_0', 'brand_1')
WHERE NOT EXISTS (
  SELECT 1 FROM SILVER.brands_mapping WHERE client_id = CURRENT_USER()
);

INSERT INTO SILVER.brands_mapping (client_id, role, allowed_brands)
SELECT 'legacy_tool', 'ANALYST', ARRAY_CONSTRUCT('brand_1', 'brand_2')
WHERE NOT EXISTS (
  SELECT 1 FROM SILVER.brands_mapping WHERE client_id = 'legacy_tool' AND role = 'ANALYST'
);

ALTER DYNAMIC TABLE GOLD.agg_geo_sector_brand REFRESH;

CALL GOLD.test_pipeline();

SET user_brands = 'brand_0';

SELECT CASE
  WHEN (SELECT COUNT(*) FROM GOLD.gold_view) =
       (SELECT COUNT(*) FROM GOLD.agg_geo_sector_brand WHERE brand_id = 'brand_0') THEN 'rap-filter-passed'
  ELSE (SELECT 1/0)
END AS rap_status;

UNSET user_brands;

SELECT CASE
  WHEN (SELECT COUNT(*) FROM GOLD.gold_view) =
       (SELECT COUNT(*) FROM GOLD.agg_geo_sector_brand) THEN 'rap-default-passed'
  ELSE (SELECT 1/0)
END AS rap_default;
