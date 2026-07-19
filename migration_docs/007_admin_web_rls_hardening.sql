-- RLS Hardening for Admin Web Deployment
-- Run in Supabase SQL Editor AFTER migrating auth to Supabase Auth
-- ⚠️ DO NOT run this migration until auth migration is complete
--
-- Date: 2026-07-06
-- Purpose: Enable RLS on all tables and create policies for admin/customer/anonymous access
-- Related: ADMIN_WEB_SECURITY_RLS_AUDIT.md

-- ============================================================================
-- STEP 0: Pre-flight checks
-- ============================================================================

-- Verify Supabase Auth is configured (admin users must exist in auth.users)
-- SELECT id, email FROM auth.users WHERE email LIKE '%@mahalaxmibangles.com';

-- ============================================================================
-- STEP 1: Enable RLS on all tables
-- ============================================================================

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_list ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE cutmails ENABLE ROW LEVEL SECURITY;
ALTER TABLE cutmail_sizes ENABLE ROW LEVEL SECURITY;
ALTER TABLE chuda_customization_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE tag_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE cost_breakdown ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_materials ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 2: Create admin role helper function
-- ============================================================================

-- Function to check if current user is an admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (
    SELECT EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'admin'
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is a labour user
CREATE OR REPLACE FUNCTION is_labour()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (
    SELECT EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'labour'
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is a customer
CREATE OR REPLACE FUNCTION is_customer()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (
    SELECT EXISTS (
      SELECT 1 FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'customer'
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STEP 3: Customers table policies
-- ============================================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "customers_select_own" ON customers;
DROP POLICY IF EXISTS "customers_update_own" ON customers;
DROP POLICY IF EXISTS "customers_admin_full" ON customers;
DROP POLICY IF EXISTS "customers_anon_login" ON customers;

-- Customers: Admin can read/write all
CREATE POLICY "customers_admin_full" ON customers
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Customers: Labour can read all (for order creation)
CREATE POLICY "customers_labour_read" ON customers
  FOR SELECT
  USING (is_labour());

-- Customers: Customer can read own row (by customer_id matching auth.uid())
-- Note: This requires customers.id to map to auth.users.id
-- Adjust the column mapping based on your schema
CREATE POLICY "customers_read_own" ON customers
  FOR SELECT
  USING (
    is_customer()
    AND id::text = auth.uid()::text
  );

-- Customers: Customer can update own last_active_at
CREATE POLICY "customers_update_own_activity" ON customers
  FOR UPDATE
  USING (
    is_customer()
    AND id::text = auth.uid()::text
  )
  WITH CHECK (
    is_customer()
    AND id::text = auth.uid()::text
  );

-- Customers: Anon can read for PIN login (temporary — remove after auth migration)
CREATE POLICY "customers_anon_pin_login" ON customers
  FOR SELECT
  USING (auth.role() = 'anon');

-- ============================================================================
-- STEP 4: Orders table policies
-- ============================================================================

DROP POLICY IF EXISTS "orders_admin_full" ON orders;
DROP POLICY IF EXISTS "orders_customer_read_own" ON orders;
DROP POLICY IF EXISTS "orders_customer_insert_own" ON orders;
DROP POLICY IF EXISTS "orders_anon_full" ON orders;

-- Orders: Admin full access
CREATE POLICY "orders_admin_full" ON orders
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Orders: Labour can read all (for order processing)
CREATE POLICY "orders_labour_read" ON orders
  FOR SELECT
  USING (is_labour());

-- Orders: Customer can read own orders
CREATE POLICY "orders_customer_read_own" ON orders
  FOR SELECT
  USING (
    is_customer()
    AND customer_id::text = auth.uid()::text
  );

-- Orders: Customer can insert own orders (status must be 'pending')
CREATE POLICY "orders_customer_insert_own" ON orders
  FOR INSERT
  WITH CHECK (
    is_customer()
    AND customer_id::text = auth.uid()::text
    AND status = 'pending'
  );

-- Orders: Customer can update own orders (only status to 'cancelled')
CREATE POLICY "orders_customer_cancel_own" ON orders
  FOR UPDATE
  USING (
    is_customer()
    AND customer_id::text = auth.uid()::text
    AND status IN ('pending', 'confirmed')
  )
  WITH CHECK (
    is_customer()
    AND customer_id::text = auth.uid()::text
    AND status = 'cancelled'
  );

-- Orders: Anon full access (temporary — remove after auth migration)
CREATE POLICY "orders_anon_full" ON orders
  FOR ALL
  USING (auth.role() = 'anon')
  WITH CHECK (auth.role() = 'anon');

-- ============================================================================
-- STEP 5: Order Items table policies
-- ============================================================================

DROP POLICY IF EXISTS "order_items_admin_full" ON order_items;
DROP POLICY IF EXISTS "order_items_customer_read_own" ON order_items;
DROP POLICY IF EXISTS "order_items_customer_insert_own" ON order_items;
DROP POLICY IF EXISTS "order_items_anon_full" ON order_items;

-- Order Items: Admin full access
CREATE POLICY "order_items_admin_full" ON order_items
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Order Items: Labour can read all
CREATE POLICY "order_items_labour_read" ON order_items
  FOR SELECT
  USING (is_labour());

-- Order Items: Customer can read items for own orders
CREATE POLICY "order_items_customer_read_own" ON order_items
  FOR SELECT
  USING (
    is_customer()
    AND order_id IN (
      SELECT order_id FROM orders
      WHERE customer_id::text = auth.uid()::text
    )
  );

-- Order Items: Customer can insert items for own orders
CREATE POLICY "order_items_customer_insert_own" ON order_items
  FOR INSERT
  WITH CHECK (
    is_customer()
    AND order_id IN (
      SELECT order_id FROM orders
      WHERE customer_id::text = auth.uid()::text
      AND status = 'pending'
    )
  );

-- Order Items: Anon full access (temporary — remove after auth migration)
CREATE POLICY "order_items_anon_full" ON order_items
  FOR ALL
  USING (auth.role() = 'anon')
  WITH CHECK (auth.role() = 'anon');

-- ============================================================================
-- STEP 6: Rate List (Catalogue) policies
-- ============================================================================

DROP POLICY IF EXISTS "rate_list_admin_full" ON rate_list;
DROP POLICY IF EXISTS "rate_list_customer_read" ON rate_list;
DROP POLICY IF EXISTS "rate_list_anon_read" ON rate_list;

-- Rate List: Admin full access
CREATE POLICY "rate_list_admin_full" ON rate_list
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Rate List: Labour can read all
CREATE POLICY "rate_list_labour_read" ON rate_list
  FOR SELECT
  USING (is_labour());

-- Rate List: Customer can read available items with price
CREATE POLICY "rate_list_customer_read" ON rate_list
  FOR SELECT
  USING (
    is_customer()
    AND is_available = true
    AND selling_price > 0
  );

-- Rate List: Anon can read available items (for customer web app)
CREATE POLICY "rate_list_anon_read" ON rate_list
  FOR SELECT
  USING (
    auth.role() = 'anon'
    AND is_available = true
    AND selling_price > 0
  );

-- ============================================================================
-- STEP 7: Categories policies
-- ============================================================================

DROP POLICY IF EXISTS "categories_admin_full" ON categories;
DROP POLICY IF EXISTS "categories_customer_read" ON categories;
DROP POLICY IF EXISTS "categories_anon_read" ON categories;

-- Categories: Admin full access
CREATE POLICY "categories_admin_full" ON categories
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Categories: Labour can read all
CREATE POLICY "categories_labour_read" ON categories
  FOR SELECT
  USING (is_labour());

-- Categories: Customer can read active categories
CREATE POLICY "categories_customer_read" ON categories
  FOR SELECT
  USING (
    is_customer()
    AND is_active = true
  );

-- Categories: Anon can read active categories
CREATE POLICY "categories_anon_read" ON categories
  FOR SELECT
  USING (
    auth.role() = 'anon'
    AND is_active = true
  );

-- ============================================================================
-- STEP 8: Cutmails policies (Admin/Labour only)
-- ============================================================================

DROP POLICY IF EXISTS "cutmails_admin_full" ON cutmails;
DROP POLICY IF EXISTS "cutmails_labour_create" ON cutmails;
DROP POLICY IF EXISTS "cutmails_labour_read" ON cutmails;

-- Cutmails: Admin full access
CREATE POLICY "cutmails_admin_full" ON cutmails
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Cutmails: Labour can create cutmails
CREATE POLICY "cutmails_labour_create" ON cutmails
  FOR INSERT
  WITH CHECK (is_labour());

-- Cutmails: Labour can read all cutmails
CREATE POLICY "cutmails_labour_read" ON cutmails
  FOR SELECT
  USING (is_labour());

-- Cutmails: No customer or anon access
-- (No policy = denied by default when RLS is enabled)

-- ============================================================================
-- STEP 9: Cutmail Sizes policies (Admin/Labour only)
-- ============================================================================

DROP POLICY IF EXISTS "cutmail_sizes_admin_full" ON cutmail_sizes;
DROP POLICY IF EXISTS "cutmail_sizes_labour_create" ON cutmail_sizes;
DROP POLICY IF EXISTS "cutmail_sizes_labour_read" ON cutmail_sizes;

-- Cutmail Sizes: Admin full access
CREATE POLICY "cutmail_sizes_admin_full" ON cutmail_sizes
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Cutmail Sizes: Labour can create sizes
CREATE POLICY "cutmail_sizes_labour_create" ON cutmail_sizes
  FOR INSERT
  WITH CHECK (is_labour());

-- Cutmail Sizes: Labour can read all sizes
CREATE POLICY "cutmail_sizes_labour_read" ON cutmail_sizes
  FOR SELECT
  USING (is_labour());

-- ============================================================================
-- STEP 10: Chuda Customization Options policies
-- ============================================================================

DROP POLICY IF EXISTS "chuda_options_admin_full" ON chuda_customization_options;
DROP POLICY IF EXISTS "chuda_options_customer_read" ON chuda_customization_options;
DROP POLICY IF EXISTS "chuda_options_anon_read" ON chuda_customization_options;

-- Chuda Options: Admin full access
CREATE POLICY "chuda_options_admin_full" ON chuda_customization_options
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Chuda Options: Customer can read active options
CREATE POLICY "chuda_options_customer_read" ON chuda_customization_options
  FOR SELECT
  USING (
    is_customer()
    AND is_active = true
  );

-- Chuda Options: Anon can read active options
CREATE POLICY "chuda_options_anon_read" ON chuda_customization_options
  FOR SELECT
  USING (
    auth.role() = 'anon'
    AND is_active = true
  );

-- ============================================================================
-- STEP 11: Tag Master policies
-- ============================================================================

DROP POLICY IF EXISTS "tag_master_admin_full" ON tag_master;
DROP POLICY IF EXISTS "tag_master_customer_read" ON tag_master;
DROP POLICY IF EXISTS "tag_master_anon_read" ON tag_master;

-- Tag Master: Admin full access
CREATE POLICY "tag_master_admin_full" ON tag_master
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Tag Master: Customer can read active tags
CREATE POLICY "tag_master_customer_read" ON tag_master
  FOR SELECT
  USING (
    is_customer()
    AND is_active = true
  );

-- Tag Master: Anon can read active tags
CREATE POLICY "tag_master_anon_read" ON tag_master
  FOR SELECT
  USING (
    auth.role() = 'anon'
    AND is_active = true
  );

-- ============================================================================
-- STEP 12: App Settings policies
-- ============================================================================

DROP POLICY IF EXISTS "app_settings_admin_full" ON app_settings;
DROP POLICY IF EXISTS "app_settings_customer_read" ON app_settings;
DROP POLICY IF EXISTS "app_settings_anon_read" ON app_settings;

-- App Settings: Admin full access
CREATE POLICY "app_settings_admin_full" ON app_settings
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- App Settings: Customer can read all settings
CREATE POLICY "app_settings_customer_read" ON app_settings
  FOR SELECT
  USING (is_customer());

-- App Settings: Anon can read all settings
CREATE POLICY "app_settings_anon_read" ON app_settings
  FOR SELECT
  USING (auth.role() = 'anon');

-- ============================================================================
-- STEP 13: Materials policies (Admin only)
-- ============================================================================

DROP POLICY IF EXISTS "materials_admin_full" ON materials;

-- Materials: Admin full access only
CREATE POLICY "materials_admin_full" ON materials
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- No customer, labour, or anon access

-- ============================================================================
-- STEP 14: Cost Breakdown policies (Admin only)
-- ============================================================================

DROP POLICY IF EXISTS "cost_breakdown_admin_full" ON cost_breakdown;

-- Cost Breakdown: Admin full access only
CREATE POLICY "cost_breakdown_admin_full" ON cost_breakdown
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- No customer, labour, or anon access

-- ============================================================================
-- STEP 15: Item Materials policies (Admin only)
-- ============================================================================

DROP POLICY IF EXISTS "item_materials_admin_full" ON item_materials;

-- Item Materials: Admin full access only
CREATE POLICY "item_materials_admin_full" ON item_materials
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- No customer, labour, or anon access

-- ============================================================================
-- STEP 16: Storage Bucket policies
-- ============================================================================

-- Enable RLS on storage
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "storage_public_read" ON storage.objects;
DROP POLICY IF EXISTS "storage_admin_upload" ON storage.objects;
DROP POLICY IF EXISTS "storage_admin_update" ON storage.objects;
DROP POLICY IF EXISTS "storage_admin_delete" ON storage.objects;

-- Storage: Public read access for product-images bucket
CREATE POLICY "storage_public_read" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'product-images');

-- Storage: Admin can upload to product-images bucket
CREATE POLICY "storage_admin_upload" ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images'
    AND is_admin()
  );

-- Storage: Admin can update files in product-images bucket
CREATE POLICY "storage_admin_update" ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'product-images'
    AND is_admin()
  )
  WITH CHECK (
    bucket_id = 'product-images'
    AND is_admin()
  );

-- Storage: Admin can delete files from product-images bucket
CREATE POLICY "storage_admin_delete" ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'product-images'
    AND is_admin()
  );

