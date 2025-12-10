--
-- PostgreSQL database dump
--

\restrict fJK0brQfaIHShfLCAzt3TOXnmj0C9M6Qo3lVnFGecGK889HOSUJKHceltbePgyr

-- Dumped from database version 17.6 (Debian 17.6-2.pgdg13+1)
-- Dumped by pg_dump version 17.6 (Debian 17.6-2.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: dbuser
--

CREATE SCHEMA auth;


ALTER SCHEMA auth OWNER TO dbuser;

--
-- Name: payments; Type: SCHEMA; Schema: -; Owner: dbuser
--

CREATE SCHEMA payments;


ALTER SCHEMA payments OWNER TO dbuser;

--
-- Name: register; Type: SCHEMA; Schema: -; Owner: dbuser
--

CREATE SCHEMA register;


ALTER SCHEMA register OWNER TO dbuser;

--
-- Name: sales; Type: SCHEMA; Schema: -; Owner: dbuser
--

CREATE SCHEMA sales;


ALTER SCHEMA sales OWNER TO dbuser;

--
-- Name: shipping; Type: SCHEMA; Schema: -; Owner: dbuser
--

CREATE SCHEMA shipping;


ALTER SCHEMA shipping OWNER TO dbuser;

--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: order_status; Type: TYPE; Schema: public; Owner: dbuser
--

CREATE TYPE public.order_status AS ENUM (
    'pending',
    'paid',
    'shipped',
    'delivered',
    'cancelled'
);


ALTER TYPE public.order_status OWNER TO dbuser;

--
-- Name: payment_status; Type: TYPE; Schema: public; Owner: dbuser
--

CREATE TYPE public.payment_status AS ENUM (
    'pending',
    'completed',
    'failed'
);


ALTER TYPE public.payment_status OWNER TO dbuser;

--
-- Name: product_status; Type: TYPE; Schema: public; Owner: dbuser
--

CREATE TYPE public.product_status AS ENUM (
    'confirmed',
    'cancelled'
);


ALTER TYPE public.product_status OWNER TO dbuser;

--
-- Name: audit_log_trigger(); Type: FUNCTION; Schema: public; Owner: dbuser
--

CREATE FUNCTION public.audit_log_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_row_id TEXT;
BEGIN
    -- Try to derive a primary key field called 'id' or '..._id'
    IF TG_OP = 'INSERT' THEN
        v_row_id := COALESCE(
            (NEW.id)::TEXT,
            (NEW.user_id)::TEXT,
            (NEW.order_id)::TEXT,
            (NEW.payment_id)::TEXT,
            NULL
        );
        INSERT INTO audit_logs(table_name, operation, row_id, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, v_row_id, to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        v_row_id := COALESCE(
            (NEW.id)::TEXT,
            (NEW.user_id)::TEXT,
            (NEW.order_id)::TEXT,
            (NEW.payment_id)::TEXT,
            NULL
        );
        INSERT INTO audit_logs(table_name, operation, row_id, old_data, new_data)
        VALUES (TG_TABLE_NAME, TG_OP, v_row_id, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        v_row_id := COALESCE(
            (OLD.id)::TEXT,
            (OLD.user_id)::TEXT,
            (OLD.order_id)::TEXT,
            (OLD.payment_id)::TEXT,
            NULL
        );
        INSERT INTO audit_logs(table_name, operation, row_id, old_data)
        VALUES (TG_TABLE_NAME, TG_OP, v_row_id, to_jsonb(OLD));
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.audit_log_trigger() OWNER TO dbuser;

--
-- Name: create_order(uuid, integer, jsonb); Type: FUNCTION; Schema: public; Owner: dbuser
--

CREATE FUNCTION public.create_order(p_user_id uuid, p_shipping_address_id integer, p_items jsonb) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_product_id    UUID;
    v_order_id      UUID;
    v_unit_price    NUMERIC(10, 2);
    v_quantity      INT;
    v_item          JSONB;
    v_item_total    NUMERIC(10, 2);
    v_total         NUMERIC := 0;
BEGIN
    -- 1) Validate items and calculate total
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id    := (v_item->>'product_id')::UUID;
        v_quantity      := (v_item->>'quantity')::INT;

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

        v_item_total    := v_unit_price * v_quantity;
        v_total         := v_total + v_item_total;
    END LOOP;

    -- 2) Insert order
    INSERT INTO orders (user_id, shipping_address_id, total)
    VALUES(p_user_id, p_shipping_address_id, v_total)
    RETURNING order_id INTO v_order_id;

    -- 3) Insert items + update stock
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id    := (v_item->>'product_id')::UUID;
        v_quantity      := (v_item->>'quantity')::INT;

        SELECT price INTO v_unit_price
        FROM products
        WHERE product_id = v_product_id;

        INSERT INTO order_items (order_id, product_id ,quantity, price)
        VALUES(v_order_id, v_product_id, v_quantity, v_unit_price);

        UPDATE product_inventory
        SET
            stock = stock - v_quantity,
            last_updated = NOW()
        WHERE product_id = v_product_id;

    END LOOP;

    return v_order_id;
