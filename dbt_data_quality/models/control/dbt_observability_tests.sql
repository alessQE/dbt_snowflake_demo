{{ config(
    materialized='view',
    tags=['observability'],
    description='Surfaces the latest dbt test execution status and latest compiled code from dbt_run_results with parent model context, sorted by database layer and test outcome.'
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
    where r.resource_type = 'test'
),

test_run_status as (
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
    upper(t.database_name) as model_database_name,
    upper(t.schema_name) as model_schema_name,
    upper(coalesce(p.name, 'unknown')) as model_name,
    upper(t.name) as test_name,
    upper(coalesce(r.status, 'not run')) as test_status,
    r.message as test_message,
    r.run_completed_at::timestamp_tz as latest_run_datetime,
    r.compiled_code as test_compiled_code
from {{ ref('elementary', 'dbt_tests') }} t
left join test_run_status r
    on t.unique_id = r.unique_id
left join {{ ref('elementary', 'dbt_models') }} p
    on t.parent_model_unique_id = p.unique_id
order by
    case
        when coalesce(r.status, 'not run') in ('error', 'fail', 'skipped', 'not run') then 1
        else 2
    end,
    case
        when t.database_name ilike '%gold%' then 1
        when t.database_name ilike '%silver%' then 2
        when t.database_name ilike '%bronze%' then 3
        else 4
    end,
    t.schema_name,
    p.name,
    t.name
