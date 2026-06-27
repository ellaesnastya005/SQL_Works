-- trigger: automatically create delivery record when delivery order is placed

-- trigger function: insert new row into deliveries with status 'waiting' and customer's address (if exists)
create or replace function create_delivery_on_order()
returns trigger 
language plpgsql
as $$
begin
	insert into deliveries (order_id, customer_id, courier_id, status, delivery_address, platform, created_at)
	values (new.order_id, new.customer_id, null, 'waiting', coalesce((select address from customers where customer_id = new.customer_id), 'address not provided'), 'own delivery', now());
-- null for courier because it not assigned yet, initial delivery status: 'waiting', if customer has no address than 'address not provided', default platform - 'own delivery', current timestamp for created_at
	return new;
end;
$$;

-- triggers after each insert, but only when order_type = 'delivery'
create trigger create_delivery
after insert on orders
for each row 
when (new.order_type = 'delivery') -- only for delivery orders
execute function create_delivery_on_order();