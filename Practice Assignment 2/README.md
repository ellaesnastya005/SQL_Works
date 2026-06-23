# Practical Assignment 2 - query optimization 

## Task Description

I want to find product categories that had more than 35000 orders from active clients after 22.06.2024. For each category, I want to show:
- category name
- total number of orders
- number of unique customers

### Non-Optimized Query
The first version uses correlated subqueries - 3 separate subqueries in select and having.
Each one joins the same 3 tables again and again for every single category row.
This means PostgreSQL repeats the same work 3 times, which is slow and uses a lot of memory.

- **Execution Time: 966.008 ms**
- **Buffer hits: 106522**

### Indexes

Before running the optimized query, I created indexes on the columns used in join and where conditions:
```sql
create index if not exists idx_orders_date on opt_orders(order_date); 
create index if not exists idx_orders_client_id on opt_orders(client_id); 
create index if not exists idx_orders_product_id on opt_orders(product_id); 
create index if not exists idx_clients_status on opt_clients(status);
```

An index works like a table of contents in a book - instead of reading every row, PostgreSQL can jump directly to the rows it needs.

### Optimized query (cte + indexes)

The optimized query uses CTEs that break the query into named steps:

1. filtered_orders - joins all 3 tables once and filters active clients + date
2. category_statistics - counts total orders and unique customers per category once

Then the final select just reads the result of those steps, basically, no repeated work.

- **Execution Time: 342.680 ms**
- **Buffer hits: 9692**
- **in almost 2.8 times faster than non-optimized**

## Execution plan comparison

| Metric | Non-optimized | Optimized |
|--------|--------------|-----------|
| Execution time | 966 ms | 342 ms |
| Buffer hits | 106522 | 9692 |

*Readme file was polished (typo fixes and visual structure) by AI tool.
