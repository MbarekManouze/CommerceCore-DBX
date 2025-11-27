import { Router } from "express";
import { validateCredentials, validateSerialId, validateUUID } from "../middlware/validate";
import { productController } from "../modules/product/product.controller";

const router = Router();

router.get("/", productController.products);
router.get("all", );
router.get("user", );
router.post("new", );
router.put("modify", );
router.delete("delete", );
router.get("analyze", );