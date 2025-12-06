CREATE TRIGGER trg_order_cancelled
AFTER UPDATE OF status ON orders
FOR EACH ROW
WHEN (NEW.status = 'cancelled' AND OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION set_order_items_cancelled();