END;
$$;


ALTER FUNCTION public.create_order(p_user_id uuid, p_shipping_address_id integer, p_items jsonb) OWNER TO dbuser;

--
-- Name: create_product(uuid, text, text, numeric, jsonb, integer, integer); Type: FUNCTION; Schema: public; Owner: dbuser
--

CREATE FUNCTION public.create_product(p_user_id uuid, p_name text, p_description text, p_price numeric, p_attributes jsonb, p_stock integer, p_category_id integer) RETURNS TABLE(product_id uuid, err_msg text)
    LANGUAGE plpgsql
    AS $$
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
        RETURN QUERY SELECT NULL::UUID, SQLERRM;
END;
$$;


ALTER FUNCTION public.create_product(p_user_id uuid, p_name text, p_description text, p_price numeric, p_attributes jsonb, p_stock integer, p_category_id integer) OWNER TO dbuser;

--
-- Name: create_user_with_details(text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: dbuser
--

CREATE FUNCTION public.create_user_with_details(p_email text, p_username text, p_password text, p_role text, p_full_name text, p_phone text, p_street text, p_city text, p_state text, p_postal_code text, p_country text) RETURNS TABLE(user_id uuid, user_role text, address_id integer, err_msg text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id UUID;
BEGIN
    --- transaction block Begin
    INSERT INTO users (email, username, password_hash)
    VALUES (p_email, p_username, p_password)
    RETURNING users.user_id INTO v_user_id;

    INSERT INTO user_role (user_id, roles)
    VALUES (v_user_id, p_role);

    INSERT INTO addresses (user_id, full_name, phone, street, city, "state", postal_code, country)
    VALUES (v_user_id, p_full_name, p_phone, p_street, p_city, p_state, p_postal_code, p_country)
    RETURNING addresses.address_id INTO address_id;

    RETURN QUERY SELECT v_user_id as "user_id", p_role as user_role, address_id, err_msg;
EXCEPTION
    WHEN OTHERS THEN
        -- RAISE NOTICE 'Error creating user: %', SQLERRM
        -- ROLLBACK;
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT, NULL::INT, SQLERRM;
END;
$$;


ALTER FUNCTION public.create_user_with_details(p_email text, p_username text, p_password text, p_role text, p_full_name text, p_phone text, p_street text, p_city text, p_state text, p_postal_code text, p_country text) OWNER TO dbuser;

--
-- Name: delete_product_in_order(uuid, uuid); Type: FUNCTION; Schema: public; Owner: dbuser
--

CREATE FUNCTION public.delete_product_in_order(p_order_id uuid, p_product_id uuid) RETURNS text
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


ALTER FUNCTION public.delete_product_in_order(p_order_id uuid, p_product_id uuid) OWNER TO dbuser;

--
-- Name: mark_payment_completed_by_id(uuid); Type: FUNCTION; Schema: public; Owner: dbuser
--

CREATE FUNCTION public.mark_payment_completed_by_id(p_payment_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_payment payments%ROWTYPE;
BEGIN
    SELECT *
    INTO v_payment
    FROM payments
    WHERE payment_id = p_payment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Payment with id % not found', p_payment_id;
    END IF;

    IF v_payment.status = 'completed' THEN
        RETURN;
    END IF;

    IF v_payment.status <> 'pending' THEN
        RAISE EXCEPTION
            'Cannot mark payment % as completed from status %',
            v_payment.payment_id, v_payment.status;
    END IF;

    UPDATE payments
    SET
        status  = 'completed',
        paid_at = COALESCE(paid_at, now())
    WHERE payment_id = v_payment.payment_id;

    IF v_payment.order_id IS NOT NULL THEN
        UPDATE orders
        SET status = 'paid'
        WHERE order_id = v_payment.order_id;
    END IF;
END;
$$;


ALTER FUNCTION public.mark_payment_completed_by_id(p_payment_id uuid) OWNER TO dbuser;

--
-- Name: mark_payment_completed_by_session(text); Type: FUNCTION; Schema: public; Owner: dbuser
--

CREATE FUNCTION public.mark_payment_completed_by_session(p_session_id text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_payment  payments%ROWTYPE;
BEGIN
    -- Lock the payment row for this session
    SELECT *
    INTO v_payment
    FROM payments
    WHERE provider_payment_id = p_session_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Payment with provider_payment_id % not found', p_session_id;
    END IF;

    -- Idempotency: if already completed, do nothing
    IF v_payment.status = 'completed' THEN
        RETURN;
    END IF;

    -- Only allow transition from 'pending' → 'completed'
    IF v_payment.status <> 'pending' THEN
        RAISE EXCEPTION
            'Cannot mark payment % as completed from status %',
            v_payment.payment_id, v_payment.status;
    END IF;

    -- Update payment
    UPDATE payments
    SET
        status  = 'completed',
        paid_at = COALESCE(paid_at, now())
    WHERE payment_id = v_payment.payment_id;

    -- Update order: mark as paid if linked
    IF v_payment.order_id IS NOT NULL THEN
        UPDATE orders
        SET status = 'paid'
        WHERE order_id = v_payment.order_id;
    END IF;
END;
$$;


ALTER FUNCTION public.mark_payment_completed_by_session(p_session_id text) OWNER TO dbuser;

--
-- Name: mark_payment_failed_by_id(uuid); Type: FUNCTION; Schema: public; Owner: dbuser
--

CREATE FUNCTION public.mark_payment_failed_by_id(p_payment_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_payment payments%ROWTYPE;
BEGIN
    SELECT *
    INTO v_payment
    FROM payments
    WHERE payment_id = p_payment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Payment with id % not found', p_payment_id;
    END IF;

    IF v_payment.status = 'failed' THEN
        RETURN;
    END IF;

    IF v_payment.status <> 'pending' THEN
        RAISE EXCEPTION
            'Cannot mark payment % as failed from status %',
            v_payment.payment_id, v_payment.status;
    END IF;

    UPDATE payments
    SET status = 'failed'
    WHERE payment_id = v_payment.payment_id;

    -- Again, you can decide to update orders here if you want
END;
$$;


ALTER FUNCTION public.mark_payment_failed_by_id(p_payment_id uuid) OWNER TO dbuser;

--
-- Name: mark_payment_failed_by_session(text); Type: FUNCTION; Schema: public; Owner: dbuser
--

CREATE FUNCTION public.mark_payment_failed_by_session(p_session_id text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_payment payments%ROWTYPE;
BEGIN
    SELECT *
    INTO v_payment
    FROM payments
    WHERE provider_payment_id = p_session_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Payment with provider_payment_id % not found', p_session_id;
    END IF;

    -- Idempotency: if already failed, do nothing
    IF v_payment.status = 'failed' THEN
        RETURN;
    END IF;

    -- Only allow transition from 'pending' → 'failed'
    IF v_payment.status <> 'pending' THEN
        RAISE EXCEPTION
            'Cannot mark payment % as failed from status %',
            v_payment.payment_id, v_payment.status;
    END IF;

    UPDATE payments
    SET status = 'failed'
    WHERE payment_id = v_payment.payment_id;

    -- Usually you keep the order 'pending' so the user can retry.
    -- If you want to mark the order differently, you can do it here.
END;
$$;


ALTER FUNCTION public.mark_payment_failed_by_session(p_session_id text) OWNER TO dbuser;

--
-- Name: modify_order(uuid, jsonb); Type: FUNCTION; Schema: public; Owner: dbuser
--

CREATE FUNCTION public.modify_order(p_order_id uuid, p_modifications jsonb) RETURNS uuid
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


ALTER FUNCTION public.modify_order(p_order_id uuid, p_modifications jsonb) OWNER TO dbuser;

--
-- Name: refresh_mv_daily_revenue(); Type: FUNCTION; Schema: public; Owner: dbuser
--

CREATE FUNCTION public.refresh_mv_daily_revenue() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_revenue;
END;
$$;


ALTER FUNCTION public.refresh_mv_daily_revenue() OWNER TO dbuser;

--
-- Name: set_order_items_cancelled(); Type: FUNCTION; Schema: public; Owner: dbuser
--

CREATE FUNCTION public.set_order_items_cancelled() RETURNS trigger
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


ALTER FUNCTION public.set_order_items_cancelled() OWNER TO dbuser;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: users; Type: TABLE; Schema: auth; Owner: dbuser
--

CREATE TABLE auth.users (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(50) NOT NULL,
    email_verified boolean DEFAULT false,
    username character varying(20) NOT NULL,
    password_hash text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone
);


ALTER TABLE auth.users OWNER TO dbuser;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: dbuser
--

CREATE TABLE public.addresses (
    address_id integer NOT NULL,
    user_id uuid,
    full_name text NOT NULL,
    phone text NOT NULL,
    street text NOT NULL,
    city text NOT NULL,
    state text,
    postal_code text,
    country text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone
);


ALTER TABLE public.addresses OWNER TO dbuser;

--
-- Name: addresses_address_id_seq; Type: SEQUENCE; Schema: public; Owner: dbuser
--

CREATE SEQUENCE public.addresses_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.addresses_address_id_seq OWNER TO dbuser;

--
-- Name: addresses_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dbuser
--

ALTER SEQUENCE public.addresses_address_id_seq OWNED BY public.addresses.address_id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: dbuser
--

CREATE TABLE public.audit_logs (
    audit_id bigint NOT NULL,
    table_name text NOT NULL,
    operation text NOT NULL,
    row_id text,
    old_data jsonb,
    new_data jsonb,
    changed_at timestamp with time zone DEFAULT now() NOT NULL,
    changed_by text
);


ALTER TABLE public.audit_logs OWNER TO dbuser;

--
-- Name: audit_logs_audit_id_seq; Type: SEQUENCE; Schema: public; Owner: dbuser
--

CREATE SEQUENCE public.audit_logs_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_logs_audit_id_seq OWNER TO dbuser;

--
-- Name: audit_logs_audit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dbuser
--

ALTER SEQUENCE public.audit_logs_audit_id_seq OWNED BY public.audit_logs.audit_id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: dbuser
--

CREATE TABLE public.categories (
    category_id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.categories OWNER TO dbuser;

--
-- Name: categories_category_id_seq; Type: SEQUENCE; Schema: public; Owner: dbuser
--

CREATE SEQUENCE public.categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_category_id_seq OWNER TO dbuser;

--
-- Name: categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dbuser
--

ALTER SEQUENCE public.categories_category_id_seq OWNED BY public.categories.category_id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: dbuser
--

CREATE TABLE public.orders (
    order_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    shipping_address_id integer,
    total numeric(10,2),
    status public.order_status DEFAULT 'pending'::public.order_status,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.orders OWNER TO dbuser;

--
-- Name: mv_daily_revenue; Type: MATERIALIZED VIEW; Schema: public; Owner: dbuser
--

CREATE MATERIALIZED VIEW public.mv_daily_revenue AS
 SELECT date(created_at) AS day,
    count(*) AS orders_count,
    sum(total) AS total_revenue
   FROM public.orders
  WHERE (status = 'paid'::public.order_status)
  GROUP BY (date(created_at))
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.mv_daily_revenue OWNER TO dbuser;

--
-- Name: order_items; Type: TABLE; Schema: public; Owner: dbuser
--

CREATE TABLE public.order_items (
    order_id uuid NOT NULL,
    product_id uuid NOT NULL,
    quantity integer,
    price numeric(10,2),
    total numeric(10,2) GENERATED ALWAYS AS (((quantity)::numeric * price)) STORED,
    status public.product_status DEFAULT 'confirmed'::public.product_status,
    CONSTRAINT order_items_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE public.order_items OWNER TO dbuser;

--
-- Name: payment_methods; Type: TABLE; Schema: public; Owner: dbuser
--

CREATE TABLE public.payment_methods (
    method_id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.payment_methods OWNER TO dbuser;

--
-- Name: payment_methods_method_id_seq; Type: SEQUENCE; Schema: public; Owner: dbuser
--

CREATE SEQUENCE public.payment_methods_method_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_methods_method_id_seq OWNER TO dbuser;

--
-- Name: payment_methods_method_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: dbuser
--

ALTER SEQUENCE public.payment_methods_method_id_seq OWNED BY public.payment_methods.method_id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: dbuser
--

CREATE TABLE public.payments (
    payment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid,
    method_id integer,
    amount numeric(10,2) NOT NULL,
    status public.payment_status DEFAULT 'pending'::public.payment_status,
    provider text,
    provider_payment_id text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    paid_at timestamp with time zone,
    CONSTRAINT payments_amount_check CHECK ((amount >= (0)::numeric))
);


ALTER TABLE public.payments OWNER TO dbuser;

--
-- Name: product_inventory; Type: TABLE; Schema: public; Owner: dbuser
--

CREATE TABLE public.product_inventory (
    product_id uuid NOT NULL,
    stock integer DEFAULT 0 NOT NULL,
    last_updated timestamp with time zone,
    CONSTRAINT product_inventory_stock_check CHECK ((stock >= 0))
);


ALTER TABLE public.product_inventory OWNER TO dbuser;

--
-- Name: products; Type: TABLE; Schema: public; Owner: dbuser
--

CREATE TABLE public.products (
    product_id uuid DEFAULT gen_random_uuid() NOT NULL,
    category_id integer,
    name text NOT NULL,
    description text,
    price numeric(10,2) NOT NULL,
    attributes jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    user_id uuid,
    CONSTRAINT products_price_check CHECK ((price >= (0)::numeric))
);


ALTER TABLE public.products OWNER TO dbuser;

--
-- Name: user_role; Type: TABLE; Schema: public; Owner: dbuser
--

CREATE TABLE public.user_role (
    user_id uuid,
    roles text NOT NULL,
    CONSTRAINT user_role_roles_check CHECK ((roles = ANY (ARRAY['costumer'::text, 'admin'::text, 'manager'::text, 'seller'::text, 'driver'::text])))
);


ALTER TABLE public.user_role OWNER TO dbuser;

--
-- Name: users; Type: TABLE; Schema: public; Owner: dbuser
--

CREATE TABLE public.users (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(50) NOT NULL,
    email_verified boolean DEFAULT false,
    username character varying(20) NOT NULL,
    password_hash text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO dbuser;

--
-- Name: v_payments_safe; Type: VIEW; Schema: public; Owner: dbuser
--

CREATE VIEW public.v_payments_safe AS
 SELECT p.payment_id,
    p.order_id,
    pm.name AS method_name,
    p.amount,
    p.status,
    p.provider,
    ("left"(p.provider_payment_id, 6) || repeat('*'::text, (length(p.provider_payment_id) - 6))) AS provider_payment_id_masked,
    ((p.metadata - 'debug'::text) - 'internal_notes'::text) AS metadata,
    p.created_at,
    p.paid_at,
    o.total AS order_total,
    o.status AS order_status,
    o.created_at AS order_created_at,
    regexp_replace((u.email)::text, '(^.).*(@.*$)'::text, '\1***\2'::text) AS customer_email_masked,
    u.username AS customer_username
   FROM (((public.payments p
     JOIN public.orders o ON ((p.order_id = o.order_id)))
     JOIN public.users u ON ((o.user_id = u.user_id)))
     LEFT JOIN public.payment_methods pm ON ((p.method_id = pm.method_id)));


ALTER VIEW public.v_payments_safe OWNER TO dbuser;

--
-- Name: addresses address_id; Type: DEFAULT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.addresses ALTER COLUMN address_id SET DEFAULT nextval('public.addresses_address_id_seq'::regclass);


--
-- Name: audit_logs audit_id; Type: DEFAULT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN audit_id SET DEFAULT nextval('public.audit_logs_audit_id_seq'::regclass);


--
-- Name: categories category_id; Type: DEFAULT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.categories ALTER COLUMN category_id SET DEFAULT nextval('public.categories_category_id_seq'::regclass);


--
-- Name: payment_methods method_id; Type: DEFAULT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.payment_methods ALTER COLUMN method_id SET DEFAULT nextval('public.payment_methods_method_id_seq'::regclass);


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: dbuser
--

COPY auth.users (user_id, email, email_verified, username, password_hash, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: addresses; Type: TABLE DATA; Schema: public; Owner: dbuser
--

COPY public.addresses (address_id, user_id, full_name, phone, street, city, state, postal_code, country, created_at, updated_at) FROM stdin;
12	4b546c1e-a34c-41d0-a912-547a8422efcd	ohoooo	008899007	Hassan ||	benguerir	ghiid	80000	Morocco	2025-10-26 10:50:19.308498+00	\N
13	3d47ead3-82e2-4986-a42c-790fc3c5daa1	ohoooo	008899007	Hassan ||	benguerir	ghiid	80000	Morocco	2025-10-26 14:45:44.704975+00	\N
10	1c2b1f73-5d21-4e6e-8aa3-cf76bc4cbbbf	moubarak manouze	0644891716	Hassan ||	benguerir	ghiid	80000	Norway	2025-10-26 10:48:14.888853+00	2025-11-12 08:53:27.129825+00
15	016d6135-945b-4de5-b580-1896da3fcfe9	ohoooo	008899007	Hassan ||	benguerir	ghiid	80000	Morocco	2025-12-05 16:00:35.388421+00	\N
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: dbuser
--

COPY public.audit_logs (audit_id, table_name, operation, row_id, old_data, new_data, changed_at, changed_by) FROM stdin;
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: dbuser
--

COPY public.categories (category_id, name) FROM stdin;
1	Shoes
2	Jacket
3	Hoodie
4	Sandale
5	Short
6	T-shrt
7	Pants
8	Suit
9	Pijamas
10	Socks
11	Cap
12	Hat
13	Mask
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: dbuser
--

COPY public.order_items (order_id, product_id, quantity, price, status) FROM stdin;
2cad3577-2c4f-4591-b172-93538d5ab873	24a82de6-3035-49b4-8199-9b0da7f0b6a7	2	230.00	cancelled
f1c6af6d-e7d1-4d5f-bea4-40964581d8c4	24a82de6-3035-49b4-8199-9b0da7f0b6a7	2	230.00	cancelled
97a43296-f362-4652-99f6-71e7981b679f	84a53249-b332-4f0f-a769-729843b372fc	2	230.00	confirmed
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: dbuser
--

COPY public.orders (order_id, user_id, shipping_address_id, total, status, created_at) FROM stdin;
e77caa9a-b54e-43b7-9059-299553d0ed34	016d6135-945b-4de5-b580-1896da3fcfe9	10	0.00	cancelled	2025-12-06 17:00:37.333977
2cad3577-2c4f-4591-b172-93538d5ab873	016d6135-945b-4de5-b580-1896da3fcfe9	10	0.00	cancelled	2025-12-06 17:26:58.660181
f1c6af6d-e7d1-4d5f-bea4-40964581d8c4	016d6135-945b-4de5-b580-1896da3fcfe9	10	460.00	cancelled	2025-12-06 22:09:27.35869
97a43296-f362-4652-99f6-71e7981b679f	016d6135-945b-4de5-b580-1896da3fcfe9	10	460.00	paid	2025-12-08 18:14:04.024631
\.


--
-- Data for Name: payment_methods; Type: TABLE DATA; Schema: public; Owner: dbuser
--

COPY public.payment_methods (method_id, name) FROM stdin;
1	stripe_card
2	paypal
3	cash_on_delivery
4	bank_transfer
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: dbuser
--

COPY public.payments (payment_id, order_id, method_id, amount, status, provider, provider_payment_id, metadata, created_at, paid_at) FROM stdin;
a1ef6ffb-73a8-49eb-baa7-aa811317023e	97a43296-f362-4652-99f6-71e7981b679f	1	460.00	pending	stripe_checkout	cs_test_a13Nx6LcVYgSNreNfu6qWcV4wIPZn0gT0jqrlB0tFTgdJAzurd94somTZa	{"stripe_session_id": "cs_test_a13Nx6LcVYgSNreNfu6qWcV4wIPZn0gT0jqrlB0tFTgdJAzurd94somTZa"}	2025-12-09 12:49:03.802529+00	\N
9ef3bd75-fb49-4dde-b7f9-bfdd3d3a3d4f	97a43296-f362-4652-99f6-71e7981b679f	1	460.00	pending	stripe_checkout	cs_test_a1VEzRYOPRl6plH9IyMYC1WvCu24w56QwGCnlwhtJt7kbE4lWOZonKQm11	{"stripe_session_id": "cs_test_a1VEzRYOPRl6plH9IyMYC1WvCu24w56QwGCnlwhtJt7kbE4lWOZonKQm11"}	2025-12-09 12:54:33.926495+00	\N
90d8e010-9352-43b3-b439-b11c8fc32239	97a43296-f362-4652-99f6-71e7981b679f	1	460.00	pending	stripe_checkout	cs_test_a11WCS2KtFuvEbwrUg8goOCJWEVDjRbi955UozfE2AJJRHs0CDGo5ixKsN	{"stripe_session_id": "cs_test_a11WCS2KtFuvEbwrUg8goOCJWEVDjRbi955UozfE2AJJRHs0CDGo5ixKsN"}	2025-12-09 13:07:31.370133+00	\N
259dd763-d4d3-4e72-b909-4e793babcf79	97a43296-f362-4652-99f6-71e7981b679f	1	460.00	pending	stripe_checkout	cs_test_a1Rm3DiTPJDSCTBwsFcKEInBchVuOeWspFp74zDdKGLZdrbJyZtJy6e5pO	{"stripe_session_id": "cs_test_a1Rm3DiTPJDSCTBwsFcKEInBchVuOeWspFp74zDdKGLZdrbJyZtJy6e5pO"}	2025-12-09 13:10:15.482775+00	\N
dfde3c48-ab8c-4ea6-8758-87d6053f5599	97a43296-f362-4652-99f6-71e7981b679f	1	460.00	completed	stripe_checkout	cs_test_a10dt7QcSZsHpVbLbQg2VVwUqawrJuJZD1XTgU0ze5pAxO5CKpmOGiY7fo	{"stripe_session_id": "cs_test_a10dt7QcSZsHpVbLbQg2VVwUqawrJuJZD1XTgU0ze5pAxO5CKpmOGiY7fo"}	2025-12-09 14:01:47.499337+00	2025-12-09 15:10:35.46336+00
\.


--
-- Data for Name: product_inventory; Type: TABLE DATA; Schema: public; Owner: dbuser
--

COPY public.product_inventory (product_id, stock, last_updated) FROM stdin;
24a82de6-3035-49b4-8199-9b0da7f0b6a7	2	2025-12-06 22:09:27.35869+00
84a53249-b332-4f0f-a769-729843b372fc	2	2025-12-08 18:14:04.024631+00
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: dbuser
--

COPY public.products (product_id, category_id, name, description, price, attributes, created_at, updated_at, user_id) FROM stdin;
24a82de6-3035-49b4-8199-9b0da7f0b6a7	3	STWD hoodie	Tiger mood -- Cosy, Warm, Built for cold	230.00	{"mark": "STWD ... Pull & Brear", "color": "Black & yellow", "width": "35 cm", "height": "55 cm", "weight": "250 g"}	2025-12-05 16:01:07.152504+00	\N	016d6135-945b-4de5-b580-1896da3fcfe9
84a53249-b332-4f0f-a769-729843b372fc	3	STWD hoodie	Tiger mood -- Cosy, Warm, Built for cold	230.00	{"mark": "STWD ... Pull & Brear", "color": "Black & yellow", "width": "35 cm", "height": "55 cm", "weight": "250 g"}	2025-12-06 17:26:35.680159+00	\N	016d6135-945b-4de5-b580-1896da3fcfe9
\.


--
-- Data for Name: user_role; Type: TABLE DATA; Schema: public; Owner: dbuser
--

COPY public.user_role (user_id, roles) FROM stdin;
1c2b1f73-5d21-4e6e-8aa3-cf76bc4cbbbf	seller
4b546c1e-a34c-41d0-a912-547a8422efcd	seller
3d47ead3-82e2-4986-a42c-790fc3c5daa1	seller
016d6135-945b-4de5-b580-1896da3fcfe9	seller
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: dbuser
--

COPY public.users (user_id, email, email_verified, username, password_hash, created_at, updated_at) FROM stdin;
1c2b1f73-5d21-4e6e-8aa3-cf76bc4cbbbf	a@b.com	f	userA	hashpass	2025-10-26 10:48:14.888853	\N
4b546c1e-a34c-41d0-a912-547a8422efcd	ohoooo@mail.com	f	ohoooo	$argon2id$v=19$m=65536,t=3,p=4$Ph+WNo20x/OQ0vX1vWJl3A$5kRD4RR4VhTVztfBNYCRKXdWklZ+16h1r5Fbmz6gaFM	2025-10-26 10:50:19.308498	\N
3d47ead3-82e2-4986-a42c-790fc3c5daa1	wayliiiii@ana.com	f	wayliiiii	$argon2id$v=19$m=65536,t=3,p=4$ERHIM4AcdWL6xEXJ9Onq+A$3B11dDqmx7zsH061NdFB4GCIYG3g223lrdeZOP5y8vs	2025-10-26 14:45:44.704975	2025-11-10 17:21:32.635896
016d6135-945b-4de5-b580-1896da3fcfe9	iyiiiih@mail.com	f	iyiiiih	$argon2id$v=19$m=65536,t=3,p=4$5LoVDISuvhd2dDwBGRvvTg$vHjdRtEhoMjgcIKQxhnl42t1EuetXSZXsW9SPiaZiP8	2025-12-05 16:00:35.388421	\N
\.


--
-- Name: addresses_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: dbuser
--

SELECT pg_catalog.setval('public.addresses_address_id_seq', 15, true);


--
-- Name: audit_logs_audit_id_seq; Type: SEQUENCE SET; Schema: public; Owner: dbuser
--

SELECT pg_catalog.setval('public.audit_logs_audit_id_seq', 1, false);


--
-- Name: categories_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: dbuser
--

SELECT pg_catalog.setval('public.categories_category_id_seq', 13, true);


--
-- Name: payment_methods_method_id_seq; Type: SEQUENCE SET; Schema: public; Owner: dbuser
--

SELECT pg_catalog.setval('public.payment_methods_method_id_seq', 5, true);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: auth; Owner: dbuser
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: dbuser
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: auth; Owner: dbuser
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (address_id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (audit_id);


--
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (order_id, product_id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (order_id);


--
-- Name: payment_methods payment_methods_name_key; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.payment_methods
    ADD CONSTRAINT payment_methods_name_key UNIQUE (name);


--
-- Name: payment_methods payment_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.payment_methods
    ADD CONSTRAINT payment_methods_pkey PRIMARY KEY (method_id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (payment_id);


--
-- Name: product_inventory product_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.product_inventory
    ADD CONSTRAINT product_inventory_pkey PRIMARY KEY (product_id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- Name: user_role user_role_user_id_roles_key; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_user_id_roles_key UNIQUE (user_id, roles);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_mv_daily_revenue_day; Type: INDEX; Schema: public; Owner: dbuser
--

CREATE INDEX idx_mv_daily_revenue_day ON public.mv_daily_revenue USING btree (day);


--
-- Name: idx_payments_order_id; Type: INDEX; Schema: public; Owner: dbuser
--

CREATE INDEX idx_payments_order_id ON public.payments USING btree (order_id);


--
-- Name: idx_payments_provider_payment_id; Type: INDEX; Schema: public; Owner: dbuser
--

CREATE INDEX idx_payments_provider_payment_id ON public.payments USING btree (provider_payment_id);


--
-- Name: orders trg_audit_orders; Type: TRIGGER; Schema: public; Owner: dbuser
--

CREATE TRIGGER trg_audit_orders AFTER INSERT OR DELETE OR UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: payments trg_audit_payments; Type: TRIGGER; Schema: public; Owner: dbuser
--

CREATE TRIGGER trg_audit_payments AFTER INSERT OR DELETE OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: users trg_audit_users; Type: TRIGGER; Schema: public; Owner: dbuser
--

CREATE TRIGGER trg_audit_users AFTER INSERT OR DELETE OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();


--
-- Name: orders trg_order_cancelled; Type: TRIGGER; Schema: public; Owner: dbuser
--

CREATE TRIGGER trg_order_cancelled AFTER UPDATE OF status ON public.orders FOR EACH ROW WHEN (((new.status = 'cancelled'::public.order_status) AND (old.status IS DISTINCT FROM new.status))) EXECUTE FUNCTION public.set_order_items_cancelled();


--
-- Name: addresses addresses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(order_id) ON DELETE CASCADE;


--
-- Name: order_items order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id);


--
-- Name: orders orders_shipping_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_shipping_address_id_fkey FOREIGN KEY (shipping_address_id) REFERENCES public.addresses(address_id);


--
-- Name: orders orders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: payments payments_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_method_id_fkey FOREIGN KEY (method_id) REFERENCES public.payment_methods(method_id);


--
-- Name: payments payments_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(order_id) ON DELETE SET NULL;


--
-- Name: product_inventory product_inventory_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.product_inventory
    ADD CONSTRAINT product_inventory_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- Name: products products_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(category_id) ON DELETE SET NULL;


--
-- Name: products products_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_role user_role_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: dbuser
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: mv_daily_revenue; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: dbuser
--

REFRESH MATERIALIZED VIEW public.mv_daily_revenue;


--
-- PostgreSQL database dump complete
--

\unrestrict fJK0brQfaIHShfLCAzt3TOXnmj0C9M6Qo3lVnFGecGK889HOSUJKHceltbePgyr

