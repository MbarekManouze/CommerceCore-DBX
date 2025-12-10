CREATE OR REPLACE FUNCTION mark_payment_failed_by_session(
    p_session_id TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_payment payments%ROWTYPE;
BEGIN
    SELECT *
    INTO v_payment
    FROM payments
    WHERE provider_payment_id = p_session_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Payment with provider_payment_id % not found', p_session_id;
    END IF;

    -- Idempotency: if already failed, do nothing
    IF v_payment.status = 'failed' THEN
        RETURN;
    END IF;

    -- Only allow transition from 'pending' → 'failed'
    IF v_payment.status <> 'pending' THEN
        RAISE EXCEPTION
            'Cannot mark payment % as failed from status %',
            v_payment.payment_id, v_payment.status;
    END IF;

    UPDATE payments
    SET status = 'failed'
    WHERE payment_id = v_payment.payment_id;

    -- Usually you keep the order 'pending' so the user can retry.
    -- If you want to mark the order differently, you can do it here.
END;
$$;
