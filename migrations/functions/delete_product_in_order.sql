CREATE OR REPLACE FUNCTION delete_product_in_order(
    p_order_id   UUID,
    p_product_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_quantity    INT;
    v_price       NUMERIC(10, 2);
    v_line_total  NUMERIC(10, 2);
    v_item_count  INT;
BEGIN
    -- Get quantity and price from the order item (source of truth)
    
    PERFORM 1 FROM orders
    WHERE order_id = p_order_id
        AND status = 'pending';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Only pending orders can be modified. Order % has status %',
        p_order_id,(SELECT status FROM orders WHERE order_id = p_order_id);
    END IF;

    SELECT quantity, price, total
    INTO v_quantity, v_price, v_line_total
    FROM order_items
    WHERE order_id = p_order_id
      AND product_id = p_product_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order item for product % not found in order %',
            p_product_id, p_order_id;
    END IF;

    -- Count how many items the order has
    SELECT COUNT(*)
    INTO v_item_count
    FROM order_items
    WHERE order_id = p_order_id;

    -- Return stock to inventory
    UPDATE product_inventory
    SET stock = stock + v_quantity,
        last_updated = now()
    WHERE product_id = p_product_id;

    -- Decrease order total
    UPDATE orders
    SET total = total - v_line_total
    WHERE order_id = p_order_id;

    -- Delete the order item
    
    -- (    
        -- DELETE FROM order_items
        -- WHERE order_id = p_order_id
        --   AND product_id = p_product_id;
    -- )

    -- Added a `status` column to `order_items` to support operational tracking of
    -- order confirmations and cancellations, improving visibility into revenue impact
    -- and customer payment obligations.

    UPDATE order_items
    SET status = 'cancelled'
    WHERE order_id = p_order_id;

    IF v_item_count = 1 THEN
        UPDATE orders
        SET status = 'cancelled'
        WHERE order_id = p_order_id;
        RETURN format(
          'Product %s deleted and order %s cancelled (no more items)',
          p_product_id, p_order_id
        );
    END IF;

    RETURN format(
        'Product %s has been deleted from order %s',
        p_product_id, p_order_id
    );
END;
$$;
