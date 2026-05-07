BEGIN;

ALTER TABLE products 
DROP COLUMN is_sold,
DROP COLUMN is_purchased;

COMMIT;