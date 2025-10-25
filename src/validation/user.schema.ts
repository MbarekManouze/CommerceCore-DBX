import {email, z} from "zod";

const roles = ["costumer", "admin", 'manager', 'seller', 'driver'];

export const SingUp = z.object({
    username: z.string().min(3).max(12),
    email: z.email(),
    password: z.string().min(6),
    role: z.enum(roles),
    full_name: z.string(),
    phone: z.string(),
    city: z.string(),
    // "state": z.string,
    street: z.string(),
    postal_code: z.string(),
    country: z.string()
});

export const updateUserSchema = z.object({
    email: z.string().optional(),
    username: z.string().min(3).max(12).optional(),
    password: z.string().min(6).optional()
});