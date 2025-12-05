import { Router } from "express";
import { validateCredentials, validateSerialId, validateUUID } from "../middlware/validate";
import { auth } from "../middlware/auth";
import { ordreController } from "../modules/order/order.controller";
import { createOrderSchema, modifyOrderSchema } from "../validation/order.schema";


const router = Router();

router.post("/create",auth, validateCredentials(createOrderSchema) ,ordreController.createOrder);
router.put("/modify/:id",auth, validateUUID, validateCredentials(modifyOrderSchema),ordreController.modifyOrder);
router.put("/modify/address/:id",auth, validateUUID, ordreController.modifyOrder_address);
router.delete("/delete_order/:id",auth, validateUUID, ordreController.deleteOrder);
router.delete("/delete_product/:id",auth, validateUUID, ordreController.deleteProduct);
router.get("/track/:id", ordreController.trackOrder);

export default router;