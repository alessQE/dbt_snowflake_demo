-- Snowflake teardown for this demo project.
-- Run as ACCOUNTADMIN (or a role with equivalent privileges).
-- This removes all objects created by the README setup and dbt runs.

use role accountadmin;

-- Drop databases used by the medallion layers.
drop database if exists BRONZE;
drop database if exists SILVER;
drop database if exists GOLD;

-- Drop old single-database layout if it exists from earlier setup versions.
drop database if exists DBT_DATA_QUALITY;

-- Drop demo warehouse and role.
drop warehouse if exists DBT_WH;
drop role if exists DBT_ROLE;