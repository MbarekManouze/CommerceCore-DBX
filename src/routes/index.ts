import { Router } from "express";
import userRoutes from "./user.routes";
import productRoutes from "./product.routes"
import orderRoutes from "./order.routes"
import paymentRoutes from "./payment.routes";

const router = Router();

router.use("/users", userRoutes);
router.use("/products", productRoutes);
router.use("/orders", orderRoutes);
router.use("/payments", paymentRoutes);


export default router;
