select
    p.part_key,
    p.part_name,
    p.brand,
    sum(li.quantity) as total_quantity,
    sum(li.extended_price * (1 - li.discount)) as net_revenue
from {{ ref('silver_parts') }} p
join {{ ref('silver_lineitems') }} li
    on p.part_key = li.part_key
group by 1, 2, 3
