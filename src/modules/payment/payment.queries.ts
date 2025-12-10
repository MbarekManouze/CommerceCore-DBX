import SQL from "sql-template-strings"

export const PaymentQueries = {

    getOrderForPayment: (order_id: string, user_id: string) => SQL`
        SELECT order_id, user_id, total, status
        FROM orders
        WHERE order_id = ${order_id}
            AND user_id = ${user_id}
            AND status = 'pending';
    `,

    createPendingPayment: (order_id: string,method_id: number,amount: number,provider: string) => SQL`
        INSERT INTO payments (order_id, method_id, amount, status, provider)
        VALUES (${order_id}, ${method_id}, ${amount}, 'pending', ${provider})
        RETURNING *;
    `,

    attachStripeSession: (payment_id: string, session_id: string) => SQL`
        UPDATE payments
        SET
        provider_payment_id = ${session_id},
        metadata = jsonb_set(
            COALESCE(metadata, '{}'::jsonb),
            '{stripe_session_id}',
            to_jsonb(${session_id}::text),
            true
        )
        WHERE payment_id = ${payment_id};
    `,

    // getPaymentById: (payment_id: string, user_id: string) => SQL`
    //     SELECT p.*
    //     FROM payments p
    //     JOIN orders o ON p.order_id = o.order_id
    //     WHERE p.payment_id = ${payment_id}
    //         AND o.user_id = ${user_id};
    // `,

    getPaymentById: (payment_id: string, user_id: string) => SQL`
        SELECT p.*
        FROM v_payments_safe p
        JOIN orders o ON p.order_id = o.order_id
        WHERE p.payment_id = ${payment_id}
            AND o.user_id = ${user_id};
    `,

    getLatestPaymentByOrderId: (order_id: string,user_id: string) => SQL`
        SELECT p.*
        FROM v_payments_safe p
        JOIN orders o ON p.order_id = o.order_id
        WHERE p.order_id = ${order_id}
            AND o.user_id = ${user_id}
        ORDER BY p.created_at DESC
        LIMIT 1;
    `,

    // getLatestPaymentByOrderId: (order_id: string,user_id: string) => SQL`
    //     SELECT p.*
    //     FROM payments p
    //     JOIN orders o ON p.order_id = o.order_id
    //     WHERE p.order_id = ${order_id}
    //         AND o.user_id = ${user_id}
    //     ORDER BY p.created_at DESC
    //     LIMIT 1;
    // `,

    markPaymentCompletedBySession: (session_id: string) => SQL`
        UPDATE payments
        SET
            status = 'completed',
            paid_at = now()
        WHERE provider_payment_id = ${session_id}
        RETURNING *; 
    `,

    markPaymentFailedBySession: (session_id: string) => SQL`
        UPDATE payments
        SET status = 'failed'
        WHERE provider_payment_id = ${session_id}
        RETURNING *;
    `,

    updateOrderStatus: (order_id: string,status: string) => SQL`
        UPDATE orders
        SET status = ${status}
        WHERE order_id = ${order_id};
    `

}