-- 000003_seed_pt_unggas_coa.up.sql
-- Seed Chart of Accounts for PT. Unggas (Workspace: e16460f8-1479-4cd3-a453-f0e2d26449c8)

INSERT INTO chart_of_accounts (id, workspace_id, code, name, type, normal_balance) VALUES
-- 1. ASSETS (ASET)
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '11001', 'Kas Kecil (Petty Cash)', 'ASSET', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '11002', 'Bank BCA', 'ASSET', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '11010', 'Piutang Usaha (A/R Customer)', 'ASSET', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '11020', 'Persediaan Ayam Hidup (Live Birds)', 'ASSET', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '11021', 'Persediaan Pakan & Vaksin', 'ASSET', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '12000', 'Aset Tetap (Kandang & Truk Operasional)', 'ASSET', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '12099', 'Akumulasi Penyusutan (Truk/Kandang)', 'ASSET', 'CREDIT'),

-- 2. LIABILITIES (KEWAJIBAN)
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '21010', 'Hutang Usaha Supplier (Pakan/DO)', 'LIABILITY', 'CREDIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '21020', 'Hutang Pajak', 'LIABILITY', 'CREDIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '21030', 'Hutang Gaji Pekerja Kandang & Supir', 'LIABILITY', 'CREDIT'),

-- 3. EQUITY (MODAL)
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '31001', 'Modal Disetor Pemilik', 'EQUITY', 'CREDIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '31002', 'Laba Ditahan', 'EQUITY', 'CREDIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '31003', 'Prive Pemilik', 'EQUITY', 'DEBIT'),

-- 4. REVENUE (PENDAPATAN)
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '41000', 'Penjualan Ayam Hidup (Ekor/Tonase)', 'REVENUE', 'CREDIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '42000', 'Penjualan Karkas/Ayam Potong', 'REVENUE', 'CREDIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '43000', 'Potongan / Diskon Penjualan', 'REVENUE', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '44000', 'Retur Penjualan (Ayam Mati di Jalan/Susut)', 'REVENUE', 'DEBIT'),

-- 5. COGS (HARGA POKOK PENJUALAN)
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '51000', 'HPP Ayam Hidup & Karkas', 'COGS', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '51001', 'Beban Pembelian Pakan & Vaksin', 'COGS', 'DEBIT'),

-- 6. EXPENSES (BEBAN OPERASIONAL)
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '61001', 'Beban Gaji Kurir, Checker, Supir', 'EXPENSE', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '61002', 'Beban Sewa Kandang / Gudang Transit', 'EXPENSE', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '61003', 'Beban Listrik (Pemanas Kandang DOC)', 'EXPENSE', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '61004', 'Beban Bensin & Logistik Armada (DO)', 'EXPENSE', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '61005', 'Beban Telpon & Kuota (Checker)', 'EXPENSE', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '61099', 'Beban Penyusutan Aset (Truk/Timbangan)', 'EXPENSE', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '91000', 'Biaya Admin Bank & Pajak Bunga', 'EXPENSE', 'DEBIT'),
(gen_random_uuid(), 'e16460f8-1479-4cd3-a453-f0e2d26449c8', '91001', 'Selisih Pembulatan (Rounding Adjustment)', 'EXPENSE', 'DEBIT')

ON CONFLICT (workspace_id, code) DO NOTHING;
