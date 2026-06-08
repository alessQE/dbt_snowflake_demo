select
    O_ORDERKEY as order_key,
    O_CUSTKEY as customer_key,
    {{ clean_text('O_ORDERSTATUS') }} as order_status,
    cast(O_ORDERDATE as date) as order_date,
    O_TOTALPRICE as total_price,
    {{ clean_text('O_ORDERPRIORITY') }} as order_priority,
    O_SHIPPRIORITY as ship_priority
from {{ ref('bronze_orders') }}
