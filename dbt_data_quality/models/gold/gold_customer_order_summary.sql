select
    c.customer_key,
    c.customer_name,
    c.market_segment,
    count(distinct o.order_key) as total_orders,
    sum(o.total_price) as total_order_value,
    min(o.order_date) as first_order_date,
    max(o.order_date) as last_order_date
from {{ ref('silver_customers') }} c
left join {{ ref('silver_orders') }} o
    on c.customer_key = o.customer_key
group by 1, 2, 3
having count(distinct o.order_key) > 0
order by customer_key
