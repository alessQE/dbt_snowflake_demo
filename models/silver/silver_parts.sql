select
    P_PARTKEY as part_key,
    P_NAME as part_name,
    P_MFGR as manufacturer,
    P_BRAND as brand,
    P_TYPE as part_type,
    P_SIZE as size,
    P_RETAILPRICE as retail_price
from {{ ref('bronze_parts') }}
