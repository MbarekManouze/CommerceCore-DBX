CREATE TYPE order_status as ENUM ('pending','paid','shipped','delivered','cancelled');

CREATE TABLE orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id),
    shipping_address_id INT REFERENCES addresses(address_id),
    total NUMERIC(10,2),
    status order_status DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE order_items (
    order_id UUID REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(product_id),
    quantity INT check (quantity > 0),
    price NUMERIC(10, 2),
    total NUMERIC(10, 2) generated always as (quantity * price) stored,
    PRIMARY KEY(order_id, product_id)
);