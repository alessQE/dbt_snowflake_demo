{{ config(
    materialized='view',
    tags=['observability'],
    description='Business-focused model refresh status showing database, schema, table name, current status, and last refreshed datetime for all modeled tables and views.'
) }}

with model_scope as (
    select
        m.database_name,
        m.schema_name,
        m.name as model_name,
        m.unique_id as model_unique_id,
        m.materialization
    from {{ ref('elementary', 'dbt_models') }} m
    where (
        m.database_name ilike '%gold%'
        or m.database_name ilike '%silver%'
        or m.database_name ilike '%bronze%'
    )
      and coalesce(m.materialization, '') <> 'ephemeral'
),

latest_model_runs as (
    select
        m.model_unique_id,
        r.name as model_alias,
        r.invocation_id as model_invocation_id,
        r.status as model_run_status,
        r.execute_completed_at,
        row_number() over (
            partition by m.model_unique_id
            order by
                i.generated_at desc nulls last,
                coalesce(r.execute_completed_at, r.generated_at) desc nulls last
        ) as rn
    from model_scope m
    left join {{ ref('elementary', 'dbt_run_results') }} r
        on m.model_unique_id = r.unique_id
       and r.resource_type = 'model'
    left join {{ ref('elementary', 'dbt_invocations') }} i
        on r.invocation_id = i.invocation_id
),

last_successful_run as (
    select
        r.unique_id as model_unique_id,
        max(coalesce(r.execute_completed_at, r.generated_at)) as last_successful_execute_completed_at
    from {{ ref('elementary', 'dbt_run_results') }} r
    where r.resource_type = 'model'
      and r.status = 'success'
    group by r.unique_id
),

business_status as (
    select
        m.database_name,
        m.schema_name,
        coalesce(r.model_alias, m.model_name) as model_alias,
        case
            when r.model_run_status = 'success' then 'Refreshed'
            else 'Not Refreshed'
        end as status,
        case
            when r.model_run_status = 'success' then r.execute_completed_at
            else s.last_successful_execute_completed_at
        end as execute_completed_at
    from model_scope m
    left join latest_model_runs r
        on m.model_unique_id = r.model_unique_id
       and r.rn = 1
    left join last_successful_run s
        on m.model_unique_id = s.model_unique_id
)

select
    upper(database_name) as database_name,
    upper(schema_name) as schema_name,
    upper(model_alias) as table_name,
    upper(status) as current_status,
    execute_completed_at::timestamp_tz as last_refreshed_datetime
from business_status
order by
    case when status = 'Not Refreshed' then 1 else 2 end,
    model_alias
