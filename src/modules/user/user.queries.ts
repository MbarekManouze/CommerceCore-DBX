import SQL, { SQLStatement } from "sql-template-strings";
import { UserAdrress, Userinfos, UserUpdate } from "./user.type";

export const UserQueries = {

    countall: () => SQL`SELECT COUNT(*) AS total from users;`,

    findById: (id: string) => SQL`SELECT * FROM users WHERE user_id = ${id};`,

    findByEmail: (email: string) => SQL`SELECT *, ur.roles as role FROM users u JOIN user_role ur on u.user_id=ur.user_id WHERE u.email = ${email};`,

    findByUsername: (username: string) => SQL`SELECT * FROM users WHERE username = ${username};`,

    findAll: (offset: number, limit: number) => SQL`SELECT * FROM users ORDER BY created_at LIMIT ${limit} OFFSET ${offset};`,

    userDetails: (id: string) => SQL`
        SELECT
            u.user_id,
            u.username,
            u.email,
            u.email_verified,
            u.created_at as Join_Date,
            json_build_object(
                'roles', r.roles
            ) AS role,
            json_build_object(
                'address_id', a.address_id,
                'full_name', a.full_name,
                'phone', a.phone,
                'street', a.street,
                'city', a.city,
                'state', a.state,
                'postal_code', a.postal_code,
                'country', a.country,
                'created_at', a.created_at
            ) AS address
        FROM
            users u
        JOIN user_role r ON u.user_id = r.user_id
        JOIN addresses a ON u.user_id = r.user_id
        WHERE
            u.user_id = ${id};
    `,

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

    updateUserAddress: (id: number, data: UserAdrress) => {
        const query = SQL`UPDATE addresses SET `;
        const fields: SQLStatement[] = [];

        if (data.full_name) fields.push(SQL`full_name = ${data.full_name}`);
        if (data.city) fields.push(SQL`city = ${data.city}`);
        if (data.country) fields.push(SQL`country = ${data.country}`);
        if (data.phone) fields.push(SQL`phone = ${data.phone}`);
        if (data.postal_code) fields.push(SQL`postal_code = ${data.postal_code}`);
        if (data.state) fields.push(SQL`state = ${data.state}`);
        if (data.street) fields.push(SQL`street = ${data.street}`);
        if (fields.length > 0) fields.push(SQL`updated_at = NOW()`);

        fields.forEach((field, i) => {
            if (i > 0) query.append(SQL`, `);
            query.append(field);
        });
        query.append(SQL` WHERE address_id = ${id} RETURNING *;`);
        return query;
    },

    updateUser: (id: string, data: UserUpdate) => {
        const query = SQL`UPDATE users SET `;
        const fields: SQLStatement[] = [];
    
        if (data.email) {
            fields.push(SQL`email = ${data.email}`);
            fields.push(SQL`email_verified = FALSE`);
        }
        if (data.password) fields.push(SQL`password_hash = ${data.password}`);
        if (data.username) fields.push(SQL`username = ${data.username}`)
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