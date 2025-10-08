import SQL, { SQLStatement } from "sql-template-strings";
import { UserUpdate } from "./user.type";
import { UUID } from "crypto";

export const UserQueries = {

    countall: () => SQL`SELECT COUNT(*) AS total from users;`,

    findById: (id: UUID) => SQL`SELECT * FROM users WHERE user_id = ${id};`,

    findByEmail: (email: string) => SQL`SELECT * FROM users WHERE email = ${email};`,

    findByUsername: (username: string) => SQL`SELECT * FROM users WHERE username = ${username};`,

    findAll: (offset: number, limit: number) => SQL`SELECT * FROM users ORDER BY created_at LIMIT ${limit} OFFSET ${offset};`,

    createUser: (data: UserUpdate) => SQL`
        INSERT INTO users (email, username, password) 
        VALUES (${data.email}, ${data.username}, ${data.password})
        RETURNING *;
    `,

    updateUser: (id: UUID, data: UserUpdate) => {
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

    deleteUser: (id: UUID) => SQL`DELETE FROM users WHERE user_id = ${id};`
}