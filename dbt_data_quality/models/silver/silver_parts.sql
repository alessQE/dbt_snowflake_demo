select
    P_PARTKEY as part_key,
    {{ clean_text('P_NAME') }} as part_name,
    {{ clean_text('P_MFGR') }} as manufacturer,
    {{ clean_text('P_BRAND') }} as brand,
    {{ clean_text('P_TYPE') }} as part_type,
    P_SIZE as size,
    P_RETAILPRICE as retail_price
from {{ ref('bronze_parts') }}
