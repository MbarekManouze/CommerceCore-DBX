import { Router } from "express";
import * as userController from "../modules/user/user.controller"
import { validateCredentials, validateUUID } from "../middlware/validate";
import { singIn, SingUp, updateUserSchema } from "../validation/user.schema";

const router = Router();

router.get("/",userController.getUsers);
router.post("/signup", validateCredentials(SingUp) , userController.singUp);
router.get("/signin", validateCredentials(singIn), userController.singIn);
router.get("/:id", validateUUID, userController.getUser);
router.put("/:id", validateUUID, validateCredentials(updateUserSchema), userController.updateUser);
router.post("/email_verification", userController.verify_email);

// router.post()

export default router;
