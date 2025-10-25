import SQL, { SQLStatement } from "sql-template-strings";
import { Userinfos, UserUpdate } from "./user.type";
import { UUID } from "crypto";
import { userInfo } from "os";

export const UserQueries = {

    countall: () => SQL`SELECT COUNT(*) AS total from users;`,

    findById: (id: string) => SQL`SELECT * FROM users WHERE user_id = ${id};`,

    findByEmail: (email: string) => SQL`SELECT * FROM users WHERE email = ${email};`,

    findByUsername: (username: string) => SQL`SELECT * FROM users WHERE username = ${username};`,

    findAll: (offset: number, limit: number) => SQL`SELECT * FROM users ORDER BY created_at LIMIT ${limit} OFFSET ${offset};`,

    createUser: (email: string, username: string, password: string) => SQL`
        INSERT INTO users (email, username, password_hash) 
        VALUES (${email}, ${username}, ${password})
        RETURNING *;
    `,
    
    createUserRole: (role: Userinfos, userId: string) => SQL`
        INSERT INTO user_role (user_id, roles)
        VALUES (${userId}, ${role})
        RETURNING roles;
    `,

    updateUserRole: (userId: string, role: string) => SQL`
        UPDATE user_role
        SET roles = ${role}
        WHERE user_id = ${userId};
    `,

    createUserAddress: (full_name: string,
        phone: string,
        street: string,
        city: string,
        state: string,
        postal_code: string,
        country: string,
        userId: string) => SQL`
        INSERT INTO addresses (user_id, full_name, phone, street, city, state, postal_code, country)
        VALUES (${userId}, ${full_name}, ${phone}, ${street}, ${city}, ${state}, ${postal_code}, ${country})
        RETURNING address_id;
    `,

    updateUser: (id: string, data: UserUpdate) => {
        const query = SQL`UPDATE users SET `;
        const fields: SQLStatement[] = [];
    
        if (data.email) fields.push(SQL`email = ${data.email}`);
        if (data.email_verified !== undefined) fields.push(SQL`email_verified = ${data.email_verified}`);
        if (data.password) fields.push(SQL`password = ${data.password}`);
        if (fields.length > 0) fields.push(SQL`updated_at = NOW()`);

        // query.append(fields.join(", "));
        fields.forEach((field, i) => {
            if (i > 0) query.append(SQL`, `);
            query.append(field);
        });
        query.append(SQL` WHERE user_id = ${id} RETURNING *;`)

        return query;
    },

    deleteUser: (id: string) => SQL`DELETE FROM users WHERE user_id = ${id};`
}