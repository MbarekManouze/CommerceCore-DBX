CREATE OR REPLACE FUNCTION mark_payment_completed_by_session(
    p_session_id TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_payment  payments%ROWTYPE;
BEGIN
    -- Lock the payment row for this session
    SELECT *
    INTO v_payment
    FROM payments
    WHERE provider_payment_id = p_session_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Payment with provider_payment_id % not found', p_session_id;
    END IF;

    -- Idempotency: if already completed, do nothing
    IF v_payment.status = 'completed' THEN
        RETURN;
    END IF;

    -- Only allow transition from 'pending' → 'completed'
    IF v_payment.status <> 'pending' THEN
        RAISE EXCEPTION
            'Cannot mark payment % as completed from status %',
            v_payment.payment_id, v_payment.status;
    END IF;

    -- Update payment
    UPDATE payments
    SET
        status  = 'completed',
        paid_at = COALESCE(paid_at, now())
    WHERE payment_id = v_payment.payment_id;

    -- Update order: mark as paid if linked
    IF v_payment.order_id IS NOT NULL THEN
        UPDATE orders
        SET status = 'paid'
        WHERE order_id = v_payment.order_id;
    END IF;
END;
$$;
