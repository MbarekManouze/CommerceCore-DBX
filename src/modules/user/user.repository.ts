import { QueryResult } from "pg";
import pool from "../../db/config";
import { UserQueries } from "./user.queries";
import {User, UserUpdate } from "./user.type";
import { UUID } from "crypto";
import { hashPassword } from "../../utils/passwords";

export class UserRepository {
    
    static async countall(): Promise<number | null> {
        
        const countQuery = UserQueries.countall();
        const total = await pool.query<{ total: number }>(countQuery);

        return total.rows[0].total || null;
    }

    static async findall (limit: number, offset: number): Promise<User[] | null> {
        const query = UserQueries.findAll(limit, offset);
        const user : QueryResult<User> = await pool.query(query);

        return user.rows || null;
    }
    
    static async findOne_email (email : string): Promise<User | null> {
        
        const query = UserQueries.findByEmail(email);
        const user : QueryResult<User> = await pool.query(query);

        return user.rows[0] || null;
    }
    
    static async findOne_id (id : string): Promise<User | null> {
        const query = UserQueries.findById(id);
        const user : QueryResult<User> = await pool.query(query);

        return user.rows[0] || null;
    }

    static async findOne_username (username : string): Promise<User> {
        const query = UserQueries.findByUsername(username);
        const user : QueryResult<User> = await pool.query(query);
        return user.rows[0] || null;
    }

    static async create (user_data): Promise<User | null> {
        user_data.password = await hashPassword(user_data.password);
        
        const userquery = UserQueries.createUser(user_data);
        const user : QueryResult<User> = await pool.query(userquery);
        const user_id = user.rows[0].id;
        if (!user_id)
            return null;

        const rolequery = UserQueries.createUserRole(user_data, user_id);
        const role : QueryResult<String> = await pool.query(rolequery);

        const addressquery = UserQueries.createUserAddress(user_data, user_id);
        const address : QueryResult<Number> = await pool.query(addressquery);

        if (!role || !address)
            return null;

        return user.rows[0] || null;
    }
    

    static async update (id: string, data: UserUpdate): Promise<User | null> {
        const query = UserQueries.updateUser(id, data);
        const resposne : QueryResult<User> = await pool.query(query);
        return resposne.rows[0] || null;
    }

    static async delete () {

    }
}