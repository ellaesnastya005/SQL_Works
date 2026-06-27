drop table if exists customers cascade;
drop table if exists staff cascade;
drop table if exists tables cascade;
drop table if exists deliveries cascade;
drop table if exists orders cascade;
drop table if exists menu_items cascade;
drop table if exists order_items cascade;

create table customers (
	customer_id serial primary key,
	full_name varchar(200) not null,
	email varchar(200) unique not null,
	phone varchar(20) not null,
	address text
);

comment on table customers is 'information about customer';
comment on column customers.customer_id is 'unique number for each customer';
comment on column customers.full_name is 'full name of customer';
comment on column customers.email is 'email of customer';
comment on column customers.phone is 'phone number of customer';
comment on column customers.address is 'delivery address of customer';

create table staff (
	staff_id serial primary key,
	full_name varchar(200) not null,
	role varchar(50) not null check (role in ('waiter', 'cook', 'chef', 'administrator', 'courier')),
	phone varchar(20) not null,
	is_active boolean default true
);

comment on table staff is 'information about restaurant's staff';
comment on column staff.staff_id is 'unique number for each staff member';
comment on column staff.full_name is 'full name of staff member';
comment on column staff.role is 'role of staff memeber in restaurant';
comment on column staff.phone is 'phone number of staff member';
comment on column staff.is_active is 'whether staff member is currently active';

create table tables (
	table_id serial primary key,
	table_number int unique not null,
	seats int not null check (seats > 0),
	location varchar(50) not null check (location in ('indoor', 'outdoor', 'bar'))
);

comment on table tables is 'information about physical tables in restaurant';
comment on column tables.table_id is 'unique number for each table';
comment on column tables.table_number is 'table number that visible to customers';
comment on column tables.seats is 'number of seats of table';
comment on column tables.location is 'location of table: indoor, outdoor or bar';

create table menu_items (
	item_id serial primary key,
	item_name varchar(100) not null,
	category varchar(100) not null check (category in ('main', 'dessert', 'drink', 'starter', 'salad', 'soup', 'meat', 'fish')),
	price numeric not null check (price > 0),
	is_available boolean default true,
	description text
);

comment on table menu_items is 'stores all the dishes and drinks that are available in restaurant';
comment on column menu_items.item_id is 'unique number for each menu item';
comment on column menu_items.item_name is 'name of dish or drink';
comment on column menu_items.category is 'category of menu item';
comment on column menu_items.price is 'price of menu item';
comment on column menu_items.is_available is 'whether item is currently available';
comment on column menu_items.description is 'short description of menu item';

create table orders (
	order_id serial primary key,
	customer_id int references customers(customer_id),
	staff_id int references staff(staff_id),
	table_id int references tables(table_id),
	order_type varchar(20) not null check (order_type in ('delivery', 'takeaway', 'inside')),
	status varchar(20) not null check (status in ('ready', 'delivered', 'preparing', 'pending', 'cancelled')),
	total_amount numeric default 0,
	created_at timestamp default current_timestamp
);

comment on table orders is 'all customer orders';
comment on column orders.order_id is 'unique number for each order';
comment on column orders.customer_id is 'reference to customer who ordered something';
comment on column orders.staff_id is 'reference to staff member handling order';
comment on column orders.table_id is 'reference to table, null for delivery and takeaway';
comment on column orders.order_type is 'type of order: delivery, takeaway, inside';
comment on column orders.status is 'current status of order';
comment on column orders.total_amount is 'total price of order';
comment on column orders.created_at is 'time when order was created';

create table order_items (
    order_item_id serial primary key,
	order_id int references orders(order_id),
	item_id int not null references menu_items(item_id),
	quantity int not null check (quantity > 0),
	price numeric not null check (price > 0)
);

comment on table order_items is 'info about individual items within each order';
comment on column order_items.order_item_id is 'unique number for each order item';
comment on column order_items.order_id is 'reference to order this item belongs to';
comment on column order_items.item_id is 'reference to menu item';
comment on column order_items.quantity is 'number of units ordered';
comment on column order_items.price is 'price of item at the time of order';

create table deliveries (
	delivery_id serial primary key,
	order_id int references orders(order_id),
	customer_id int references customers(customer_id),
	courier_id int references staff(staff_id),
	status varchar(20) default 'waiting' check (status in('delivered', 'waiting', 'failed', 'accepted', 'on_the_way', 'picked_up')),
	delivery_address text not null,
	platform varchar(50) check (platform in ('Bolt', 'Glovo', 'own delivery')),
	delivered_at timestamp,
	created_at timestamp default current_timestamp
);

comment on table deliveries is 'delivery information for delivery-type orders';
comment on column deliveries.delivery_id is 'unique number for each delivery';
comment on column deliveries.order_id is 'reference to order being delivered';
comment on column deliveries.customer_id is 'reference to customer receiving delivery';
comment on column deliveries.courier_id is 'reference to courier handling delivery';
comment on column deliveries.status is 'current status of delivery';
comment on column deliveries.delivery_address is 'address where order is delivered';
comment on column deliveries.platform is 'delivery platform: bolt, glovo or own delivery service';
comment on column deliveries.delivered_at is 'time when order was delivered';
comment on column deliveries.created_at is 'time when order was created';

create index if not exists index_orders_created_at on orders(created_at);
create index if not exists index_orders_customer_id on orders(customer_id);
create index if not exists index_orders_status on orders(status);
create index if not exists index_order_items_order_id on order_items(order_id);
create index if not exists index_order_items_item_id on order_items(item_id);
create index if not exists index_deliveries_order_id on deliveries(order_id);
