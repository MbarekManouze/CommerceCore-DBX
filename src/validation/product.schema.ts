import z from "zod";

export const product = z.object({
    category_id: z.number().positive(),
    name: z.string().min(5).max(60),
    description: z.string().min(20).max(500),
    price: z.number().positive(),
    attributes: z.json().optional(),
    stock: z.number().optional().default(0)
})

export const updateProduct = z.object({
    category_id: z.number().positive().optional(),
    name: z.string().min(5).max(60).optional(),
    description: z.string().min(20).max(500).optional(),
    price: z.number().positive().optional(),
    attributes: z.json().optional(),
    stock: z.number().optional()
})