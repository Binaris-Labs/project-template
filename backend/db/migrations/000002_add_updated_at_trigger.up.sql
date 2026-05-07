-- 1. Buat Mesin Fungsi-nya (Hanya perlu dibuat 1 kali untuk seluruh database)
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Buat Fungsi khusus untuk inventory_balances karena struktur namanya berbeda
CREATE OR REPLACE FUNCTION trigger_set_last_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Pasang alarm (Trigger) ke tabel-tabel identitas
CREATE TRIGGER set_timestamp_users BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();
CREATE TRIGGER set_timestamp_workspaces BEFORE UPDATE ON workspaces FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- 4. Pasang alarm (Trigger) ke tabel Master Data
CREATE TRIGGER set_timestamp_contacts BEFORE UPDATE ON contacts FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();
CREATE TRIGGER set_timestamp_products BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();
CREATE TRIGGER set_timestamp_workspace_settings BEFORE UPDATE ON workspace_settings FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- 5. Pasang alarm (Trigger) ke tabel Jurnal
CREATE TRIGGER set_timestamp_journal_entries BEFORE UPDATE ON journal_entries FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();
CREATE TRIGGER set_timestamp_manual_journals BEFORE UPDATE ON manual_journals FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- 6. Pasang alarm (Trigger) ke tabel Dokumen Keuangan
CREATE TRIGGER set_timestamp_sales_invoices BEFORE UPDATE ON sales_invoices FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();
CREATE TRIGGER set_timestamp_purchase_bills BEFORE UPDATE ON purchase_bills FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();
CREATE TRIGGER set_timestamp_expenses BEFORE UPDATE ON expenses FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();
CREATE TRIGGER set_timestamp_internal_transfers BEFORE UPDATE ON internal_transfers FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

-- 7. Trigger khusus untuk inventory_balances
CREATE TRIGGER set_timestamp_inventory_balances BEFORE UPDATE ON inventory_balances FOR EACH ROW EXECUTE FUNCTION trigger_set_last_updated_at();
