import { QueryResult } from "pg";
import pool from "../../db/config";
import { UserQueries } from "./user.queries";
import { User, UserUpdate } from "./user.type";
import { UUID } from "crypto";
import { hashPassword } from "../../utils/passwords";
export class UserRepository {
    
    static async findall (limit: number, offset: number) {
        const query = UserQueries.findAll(limit, offset);
        const user : QueryResult<User> = await pool.query(query);

        return user.rows[0] || null;
    }
    
    static async findOne_email (email : string): Promise<User | null> {
        
        const query = UserQueries.findByEmail(email);
        const user : QueryResult<User> = await pool.query(query);

        return user.rows[0] || null;
    }
    
    static async findOne_id (id : UUID): Promise<User> {
        const query = UserQueries.findById(id);
        const user : QueryResult<User> = await pool.query(query);

        return user.rows[0] || null;
    }

    static async findOne_username (username : string): Promise<User> {
        const query = UserQueries.findByUsername(username);
        const user : QueryResult<User> = await pool.query(query);
        return user.rows[0] || null;
    }

    static async create (user_data): Promise<User> {
        user_data.password = await hashPassword(user_data.password);
        const query = UserQueries.createUser(user_data);
        const user : QueryResult<User> = await pool.query(query);
        return user.rows[0] || null;
    }
    

    static async update () {

    }

    static async delete () {

    }
}