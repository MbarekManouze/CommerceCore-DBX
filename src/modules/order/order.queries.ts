import SQL from "sql-template-strings";

export const orderQueries = {

    getOrder: (order_id: string, user_id: string) => SQL`
        SELECT odrer_id
        FROM orders
        WHERE order_id = ${order_id} AND user_id = ${user_id};
    `,

    
    /**
     * delete order needs to check and return stock to product
     * inventory before it cancells order and Trigger cancells the linked products
     * */ 
    deleteOrder: (order_id : string) => SQL`
        UPDATE orders
        SET status = 'cancelled'
        WHERE order_id = ${order_id};
    `,

    modifyAddress: (order_id: string, address_id: number) => SQL`
        UPDATE orders
        SET shipping_address_id = ${address_id}
        WHERE order_id = ${order_id};
    `,
};