CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- AUTH SCHEMA
CREATE SCHEMA auth;

CREATE TABLE auth.users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(50) UNIQUE NOT NULL,
    email_verified BOOLEAN DEFAULT false,
    username VARCHAR(20) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP
);

CREATE TABLE auth.user_role (
    user_id UUID REFERENCES auth.user(user_id) on DELETE CASCADE,
    roles TEXT NOT NULL CHECK (roles IN ('costumer', 'admin', 'manager')),
    UNIQUE(user_id, roles)
);


CREATE TABLE auth.addresses (
  address_id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(user_id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  street TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT,
  postal_code TEXT,
  country TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);


-- register SCHEMA

CREATE SCHEMA register;

CREATE TABLE register.categories (
  category_id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL
);

CREATE TABLE register.products (
  product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id INT REFERENCES register.categories(category_id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  attributes JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE register.product_inventory (
  product_id UUID PRIMARY KEY REFERENCES register.products(product_id) ON DELETE CASCADE,
  stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
  last_updated TIMESTAMPTZ DEFAULT now()
);

--- Sales schema

CREATE SCHEMA sales;

CREATE TYPE sales.order_status as ENUM ('pending','paid','shipped','delivered','cancelled');

CREATE TABLE sales.orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(user_id),
    shipping_addresss_id REFERENCES auth.addresses(address_id),
    total NUMERIC(10,2),
    status sales.order_status DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE sales.order_items (
    order_id UUID REFERENCES sales.orders(order_id),
    product_id UUID REFERENCES register.products(product_id),
    quantity INT check (quantity > 0),
    price NUMERIC(10, 2),
    total NUMERIC(10, 2) generated always as (quantity * price) stored,
    PRIMARY KEY(order_id, product_id)
);

--- payment schema

CREATE SCHEMA payments;

CREATE TYPE payments.payment_status AS ENUM ('pending','completed','failed');

CREATE TABLE payments.payment_methods (
    method_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

CREATE TABLE payments.payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID UNIQUE REFERENCES sales.orders(order_id) on delete set NULL,
    method_id INT REFERENCES payments.payment_method(method_id),
    amount NUMERIC(10, 2) not NULL check (amount >= 0),
    status payments.payment_status DEFAULT 'pending',
    DEFAULT JSONB,
    paid_at TIMESTAMP
);


--- shipping schema

CREATE SCHEMA shipping;

CREATE TABLE shipping.shipment_statuses (
    status_id SERIAL PRIMARY KEY,
    status TEXT UNIQUE NOT NULL
);

CREATE TABLE shipping.shipments (
    shipment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID UNIQUE REFERENCES sales.orders(order_id),
    status_id INT REFERENCES shipping.shipment_statuses(status_id),
      tracking_number TEXT,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP
);