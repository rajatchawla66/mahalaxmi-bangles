-- Migration: Add production_status JSONB column to order_items
-- Run this manually in Supabase SQL Editor.

ALTER TABLE order_items
ADD COLUMN IF NOT EXISTS production_status JSONB DEFAULT '{}'::jsonb;

-- Verify:
-- SELECT order_id, item_number, production_status FROM order_items LIMIT 10;
