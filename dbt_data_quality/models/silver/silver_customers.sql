select
    C_CUSTKEY as customer_key,
    {{ clean_text('C_NAME') }} as customer_name,
    C_NATIONKEY as nation_key,
    C_PHONE as phone,
    C_ACCTBAL as account_balance,
    {{ clean_text('C_MKTSEGMENT') }} as market_segment
from {{ ref('bronze_customers') }}
