CREATE OR REPLACE FUNCTION audit_log_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_row_id TEXT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_row_id := COALESCE(
            to_jsonb(NEW)->>'id',
            to_jsonb(NEW)->>'user_id',
            to_jsonb(NEW)->>'order_id',
            to_jsonb(NEW)->>'payment_id'
        );
        INSERT INTO audit_logs(table_name, operation, row_id, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, v_row_id, to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        v_row_id := COALESCE(
            to_jsonb(NEW)->>'id',
            to_jsonb(NEW)->>'user_id',
            to_jsonb(NEW)->>'order_id',
            to_jsonb(NEW)->>'payment_id'
        );
        INSERT INTO audit_logs(table_name, operation, row_id, old_data, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, v_row_id, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        v_row_id := COALESCE(
            to_jsonb(OLD)->>'id',
            to_jsonb(OLD)->>'user_id',
            to_jsonb(OLD)->>'order_id',
            to_jsonb(OLD)->>'payment_id'
        );
        INSERT INTO audit_logs(table_name, operation, row_id, old_data)
        VALUES (TG_TABLE_NAME, TG_OP, v_row_id, to_jsonb(OLD));
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;
