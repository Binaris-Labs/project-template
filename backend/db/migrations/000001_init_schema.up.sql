-- =============================================
-- 0. EXTENSIONS & USER SECURITY
-- =============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- A. USERS (Global Identity)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_users_email ON users(email);

-- B. WORKSPACES (Tenant)
CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    tax_id_number VARCHAR(50),
    address TEXT,
    owner_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- C. WORKSPACE MEMBERS (RBAC)
CREATE TYPE user_role AS ENUM ('OWNER', 'ADMIN', 'VIEWER');

CREATE TABLE workspace_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    role user_role NOT NULL DEFAULT 'VIEWER',
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, workspace_id)
);
CREATE INDEX idx_members_user ON workspace_members(user_id);
CREATE INDEX idx_members_workspace ON workspace_members(workspace_id);


-- =============================================
-- 1. MASTER DATA
-- =============================================

-- 1.A. CHART OF ACCOUNTS
CREATE TYPE balance_side AS ENUM ('DEBIT', 'CREDIT');
CREATE TYPE account_type AS ENUM ('ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'COGS', 'EXPENSE');

CREATE TABLE chart_of_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    code VARCHAR(20) NOT NULL,
    name VARCHAR(255) NOT NULL,
    type account_type NOT NULL,
    normal_balance balance_side NOT NULL,
    parent_id UUID REFERENCES chart_of_accounts(id),
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, code) 
);
CREATE INDEX idx_coa_workspace ON chart_of_accounts(workspace_id);
CREATE INDEX idx_coa_code ON chart_of_accounts(code);

-- 1.B. TAX RATES
CREATE TABLE tax_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    name VARCHAR(50) NOT NULL, 
    rate DECIMAL(5, 2) NOT NULL, 
    code VARCHAR(20), 
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 1.C. CONTACTS
CREATE TABLE contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    code VARCHAR(50), 
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    mobile VARCHAR(50),
    website VARCHAR(255),
    shipping_address TEXT,
    billing_address TEXT,
    tax_id_number VARCHAR(50),
    
    bank_name VARCHAR(100),
    bank_branch VARCHAR(100),
    bank_account_number VARCHAR(50),
    bank_account_holder VARCHAR(255),
    
    is_customer BOOLEAN DEFAULT FALSE,
    is_vendor BOOLEAN DEFAULT FALSE,
    is_employee BOOLEAN DEFAULT FALSE,
    
    currency_code VARCHAR(3) DEFAULT 'IDR',
    payment_term_days INT DEFAULT 0,
    
    receivable_account_id UUID REFERENCES chart_of_accounts(id),
    payable_account_id UUID REFERENCES chart_of_accounts(id),
    
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_contacts_workspace ON contacts(workspace_id);
CREATE INDEX idx_contacts_name ON contacts(name);

-- 1.D. PRODUCTS
CREATE TYPE product_type AS ENUM ('GOODS', 'SERVICE', 'NON_INVENTORY');
CREATE TYPE uom_type AS ENUM ('PCS', 'KG', 'EKOR', 'LITER', 'BOX', 'PACK', 'SAK');

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    sku VARCHAR(100),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    uom uom_type DEFAULT 'PCS',
    secondary_uom uom_type, -- [NEW: Support for Dual UOM, e.g. Ekor if primary is Kg]
    type product_type NOT NULL DEFAULT 'GOODS',
    track_inventory BOOLEAN DEFAULT TRUE,
    
    sales_price DECIMAL(19, 4) DEFAULT 0 CHECK (sales_price >= 0),
    purchase_cost DECIMAL(19, 4) DEFAULT 0 CHECK (purchase_cost >= 0),
    
    tax_rate_id UUID REFERENCES tax_rates(id),
    
    income_account_id UUID REFERENCES chart_of_accounts(id),
    expense_account_id UUID REFERENCES chart_of_accounts(id),
    inventory_account_id UUID REFERENCES chart_of_accounts(id),
    
    min_stock_level INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, sku)
);
CREATE INDEX idx_products_workspace ON products(workspace_id);
CREATE INDEX idx_products_sku ON products(sku);

-- 1.E. WAREHOUSES [MOVED FROM INVENTORY MODULE]
CREATE TABLE warehouses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    code VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, code)
);
CREATE INDEX idx_warehouses_workspace ON warehouses(workspace_id);


