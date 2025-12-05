export interface products {
    category_id?: number,
    name?: string,
    description?: string,
    price?: number,
    attributes?: JSON,
    stock?: number
};

export interface product_id {
    product_id: string
};