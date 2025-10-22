import {email, z} from "zod";

export const updateUserSchema = z.object({
    email: z.string().optional(),
    username: z.string().min(3).max(12).optional(),
    password: z.string().min(6).optional()
});