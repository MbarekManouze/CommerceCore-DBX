import { ZodObject } from "zod";
import { Request, Response, NextFunction } from "express";

export const validate = (schema: ZodObject) => (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
        return res.json({error: result.error.flatten()}).status(400);
    }
    req.body = result.data;
    next();
}