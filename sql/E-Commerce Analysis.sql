--DATA QUALITY AND CONSISTENCY CHECKS

-- Sample records
select top 2 * from orders 
select top 2 * from order_items
select top 2 * from order_item_refunds
select top 2 * from website_sessions
select top 2 * from website_pageviews
select top 2 * from products

--1. Data Completedness- Row count of all tables

select 'website_sessions' as table_name, count(*) as row_count from website_sessions
union all 
select 'website_pageviews', count(*) from website_pageviews
union all 
select 'orders', count(*) from orders
union all 
select 'order_items', count(*) from order_items
union all 
select 'order_item_refunds', count(*) from order_item_refunds
union all 
select 'products', count(*) from products

--2. Primary Key Validation - Check dupicate IDs

select website_session_id, count(*) as duplicate_count 
from website_sessions
group by website_session_id
having count(*) > 1

select website_pageview_id, count(*) as duplicate_count 
from website_pageviews
group by website_pageview_id
having count(*) > 1

select order_id, count(*) as duplicate_count 
from orders
group by order_id
having count(*) > 1

select order_item_id, count(*) as duplicate_count 
from order_items
group by order_item_id
having count(*) > 1

select order_item_refund_id, count(*) as duplicate_count 
from order_item_refunds
group by order_item_refund_id
having count(*) > 1

select product_id, count(*) as duplicate_count 
from products
group by product_id
having count(*) > 1

--3. Missing Values - Check NULL values in important columns

select * from website_sessions
where website_session_id is null 

select * from website_pageviews
where website_pageview_id is null 

select * from orders
where order_id is null 

select * from order_items
where order_item_id is null 

select * from order_item_refunds
where order_item_refund_id is null 

select * from products
where product_id is null 

--4. Referential Integrety - Check foreign keys without matching parent records

select o.order_id, o.website_session_id
from orders as o
left join website_sessions as ws
on o.website_session_id = ws.website_session_id
where o.website_session_id is null

select o.order_id, o.primary_product_id
from orders as o
left join products as p 
on o.primary_product_id = p.product_id
where p.product_id is null

select oi.order_item_id, oi.order_id
from order_items as oi 
left join orders as o
on oi.order_id = o.order_id
where o.order_id is null

select oi.order_item_id, oi.product_id
from order_items as oi
left join products as p 
on oi.product_id = p.product_id
where p.product_id is null

select r.order_item_refund_id, r.order_item_id
from order_item_refunds as r
left join order_items as i
on r.order_item_id = i.order_item_id
where i.order_item_id is null

select r.order_item_refund_id, r.order_id
from order_item_refunds as r
left join orders as o
on r.order_id = o.order_id
where o.order_id is null

select wp.website_pageview_id, wp.website_session_id
from website_pageviews as wp
left join website_sessions as ws
on wp.website_session_id = ws.website_session_id
where ws.website_session_id is null

--5. Date Validation - Check missing or inconsistent dates
--A. Null or invalid dates
select order_id, created_at from orders
where created_at is null

select order_item_id, created_at from order_items
where created_at is null

select order_item_refund_id, created_at from order_item_refunds
where created_at is null

select website_session_id, created_at from website_sessions
where created_at is null

select website_pageview_id, created_at from website_pageviews
where created_at is null

select product_id, created_at from products
where created_at is null

--B. Order date before session date

select o.order_id, o.created_at as order_date, ws.created_at as session_date
from orders as o
left join website_sessions as ws
on o.website_session_id = ws.website_session_id
where o.created_at < ws.created_at

--C. Order item created before order

select oi.order_item_id, oi.created_at as order_item_date, o.created_at as order_date
from order_items as oi
left join orders as o
on oi.order_id = o.order_id
where oi.created_at < o.created_at

--D. Refund created before order item

select r.order_item_refund_id, r.created_at as refund_date, i.created_at as order_item_date
from order_item_refunds as r
left join order_items as i
on r.order_item_id = i.order_item_id
where r.created_at < i.created_at

--E. Pageview before session

select wp.website_pageview_id, wp.created_at as pageview_date, ws.created_at as session_id
from website_pageviews as wp
left join website_sessions as ws
on wp.website_session_id = ws.website_session_id
where wp.created_at < ws.created_at

--6. Financial Validation - Check negative, invalid price, cogs or refund amounts

select * from orders 
where price_usd <= 0 or cogs_usd <= 0

select * from order_items 
where price_usd <= 0 or cogs_usd <= 0

select * from order_item_refunds 
where refund_amount_usd <= 0 

--whether refund amount > price

select *
from order_item_refunds as r
left join order_items as i
on r.order_item_id = i.order_item_id
where r.refund_amount_usd > i.price_usd

-- Checking cost and price inconsistency

select * from orders
where cogs_usd > price_usd

select * from order_items
where cogs_usd > price_usd


--7. Revenue/Cost Reconciliation

select o.order_id, o.price_usd, sum(i.price_usd) as item_total
from orders as o
join order_items as i
on o.order_id = i.order_id
group by o.order_id, o.price_usd
having round(o.price_usd,2) != round(sum(i.price_usd),2)

