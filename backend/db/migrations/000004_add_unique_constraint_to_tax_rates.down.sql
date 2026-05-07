-- 000004_add_unique_constraint_to_tax_rates.down.sql
-- Revert the unique constraints

ALTER TABLE tax_rates DROP CONSTRAINT IF EXISTS unique_tax_name_per_workspace;
ALTER TABLE tax_rates DROP CONSTRAINT IF EXISTS unique_tax_code_per_workspace;
