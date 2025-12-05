CREATE OR REPLACE FUNCTION modify_order (
    p_order_id UUID,
    p_modifications JSONB  -- [{ "product_id": "...", "quantity": 5 }, ...]
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id      UUID;
    v_new_quantity    INT;
    v_old_quantity    INT;
    v_delta           INT;
    v_unit_price      NUMERIC(10, 2);
    v_item_total      NUMERIC(10, 2);
    v_total           NUMERIC(10, 2) := 0;
    v_item            JSONB;
    v_stock           INT;
BEGIN
    -- 1) For each modified item: adjust inventory and compute total
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_modifications)
    LOOP
        v_product_id   := (v_item->>'product_id')::UUID;
        v_new_quantity := (v_item->>'quantity')::INT;

        -- Get old quantity from order_items (source of truth)
        SELECT quantity INTO v_old_quantity
        FROM order_items
        WHERE order_id = p_order_id
          AND product_id = v_product_id;

        IF v_old_quantity IS NULL THEN
            RAISE EXCEPTION 'Order item for product % not found in order %',
                v_product_id, p_order_id;
        END IF;

        v_delta := v_new_quantity - v_old_quantity;  -- + means more, - means less

        -- Only touch inventory if quantity actually changes
        IF v_delta <> 0 THEN
            -- Lock row to avoid race conditions
            SELECT stock INTO v_stock
            FROM product_inventory
            WHERE product_id = v_product_id
            FOR UPDATE;

            IF v_stock IS NULL THEN
                RAISE EXCEPTION 'Inventory row for product % not found', v_product_id;
            END IF;

            IF v_delta > 0 THEN
                -- need more stock
                IF v_stock < v_delta THEN
                    RAISE EXCEPTION 'Insufficient stock for product %', v_product_id;
                END IF;
                v_stock := v_stock - v_delta;
            ELSE
                -- returning stock (quantity decreased)
                v_stock := v_stock + (-v_delta); -- add back abs(delta)
            END IF;

            UPDATE product_inventory
            SET stock = v_stock,
                last_updated = now()
            WHERE product_id = v_product_id;
        END IF;

        -- Recompute price & line total for new quantity
        SELECT price INTO v_unit_price
        FROM products
        WHERE product_id = v_product_id;

        IF v_unit_price IS NULL THEN
            RAISE EXCEPTION 'Price of product % not found', v_product_id;
        END IF;

        v_item_total := v_unit_price * v_new_quantity;
        v_total      := v_total + v_item_total;
    END LOOP;

    -- 2) Update order total
    UPDATE orders 
    SET total = v_total
    WHERE order_id = p_order_id;

    -- 3) Update each order_item row
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_modifications)
    LOOP
        v_product_id   := (v_item->>'product_id')::UUID;
        v_new_quantity := (v_item->>'quantity')::INT;

        SELECT price INTO v_unit_price
        FROM products
        WHERE product_id = v_product_id;

        UPDATE order_items
        SET
            quantity = v_new_quantity,
            price    = v_unit_price
        WHERE 
            order_id   = p_order_id
            AND product_id = v_product_id;
    END LOOP;

    RETURN p_order_id;
END;
$$;
