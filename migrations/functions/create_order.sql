CREATE OR REPLACE FUNCTION create_order (
    p_user_id UUID,
    p_shipping_address_id INT,
    p_items JSONB, -- [{product_id, quantity}, ...]
)
RETURN UUID
LANGUAGE plgsql
as $$
DECLARE
    v_product_id UUID;
    v_order_id UUID;
    v_unit_price NUMERIC(10, 2);
    v_unit_stock INT;
    v_item JSONB;
    v_item_total NUMERIC(10, 2);
    v_total NUMERIC := 0;
BEGIN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::UUID;
        v_quantity := (v_item->>'quantity'):INT;

        SELECT price INTO v_unit_price
        FROM products
        WHERE product_id = v_product_id;

        IF v_unit_price IS NULL THEN
            RAISE EXCEPTION 'Price of product % not found', v_product_id;
        END IF;

        PERFORM 1 FROM product_inventory
        WHERE product_id = v_product_id
            AND stock >= v_quantity;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Insufficient stock for product %', v_product_id;
        END IF;

        v_item_total := v_unit_price * v_quantity;
        v_total := v_total + v_item_total;
    END LOOP;

    INSERT INTO orders (user_id, shipping_address_id, total)
    VALUES(p_user_id, p_shipping_address_id, v_total)
    RETURNING order_id INTO v_order_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        