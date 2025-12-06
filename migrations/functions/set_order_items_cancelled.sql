CREATE OR REPLACE FUNCTION set_order_items_cancelled()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Only act when status actually changes to 'cancelled'
  IF NEW.status = 'cancelled'
     AND (OLD.status IS DISTINCT FROM NEW.status) THEN

    UPDATE order_items
    SET status = 'cancelled'
    WHERE order_id = NEW.order_id;
  END IF;

  RETURN NEW;
END;
$$;
