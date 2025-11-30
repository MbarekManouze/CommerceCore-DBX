import SQL, { SQLStatement } from "sql-template-strings";

export const ProductQueries = {

    // JOIN user's data with product
    // filtering logic still nedded (price, stock, name, ...) DYNAMIC
    all: (limit: number, offset: number, user_id?: string) => {
        const query = SQL`
          SELECT 
            p.product_id,
            p.name,
            p.price,
            p.description,
            p.created_at AS "product_date",
            p.attributes,
            json_build_object(
              'category', c.name
            ) AS category,
            json_build_object(
              'stock', pi.stock
            ) AS stock
          FROM
            products p
          JOIN categories c ON c.category_id = p.category_id
          JOIN product_inventory pi ON pi.product_id = p.product_id
        `;
    
        if (user_id && user_id.length > 0) {
          query.append(SQL` WHERE p.user_id = ${user_id}`);
        }
    
        query.append(SQL` LIMIT ${limit} OFFSET ${offset}`);
    
        return query;
    },
    

    update: (product_id: string, product_date: any) => {

        const query = SQL`UPDATE products SET `;
        const fields: SQLStatement[] = [];
    
        if (product_date.category_id) fields.push(SQL`category_id = ${product_date.category_id}`);
        if (product_date.name) fields.push(SQL`name = ${product_date.name}`);
        if (product_date.description) fields.push(SQL`description = ${product_date.description}`);
        if (product_date.price) fields.push(SQL`price = ${product_date.price}`);
        if (product_date.attributes) fields.push(SQL`attributes = ${product_date.attributes}`);
        if (fields.length > 0) {
            fields.push(SQL`updated_at = NOW()`);
            // query.append(fields.join(", "));
            fields.forEach((field, i) => {
                if (i > 0) query.append(SQL`, `);
                query.append(field);
            });
            query.append(SQL` WHERE product_id = ${product_id} RETURNING *;`)
            // console.log(query);
    
            return query;
        }
        else return null;

    },

    updateStock: (product_id: string, stock: number) => SQL`
        UPDATE product_inventory SET
        stock = ${stock},
        last_updated = NOW()
        WHERE product_id = ${product_id}
    `,

    delete: (product_id: string) => SQL`
        DELETE FROM products
        WHERE product_id = ${product_id};
    `,


}