-- =============================================
-- 2. ACCOUNTING CORE
-- =============================================

-- 2.A. DOCUMENT SEQUENCES [NEW - ANTI CRASH]
CREATE TABLE document_sequences (
    id SERIAL PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL, -- 'SALES_INVOICE', 'PURCHASE_BILL', 'CREDIT_NOTE', etc
    prefix VARCHAR(20) NOT NULL,
    year INT NOT NULL,
    month INT,
    current_number INT DEFAULT 0,
    
    UNIQUE(workspace_id, document_type, year, month)
);
CREATE INDEX idx_sequences_workspace ON document_sequences(workspace_id);

CREATE TABLE accounting_periods (
    id SERIAL PRIMARY KEY,
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_closed BOOLEAN DEFAULT FALSE,
    closed_at TIMESTAMP,
    closed_by UUID
);

CREATE TYPE journal_status AS ENUM ('DRAFT', 'POSTED', 'VOID');

CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    transaction_no VARCHAR(50),
    transaction_date DATE NOT NULL,
    description TEXT,
    
    entity_type VARCHAR(50),
    entity_id UUID,
    reference VARCHAR(50),
    
    status journal_status DEFAULT 'DRAFT',
    
    created_by UUID, 
    posted_by UUID,
    posted_at TIMESTAMP,
    voided_by UUID,
    voided_reason TEXT,
    
    version INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, transaction_no)
);
CREATE INDEX idx_journals_workspace ON journal_entries(workspace_id);
CREATE INDEX idx_journals_date ON journal_entries(transaction_date);

CREATE TABLE journal_entry_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_entry_id UUID REFERENCES journal_entries(id) ON DELETE CASCADE,
    account_id UUID REFERENCES chart_of_accounts(id),
    
    debit DECIMAL(19, 4) DEFAULT 0 CHECK (debit >= 0),
    credit DECIMAL(19, 4) DEFAULT 0 CHECK (credit >= 0),
    description TEXT,
    
    CONSTRAINT check_valid_entry CHECK (
        (debit > 0 AND credit = 0) OR 
        (credit > 0 AND debit = 0)
    )
);
CREATE INDEX idx_journal_lines_account ON journal_entry_lines(account_id);
CREATE INDEX idx_journal_lines_entry ON journal_entry_lines(journal_entry_id);

-- 2.C. JOURNAL AUDIT TRAIL (The "Black Box")
CREATE TABLE journal_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    journal_entry_id UUID NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    
    action VARCHAR(50) NOT NULL, -- 'CREATE', 'UPDATE', 'VOID', 'POST'
    changed_by UUID REFERENCES users(id),
    changed_at TIMESTAMP DEFAULT NOW(),
    
    old_data JSONB, 
    new_data JSONB, 
    
    reason TEXT
);
CREATE INDEX idx_audit_workspace ON journal_audit_logs(workspace_id);
CREATE INDEX idx_audit_journal ON journal_audit_logs(journal_entry_id);


-- =============================================
-- 3. SALES MODULE
-- =============================================
CREATE TYPE invoice_status AS ENUM ('DRAFT', 'APPROVED', 'VOID', 'PAID', 'PARTIAL');

CREATE TABLE sales_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    invoice_number VARCHAR(50) NOT NULL,
    reference_number VARCHAR(50),
    
    transaction_date DATE NOT NULL,
    due_date DATE NOT NULL,
    
    customer_id UUID NOT NULL REFERENCES contacts(id),
    billing_address TEXT,
    shipping_address TEXT,
    
    currency_code VARCHAR(3) DEFAULT 'IDR',
    exchange_rate DECIMAL(19, 6) DEFAULT 1,
    
    subtotal DECIMAL(19, 4) DEFAULT 0,
    tax_total DECIMAL(19, 4) DEFAULT 0,
    discount_total DECIMAL(19, 4) DEFAULT 0,
    global_discount_type VARCHAR(20),
    global_discount_value DECIMAL(19, 4) DEFAULT 0,
    rounding_adjustment DECIMAL(19, 4) DEFAULT 0,
    grand_total DECIMAL(19, 4) DEFAULT 0,
    amount_paid DECIMAL(19, 4) DEFAULT 0,
    balance_due DECIMAL(19, 4) DEFAULT 0,
    
    tax_inclusive BOOLEAN DEFAULT FALSE,
    notes TEXT,
    terms_and_conditions TEXT,
    
    status invoice_status DEFAULT 'DRAFT',
    journal_entry_id UUID REFERENCES journal_entries(id),
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, invoice_number)
);
CREATE INDEX idx_sales_inv_workspace ON sales_invoices(workspace_id);
CREATE INDEX idx_sales_inv_number ON sales_invoices(invoice_number);

