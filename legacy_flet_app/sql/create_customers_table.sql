-- Run this in the Supabase SQL Editor to create the customers table
-- for the PIN-based login system.

CREATE TABLE IF NOT EXISTS customers (
    id BIGSERIAL PRIMARY KEY,
    pin TEXT NOT NULL UNIQUE,
    shop_name TEXT NOT NULL,
    owner_name TEXT DEFAULT '',
    mobile TEXT DEFAULT '',
    city TEXT DEFAULT '',
    notes TEXT DEFAULT '',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active_at TIMESTAMP WITH TIME ZONE
);

-- Index on pin for fast login lookups
CREATE INDEX IF NOT EXISTS idx_customers_pin ON customers (pin);

-- Index on is_active for filtering
CREATE INDEX IF NOT EXISTS idx_customers_active ON customers (is_active);