-- ============================================================================
-- STEP 17: Revoke anon access for admin-only tables
-- ============================================================================

-- After auth migration, revoke anon access to admin-only tables
-- This ensures even if RLS is bypassed, anon role cannot access these tables

-- Note: These GRANT statements assume you have created roles 'admin', 'labour', 'customer'
-- Adjust based on your actual Supabase Auth setup

-- REVOKE ALL ON materials FROM anon;
-- REVOKE ALL ON cost_breakdown FROM anon;
-- REVOKE ALL ON item_materials FROM anon;

-- ============================================================================
-- STEP 18: Create indexes for RLS performance
-- ============================================================================

-- Indexes to speed up RLS policy checks
CREATE INDEX IF NOT EXISTS idx_customers_auth_id ON customers(id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_rate_list_availability ON rate_list(is_available, selling_price);
CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(is_active);
CREATE INDEX IF NOT EXISTS idx_cutmails_status ON cutmails(status);
CREATE INDEX IF NOT EXISTS idx_chuda_options_active ON chuda_customization_options(is_active);
CREATE INDEX IF NOT EXISTS idx_tag_master_active ON tag_master(is_active);

-- ============================================================================
-- STEP 19: Verification queries
-- ============================================================================

-- Run these after applying RLS to verify policies work:

-- Check RLS is enabled on all tables
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN (
  'customers', 'orders', 'order_items', 'rate_list', 'categories',
  'cutmails', 'cutmail_sizes', 'chuda_customization_options',
  'tag_master', 'app_settings', 'materials', 'cost_breakdown', 'item_materials'
);

-- List all policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Test admin access (run as admin user)
-- SELECT count(*) FROM customers; -- Should return all rows
-- SELECT count(*) FROM materials; -- Should return all rows

-- Test customer access (run as customer user)
-- SELECT count(*) FROM customers WHERE id::text = auth.uid()::text; -- Should return 1
-- SELECT count(*) FROM rate_list WHERE is_available = true; -- Should return available items
-- SELECT count(*) FROM materials; -- Should return 0 (no access)

-- Test anon access (unauthenticated)
-- SELECT count(*) FROM rate_list WHERE is_available = true; -- Should return available items
-- SELECT count(*) FROM materials; -- Should return 0 (no access)

-- ============================================================================
-- NOTES
-- ============================================================================

-- 1. This migration assumes Supabase Auth is configured with the following user metadata:
--    - Admin users: raw_user_meta_data->>'role' = 'admin'
--    - Labour users: raw_user_meta_data->>'role' = 'labour'
--    - Customer users: raw_user_meta_data->>'role' = 'customer'

-- 2. The customer_id in orders table must map to auth.users.id
--    Adjust the policy if your schema uses a different mapping

-- 3. After applying this migration:
--    - Remove the anon policies (customers_anon_pin_login, orders_anon_full, etc.)
--    - Update Flutter apps to use Supabase Auth instead of custom auth
--    - Test all three apps thoroughly

-- 4. The temporary anon policies allow backward compatibility during migration
--    Remove them once all apps are updated to use Supabase Auth

-- 5. Storage policies assume the 'product-images' bucket exists
--    Create it if it doesn't: INSERT INTO storage.buckets (id, name, public) VALUES ('product-images', 'product-images', true);
