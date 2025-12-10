CREATE OR REPLACE VIEW v_payments_safe AS
SELECT 
    p.payment_id,
    p.order_id,
    pm.name AS method_name,
    p.amount,
    p.status,
    p.provider,

    -- Mask provider_payment_id: first 6 chars + exact number of '*'
    left(p.provider_payment_id, 6)
        || repeat('*', length(p.provider_payment_id) - 6)
        AS provider_payment_id_masked,

    -- keep metadata but strip dangerous/internal stuff
    p.metadata - 'debug' - 'internal_notes' AS metadata,

    p.created_at,
    p.paid_at,
    o.total AS order_total,
    o.status AS order_status,
    o.created_at AS order_created_at,

    -- Mask email (only first char + domain)
    regexp_replace(
      u.email,
      '(^.).*(@.*$)',
      '\1***\2'
    ) AS customer_email_masked,

    u.username AS customer_username
FROM payments p
JOIN orders o ON p.order_id = o.order_id
JOIN users u ON o.user_id = u.user_id
LEFT JOIN payment_methods pm ON p.method_id = pm.method_id;