CREATE TABLE sales_invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sales_invoice_id UUID REFERENCES sales_invoices(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    
    warehouse_id UUID REFERENCES warehouses(id), -- [UPDATE: Truk mana yang jual]
    
    product_name VARCHAR(255),
    description TEXT,
    
    quantity DECIMAL(19, 4) NOT NULL,
    secondary_quantity DECIMAL(19, 4), -- [NEW: Support for Dual UOM]
    unit_price DECIMAL(19, 4) NOT NULL,
    discount_type VARCHAR(20),
    discount_value DECIMAL(19, 4) DEFAULT 0,
    discount_amount DECIMAL(19, 4) DEFAULT 0,
    
    tax_rate_id UUID REFERENCES tax_rates(id),
    tax_rate DECIMAL(5, 2) DEFAULT 0, 
    tax_amount DECIMAL(19, 4) DEFAULT 0,
    
    total_price DECIMAL(19, 4) NOT NULL
);

-- [NEW] CREDIT NOTES (RETUR PENJUALAN)
CREATE TYPE credit_note_status AS ENUM ('DRAFT', 'POSTED', 'VOID');

CREATE TABLE credit_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    credit_note_number VARCHAR(50) NOT NULL,
    transaction_date DATE NOT NULL,
    customer_id UUID NOT NULL REFERENCES contacts(id),
    
    original_invoice_id UUID NOT NULL REFERENCES sales_invoices(id),
    
    subtotal DECIMAL(19, 4) DEFAULT 0,
    tax_total DECIMAL(19, 4) DEFAULT 0,
    grand_total DECIMAL(19, 4) DEFAULT 0,
    
    status credit_note_status DEFAULT 'DRAFT',
    journal_entry_id UUID REFERENCES journal_entries(id),
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, credit_note_number)
);

CREATE TABLE credit_note_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    credit_note_id UUID REFERENCES credit_notes(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    
    warehouse_id UUID REFERENCES warehouses(id), -- [NEW: Truk mana yang terima kembali ayam mati/susut]
    
    quantity DECIMAL(19, 4) NOT NULL,
    secondary_quantity DECIMAL(19, 4), -- [NEW: Support for Dual UOM]
    unit_price DECIMAL(19, 4) NOT NULL,
    tax_rate_id UUID REFERENCES tax_rates(id),
    tax_rate DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(19, 4) DEFAULT 0,
    
    total_price DECIMAL(19, 4) NOT NULL
);


CREATE TYPE receipt_status AS ENUM ('DRAFT', 'POSTED', 'VOID');

CREATE TABLE sales_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    receipt_number VARCHAR(50) NOT NULL,
    transaction_date DATE NOT NULL,
    reference_number VARCHAR(50),
    
    customer_id UUID NOT NULL REFERENCES contacts(id),
    deposit_to_account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    
    currency_code VARCHAR(3) DEFAULT 'IDR',
    exchange_rate DECIMAL(19, 6) DEFAULT 1,
    total_amount DECIMAL(19, 4) NOT NULL,
    unused_amount DECIMAL(19, 4) DEFAULT 0,
    
    status receipt_status DEFAULT 'POSTED',
    journal_entry_id UUID REFERENCES journal_entries(id),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, receipt_number)
);
CREATE INDEX idx_sales_rcp_workspace ON sales_receipts(workspace_id);

CREATE TABLE sales_receipt_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sales_receipt_id UUID REFERENCES sales_receipts(id) ON DELETE CASCADE,
    sales_invoice_id UUID REFERENCES sales_invoices(id),
    amount_paid DECIMAL(19, 4) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);


