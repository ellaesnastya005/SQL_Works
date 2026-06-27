-- delivery details with courier info
-- shows all delivery orders with customer, courier and order details
-- only includes orders of type 'delivery'

create or replace view delivery_details as
select d.delivery_id, d.created_at, d.status as delivery_status, d.platform, d.delivery_address, d.delivered_at,
c.full_name as customer_name, c.phone as customer_phone, s.full_name as courier_name, s.phone as courier_phone, o.total_amount
from deliveries d
join customers c on d.customer_id = c.customer_id
left join staff s on d.courier_id = s.staff_id
join orders o on d.order_id = o.order_id
where o.order_type = 'delivery'; -- only delivery orders

-- to check performance:
-- explain analyze select * from delivery_details;
