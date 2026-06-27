-- user 1: menu_reader - read-only access to menu and orders
do $$
begin
    if not exists (select 1 from pg_roles where rolname = 'menu_reader') then
        create role menu_reader login password '123456Aa@';
    end if;
end
$$;

grant connect on database restaurant to menu_reader; -- allow connection to the database
grant usage on schema public to menu_reader; -- allow access to public schema
grant select on menu_items to menu_reader; -- read-only access to menu

-- user 2: waiter - can view and insert orders, order_items, read customers and tables
do $$
begin
    if not exists (select 1 from pg_roles where rolname = 'waiter') then
        create role waiter login password '654321Ww@';
    end if;
end
$$;

grant connect on database restaurant to waiter; -- allow connection to the database
grant usage on schema public to waiter; -- allow access to public schema
grant select on customers, tables, menu_items, staff to waiter; -- waiter can only view not modify these tables
grant select, insert, update on orders, order_items to waiter; -- manage orders
grant select on delivery_details to waiter; -- view delivery info

-- user 3: restaurant_admin - full access to all tables and views
do $$
begin
    if not exists (select 1 from pg_roles where rolname = 'restaurant_admin') then
        create role restaurant_admin login password '654321Admin!@';
    end if;
end
$$;

grant connect on database restaurant to restaurant_admin; -- allow connection to the database
grant usage on schema public to restaurant_admin; -- allow access to public schema
grant all privileges on all tables in schema public to restaurant_admin; -- full access to all tables
grant all privileges on all sequences in schema public to restaurant_admin; -- needed for insertion with serial columns