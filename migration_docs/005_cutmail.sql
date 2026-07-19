-- Cutmail / Stock Check feature
-- Phase 1: General Cutmail (not linked to orders)

CREATE TABLE IF NOT EXISTS cutmails (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid,
  category_name text NOT NULL,
  item_id uuid NOT NULL,
  item_name_snapshot text NOT NULL,
  item_number_snapshot text,
  image_url_snapshot text,
  checked_by_labour_id uuid,
  checked_by_name text,
  status text NOT NULL DEFAULT 'pending',
  note text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  reviewed_at timestamptz,
  reviewed_by text
);

CREATE TABLE IF NOT EXISTS cutmail_sizes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cutmail_id uuid NOT NULL REFERENCES cutmails(id) ON DELETE CASCADE,
  size text NOT NULL,
  available_qty integer NOT NULL DEFAULT 0,
  is_available boolean NOT NULL DEFAULT true,
  note text,
  created_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_cutmails_created_at ON cutmails(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cutmails_status ON cutmails(status);
CREATE INDEX IF NOT EXISTS idx_cutmails_category_name ON cutmails(category_name);
CREATE INDEX IF NOT EXISTS idx_cutmails_item_id ON cutmails(item_id);
CREATE INDEX IF NOT EXISTS idx_cutmail_sizes_cutmail_id ON cutmail_sizes(cutmail_id);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_cutmails_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_cutmails_updated_at ON cutmails;
CREATE TRIGGER trigger_cutmails_updated_at
  BEFORE UPDATE ON cutmails
  FOR EACH ROW
  EXECUTE FUNCTION update_cutmails_updated_at();

-- RLS
ALTER TABLE cutmails ENABLE ROW LEVEL SECURITY;
ALTER TABLE cutmail_sizes ENABLE ROW LEVEL SECURITY;

-- Admin full access
DROP POLICY IF EXISTS "Admin full access on cutmails" ON cutmails;
CREATE POLICY "Admin full access on cutmails"
  ON cutmails
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Admin full access on cutmail_sizes" ON cutmail_sizes;
CREATE POLICY "Admin full access on cutmail_sizes"
  ON cutmail_sizes
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Labour insert + read own
DROP POLICY IF EXISTS "Labour insert cutmails" ON cutmails;
CREATE POLICY "Labour insert cutmails"
  ON cutmails
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Labour read cutmails" ON cutmails;
CREATE POLICY "Labour read cutmails"
  ON cutmails
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Labour insert cutmail_sizes" ON cutmail_sizes;
CREATE POLICY "Labour insert cutmail_sizes"
  ON cutmail_sizes
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Labour read cutmail_sizes" ON cutmail_sizes;
CREATE POLICY "Labour read cutmail_sizes"
  ON cutmail_sizes
  FOR SELECT
  TO authenticated
  USING (true);
