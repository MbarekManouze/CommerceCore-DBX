import SQL, { SQLStatement } from "sql-template-strings";

export const ProductQueries = {


    // filtering logic still nedded (price, stock, name, ...) DYNAMIC
    all: (limit: number, offset: number, user_id: string) => {
        const query = SQL`
            SELECT 
                p.product_id,
                p.name,
                p.description,
                p.price,
                p.attributes,
                p.created_at AS "product_date",
                json_build_object(
                    'category', c.name
                ) AS category,
                json_build_object(
                    'stock', pi.stock
                ) AS stock
            FROM
                products
            JOIN categories c ON c.category_id=p.category_id
            JOIN product_inventory pi ON pi.product_id=p.product_id
        `;
        const fields: SQLStatement[] = [];
        if (user_id.length > 0) fields.push(SQL`WHERE user_id=${user_id}`);

        fields.push(SQL`LIMIT ${limit}`);
        fields.push(SQL`OFFSET ${offset}`);

        fields.forEach((field, i) => {
            if (i > 0) query.append(SQL`, `);
            query.append(field);
        });

        return query;
    }

}