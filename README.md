# Survey Aggregation PoC

Невеликий Snowflake-проєкт `SurveyAgg` для збору й агрегації результатів опитувань по регіонах, категоріях та брендах. Відповідає медальйонній архітектурі: Bronze (raw), Silver (clean), Gold (dynamic aggregation + RAP), плюс CI/CD-скрипти без dbt.

## Структура

- `sql/01_bronze.sql` — DDL для сирих таблиць (`surveys_raw`, `brands_raw`).
- `sql/02_silver.sql` — CTAS/view для очищених `surveys_clean` та `brands_clean`.
- `sql/03_gold.sql` — `DYNAMIC TABLE` з AVG/COUNT агрегацією хеш-районів, секторів, брендів.
- `sql/04_mapping.sql` — таблиця `brands_mapping` з дозволеними брендами на клієнта/роль.
- `sql/05_rap.sql` — ROW ACCESS POLICY `filter_brands` + захищений view на Gold.
- `sql/06_task.sql` — `TASK` для щоденного REFRESH динамічної таблиці.
- `sql/07_test_proc.sql` — Stored procedure `test_pipeline()` з HASH/SUM/COUNT перевірками.
- `tests/test_queries.sql` — CI-запити: mock data, `CALL test_pipeline()`, RAP-фільтри.
- `deploy.sql` — master script, підлаштований під SnowSQL/SnowCLI deployment.
- `.github/workflows/ci-tests.yml` — прогін тестів на PR/MR.
- `.github/workflows/cd-deploy.yml` — деплой на push/main.

## Передумови

1. **Snowflake**: має бути налаштовано `DATABASE`, `SCHEMA`, `WAREHOUSE`, `ROLE`, `USER`, `ACCOUNT`. Потрібні секрети для workflows:
   - `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_SCHEMA`
   - `SNOWFLAKE_PRIVATE_KEY`, `SNOWFLAKE_PRIVATE_KEY_PASSPHRASE`
   - Для продакшн-розгортання додатково `SNOWFLAKE_PROD_*` (аналогічні ключі/параметри).
2. **SnowCLI**: використовується у GitHub Actions і локально через `pip install snowcli`.
3. **Права**: користувач повинен мати доступ на `CREATE DATABASE`, `CREATE SCHEMA`, `CREATE TASK`, `ROW ACCESS POLICY` тощо.

## Локально

```bash
pip install --upgrade snowcli
snow auth login --account <account> --user <user> --private-key-path <key> \
  --role <role> --warehouse <warehouse> --database <database> --schema <schema>
```

Потім запускайте весь стек:

```bash
snow sql --file deploy.sql
```

Або виконуйте окремі скрипти (наприклад, `snow sql --file sql/03_gold.sql`).

## Тести

1. Деплой обʼєктів на деві (якщо треба): `snow sql --file deploy.sql`
2. Прогін CI-сценарію:
   ```bash
   snow sql --file tests/test_queries.sql
   ```
3. Скрипт генерує mock-дані за допомогою `GENERATOR`, виконує `ALTER DYNAMIC TABLE ... REFRESH`, викликає `CALL GOLD.test_pipeline()`, тестує `RAP` через `SET user_brands = '...'`.

## CI/CD (GitHub Actions)

- **ci-tests.yml**: запускається на PR/MR, підключається до дев-облікового запису, виконує `deploy.sql`, вставляє mocks, запускає `tests/test_queries.sql`.
- **cd-deploy.yml**: запускається на `push`/merge в основну гілку, деплоїть у `prod` warehouse/схему через `deploy.sql`.

Обидва workflow використовують SnowCLI-команди `snow sql --file <script>`; секрети передаються через `secrets` у GitHub (див. секцію `Env vars`).

## Наступні кроки

1. Підключити реальні таблиці даних або `STREAM` для Bronze.
2. Розширити тестову процедурну логіку `test_pipeline()` новими контрактами.
3. Підвʼязати RAP до user/role mapping з управлінням у UI.
