Here you can find realisation of Practice Assignments for course "Introduction to Databases"
Data structure:

erDiagram
    CLIENTS {
        int client_id PK
        varchar full_name
        varchar email
        varchar phone
        varchar city
        varchar country
        date date_of_birth
    }

    ACCOUNTS {
        int account_id PK
        int client_id FK
        varchar account_type
        varchar currency
        numeric balance
        date opened_date
        varchar iban
    }

    TRANSACTIONS {
        int transaction_id PK
        int account_id FK
        varchar transaction_type
        numeric amount
        varchar currency
        date transaction_date
        varchar status
        varchar description
    }

    LOANS {
        int loan_id PK
        int client_id FK
        varchar loan_type
        numeric amount
        numeric interest_rate
        date start_date
        date end_date
        varchar status
    }

    CARDS {
        int card_id PK
        int account_id FK
        varchar card_type
        varchar card_number
        varchar expiry_date
        varchar status
        date issued_date
    }

    CLIENTS ||--o{ ACCOUNTS : owns
    ACCOUNTS ||--o{ TRANSACTIONS : has
    CLIENTS ||--o{ LOANS : takes
    ACCOUNTS ||--o{ CARDS : linked_to
