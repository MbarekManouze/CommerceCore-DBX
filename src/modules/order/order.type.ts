export interface createOrder {
    items : {
        product_id: string,
        quantity: number
    }[],
    shipping_address_id: number,
};

export interface modifyOrder {
    items: {
        product_id: string,
        quantity: number
    }[],
};

export interface shipping_address_id {
    shipping_address_id: number,
};

