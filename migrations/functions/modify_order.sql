CREATE OR REPLACE FUNCTION modify_order (
    p_order_id UUID,
    p_modifications JSONB
)
RETURNS UUID
LANGUAGE plpgsql
as $$
DECLARE
    v_product_id    UUID;
    v_quantity      INT;
    v_unit_price    NUMERIC(10, 2);
    v_item_total    NUMERIC(10, 2);
    v_total         NUMERIC := 0;
    v_item          JSONB;
    v_stock         INT;
    v_curr_quantity INT := 0; 
BEGIN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_modifications)
    LOOP
        v_product_id    := (v_item->>'product_id')::UUID;
        v_quantity      := (v_item->>'quantity')::INT;
        v_previous_quantity   := (v_item->>'previous_quantity')::INT;

        SELECT price INTO v_unit_price
        FROM products
        WHERE product_id = v_product_id;

        IF v_unit_price IS NULL THEN
            RAISE EXCEPTION 'Price of product % not found', v_product_id;
        END IF;

        SELECT stock INTO v_stock
        FROM product_inventory
        WHERE product_id = v_product_id;

        IF v_stock < v_quantity THEN
            RAISE EXCEPTION 'Insufficient stock for product %', v_product_id;
        END IF;

        IF v_previous_quantity > v_quantity THEN
            v_curr_quantity := v_stock + (v_previous_quantity - v_quantity);

            UPDATE product_inventory
            SET v_stock = v_curr_quantity
            WHERE product_id = v_product_id;
        END IF;

        IF v_previous_quantity < v_quantity THEN
            v_curr_quantity := v_stock + v_quantity;

            UPDATE product_inventory
            SET v_stock = v_curr_quantity
            WHERE product_id = v_product_id;
        END IF;

        v_item_total    := v_unit_price * v_quantity;
        v_total         := v_total + v_item_total;
    END LOOP;

    UPDATE orders 
    SET total = v_total
    WHERE order_id = p_order_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_modifications)
    LOOP
        v_product_id        := (v_item->>'product_id')::UUID;
        v_quantity          := (v_item->>'quantity')::INT;

        SELECT price INTO v_unit_price
        FROM products
        WHERE product_id = v_product_id;

        UPDATE order_items
        SET
            quantity = v_quantity,
            price = v_unit_price
        WHERE 
            order_id = p_order_id
            AND
            product_id = v_product_id;
    END LOOP;

    RETURNS p_order_id;
END;
$$;

-- FUNCTION still needs cheking