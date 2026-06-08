select
    L_ORDERKEY as order_key,
    L_PARTKEY as part_key,
    L_QUANTITY as quantity,
    L_EXTENDEDPRICE as extended_price,
    L_DISCOUNT as discount,
    L_TAX as tax,
    {{ clean_text('L_RETURNFLAG') }} as return_flag,
    {{ clean_text('L_LINESTATUS') }} as line_status,
    cast(L_SHIPDATE as date) as ship_date
from {{ ref('bronze_lineitems') }}
