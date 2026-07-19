-- Cost Calc port: Create cost_calculations and material_settings tables

CREATE TABLE IF NOT EXISTS cost_calculations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  item_name text NOT NULL,
  category text NOT NULL,
  sub_category text,
  materials jsonb NOT NULL DEFAULT '{}',
  total_cost numeric(10,2) NOT NULL DEFAULT 0,
  created_by text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_by text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE cost_calculations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_all" ON cost_calculations
  FOR ALL USING (true) WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_cost_calculations_category ON cost_calculations(category);
CREATE INDEX IF NOT EXISTS idx_cost_calculations_updated_at ON cost_calculations(updated_at DESC);

CREATE TABLE IF NOT EXISTS material_settings (
  id int PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  nihar numeric(10,2) NOT NULL DEFAULT 0,
  dot_plain numeric(10,2) NOT NULL DEFAULT 0,
  dot_stone numeric(10,2) NOT NULL DEFAULT 0,
  dot_kundan numeric(10,2) NOT NULL DEFAULT 0,
  taj_stone numeric(10,2) NOT NULL DEFAULT 0,
  sunshine numeric(10,2) NOT NULL DEFAULT 0,
  moti_103 numeric(10,2) NOT NULL DEFAULT 0,
  patti_gol numeric(10,2) NOT NULL DEFAULT 0,
  patti_without_gol numeric(10,2) NOT NULL DEFAULT 0,
  box_presets jsonb NOT NULL DEFAULT '[15, 30, 55, 70, 90, 100, 120]',
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by text NOT NULL DEFAULT ''
);

ALTER TABLE material_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_all" ON material_settings
  FOR ALL USING (true) WITH CHECK (true);

INSERT INTO material_settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
