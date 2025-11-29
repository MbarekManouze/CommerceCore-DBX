import { Router } from "express";
import { validateCredentials, validateSerialId, validateUUID } from "../middlware/validate";
import { productController } from "../modules/product/product.controller";
import { auth } from "../middlware/auth";
import { product, updateProduct } from "../validation/product.schema";

const router = Router();

// /     ---> all products
// /user ---> user's products
// /:id  ---> someone's products


router.get("/", auth, productController.products);
router.get("/my", productController.userProducts);
router.get("/:id", productController.othersProducts);
router.post("/new", auth, validateCredentials(product) ,productController.newProducts);
router.put("/modify/:id", auth , validateUUID, validateCredentials(updateProduct), productController.modifyProduct);
router.delete("/delete/:id", auth , validateUUID, productController.deleteProduct);
// router.get("analyze", );

export default router;