# Survey Aggregation PoC

A small Snowflake project `SurveyAgg` for collecting and aggregating survey results by regions, categories, and brands. Follows the medallion architecture: Bronze (raw), Silver (clean), Gold (dynamic aggregation + RAP), plus CI/CD scripts without dbt.

## Structure

- `sql/01_bronze.sql` — DDL for raw tables (`surveys_raw`, `brands_raw`).
- `sql/02_silver.sql` — CTAS/view for cleaned `surveys_clean` and `brands_clean`.
- `sql/03_gold.sql` — `DYNAMIC TABLE` with AVG/COUNT aggregation of hash districts, sectors, brands.
- `sql/04_mapping.sql` — `brands_mapping` table with allowed brands per client/role.
- `sql/05_rap.sql` — ROW ACCESS POLICY `filter_brands` + protected view on Gold.
- `sql/06_task.sql` — `TASK` for daily REFRESH of the dynamic table.
- `sql/07_test_proc.sql` — Stored procedure `test_pipeline()` with HASH/SUM/COUNT validations.
- `tests/test_queries.sql` — CI queries: mock data, `CALL test_pipeline()`, RAP filters.
- `deploy.sql` — master script, configured for SnowSQL/SnowCLI deployment.
- `.github/workflows/ci-tests.yml` — test execution on PR/MR.
- `.github/workflows/cd-deploy.yml` — deployment on push/main.

## Prerequisites

1. **Snowflake**: must have configured `DATABASE`, `SCHEMA`, `WAREHOUSE`, `ROLE`, `USER`, `ACCOUNT`. Required secrets for workflows:
   - `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_SCHEMA`
   - `SNOWFLAKE_PRIVATE_KEY`, `SNOWFLAKE_PRIVATE_KEY_PASSPHRASE`
   - For production deployment additionally `SNOWFLAKE_PROD_*` (similar keys/parameters).
2. **SnowCLI**: used in GitHub Actions and locally via `pip install snowcli`.
3. **Permissions**: user must have access to `CREATE DATABASE`, `CREATE SCHEMA`, `CREATE TASK`, `ROW ACCESS POLICY`, etc.

## Local Usage

```bash
pip install --upgrade snowcli
snow auth login --account <account> --user <user> --private-key-path <key> \
  --role <role> --warehouse <warehouse> --database <database> --schema <schema>
```

Then run the full stack:

```bash
snow sql --file deploy.sql
```

Or execute individual scripts (e.g., `snow sql --file sql/03_gold.sql`).

## Tests

1. Deploy objects to dev (if needed): `snow sql --file deploy.sql`
2. Run CI scenario:
   ```bash
   snow sql --file tests/test_queries.sql
   ```
3. The script generates mock data using `GENERATOR`, executes `ALTER DYNAMIC TABLE ... REFRESH`, calls `CALL GOLD.test_pipeline()`, tests `RAP` via `SET user_brands = '...'`.

## CI/CD (GitHub Actions)

- **ci-tests.yml**: runs on PR/MR, connects to dev account, executes `deploy.sql`, inserts mocks, runs `tests/test_queries.sql`.
- **cd-deploy.yml**: runs on `push`/merge to main branch, deploys to `prod` warehouse/schema via `deploy.sql`.

Both workflows use SnowCLI commands `snow sql --file <script>`; secrets are passed through `secrets` in GitHub (see `Env vars` section).

## Next Steps

1. Connect real data tables or `STREAM` for Bronze.
2. Extend test procedure logic `test_pipeline()` with new contracts.
3. Link RAP to user/role mapping with UI management.
