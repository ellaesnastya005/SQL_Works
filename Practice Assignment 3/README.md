# Practice Assignment 3 - order management database

Database system for managing orders in an online store. Implements functions, procedures, triggers, logging and query analysis.

## Database Structure

```mermaid
erDiagram
    customers {
        serial customer_id PK
        varchar full_name
        varchar email
        numeric balance
    }

    orders {
        serial order_id PK
        int customer_id FK
        timestamp order_date
        numeric total_amount
    }

    products {
        serial product_id PK
        varchar product_name
        numeric price
        int stock_quantity
    }

    order_items {
        serial order_item_id PK
        int order_id FK
        int product_id FK
        int quantity
        numeric price
    }

    order_log {
        serial log_id PK
        int order_id
        int customer_id
        varchar action
        timestamp log_date
    }

    customers ||--o{ orders : "places"
    orders ||--o{ order_items : "contains"
    products ||--o{ order_items : "included in"
    orders ||--o{ order_log : "logged in"
```

## Comments about queries:
Comments and explanation in sql file named "PracticeAssignment3"
