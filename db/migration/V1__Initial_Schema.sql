
-- V1__Initial_Schema.sql
-- ==========================================
--  CORE TABLES
-- ==========================================

-- Chart of Accounts
CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL CHECK (type IN ('asset', 'liability', 'equity', 'revenue', 'expense')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Transaction Headers
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    description TEXT,
    reference_no VARCHAR(50),
    posted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Journal Entries (The "Legs")
CREATE TABLE entries (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    amount NUMERIC(20,2) NOT NULL CHECK (amount > 0),
    direction TEXT NOT NULL CHECK (direction IN ('debit','credit')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Fast Balance Lookup Table
CREATE TABLE account_balances (
    account_id UUID PRIMARY KEY REFERENCES accounts(id),
    total_debit NUMERIC(20,2) NOT NULL DEFAULT 0,
    total_credit NUMERIC(20,2) NOT NULL DEFAULT 0,
    current_balance NUMERIC(20,2) GENERATED ALWAYS AS (total_debit - total_credit) STORED,
    last_updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE account_milestones (
    account_id UUID PRIMARY KEY REFERENCES accounts(id),
    milestone_entry_id UUID NOT NULL, -- The UUID v7 acts as a timestamp
    verified_balance NUMERIC(20,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indices for performance
CREATE INDEX idx_entries_transaction_id ON entries(transaction_id);
CREATE INDEX idx_entries_account_id ON entries(account_id);
CREATE INDEX idx_entries_account_direction ON entries(account_id, direction);
CREATE INDEX CONCURRENTLY idx_entries_account_milestone ON entries(account_id, id);
