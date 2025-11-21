import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "supersecretkey"; // put in .env

export const signToken = (user_id: string, role: string) => {
  return jwt.sign({ user_id, role }, JWT_SECRET, { expiresIn: "7d" });
};

export const verifyToken = (token: string) => {
  return jwt.verify(token, JWT_SECRET) as { user_id: string, role: string };
};
