import { QueryResult } from "pg";
import pool from "../../db/config";
import { createOrder, modifyOrder } from "./order.type";
import { orderQueries } from "./order.queries";

export class orderRepository {

    static async create(user_id: string, order: createOrder) : Promise<any>{
        const result : QueryResult<any> = await pool.query(`
            SELECT * FROM create_order(
                $1, $2, $3
        )`, [
                user_id,
                order.shipping_address_id,
                JSON.stringify(order.items),
            ]
        );
        return { order_id: result.rows[0].order_id };
    }

    static async modifyOrder(order_id: string, new_order: modifyOrder) : Promise<any>{
        const result : QueryResult<any> = await pool.query(`
            SELECT * FROM modify_order(
                $1, $2
        )`, [
                order_id,
                JSON.stringify(new_order.items)
            ]
        );
        return { order_id: result.rows[0].order_id };
    }

    static async modifyAddress(address_id: number, order_id: string) : Promise<any>{
        const query = orderQueries.modifyAddress(order_id, address_id);
        const result = await pool.query(query);
        return result.rows[0];
    }

    static async deleteProduct(order_id: string, product_id: string) : Promise<any>{
        const result = await pool.query(`
            SELECT * FROM delete_product_in_order(
                $1, $2
            )`, [
                    order_id,
                    product_id
                ]
        );
        return { message: result.rows[0].message };
    }

    static async deleteOrder(order_id: string) : Promise<any>{
        const query = orderQueries.deleteOrder(order_id);
        const result : QueryResult<any> = await pool.query(query);
        return result.rows;
    }

    static async track() {
        
    }

}