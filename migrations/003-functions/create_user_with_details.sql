CREATE OR REPLACE FUNCTION create_user_with_details (
    p_email TEXT,
    p_username TEXT,
    p_password TEXT,
    p_role TEXT,
    p_full_name TEXT,
    p_phone TEXT,
    p_street TEXT,
    p_city TEXT,
    p_state TEXT,
    p_postal_code TEXT,
    p_country TEXT
)
RETURNS TABLE (user_id UUID, user_role TEXT, address_id INT) as $$
DECLARE
    v_user_id UUID;
BEGIN
    --- transaction block Begin
    INSERT INTO users (email, username, password_hash)
    VALUES (p_email, p_username, p_password)
    RETURNING user_id INTO v_user_id;

    INSERT INTO user_role (user_id, roles)
    VALUES (v_user_id, p_role);

    INSERT INTO addresses (user_id, full_name, phone, street, city, "state", postal_code, country)
    VALUES (v_user_id, p_full_name, p_phone, p_street, p_city, p_state, p_postal_code, p_country)
    RETURNING address_id INTO address_id;

    RETURN QUERY SELECT v_user_id, p_role, address_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating user: %', SQLERROR
        ROLLBACK;
        RETURN;
END;
$$ LANGUAGE PLPGSQL;