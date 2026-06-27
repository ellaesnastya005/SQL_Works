import random
import psycopg2
from psycopg2.extras import execute_values
from psycopg2 import Error
from faker import Faker

HOST = 'localhost'       # put your credentials here
USER = 'postgres'        # put your credentials here
PASSWORD = 'postgres'    # put your credentials here
DATABASE = 'restaurant'  # put your credentials here
PORT = '5432'            # put your credentials here

fake = Faker()

ROLES = ['waiter', 'cook', 'chef', 'administrator', 'courier']
LOCATIONS = ['indoor', 'outdoor', 'bar']
ORDER_TYPES = ['delivery', 'takeaway', 'inside']
ORDER_STATUSES = ['ready', 'delivered', 'preparing', 'pending', 'cancelled']
DELIVERY_STATUSES = ['delivered', 'waiting', 'failed', 'accepted', 'on_the_way', 'picked_up']
PLATFORMS = ['Bolt', 'Glovo', 'own delivery']

MENU = [
    ('Margherita Pizza', 'main', 12.99),
    ('Pepperoni Pizza', 'main', 14.99),
    ('Caesar Salad', 'salad', 8.49),
    ('Greek Salad', 'salad', 7.99),
    ('Garlic Bread', 'starter', 4.49),
    ('Chicken Wings', 'starter', 9.49),
    ('Pasta Carbonara', 'main', 13.99),
    ('Grilled Salmon', 'fish', 18.99),
    ('Beef Steak', 'meat', 22.99),
    ('Tomato Soup', 'soup', 6.49),
    ('Tiramisu', 'dessert', 5.99),
    ('Cheesecake', 'dessert', 5.49),
    ('Lemonade', 'drink', 3.49),
    ('Espresso', 'drink', 2.49),
    ('Craft Beer', 'drink', 4.99),
]


def create_connection():
    try:
        connection = psycopg2.connect(
            host=HOST, port=PORT, user=USER, password=PASSWORD, dbname=DATABASE
        )
        print('Connection to PostgreSQL DB successful')
        return connection
    except Error as e:
        print(f"The error '{e}' occurred")
        return None


def insert_customers(cursor, n=1000):
    print(f'Inserting {n} customers...')
    data = [
        (fake.name(), fake.unique.email(), fake.phone_number()[:20], fake.address())
        for _ in range(n)
    ]
    execute_values(cursor, """
        INSERT INTO customers (full_name, email, phone, address)
        VALUES %s ON CONFLICT (email) DO NOTHING
    """, data)
    cursor.execute('SELECT customer_id FROM customers')
    return [r[0] for r in cursor.fetchall()]


def insert_staff(cursor):
    print('Inserting staff...')
    data = [
        (fake.name(), random.choice(ROLES), fake.phone_number()[:20], True)
        for _ in range(30)
    ]
    execute_values(cursor, """
        INSERT INTO staff (full_name, role, phone, is_active) VALUES %s
    """, data)
    cursor.execute('SELECT staff_id, role FROM staff')
    rows = cursor.fetchall()
    return {
        'all': [r[0] for r in rows],
        'waiters': [r[0] for r in rows if r[1] == 'waiter'],
        'couriers': [r[0] for r in rows if r[1] == 'courier'],
    }


def insert_tables(cursor):
    print('Inserting tables...')
    data = [(i, random.randint(2, 8), random.choice(LOCATIONS)) for i in range(1, 21)]
    execute_values(cursor, """
        INSERT INTO tables (table_number, seats, location)
        VALUES %s ON CONFLICT (table_number) DO NOTHING
    """, data)
    cursor.execute('SELECT table_id FROM tables')
    return [r[0] for r in cursor.fetchall()]


def insert_menu_items(cursor):
    print('Inserting menu items...')
    execute_values(cursor, """
        INSERT INTO menu_items (item_name, category, price, is_available, description)
        VALUES %s
    """, [(name, cat, price, True, fake.sentence()) for name, cat, price in MENU])
    cursor.execute('SELECT item_id, price FROM menu_items')
    return cursor.fetchall()


def insert_orders(cursor, customer_ids, staff_ids, table_ids, menu_items, n=500000):
    print(f'Inserting {n} orders and order items (this may take a while)...')
    waiters = staff_ids['waiters'] or staff_ids['all']
    couriers = staff_ids['couriers'] or staff_ids['all']
    CHUNK = 5000

    for start in range(0, n, CHUNK):
        chunk_size = min(CHUNK, n - start)

        orders_data = []
        for _ in range(chunk_size):
            order_type = random.choice(ORDER_TYPES)
            table_id = random.choice(table_ids) if order_type == 'inside' else None
            staff_id = random.choice(waiters) if order_type == 'inside' else None
            orders_data.append((
                random.choice(customer_ids),
                staff_id,
                table_id,
                order_type,
                random.choice(ORDER_STATUSES),
                0,
                fake.date_time_between(start_date='-1y', end_date='now'),
            ))

        execute_values(cursor, """
            INSERT INTO orders (customer_id, staff_id, table_id, order_type, status, total_amount, created_at)
            VALUES %s RETURNING order_id, order_type, customer_id
        """, orders_data)
        returned = cursor.fetchall()

        items_data = []
        totals = {}
        deliveries_data = []

        for order_id, order_type, customer_id in returned:
            chosen = random.sample(menu_items, random.randint(1, 5))
            total = 0
            for item_id, price in chosen:
                qty = random.randint(1, 3)
                items_data.append((order_id, item_id, qty, float(price)))
                total += qty * float(price)
            totals[order_id] = round(total, 2)

            if order_type == 'delivery':
                deliveries_data.append((
                    order_id,
                    customer_id,
                    random.choice(couriers) if couriers else None,
                    random.choice(DELIVERY_STATUSES),
                    fake.address(),
                    random.choice(PLATFORMS),
                ))

        execute_values(cursor, """
            INSERT INTO order_items (order_id, item_id, quantity, price) VALUES %s
        """, items_data)

        for order_id, total in totals.items():
            cursor.execute(
                'UPDATE orders SET total_amount = %s WHERE order_id = %s',
                (total, order_id)
            )

        if deliveries_data:
            execute_values(cursor, """
                INSERT INTO deliveries (order_id, customer_id, courier_id, status, delivery_address, platform)
                VALUES %s
            """, deliveries_data)

        print(f'  Inserted {start + chunk_size} / {n} orders...')


def insert_data():
    connection = create_connection()
    if connection is None:
        return
    try:
        with connection:
            with connection.cursor() as cursor:
                customer_ids = insert_customers(cursor, n=1000)
                staff_ids = insert_staff(cursor)
                table_ids = insert_tables(cursor)
                menu_items = insert_menu_items(cursor)
                insert_orders(cursor, customer_ids, staff_ids, table_ids, menu_items, n=500000)
        print('All data inserted successfully!')
    except Exception as e:
        print(f"Error: {e}")
    finally:
        connection.close()


if __name__ == '__main__':
    insert_data()
