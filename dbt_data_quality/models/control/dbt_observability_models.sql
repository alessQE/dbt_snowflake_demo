{{ config(
    materialized='view',
    tags=['observability'],
    description='Surfaces the latest dbt model run status and latest compiled code from dbt_run_results, sorted by database layer and execution outcome.'
) }}

with latest_run_results as (
    select
        r.unique_id,
        r.status,
        r.message,
        r.compiled_code,
        coalesce(r.execute_completed_at, r.generated_at) as run_completed_at,
        row_number() over (
            partition by r.unique_id
            order by
                i.generated_at desc nulls last,
                coalesce(r.execute_completed_at, r.generated_at) desc nulls last
        ) as rn
    from {{ ref('elementary', 'dbt_run_results') }} r
    left join {{ ref('elementary', 'dbt_invocations') }} i
        on r.invocation_id = i.invocation_id
    where r.resource_type = 'model'
),

model_run_status as (
    select
        unique_id,
        status,
        message,
        compiled_code,
        run_completed_at
    from latest_run_results
    where rn = 1
)

select
    upper(m.database_name) as database_name,
    upper(m.schema_name) as schema_name,
    upper(m.name) as model_name,
    upper(coalesce(m.materialization, 'unknown')) as materialization,
    upper(coalesce(r.status, 'not run')) as status,
    r.message as execution_message,
    r.run_completed_at::timestamp_tz as latest_run_datetime,
    r.compiled_code as model_compiled_code
from {{ ref('elementary', 'dbt_models') }} m
left join model_run_status r
    on m.unique_id = r.unique_id
where coalesce(m.materialization, '') <> 'ephemeral'
order by
    case
        when coalesce(r.status, 'not run') in ('error', 'fail', 'skipped', 'not run') then 1
        else 2
    end,
    case
        when m.database_name ilike '%gold%' then 1
        when m.database_name ilike '%silver%' then 2
        when m.database_name ilike '%bronze%' then 3
        else 4
    end,
    m.schema_name,
    m.name
