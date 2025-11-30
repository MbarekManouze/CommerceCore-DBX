import { resourceUsage } from "process";
import pool from "../../db/config";
import { QueryResult } from "pg";
import { ProductQueries } from "./product.queries";
import { products } from "./product.type";


export class ProductRepository {

    static async all(limit: number, offset: number, user_id: string) : Promise<any | null> {
        const query = ProductQueries.all(limit, offset, user_id);
        console.log(query);
        const result : QueryResult<any> = await pool.query(query);
        return result.rows[0];
    }

    static async userProducts(limit: number, offset: number, user_id: string): Promise<any | null> {
        const query = ProductQueries.all(limit, offset, user_id);
        const result : QueryResult<any> = await pool.query(query);
        return result;
    }

    static async create(user_id: string, product_data: any): Promise<any | null> {
        // before testing inject SQL FUNCTION "create_product"
        console.log(product_data.name);
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

    static async update(product_id: string, product_data: products): Promise<any | null> {
        const productQuery = ProductQueries.update(product_id, product_data);      // dynamic SET ...
        const stockQuery =
          product_data.stock !== undefined ? ProductQueries.updateStock(product_id, product_data.stock) : null;
      
        await pool.query("BEGIN");
        try {
          if (productQuery) await pool.query(productQuery);
          if (stockQuery) await pool.query(stockQuery);
          await pool.query("COMMIT");
        } catch (e) {
          await pool.query("ROLLBACK");
          throw e;
        }
    }

    static async delete(product_id: string) : Promise<any | null> {
        const query = ProductQueries.delete(product_id);
        const result : QueryResult<any> = await pool.query(query);
        return result.rows[0];
    }

}