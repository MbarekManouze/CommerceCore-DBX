import SQL from "sql-template-strings";

export const orderQueries = {

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