select
    C_CUSTKEY as customer_key,
    C_NAME as customer_name,
    C_NATIONKEY as nation_key,
    C_PHONE as phone,
    C_ACCTBAL as account_balance,
    C_MKTSEGMENT as market_segment
from {{ ref('bronze_customers') }}
