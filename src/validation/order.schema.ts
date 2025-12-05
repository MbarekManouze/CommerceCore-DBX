import z from "zod";

export const createOrderSchema = z.object({
    items: z.array(
      z.object({
        product_id: z.string(),
        quantity: z.number().int().positive(),
      })
    ).min(1, "Order must contain at least one item"),
    shipping_address_id: z.number().positive(),
});

export const modifyOrderSchema = z.object({
    items: z.array(
      z.object({
        product_id: z.string(),
        quantity: z.number().int().positive(),
      })
    ).min(1, "Order must contain at least one item"),
});

