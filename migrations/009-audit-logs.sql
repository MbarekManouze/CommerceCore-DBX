CREATE TABLE IF NOT EXISTS audit_logs (
    audit_id      BIGSERIAL PRIMARY KEY,
    table_name    TEXT        NOT NULL,
    operation     TEXT        NOT NULL,   -- 'INSERT' | 'UPDATE' | 'DELETE'
    row_id        TEXT,                  -- PK as text, or composite
    old_data      JSONB,
    new_data      JSONB,
    changed_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    changed_by    TEXT                    -- later you can pass app user id here
);


-- Track changes to orders
CREATE TRIGGER trg_audit_orders
AFTER INSERT OR UPDATE OR DELETE ON orders
FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();

-- Track changes to payments
CREATE TRIGGER trg_audit_payments
AFTER INSERT OR UPDATE OR DELETE ON payments
FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();

-- (Optional) Track users
CREATE TRIGGER trg_audit_users
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();