-- =============================================
-- 4. PURCHASE MODULE
-- =============================================
CREATE TYPE bill_status AS ENUM ('DRAFT', 'APPROVED', 'VOID', 'PAID', 'PARTIAL');

CREATE TABLE purchase_bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    bill_number VARCHAR(50) NOT NULL,
    reference_number VARCHAR(50) NOT NULL, 
    
    transaction_date DATE NOT NULL,
    due_date DATE NOT NULL,
    
    vendor_id UUID NOT NULL REFERENCES contacts(id),
    billing_address TEXT,
    
    currency_code VARCHAR(3) DEFAULT 'IDR',
    exchange_rate DECIMAL(19, 6) DEFAULT 1,
    
    subtotal DECIMAL(19, 4) DEFAULT 0,
    tax_total DECIMAL(19, 4) DEFAULT 0,
    discount_total DECIMAL(19, 4) DEFAULT 0,
    global_discount_type VARCHAR(20),
    global_discount_value DECIMAL(19, 4) DEFAULT 0,
    rounding_adjustment DECIMAL(19, 4) DEFAULT 0,
    grand_total DECIMAL(19, 4) DEFAULT 0,
    amount_paid DECIMAL(19, 4) DEFAULT 0,
    balance_due DECIMAL(19, 4) DEFAULT 0,
    tax_inclusive BOOLEAN DEFAULT FALSE,
    
    status bill_status DEFAULT 'DRAFT',
    journal_entry_id UUID REFERENCES journal_entries(id),
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, bill_number)
);
CREATE INDEX idx_purch_bills_workspace ON purchase_bills(workspace_id);

CREATE TABLE purchase_bill_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_bill_id UUID REFERENCES purchase_bills(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    
    warehouse_id UUID REFERENCES warehouses(id), -- [UPDATE: Kandang mana yang terima pakan]
    
    product_name VARCHAR(255),
    description TEXT,
    
    quantity DECIMAL(19, 4) NOT NULL,
    secondary_quantity DECIMAL(19, 4), -- [NEW: Support for Dual UOM]
    unit_price DECIMAL(19, 4) NOT NULL,
    discount_type VARCHAR(20),
    discount_value DECIMAL(19, 4) DEFAULT 0,
    discount_amount DECIMAL(19, 4) DEFAULT 0,
    
    tax_rate_id UUID REFERENCES tax_rates(id),
    tax_rate DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(19, 4) DEFAULT 0,
    
    batch_number VARCHAR(50),
    expiry_date DATE,
    
    total_price DECIMAL(19, 4) NOT NULL
);
CREATE INDEX idx_purch_items_batch ON purchase_bill_items(batch_number);

CREATE TYPE payment_status AS ENUM ('DRAFT', 'POSTED', 'VOID');

CREATE TABLE purchase_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    payment_number VARCHAR(50) NOT NULL,
    transaction_date DATE NOT NULL,
    reference_number VARCHAR(50),
    
    vendor_id UUID NOT NULL REFERENCES contacts(id),
    paid_from_account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    
    currency_code VARCHAR(3) DEFAULT 'IDR',
    exchange_rate DECIMAL(19, 6) DEFAULT 1,
    total_amount DECIMAL(19, 4) NOT NULL,
    unused_amount DECIMAL(19, 4) DEFAULT 0,
    
    status payment_status DEFAULT 'POSTED',
    journal_entry_id UUID REFERENCES journal_entries(id),
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, payment_number)
);
CREATE INDEX idx_purch_pay_workspace ON purchase_payments(workspace_id);

CREATE TABLE purchase_payment_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_payment_id UUID REFERENCES purchase_payments(id) ON DELETE CASCADE,
    purchase_bill_id UUID REFERENCES purchase_bills(id),
    amount_paid DECIMAL(19, 4) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- [NEW] DEBIT NOTES (RETUR PEMBELIAN)
CREATE TYPE debit_note_status AS ENUM ('DRAFT', 'POSTED', 'VOID');

