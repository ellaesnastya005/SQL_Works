-- non-optimized query
-- I want to find categories with active customers and order date is after 22.06.2024 (2 years from now) and which have more than 35000 orders in total
-- I want to show category, total orders and unique customers per category

explain analyze
select p.product_category, -- show product category
(select count(*) from opt_orders o2
join opt_clients c2 on o2.client_id = c2.id
join opt_products p2 on o2.product_id = p2.product_id
where p2.product_category = p.product_category and c2.status = 'active' and o2.order_date >= '2024-06-22') as total_orders, -- show total orders per category (subquery)
(select count(distinct o3.client_id) from opt_orders o3
join opt_clients c3 on o3.client_id = c3.id
join opt_products p3 on o3.product_id = p3.product_id
where p3.product_category = p.product_category and c3.status = 'active' and o3.order_date >= '2024-06-22') as unique_customers -- show uniques customers per category (subquery)
from opt_products p
group by p.product_category -- group by category
having (select count(*) from opt_orders o4
join opt_clients c4 on o4.client_id = c4.id
join opt_products p4 on o4.product_id = p4.product_id
where p4.product_category = p.product_category and c4.status = 'active' and o4.order_date >= '2024-06-22') > 35000 -- filter with subquery - I want to show categories with only > 35000 orders
order by total_orders desc; -- order by total orders in descending (from biggest to lowest)
-- the problem with non-optimized query is that 3 subqueries (for total orders, unique customers, having filter) 
-- repeat the same work 3 times - they join the same tables separately for each category row
-- this is slow and waste of memory


-- optimized query
-- the same need as in previous query (however non-optimized one)
create index if not exists idx_orders_date on opt_orders(order_date); -- speed up filtering by date range (order_date >= '2024-06-22')
create index if not exists idx_orders_client_id on opt_orders(client_id); -- speed up join opt_orders and opt_clients
create index if not exists idx_orders_product_id on opt_orders(product_id); -- speed up join between opt_orders and opt_products
create index if not exists idx_clients_status on opt_clients(status); -- speed up filtering active clients (status = 'active')

explain analyze
with filtered_orders as ( -- cte named filtered orders, basically only filtered ones, who has active status and their order date is after 22.06.2024
select p.product_category, o.client_id
from opt_orders o 
join opt_clients c on o.client_id = c.id
join opt_products p on o.product_id = p.product_id
where c.status = 'active' and o.order_date >= '2024-06-22'
),
category_statistics as ( -- cte for statistics: I want to show number of total orders and unique clients per category
select product_category, count(*) as total_orders, count(distinct client_id) as unique_customers
from filtered_orders
group by product_category
)

select * -- show everything (category, number of total_orders, number of unique clients)
from category_statistics -- take it from last cte
where total_orders > 35000 -- filter: show only categories with more than 35000 orders
order by total_orders desc; -- order by total orders in descending (from biggest to lowest)

-- optimized query is the solution to problems from non-optimized one:
-- I used cte that joins all 3 tables at once in filtered_orders and then aggregates once in category_statistics
-- and also as about indexes that I add: they allow to do index scan instead of sequential scan

-- bonus task: optimizer control
-- PostgreSQL allows us to manually control which execution strategy the query planner is allowed tu use
-- We can disable certain methods to see how or plan changes and to prove that our optimization (cte + indexes) work correctly

set enable_hashjoin = off; -- hash join disabled - PostgreSQL needs to choose another strategy
-- now PostgreSQL cannot use hash join, and it will use merge join instead

explain analyze
with filtered_orders as ( -- cte named filtered orders, basically only filtered ones, who has active status and their order date is after 22.06.2024
select p.product_category, o.client_id
from opt_orders o 
join opt_clients c on o.client_id = c.id
join opt_products p on o.product_id = p.product_id
where c.status = 'active' and o.order_date >= '2024-06-22'
),
category_statistics as ( -- cte for statistics: I want to show number of total orders and unique clients per category
select product_category, count(*) as total_orders, count(distinct client_id) as unique_customers
from filtered_orders
group by product_category
)

select * -- show everything (category, number of total_orders, number of unique clients)
from category_statistics -- take it from last cte
where total_orders > 35000 -- filter: show only categories with more than 35000 orders
order by total_orders desc; -- order by total orders in descending (from biggest to lowest)

set enable_hashjoin = on; -- restore default planner settings (enabled hash join)
-- now the planner can use hash join again (the most efficient method here)
-- this demonstrates that we can control the optimizer behavior in PostgreSQL
-- using set commands that are useful for testing and performance enhancing

