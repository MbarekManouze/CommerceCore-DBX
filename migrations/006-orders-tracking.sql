CREATE TYPE product_status as ENUM ('confirmed', 'cancelled');

ALTER TABLE order_items
ADD COLUMN status product_status DEFAULT 'confirmed';