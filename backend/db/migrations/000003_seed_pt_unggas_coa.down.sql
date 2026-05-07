-- 000003_seed_pt_unggas_coa.down.sql
-- Rollback Seed Chart of Accounts for PT. Unggas

DELETE FROM chart_of_accounts
WHERE workspace_id = 'e16460f8-1479-4cd3-a453-f0e2d26449c8';
