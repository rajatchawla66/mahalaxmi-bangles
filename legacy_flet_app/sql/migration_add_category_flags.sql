-- Migration: Add category-level boolean flags for has_sizes and has_subcategories
-- Date: 2026-06-14
-- Purpose: Support admin refinement of category behavior via dedicated boolean columns
-- instead of relying on side-channel conventions.

ALTER TABLE categories
  ADD COLUMN IF NOT EXISTS has_sizes BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS has_subcategories BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN categories.has_sizes IS 'When true, items in this category use size-based quantities (e.g. 2.2–2.10) instead of flat quantity.';
COMMENT ON COLUMN categories.has_subcategories IS 'When true, the customer app shows a subcategory grid before the item grid for this category.';
