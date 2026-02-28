USE DATABASE IMPRESSIONS_DB;
USE SCHEMA GOLD;

CREATE OR REPLACE PROCEDURE test_pipeline()
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
const statement = snowflake.createStatement;

const aggHashStmt = statement({
  sqlText: `
    SELECT HASH_AGG(TO_VARIANT(ARRAY_CONSTRUCT(geo_h3, geo_region, category, site_id, impression_count, total_views))) AS ACTUAL_HASH
    FROM (
      SELECT geo_h3, geo_region, category, site_id, impression_count, total_views
      FROM GOLD.agg_geo_category_site
      ORDER BY geo_h3, category, site_id
    )`
});
const aggHash = aggHashStmt.execute();
aggHash.next();
const actualHash = aggHash.getColumnValue('ACTUAL_HASH');

const expectedHashStmt = statement({
  sqlText: `
    WITH groups AS (
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
      GROUP BY 1, 2, 3, 4
    )
    SELECT HASH_AGG(TO_VARIANT(ARRAY_CONSTRUCT(geo_h3, geo_region, category, site_id, impression_count, total_views))) AS EXPECTED_HASH
    FROM (
      SELECT *
      FROM groups
      ORDER BY geo_h3, category, site_id
    )`
});
const expectHashCursor = expectedHashStmt.execute();
expectHashCursor.next();
const expectedHash = expectHashCursor.getColumnValue('EXPECTED_HASH');

if (actualHash !== expectedHash) {
  throw new Error(`Hash contract mismatch: actual=${actualHash}, expected=${expectedHash}`);
}

const rawCountStmt = statement({ sqlText: `SELECT COUNT(*) total_raw FROM SILVER.impressions_clean` });
const rawCountCursor = rawCountStmt.execute();
rawCountCursor.next();
const rawCount = rawCountCursor.getColumnValue('TOTAL_RAW');

const aggSumStmt = statement({ sqlText: `SELECT SUM(impression_count) total_agg FROM GOLD.agg_geo_category_site` });
const aggSumCursor = aggSumStmt.execute();
aggSumCursor.next();
const aggSum = aggSumCursor.getColumnValue('TOTAL_AGG');

if (rawCount !== aggSum) {
  throw new Error(`Aggregation integrity failed: raw=${rawCount}, aggregated=${aggSum}`);
}

return `test_pipeline PASSED (${aggSum} impressions, hash ${actualHash})`;
$$;
