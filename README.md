# dbt_snowflake_demo

A complete starter project named **`dbt_data_quality`** that uses Snowflake sample data and implements a Medallion architecture:

- **Bronze**: raw sample tables
- **Silver**: cleaned/conformed business-ready entities
- **Gold**: analytics-ready aggregates

It also includes these dbt packages:

- `dbt_utils`
- `elementary`
- `dbt_expectations` (Great Expectations-style tests for dbt)

---

## 1) Prerequisites

Install:

- Python 3.10+
- `dbt-core`
- `dbt-snowflake`

```bash
pip install dbt-core dbt-snowflake
```

Validate:

```bash
dbt --version
```

---

## 2) Snowflake setup (personal account)

Use your own Snowflake account and create a warehouse/database/schema where dbt can write models.

### 2.1 Find your account identifier

In Snowflake UI, copy your account locator/URL value, for example:

- `xy12345.us-east-1`
- `xy12345.eu-west-1`

Use this value as `account` in your dbt profile.

### 2.2 Run this SQL in Snowflake

```sql
use role accountadmin;

create warehouse if not exists DBT_WH
  warehouse_size = XSMALL
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true;

create database if not exists DBT_DATA_QUALITY;
create schema if not exists DBT_DATA_QUALITY.BRONZE;
create schema if not exists DBT_DATA_QUALITY.SILVER;
create schema if not exists DBT_DATA_QUALITY.GOLD;

create role if not exists DBT_ROLE;

grant usage on warehouse DBT_WH to role DBT_ROLE;
grant operate on warehouse DBT_WH to role DBT_ROLE;

grant usage on database DBT_DATA_QUALITY to role DBT_ROLE;
grant usage on all schemas in database DBT_DATA_QUALITY to role DBT_ROLE;
grant create table, create view on all schemas in database DBT_DATA_QUALITY to role DBT_ROLE;
grant select on future tables in database DBT_DATA_QUALITY to role DBT_ROLE;

grant usage on database SNOWFLAKE_SAMPLE_DATA to role DBT_ROLE;
grant usage on all schemas in database SNOWFLAKE_SAMPLE_DATA to role DBT_ROLE;
grant select on all tables in database SNOWFLAKE_SAMPLE_DATA to role DBT_ROLE;

-- replace YOUR_USER with your Snowflake username
grant role DBT_ROLE to user YOUR_USER;
```

---

## 3) Configure dbt profile

Create `~/.dbt/profiles.yml`:

```yaml
dbt_data_quality:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "<your_account_identifier>"
      user: "<your_username>"
      password: "<your_password>"
      role: "DBT_ROLE"
      database: "DBT_DATA_QUALITY"
      warehouse: "DBT_WH"
      schema: "BRONZE"
      threads: 4
      client_session_keep_alive: false
```

### 3.1 External browser SSO style (matching your requested format)

If your Snowflake org uses SSO, configure your profile like this:

```yaml
dbt_data_quality:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "<your_account_locator>"              # example: GMB31674
      user: "<your_sso_username>"                    # do not put personal emails in shared docs
      role: "DATA_ENGINEER"
      warehouse: "PLATFORM_DEVELOPMENT_WH"
      database: "VALIDATION_DBT_DATA_QUALITY"        # use your real database name
      schema: "YOUR_SCHEMA"                          # use your real schema name (no dbt_ prefix)
      threads: 4
      authenticator: externalbrowser
```

> Password auth is fastest to get started; `externalbrowser` is recommended when your team uses SSO.

---

## 4) Install packages and validate connection

From this repository:

```bash
dbt deps
dbt debug
```

Expected: `Connection test: OK`.

---

## 5) Build Bronze → Silver → Gold

Run all models and tests:

```bash
dbt build
```

Run by layer:

```bash
dbt run --select bronze
dbt test --select bronze

dbt run --select silver
dbt test --select silver

dbt run --select gold
dbt test --select gold
```

---

## 6) Project layout

```text
dbt_project.yml
packages.yml
models/
  sources/snowflake_sample_sources.yml
  bronze/
    bronze_customers.sql
    bronze_orders.sql
    bronze_lineitems.sql
    bronze_parts.sql
    schema.yml
  silver/
    silver_customers.sql
    silver_orders.sql
    silver_lineitems.sql
    silver_parts.sql
    schema.yml
  gold/
    gold_customer_order_summary.sql
    gold_product_performance.sql
    schema.yml
```

---

## 7) Included data quality tooling

- **dbt_utils**: reusable dbt macros/helpers
- **elementary**: observability package (install-ready in `packages.yml`)
- **dbt_expectations**: Great Expectations-style assertions used in `schema.yml` tests

If you want to onboard Elementary dashboards next, you can start with:

```bash
dbt run --select elementary
```

(and then follow Elementary’s warehouse/web setup docs for full monitoring).
