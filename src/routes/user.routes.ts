import { Router } from "express";
import * as userController from "../modules/user/user.controller"
import { validate } from "../middlware/validate";
import { updateUserSchema } from "../validation/user.schema";

const router = Router();

router.get("/", userController.getUsers);
router.get("/:id", validate(updateUserSchema), userController.updateUser);


export default router;
