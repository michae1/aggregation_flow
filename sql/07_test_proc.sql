USE DATABASE SURVEY_DB;
USE SCHEMA survey_agg;

CREATE OR REPLACE PROCEDURE test_pipeline()
RETURNS STRING
LANGUAGE JAVASCRIPT
AS
$$
const statement = snowflake.createStatement;

const aggHashStmt = statement({
  sqlText: `
    SELECT HASH_AGG(TO_VARIANT(ARRAY_CONSTRUCT(geo_h3, geo_region, sector, brand_id, response_count, ROUND(avg_score,5)))) AS actual_hash
    FROM (
      SELECT geo_h3, geo_region, sector, brand_id, response_count, avg_score
      FROM agg_geo_sector_brand
      ORDER BY geo_h3, sector, brand_id
    )`
});
const aggHash = aggHashStmt.execute();
aggHash.next();
const actualHash = aggHash.getColumnValue('actual_hash');

const expectedHashStmt = statement({
  sqlText: `
    WITH groups AS (
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
      FROM surveys_clean
      GROUP BY 1,2,3,4
    )
    SELECT HASH_AGG(TO_VARIANT(ARRAY_CONSTRUCT(geo_h3, geo_region, sector, brand_id, response_count, ROUND(avg_score,5)))) AS expected_hash
    FROM (
      SELECT *
      FROM groups
      ORDER BY geo_h3, sector, brand_id
    )`
});
const expectHashCursor = expectedHashStmt.execute();
expectHashCursor.next();
const expectedHash = expectHashCursor.getColumnValue('expected_hash');

if (actualHash !== expectedHash) {
  throw new Error(`Hash contract mismatch: actual=${actualHash}, expected=${expectedHash}`);
}

const rawCountStmt = statement({ sqlText: `SELECT COUNT(*) total_raw FROM surveys_clean` });
const rawCountCursor = rawCountStmt.execute();
rawCountCursor.next();
const rawCount = rawCountCursor.getColumnValue('TOTAL_RAW');

const aggSumStmt = statement({ sqlText: `SELECT SUM(response_count) total_agg FROM agg_geo_sector_brand` });
const aggSumCursor = aggSumStmt.execute();
aggSumCursor.next();
const aggSum = aggSumCursor.getColumnValue('TOTAL_AGG');

if (rawCount !== aggSum) {
  throw new Error(`Aggregation integrity failed: raw=${rawCount}, aggregated=${aggSum}`);
}

return `test_pipeline PASSED (${aggSum} responses, hash ${actualHash})`;
$$;
