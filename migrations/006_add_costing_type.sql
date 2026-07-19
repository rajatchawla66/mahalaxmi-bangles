-- Add costing_type column to cost_calculations
ALTER TABLE cost_calculations ADD COLUMN IF NOT EXISTS costing_type text NOT NULL DEFAULT 'manufacturing';

-- Update existing records to manufacturing
UPDATE cost_calculations SET costing_type = 'manufacturing' WHERE costing_type IS NULL;
