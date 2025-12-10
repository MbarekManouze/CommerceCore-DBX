CREATE OR REPLACE FUNCTION mark_payment_completed_by_id(
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

    IF v_payment.status = 'completed' THEN
        RETURN;
    END IF;

    IF v_payment.status <> 'pending' THEN
        RAISE EXCEPTION
            'Cannot mark payment % as completed from status %',
            v_payment.payment_id, v_payment.status;
    END IF;

    UPDATE payments
    SET
        status  = 'completed',
        paid_at = COALESCE(paid_at, now())
    WHERE payment_id = v_payment.payment_id;

    IF v_payment.order_id IS NOT NULL THEN
        UPDATE orders
        SET status = 'paid'
        WHERE order_id = v_payment.order_id;
    END IF;
END;
$$;
