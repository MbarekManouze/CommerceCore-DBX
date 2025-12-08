-- ENUM: payment_status
CREATE TYPE payment_status AS ENUM ('pending','completed','failed');

-- Payment methods table
CREATE TABLE payment_methods (
    method_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

-- Payments table (one row per attempt, NOT UNIQUE per order)
CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id   UUID REFERENCES orders(order_id) ON DELETE SET NULL,
    method_id  INT REFERENCES payment_methods(method_id),
    amount     NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    status     payment_status DEFAULT 'pending',
    provider   TEXT,              -- e.g. 'stripe_checkout'
    provider_payment_id TEXT,     -- Stripe session id (or PaymentIntent id)
    metadata   JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    paid_at    TIMESTAMPTZ
);

-- Payment methods values

INSERT INTO payment_methods (name) VALUES
    ('stripe_card'),
    ('paypal'),
    ('cash_on_delivery'),
    ('bank_transfer');


-- Useful indexes
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_provider_payment_id ON payments(provider_payment_id);
