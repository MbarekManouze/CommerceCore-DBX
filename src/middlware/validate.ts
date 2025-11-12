import { ZodObject } from "zod";
import { Request, Response, NextFunction } from "express";
import isUUID from "uuid-validate";

export const validateCredentials = (schema: ZodObject) => (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
        return res.json({error: result.error.flatten()}).status(400);
    }
    req.body = result.data;
    next();
}

export const validateUUID = (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
  
    if (!isUUID(id)) {
      return res.status(400).json({ error: "Invalid UUID format" });
    }
  
    next();
  };
  
  export const validateSerialId = (req: Request, res: Response, next: NextFunction) => {
    const { id } = req.params;
  
    const num = Number(id);
    if (!Number.isInteger(num) || num <= 0) {
      return res.status(400).json({ error: "Invalid serial ID" });
    }
  
    next();
  };
  