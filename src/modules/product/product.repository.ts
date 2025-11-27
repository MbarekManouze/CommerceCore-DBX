import { resourceUsage } from "process";
import pool from "../../db/config";
import { QueryResult } from "pg";
import { ProductQueries } from "./product.queries";


export class ProductRepository {

    static async all(limit: number, offset: number, user_id: string) : Promise<any | null> {
        const query = ProductQueries.all(limit, offset, user_id);
        const result : QueryResult<any> = await pool.query(query);
        return result;
    }

}