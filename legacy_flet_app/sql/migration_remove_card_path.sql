-- Migration: Remove legacy Cloudinary price-card column
-- Run this manually in Supabase SQL Editor after code cleanup is deployed.

ALTER TABLE rate_list
DROP COLUMN IF EXISTS card_path;
