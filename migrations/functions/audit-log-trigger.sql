CREATE OR REPLACE FUNCTION audit_log_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_row_id TEXT;
BEGIN
    -- Try to derive a primary key field called 'id' or '..._id'
    IF TG_OP = 'INSERT' THEN
        v_row_id := COALESCE(
            (NEW.id)::TEXT,
            (NEW.user_id)::TEXT,
            (NEW.order_id)::TEXT,
            (NEW.payment_id)::TEXT,
            NULL
        );
        INSERT INTO audit_logs(table_name, operation, row_id, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, v_row_id, to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        v_row_id := COALESCE(
            (NEW.id)::TEXT,
            (NEW.user_id)::TEXT,
            (NEW.order_id)::TEXT,
            (NEW.payment_id)::TEXT,
            NULL
        );
        INSERT INTO audit_logs(table_name, operation, row_id, old_data, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, v_row_id, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        v_row_id := COALESCE(
            (OLD.id)::TEXT,
            (OLD.user_id)::TEXT,
            (OLD.order_id)::TEXT,
            (OLD.payment_id)::TEXT,
            NULL
        );
        INSERT INTO audit_logs(table_name, operation, row_id, old_data)
        VALUES (TG_TABLE_NAME, TG_OP, v_row_id, to_jsonb(OLD));
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;
