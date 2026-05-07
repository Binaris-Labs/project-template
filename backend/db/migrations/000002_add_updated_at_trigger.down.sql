-- 1. Copot alarm (Trigger) dari tabel-tabel dokumen
DROP TRIGGER IF EXISTS set_timestamp_inventory_balances ON inventory_balances;
DROP TRIGGER IF EXISTS set_timestamp_internal_transfers ON internal_transfers;
DROP TRIGGER IF EXISTS set_timestamp_expenses ON expenses;
DROP TRIGGER IF EXISTS set_timestamp_purchase_bills ON purchase_bills;
DROP TRIGGER IF EXISTS set_timestamp_sales_invoices ON sales_invoices;

-- 2. Copot alarm (Trigger) dari tabel jurnal
DROP TRIGGER IF EXISTS set_timestamp_manual_journals ON manual_journals;
DROP TRIGGER IF EXISTS set_timestamp_journal_entries ON journal_entries;

-- 3. Copot alarm (Trigger) dari tabel Master Data
DROP TRIGGER IF EXISTS set_timestamp_workspace_settings ON workspace_settings;
DROP TRIGGER IF EXISTS set_timestamp_products ON products;
DROP TRIGGER IF EXISTS set_timestamp_contacts ON contacts;

-- 4. Copot alarm (Trigger) dari tabel Identitas
DROP TRIGGER IF EXISTS set_timestamp_workspaces ON workspaces;
DROP TRIGGER IF EXISTS set_timestamp_users ON users;

-- 5. Hancurkan Mesin Fungsi-nya
DROP FUNCTION IF EXISTS trigger_set_timestamp();
DROP FUNCTION IF EXISTS trigger_set_last_updated_at();
