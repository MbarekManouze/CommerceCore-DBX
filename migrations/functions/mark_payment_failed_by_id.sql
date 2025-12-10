CREATE OR REPLACE FUNCTION mark_payment_failed_by_id(
    p_payment_id UUID
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
    WHERE payment_id = p_payment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Payment with id % not found', p_payment_id;
    END IF;

    IF v_payment.status = 'failed' THEN
        RETURN;
    END IF;

    IF v_payment.status <> 'pending' THEN
        RAISE EXCEPTION
            'Cannot mark payment % as failed from status %',
            v_payment.payment_id, v_payment.status;
    END IF;

    UPDATE payments
    SET status = 'failed'
    WHERE payment_id = v_payment.payment_id;

    -- Again, you can decide to update orders here if you want
END;
$$;
