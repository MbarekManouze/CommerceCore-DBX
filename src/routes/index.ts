import { Router } from "express";
import userRoutes from "./user.routes";
import productRoutes from "./product.routes"
import orderRoutes from "./order.routes"

const router = Router();

router.use("/users", userRoutes);
router.use("/products", productRoutes);
router.use("/orders", orderRoutes);

export default router;
