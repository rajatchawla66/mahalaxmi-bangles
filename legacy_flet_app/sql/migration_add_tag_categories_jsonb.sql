-- Multi-Category Tags — Phase A1: Foundation
-- Adds a JSONB `categories` column alongside the existing TEXT `category` column.
-- 
-- Semantics:
--   []          = global tag (shown for all categories)
--   ["Chuda"]   = Chuda only
--   ["Chuda", "Kalira"]  = Chuda + Kalira
--
-- This migration is backward-compatible:
--   - Old code continues reading tag_master.category
--   - New categories column is populated from existing category data
--   - No application code changes required yet
--
-- Run this in Supabase SQL Editor before deploying Phase A2 code changes.

-- 1. Add categories JSONB column alongside existing category TEXT
ALTER TABLE tag_master
ADD COLUMN IF NOT EXISTS categories JSONB DEFAULT '[]'::jsonb;

-- 2. Backfill from existing category text
UPDATE tag_master
SET categories =
CASE
    WHEN category IS NULL OR trim(category) = '' THEN '[]'::jsonb
    ELSE to_jsonb(ARRAY[category])
END
WHERE categories IS NULL OR categories = '[]'::jsonb;

-- 3. Create GIN index for efficient containment queries
CREATE INDEX IF NOT EXISTS idx_tag_master_categories
ON tag_master USING GIN(categories);
