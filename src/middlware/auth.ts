import { Request, Response, NextFunction } from "express";
import { verifyToken } from "../utils/jwt";

export interface AuthRequest extends Request {
  user?: {
    user_id: string;
    role: string;
  };
}

export const auth = (req: AuthRequest, res: Response, next: NextFunction) => {
  // console.log(req);
  const token = req.cookies.token;

  if (!token) {
    return res.status(401).json({ msg: "Not authenticated" });
  }

  try {

    const decoded = verifyToken(token); // { user_id, role }
    req.user = {
      user_id: decoded.user_id,
      role: decoded.role,
    }; // ✅ initialize object

    next();
  } catch (err) {
    return res.status(401).json({ msg: "Invalid or expired token" });
  }
};