select o.order_id, o.cogs_usd, sum(i.cogs_usd) as item_cogs_total
from orders as o
join order_items as i
on o.order_id = i.order_id
group by o.order_id, o.cogs_usd
having round(o.cogs_usd,2) != round(sum(i.cogs_usd),2)


--8. Order Consistency - compare items_purchased with actual order item records

select o.order_id, o.items_purchased,
count(i.order_item_id) as actual_items
from orders as o
left join order_items as i
on o.order_id = i.order_id
group by o.order_id, o.items_purchased
having o.items_purchased != count(i.order_item_id)

--9. Product Consistency 

select product_name, count(*) as product_count
from products
group by product_name
having count(*) > 1

--10. Refund Consistency

select r.order_item_refund_id, 
	r.order_id as refund_order_id, 
	i.order_id as actual_order_id,
	r.order_item_id
from order_item_refunds as r
left join order_items as i
on r.order_item_id = i.order_item_id
where r.order_id != i.order_id

--11. Website Consistency

select o.order_id, o.website_session_id
from orders as o
left join website_pageviews as wp
on o.website_session_id = wp.website_session_id
where wp.website_session_id is null

select device_type, count(*) as record_count from website_sessions
group by device_type
order by record_count desc

select is_repeat_session, count(*) as record_count
from website_sessions 
group by is_repeat_session
order by is_repeat_session

select utm_source, count(*) as record_count
from website_sessions
group by utm_source
order by record_count desc
-- utm_source = NULL may represent direct traffic

select utm_campaign, count(*) as record_count
from website_sessions
group by utm_campaign
order by record_count desc
-- utm_campaign = NULL may represent direct traffic

select utm_content, count(*) as record_count
from website_sessions
group by utm_content
order by record_count desc
-- utm_content = NULL may represent sessions without content

--12. Categorical fields / Domain Validation

select is_primary_item, count(*) as record_count
from order_items
group by is_primary_item
order by is_primary_item

select order_id,
	sum(case when is_primary_item = 1 then 1 else 0 end) as primary_item_count
from order_items
group by order_id
having sum(case when is_primary_item = 1 then 1 else 0 end) != 1

select o.order_id, o.primary_product_id, i.product_id as primary_item_product_id
from orders as o
join order_items as i
on o.order_id = i.order_id
where i.is_primary_item = 1
and o.primary_product_id != i.product_id

select order_item_id, count (*) as refund_count
from order_item_refunds
group by order_item_id
having count(*) != 1

select website_session_id, count (*) as order_count
from orders
group by website_session_id
having count(*) != 1

--FINAL DELIVERABLES - EDA AND DATA ANALYSIS

--1. Dataset Date range
select min(created_at) as start_date,
	max(created_at) as end_date
from website_sessions

select min(created_at) as start_date,
	max(created_at) as end_date
from orders

--2. Overall Business Performance
select 
count(order_id) as Total_Orders,
round(sum (price_usd),2) as Total_Revenue,
round(avg(price_usd),2) as Average_Order_Value,
round((sum(price_usd - cogs_usd)),2) as Total_Profit,
round(sum(price_usd - cogs_usd)*100/sum(price_usd),2) as Total_Profit_Percent
from orders

--3. Yearly Revenue

select 
year(created_at) as Year,
count(order_id) as Total_Orders,
round(sum(price_usd),2) as Yearly_Revenue
from orders
group by year(created_at)
order by Year

--4. Monthly Revenue

select 
year(created_at) as Year,
month(created_at) as Month,
count(order_id) as Total_Orders,
round(sum(price_usd),2) as Yearly_Revenue
from orders
group by year(created_at), month(created_at)
order by Year, Month

--5. Product-level Revenue

select p.product_id, p.product_name, p.created_at,
count(i.order_item_id) as Units_Sold,
round(sum(i.price_usd),2) as Product_Revenue,
round(sum(i.price_usd - i.cogs_usd),2) as Total_Profit
from order_items as i
join products as p
on i.product_id = p.product_id
group by p.product_id, p.product_name,p.created_at
order by p.created_at

--6. Website Conversion Performance

select 
count(w.website_session_id) as Total_Sessions,
count(o.order_id) as Total_Orders,
round(cast((count(o.order_id)*100) as decimal)/count(w.website_session_id),2) as Conversion_Rate
from website_sessions as w
left join orders as o 
on w.website_session_id = o.website_session_id


--7. Average Pageviews Per Session

select 
count(wp.website_pageview_id) as Total_Pageviews,
count(distinct ws.website_session_id) as Total_Sessions,
count(wp.website_pageview_id) * 1.0 / count(distinct ws.website_session_id) as Avg_Pageviews_Per_Session
from website_sessions as ws
left join website_pageviews as wp
on ws.website_session_id = wp.website_session_id

--8. Website Sessions by Traffic Source

select utm_source,
count(website_session_id) as Total_Sessions
from website_sessions
group by utm_source