CREATE TABLE debit_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    debit_note_number VARCHAR(50) NOT NULL,
    transaction_date DATE NOT NULL,
    vendor_id UUID NOT NULL REFERENCES contacts(id),
    
    original_bill_id UUID NOT NULL REFERENCES purchase_bills(id),
    
    subtotal DECIMAL(19, 4) DEFAULT 0,
    tax_total DECIMAL(19, 4) DEFAULT 0,
    grand_total DECIMAL(19, 4) DEFAULT 0,
    
    status debit_note_status DEFAULT 'DRAFT',
    journal_entry_id UUID REFERENCES journal_entries(id),
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, debit_note_number)
);

CREATE TABLE debit_note_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    debit_note_id UUID REFERENCES debit_notes(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    
    warehouse_id UUID REFERENCES warehouses(id), -- [NEW: Kandang mana yang retur ayam mati/susut]
    
    quantity DECIMAL(19, 4) NOT NULL,
    secondary_quantity DECIMAL(19, 4), -- [NEW: Support for Dual UOM]
    unit_price DECIMAL(19, 4) NOT NULL,
    tax_rate_id UUID REFERENCES tax_rates(id),
    tax_rate DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(19, 4) DEFAULT 0,
    
    total_price DECIMAL(19, 4) NOT NULL
);


-- =============================================
-- 5. INVENTORY MODULE
-- =============================================
-- [NOTE: warehouses table moved to Section 1 Master Data]

CREATE TYPE inventory_direction AS ENUM ('IN', 'OUT');

CREATE TABLE inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    transaction_date TIMESTAMP NOT NULL DEFAULT NOW(),
    warehouse_id UUID NOT NULL REFERENCES warehouses(id), -- [SAFE: Built properly because warehouse is in Section 1]
    product_id UUID NOT NULL REFERENCES products(id),
    
    batch_number VARCHAR(50), 
    expiry_date DATE,
    
    direction inventory_direction NOT NULL,
    quantity DECIMAL(19, 4) NOT NULL CHECK (quantity > 0),
    secondary_quantity DECIMAL(19, 4), -- [NEW: Support for Dual UOM]
    cost_per_unit DECIMAL(19, 4) DEFAULT 0,
    
    reference_type VARCHAR(50) NOT NULL,
    reference_id UUID NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_inv_trx_workspace ON inventory_transactions(workspace_id);
CREATE INDEX idx_inv_trx_ref ON inventory_transactions(reference_type, reference_id);

-- [NEW] REAL-TIME INVENTORY CACHE (Materialized Ledger)
CREATE TABLE inventory_balances (
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id),
    product_id UUID NOT NULL REFERENCES products(id),
    
    quantity DECIMAL(19, 4) DEFAULT 0,
    secondary_quantity DECIMAL(19, 4) DEFAULT 0,
    
    last_updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, warehouse_id, product_id)
);
CREATE INDEX idx_inv_bal_lookup ON inventory_balances(workspace_id, warehouse_id, product_id);

-- [NEW] REAL-TIME CACHE TRIGGER (Maintains inventory_balances automatically)
CREATE OR REPLACE FUNCTION update_inventory_balance()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO inventory_balances (
        workspace_id, warehouse_id, product_id, 
        quantity, secondary_quantity
    )
    VALUES (
        NEW.workspace_id, NEW.warehouse_id, NEW.product_id, 
        CASE WHEN NEW.direction = 'IN' THEN NEW.quantity ELSE -NEW.quantity END,
        CASE WHEN NEW.direction = 'IN' THEN COALESCE(NEW.secondary_quantity, 0) ELSE -COALESCE(NEW.secondary_quantity, 0) END
    )
    ON CONFLICT (workspace_id, warehouse_id, product_id)
    DO UPDATE SET 
        quantity = inventory_balances.quantity + EXCLUDED.quantity,
        secondary_quantity = inventory_balances.secondary_quantity + EXCLUDED.secondary_quantity,
        last_updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_balance
AFTER INSERT ON inventory_transactions
FOR EACH ROW EXECUTE FUNCTION update_inventory_balance();

CREATE TYPE adjustment_status AS ENUM ('DRAFT', 'APPROVED', 'VOID');

