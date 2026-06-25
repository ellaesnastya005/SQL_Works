create table customers (
    customer_id serial primary key,
    full_name varchar(100) not null,
    email varchar(100) unique not null,
    balance numeric(10,2) default 0
);

create table products (
    product_id serial primary key,
    product_name varchar(100) not null,
    price numeric(10,2) not null,
    stock_quantity int not null
);

create table orders (
    order_id serial primary key,
    customer_id int references customers(customer_id),
    order_date timestamp default current_timestamp,
    total_amount numeric(10,2) default 0
);

create table order_items (
    order_item_id serial primary key,
    order_id int references orders(order_id),
    product_id int references products(product_id),
    quantity int not null,
    price numeric(10,2) not null
);

create table order_log (
    log_id serial primary key,
    order_id int,
    customer_id int,
    action varchar(50),
    log_date timestamp default current_timestamp
);


# Main Tasks — 10 Points

## Task 1 — Function: Calculate Order Total 

create or replace function calculate_order_total(p_order_id int) -- creation of function that takes order_id as input
returns numeric -- returns number
language sql
as $$
select coalesce(sum(price * quantity), 0) -- logic: multiplicationof price and quantity for each item, sum them all up, return 0 if order is empty
from order_items
where order_id = p_order_id; -- filter: only for the given order
$$;

select calculate_order_total(1);  -- test: check total for order with order_id = 1

## Task 2 — Procedure: Create New Order  

create or replace procedure create_order(p_customer_id int) -- creation of procedure that takes customer_id as input
language sql
as $$

insert into orders (customer_id, order_date, total_amount)
select p_customer_id, current_timestamp, 0 -- insert customer_id, current time and 0 as starting point
where exists (select 1 from customers where p_customer_id = customer_id); -- only insert if customer exists

$$;

call create_order(2); -- worked: customer with customer_id = 2 exists
call create_order(10); -- does not worked, because in orders tables there was not any customer with customer_id = 10 
select * from orders;


## Task 3 — Procedure: Add Product to Order 

create or replace procedure add_product_to_order( -- creation of procedure
    p_order_id int, -- which order
    p_product_id int, --- which product
    p_quantity int -- how many
) 
language sql
as $$
insert into order_items (order_id, product_id, quantity, price)
select p_order_id, p_product_id, p_quantity, price -- take current price from products table when we add new product
from products
where product_id = p_product_id and p_quantity > 0 and stock_quantity >= p_quantity; -- filter: quantity must be > 0 and must have enough stock

update products
set stock_quantity = stock_quantity - p_quantity -- descrease stock by ordered amount
where product_id = p_product_id and p_quantity > 0 and stock_quantity >= p_quantity; -- the same filter as above
$$;

call add_product_to_order(1,1,2); -- added: 2 laptops to order 1
call add_product_to_order(1,2,0); -- won't added, because quantity needs to be > 0
call add_product_to_order(1,1,890); -- won't added, because quantity needs to be < stock_quantity (not enough stock)

select * from order_items;
select * from products; -- checking whether stock decreased

## Task 4 — Trigger: Update Order Total  

create or replace function update_order_total() -- creation of function for trigger
returns trigger -- must return trigger type 
language plpgsql
as $$
begin
	update orders
	set total_amount = calculate_order_total(coalesce(new.order_id, old.order_id)) -- recalculating total using function from task 1 and new exists for insert or update and old exists for delete
	where order_id = coalesce(new.order_id, old.order_id); -- update the right order
	return new; -- return the row back
end;
$$;

create or replace trigger trigger_update_order_total -- creation of trigger
after insert or update or delete -- triggers after any change in order_items
on order_items
for each row -- run once per changed row
execute function update_order_total();

## Task 5 — Trigger: Order Audit Log  

create or replace function log_new_order() -- creation of function for trigger
returns trigger -- must return trigger type 
language plpgsql
as $$
begin
	insert into order_log (order_id, customer_id, action, log_date)
	values (new.order_id, new.customer_id, 'order_created', current_timestamp); -- id of new order, id of customer who made order, action type, exact time when the order was created
	return new; -- return the row back
end;
$$;

create trigger trigger_log_new_order -- creation of trigger
after insert on orders -- triggers after every new order is inserted 
for each row -- run once per changed row
execute function log_new_order();

## Task 6 — Testing  

- customers can be created;
insert into customers(full_name, email) values ('test', 'test@gmail.com'); 
select * from customers; -- check if new customer appeared

- products can be created;
insert into products(product_name, price, stock_quantity) values ('test', 150, 15);
select * from products; -- check if new product appeared

- orders can be created using the procedure;
call create_order(2); -- worked: customer with customer_id = 2 exists
call create_order(10); -- does not worked, because in orders tables there was not any customer with customer_id = 10 
select * from orders; -- only order for customer with customer_id = 2 should appear

- products can be added to orders using the procedure;
call add_product_to_order(1,1,2); -- added: 2 laptops to order with order_id = 1
call add_product_to_order(1,2,0); -- won't added, because quantity needs to be > 0
call add_product_to_order(1,1,890); -- won't added, because quantity needs to be < stock_quantity

select * from order_items; -- only the first order shoul appear
select * from products; -- stock_quantity needs to decrease by 2 where order_id = 1

- order totals are updated automatically;
select * from orders; -- total_amount should be updated automatically by trigger for order with order_id = 1: total = 2 * laptop price

- product stock decreases correctly;
select * from products; -- laptop stock should decrease by 2 after add_product_to_order(1,1,2)

- order creation is logged in `order_log`
select * from order_log; -- should contain record with action - 'order_created' for every order that was created

-- bonus task 3

explain analyze
select
    oi.order_id,
    c.full_name,
    p.product_name,
    oi.quantity,
    oi.price,
    oi.quantity * oi.price as item_total
from orders o
join order_items oi on o.order_id = oi.order_id -- join orders and order_items
join products p on oi.product_id = p.product_id -- join order_itmes and products
join customers c on o.customer_id = c.customer_id -- join orders and customers
where o.order_id = 3; -- show only order with order_id = 3

-- PostgreSQL uses nested loop to join the orders and customer tables - it finds order 3 using index scan on orders_pkey,
-- then immediately looks up the customer using index scan on customers_pkey.
-- For the products and order_items tables, PostgreSQL uses sequential scan on both (because the tables are small),
-- then join them with hash join - it builds a hash table from order_itmes rows filtered by order_id = 3,
-- then matches products against it.
-- Execution Time: 0.128 ms, which is very fast because all data was found in shared memory buffers: Buffers: shared hit=6 - without reading from disk


