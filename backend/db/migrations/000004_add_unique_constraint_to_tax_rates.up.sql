-- 000004_add_unique_constraint_to_tax_rates.up.sql
-- Force Postgres to reject duplicate Tax Names and Codes in the same company

ALTER TABLE tax_rates ADD CONSTRAINT unique_tax_name_per_workspace UNIQUE (workspace_id, name);
ALTER TABLE tax_rates ADD CONSTRAINT unique_tax_code_per_workspace UNIQUE (workspace_id, code);
