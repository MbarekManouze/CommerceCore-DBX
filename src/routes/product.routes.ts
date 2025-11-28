import { Router } from "express";
import { validateCredentials, validateSerialId, validateUUID } from "../middlware/validate";
import { productController } from "../modules/product/product.controller";
import { auth } from "../middlware/auth";

const router = Router();

// /     ---> all products
// /user ---> user's products
// /:id  ---> someone's products


router.get("/", productController.products);
router.get("all", );
router.get("user", );
router.post("new", auth , validateUUID, productController.newProducts);
router.put("modify/:id", auth , validateUUID, productController.modifyProduct);
router.delete("delete/:id", auth , validateUUID, productController.deleteProduct);
router.get("analyze", );