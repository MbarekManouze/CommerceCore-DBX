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
    -- add more roles like Seller, ...etc
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
  -- is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ,
);