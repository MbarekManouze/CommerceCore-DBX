CREATE OR REPLACE create_product (
    p_name TEXT,
    p_description TEXT,
    p_price NUMERIC(10, 2),
    p_attributes OBJECT,
    p_stock INT,
    p_category_id INT,
    p_user_id UUID
)
RETURNS TABLE ("product_id" UUID, err_msg TEXT) as $$
DECLARE 
    v_product_id UUID;
BEGIN
    INSERT INTO products (user_id, category_id, "name", "description", price, "attributes")
    VALUES (p_user_id, p_category_id, p_name, p_description, p_price, p_attributes)
    RETURNING products.product_id INTO v_product_id;

    INSERT INTO product_inventory (product_id, stock)
    VALUES (v_product_id, p_stock);

    RETURN QUERY SELECT v_product_id as "product_id", err_msg;
EXCEPTION
    WHEN OTHERS THEN
        RETURNING QUERY SELECT NULL::UUID, SQLERRM;
END;
$$ LANGUAGE PLPGSQL;