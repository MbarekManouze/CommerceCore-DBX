import { resourceUsage } from "process";
import pool from "../../db/config";
import { QueryResult } from "pg";
import { ProductQueries } from "./product.queries";


export class ProductRepository {

    static async all(limit: number, offset: number, user_id: string) : Promise<any | null> {
        const query = ProductQueries.all(limit, offset, user_id);
        const result : QueryResult<any> = await pool.query(query);
        return result.rows;
    }

    static async create(user_id: string, product_data: any): Promise<any | null> {
        // before testing inject SQL FUNCTION "create_product"
        const result: QueryResult<any> = await pool.query(`
            SELECT * FROM create_product(
            $1, $2, $3, $4, $5, $6, $7
        )`, [
                user_id,
                product_data.name,
                product_data.description,
                product_data.price,
                product_data.attributes,
                product_data.stock,
                product_data.category_id
            ]
        );
        return result.rows[0];
    }

    static async update(product_id: string, product_data: any): Promise<any | null> {
        const query = ProductQueries.updateProduct(product_id, product_data);
        const result :QueryResult<any> = await pool.query(query);
        return result.rows[0];
    }

    static async delete(product_id: string) : Promise<any | null> {
        const query = ProductQueries.delete(product_id);
        const result : QueryResult<any> = await pool.query(query);
        return result.rows[0];
    }

}