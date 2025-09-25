import { Router } from "express";
import * as userController from "../modules/user/user.controller"

const router = Router();

router.get("/", userController.getUsers);

export default router;
