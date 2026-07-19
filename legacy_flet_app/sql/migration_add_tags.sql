-- Product Tags + Tag Master System
-- Run this in Supabase SQL Editor before deploying tag-related code.
-- Phase P1: tag_master table + rate_list.tags column.

-- 1. Create tag_master table
CREATE TABLE IF NOT EXISTS tag_master (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    category TEXT DEFAULT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tag_master_name
ON tag_master(name);

CREATE INDEX IF NOT EXISTS idx_tag_master_category
ON tag_master(category);

-- 2. Add tags column to rate_list
ALTER TABLE rate_list
ADD COLUMN IF NOT EXISTS tags JSONB DEFAULT '[]'::jsonb;

CREATE INDEX IF NOT EXISTS idx_rate_list_tags
ON rate_list USING GIN(tags);

-- 3. Disable RLS so anon key can read/write (matching other tables)
ALTER TABLE tag_master DISABLE ROW LEVEL SECURITY;
