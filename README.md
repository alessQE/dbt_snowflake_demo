# dbt_data_quality

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

Recommended: create and activate a local virtual environment in this repository before installing dbt:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
```

On Windows PowerShell:

```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
```

Then install:

```bash
python -m pip install dbt-core dbt-snowflake
```

Validate:

```bash
dbt --version
```

---

## 2) Snowflake setup (personal account)

Use your own Snowflake account and create a warehouse plus three databases where dbt can write models.

### 2.1 Find your account identifier

In Snowflake UI, copy your account locator/URL value, for example:

- `xy12345.us-east-1`
- `xy12345.eu-west-1`

Use this value as `account` in your dbt profile.

### 2.2 Run this SQL in Snowflake

If you already followed the earlier version of this README and created a single `DBT_DATA_QUALITY` database with `BRONZE`, `SILVER`, and `GOLD` schemas inside it, run [snowflake_cleanup_old_schema_layout.sql](/Users/alessandro.delagarza/Library/CloudStorage/OneDrive-Slalom/Desktop/side_projects/dbt_snowflake_demo/snowflake_cleanup_old_schema_layout.sql) one time before creating the new databases below.

```sql
use role accountadmin;

create warehouse if not exists DBT_WH
  warehouse_size = XSMALL
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true;

create database if not exists BRONZE;
create database if not exists SILVER;
create database if not exists GOLD;

create role if not exists DBT_ROLE;

grant usage on warehouse DBT_WH to role DBT_ROLE;
grant operate on warehouse DBT_WH to role DBT_ROLE;

grant usage on database BRONZE to role DBT_ROLE;
grant create schema on database BRONZE to role DBT_ROLE;
grant usage on all schemas in database BRONZE to role DBT_ROLE;
grant create table, create view on all schemas in database BRONZE to role DBT_ROLE;
grant select on future tables in database BRONZE to role DBT_ROLE;

grant usage on database SILVER to role DBT_ROLE;
grant create schema on database SILVER to role DBT_ROLE;
grant usage on all schemas in database SILVER to role DBT_ROLE;
grant create table, create view on all schemas in database SILVER to role DBT_ROLE;
grant select on future tables in database SILVER to role DBT_ROLE;

grant usage on database GOLD to role DBT_ROLE;
grant create schema on database GOLD to role DBT_ROLE;
grant usage on all schemas in database GOLD to role DBT_ROLE;
grant create table, create view on all schemas in database GOLD to role DBT_ROLE;
grant select on future tables in database GOLD to role DBT_ROLE;

grant imported privileges on database SNOWFLAKE_SAMPLE_DATA to role DBT_ROLE;

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
      database: "BRONZE"
      warehouse: "DBT_WH"
      schema: "PUBLIC"
      threads: 4
      client_session_keep_alive: false
```

### 3.1 External browser SSO style (matching your requested format)

If your Snowflake org uses SSO, configure your profile like this:

Use a non-sensitive username placeholder in shared docs (for example `<your_sso_username>`), not personal email addresses.

```yaml
dbt_data_quality:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "<your_account_locator>"              # example: GMB31674
      user: "<your_sso_username>"
      role: "DATA_ENGINEER"
      warehouse: "PLATFORM_DEVELOPMENT_WH"
      database: "BRONZE"                             # starting database; project config routes each layer to its own database
      schema: "PUBLIC"                               # shared schema inside each layer database
      threads: 4
      authenticator: externalbrowser
```

> Password auth is fastest to get started; `externalbrowser` is recommended when your team uses SSO.

Schema layout used by this project:

- dbt creates model schemas automatically using your profile target schema as a prefix.
- With `schema: "PUBLIC"` in your profile and model schemas like `customers`, `orders`, and `items`, dbt will create schemas such as `PUBLIC_CUSTOMERS`, `PUBLIC_ORDERS`, and `PUBLIC_ITEMS`.
- You do not need to pre-create these schemas in Snowflake setup SQL.

---

## 4) Install packages and validate connection

From this repository, with the virtual environment activated:

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

## 6) Stop everything after you finish (avoid charges)

Your warehouse in this guide is already configured with `auto_suspend = 60`, so it should stop automatically after ~60 seconds of inactivity.

If you want to stop immediately and verify nothing is still running, run:

```sql
use role accountadmin;

-- force immediate stop
alter warehouse DBT_WH suspend;

-- verify warehouse state
show warehouses like 'DBT_WH';
```

To check for any still-running queries on that warehouse:

```sql
select
  query_id,
  user_name,
  warehouse_name,
  execution_status,
  start_time
from table(
  information_schema.query_history(
    end_time_range_start => dateadd('hour', -1, current_timestamp()),
    result_limit => 1000
  )
)
where execution_status = 'RUNNING'
  and warehouse_name = 'DBT_WH'
order by start_time desc;
```

If any query is still running, cancel it:

```sql
select system$cancel_query('<query_id>');
```

Then re-run `show warehouses like 'DBT_WH';` and confirm `state` is `SUSPENDED`.

---

## 7) Project layout

```text
dbt_project.yml
packages.yml
dbt_data_quality/
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

## 8) Included data quality tooling

- **dbt_utils**: reusable dbt macros/helpers
- **elementary**: observability package (install-ready in `packages.yml`)
- **dbt_expectations**: Great Expectations-style assertions used in `schema.yml` tests

If you want to onboard Elementary dashboards next, you can start with:

```bash
dbt run --select elementary
```

(and then follow Elementary’s warehouse/web setup docs for full monitoring).
