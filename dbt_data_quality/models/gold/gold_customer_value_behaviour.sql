{{ config(schema='customers') }}

with order_metrics as (
    select
        o.customer_key,
        count(distinct o.order_key) as total_orders,
        sum(o.total_price) as total_order_value,
        avg(o.total_price) as avg_order_value,
        min(o.order_date) as first_order_date,
        max(o.order_date) as last_order_date
    from {{ ref('silver_orders') }} o
    group by 1
),

lineitem_metrics as (
    select
        o.customer_key,
        sum(li.quantity) as total_items_purchased,
        count(*) as total_lineitems,
        count(distinct li.part_key) as distinct_products_purchased,
        count(distinct p.brand) as distinct_brands_purchased,
        count_if(li.return_flag = 'R') as returned_lineitems,
        sum(li.extended_price) as gross_line_revenue,
        sum(li.extended_price * (1 - li.discount)) as net_line_revenue,
        avg(li.discount) as avg_discount_rate
    from {{ ref('silver_orders') }} o
    join {{ ref('silver_lineitems') }} li
        on o.order_key = li.order_key
    left join {{ ref('silver_parts') }} p
        on li.part_key = p.part_key
    group by 1
),

customer_360_base as (
    select
        c.customer_key,
        c.customer_name,
        c.market_segment,
        c.nation_key,
        c.account_balance,
        om.total_orders,
        om.total_order_value,
        om.avg_order_value,
        om.first_order_date,
        om.last_order_date,
        datediff('day', om.last_order_date, current_date) as days_since_last_order,
        datediff('month', om.first_order_date, om.last_order_date) + 1 as customer_lifetime_months,
        lm.total_items_purchased,
        lm.total_lineitems,
        lm.distinct_products_purchased,
        lm.distinct_brands_purchased,
        lm.returned_lineitems,
        lm.gross_line_revenue,
        lm.net_line_revenue,
        lm.avg_discount_rate,
        lm.returned_lineitems / nullif(lm.total_lineitems, 0) as return_rate,
        lm.net_line_revenue / nullif(om.total_order_value, 0) as line_to_order_value_ratio,
        datediff('day', om.first_order_date, om.last_order_date) / nullif(om.total_orders - 1, 0) as avg_days_between_orders
    from {{ ref('silver_customers') }} c
    join order_metrics om
        on c.customer_key = om.customer_key
    left join lineitem_metrics lm
        on c.customer_key = lm.customer_key
),

scored as (
    select
        b.*,
        6 - ntile(5) over (order by b.days_since_last_order asc) as r_score,
        ntile(5) over (order by b.total_orders asc) as f_score,
        ntile(5) over (order by b.total_order_value asc) as m_score
    from customer_360_base b
)

select
    customer_key,
    customer_name,
    market_segment,
    nation_key,
    account_balance,
    total_orders,
    total_order_value,
    avg_order_value,
    first_order_date,
    last_order_date,
    days_since_last_order,
    customer_lifetime_months,
    avg_days_between_orders,
    total_items_purchased,
    total_lineitems,
    distinct_products_purchased,
    distinct_brands_purchased,
    returned_lineitems,
    return_rate,
    gross_line_revenue,
    net_line_revenue,
    avg_discount_rate,
    line_to_order_value_ratio,
    r_score,
    f_score,
    m_score,
    concat(r_score, f_score, m_score) as rfm_code,
    case
        when r_score >= 4 and f_score >= 4 and m_score >= 4 then 'champions'
        when r_score >= 4 and f_score >= 4 then 'loyal_customers'
        when r_score >= 4 and f_score <= 2 then 'new_or_promising'
        when r_score <= 2 and f_score >= 4 and m_score >= 4 then 'at_risk_high_value'
        when r_score <= 2 and f_score <= 2 and m_score <= 2 then 'hibernating_low_value'
        else 'core_customers'
    end as customer_segment
from scored
order by customer_key
