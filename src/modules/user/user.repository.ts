import { QueryResult } from "pg";
import pool from "../../db/config";
import { UserQueries } from "./user.queries";
import {address_id, role, User, UserUpdate } from "./user.type";
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

    static async create (user_data: any): Promise<any | null> {
        user_data.password = await hashPassword(user_data.password);
        // console.log("password hashed : ", user_data.password);
        const userquery = UserQueries.createUser(user_data.email, user_data.username, user_data.password);
        const user : QueryResult<User> = await pool.query(userquery);
        const user_id = user.rows[0].user_id;
        // console.log("user.rows[0]: ", user.rows[0])
        // console.log("user_id : ", user_id)
        if (!user_id)
            return null;
        // console.log("user_data: ", user_data)

        const rolequery = UserQueries.createUserRole(user_data.role, user_id);
        const role : QueryResult<role> = await pool.query(rolequery);
        
        console.log("role : ", role.rows[0].roles)

        const addressquery = UserQueries
        .createUserAddress(user_data.full_name, user_data.phone, user_data.street,
        user_data.city,user_data.state,user_data.postal_code, user_data.country, user_id);
        const address : QueryResult<address_id> = await pool.query(addressquery);

        console.log("address : ", address)

        if (!role || !address)
            return null;

        return {user: user.rows[0], role: role.rows[0].roles, address: address.rows[0].address_id};
    }
    

    static async update (id: string, data: UserUpdate): Promise<User | null> {
        const query = UserQueries.updateUser(id, data);
        const resposne : QueryResult<User> = await pool.query(query);
        return resposne.rows[0] || null;
    }

    static async delete () {

    }
}