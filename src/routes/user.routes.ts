import { Router } from "express";
import * as userController from "../modules/user/user.controller"
import { validate } from "../middlware/validate";
import { updateUserSchema } from "../validation/user.schema";

const router = Router();

router.get("/", userController.getUsers);
router.post("/signup", userController.singUp);
router.get("/signin", userController.singIn);
router.get("/:id", userController.getUser);
router.put("/:id", validate(updateUserSchema), userController.updateUser);
router.post("/email_verification", userController.verify_email);

// router.post()

export default router;
