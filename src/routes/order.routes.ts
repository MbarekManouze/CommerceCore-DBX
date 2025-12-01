import { Router } from "express";
import { validateCredentials, validateSerialId, validateUUID } from "../middlware/validate";
import { auth } from "../middlware/auth";
import { ordreController } from "../modules/order/order.controller";


const router = Router();

// create an order (products, total price, address)
// modify order
// delete order
// track order

router.post("/create", ordreController.createOrder);
router.put("/modify/:id", ordreController.modifyOrder);
router.delete("/delete/:id", ordreController.deleteOrder);
router.get("/track/:id", ordreController.trackOrder);

export default router;