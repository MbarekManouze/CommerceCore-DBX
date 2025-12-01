CREATE OR REPLACE FUNCTION create_order (
    user_id UUID,
    p_shipping_address INT,
    p_items JSONB, -- [{product_id, quantity}, ...]
)
RETURN UUID
LANGUAGE plgsql
as $$
DECLARE
    v_product_id UUID;
    v_unit_price NUMERIC(10, 2);
    v_unit_stock INT;
    v_item JSONB;
BEGIN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := ()