CREATE TABLE inventory_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    adjustment_number VARCHAR(50) NOT NULL,
    transaction_date DATE NOT NULL,
    warehouse_id UUID NOT NULL REFERENCES warehouses(id),
    reason TEXT,
    
    adjustment_account_id UUID REFERENCES chart_of_accounts(id), -- [NEW: To record loss/gain account]
    status adjustment_status DEFAULT 'DRAFT',
    journal_entry_id UUID REFERENCES journal_entries(id), -- [NEW: To link to Accounting Journal]
    approved_by UUID,
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, adjustment_number)
);
CREATE INDEX idx_inv_adj_workspace ON inventory_adjustments(workspace_id);

CREATE TABLE inventory_adjustment_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inventory_adjustment_id UUID REFERENCES inventory_adjustments(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    
    batch_number VARCHAR(50),
    expiry_date DATE,
    quantity_adjustment DECIMAL(19, 4) NOT NULL,
    secondary_quantity_adjustment DECIMAL(19, 4), -- [NEW: Support for Dual UOM adjustment]
    cost_per_unit DECIMAL(19, 4) DEFAULT 0
);


-- =============================================
-- 6. EXPENSE MODULE
-- =============================================
CREATE TYPE expense_status AS ENUM ('DRAFT', 'POSTED', 'VOID');

CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    expense_number VARCHAR(50) NOT NULL,
    transaction_date DATE NOT NULL,
    
    pay_from_account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    payee_id UUID REFERENCES contacts(id),
    
    payment_method VARCHAR(50),
    reference_number VARCHAR(50),
    
    currency_code VARCHAR(3) DEFAULT 'IDR',
    exchange_rate DECIMAL(19, 6) DEFAULT 1,
    total_amount DECIMAL(19, 4) DEFAULT 0,
    
    status expense_status DEFAULT 'DRAFT',
    journal_entry_id UUID REFERENCES journal_entries(id),
    
    memo TEXT,
    attachment_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, expense_number)
);
CREATE INDEX idx_expenses_workspace ON expenses(workspace_id);

CREATE TABLE expense_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_id UUID REFERENCES expenses(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    
    description TEXT,
    tax_rate_id UUID REFERENCES tax_rates(id),
    tax_rate DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(19, 4) DEFAULT 0,
    
    amount DECIMAL(19, 4) NOT NULL,
    total_line_amount DECIMAL(19, 4) NOT NULL
);


-- =============================================
-- 7. INTERNAL TRANSFERS & MANUAL JOURNALS
-- =============================================
CREATE TABLE internal_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    transfer_number VARCHAR(50) NOT NULL,
    transaction_date DATE NOT NULL,
    
    from_account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    to_account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    
    amount DECIMAL(19, 4) NOT NULL CHECK (amount > 0),
    admin_fee DECIMAL(19, 4) DEFAULT 0,
    admin_fee_account_id UUID REFERENCES chart_of_accounts(id),
    
    memo TEXT,
    reference_number VARCHAR(50),
    attachment_url TEXT,
    
    status VARCHAR(20) DEFAULT 'POSTED',
    journal_entry_id UUID REFERENCES journal_entries(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, transfer_number)
);
CREATE INDEX idx_transfers_workspace ON internal_transfers(workspace_id);

CREATE TYPE manual_journal_status AS ENUM ('DRAFT', 'POSTED', 'VOID');

CREATE TABLE manual_journals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    journal_number VARCHAR(50) NOT NULL,
    transaction_date DATE NOT NULL,
    memo TEXT,
    
    status manual_journal_status DEFAULT 'DRAFT',
    journal_entry_id UUID REFERENCES journal_entries(id),
    
    created_by UUID,
    posted_by UUID,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id, journal_number)
);
CREATE INDEX idx_manual_journals_workspace ON manual_journals(workspace_id);

CREATE TABLE manual_journal_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    manual_journal_id UUID NOT NULL REFERENCES manual_journals(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    
    description TEXT,
    debit DECIMAL(19, 4) DEFAULT 0 CHECK (debit >= 0),
    credit DECIMAL(19, 4) DEFAULT 0 CHECK (credit >= 0),
    sequence_no INT DEFAULT 0
);


-- =============================================
-- 8. SETTINGS
-- =============================================
CREATE TABLE workspace_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    
    currency_code VARCHAR(3) DEFAULT 'IDR',
    fiscal_year_start_month INT DEFAULT 1, -- January
    lock_date DATE,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(workspace_id)
);
CREATE INDEX idx_settings_workspace ON workspace_settings(workspace_id);
