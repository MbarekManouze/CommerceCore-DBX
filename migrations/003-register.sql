CREATE TABLE categories (
  category_id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL
);

CREATE TABLE products (
  product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id INT REFERENCES categories(category_id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
  attributes JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ
);

CREATE TABLE product_inventory (
  product_id UUID PRIMARY KEY REFERENCES products(product_id) ON DELETE CASCADE,
  stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
  last_updated TIMESTAMPTZ
);
