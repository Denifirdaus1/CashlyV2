Entity List

cash_transactions
→ catatan pemasukan/pengeluaran personal.

personal_saving_goals
→ tujuan tabungan pribadi.

personal_saving_transactions
→ transaksi tabungan pribadi per tujuan.

saving_groups
→ kelompok tabungan bersama.

saving_group_members
→ anggota tiap kelompok.

saving_group_transactions
→ transaksi tabungan tiap anggota di suatu kelompok.

3.2. Mermaid ERD
erDiagram
  CASH_TRANSACTIONS {
    uuid id PK
    timestamptz transaction_date
    numeric amount
    text type
    text category
    text note
    timestamptz created_at
  }

  PERSONAL_SAVING_GOALS {
    uuid id PK
    text name
    text description
    numeric target_amount
    date deadline
    timestamptz created_at
  }

  PERSONAL_SAVING_TRANSACTIONS {
    uuid id PK
    uuid goal_id FK
    numeric amount
    text type
    text note
    timestamptz created_at
  }

  SAVING_GROUPS {
    uuid id PK
    text name
    text description
    numeric target_total
    date deadline
    timestamptz created_at
  }

  SAVING_GROUP_MEMBERS {
    uuid id PK
    uuid group_id FK
    text name
    numeric target_amount
    timestamptz created_at
  }

  SAVING_GROUP_TRANSACTIONS {
    uuid id PK
    uuid group_id FK
    uuid member_id FK
    numeric amount
    text type
    text note
    timestamptz created_at
  }

  PERSONAL_SAVING_GOALS ||--o{ PERSONAL_SAVING_TRANSACTIONS : has
  SAVING_GROUPS ||--o{ SAVING_GROUP_MEMBERS : has
  SAVING_GROUPS ||--o{ SAVING_GROUP_TRANSACTIONS : has
  SAVING_GROUP_MEMBERS ||--o{ SAVING_GROUP_TRANSACTIONS : has