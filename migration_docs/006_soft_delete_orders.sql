-- Soft Delete for Orders
-- Adds `deleted_at`, `deleted_by`, `delete_reason` columns to `orders`
-- No hard deletes from UI — this enables safe recovery and audit trails
-- Run in Supabase SQL Editor

ALTER TABLE orders
ADD COLUMN IF NOT EXISTS deleted_at timestamptz NULL,
ADD COLUMN IF NOT EXISTS deleted_by text NULL,
ADD COLUMN IF NOT EXISTS delete_reason text NULL;

-- Index for filtering deleted orders efficiently
CREATE INDEX IF NOT EXISTS idx_orders_deleted_at ON orders(deleted_at);

-- Partial index for active (non-deleted) order queries
CREATE INDEX IF NOT EXISTS idx_orders_active_status_created
ON orders(status, created_at DESC)
WHERE deleted_at IS NULL;
