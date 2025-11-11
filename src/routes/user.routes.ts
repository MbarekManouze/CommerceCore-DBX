import { Router } from "express";
import * as userController from "../modules/user/user.controller"
import { validateCredentials, validateUUID } from "../middlware/validate";
import { singIn, SingUp, updateUserAddress, updateUserCredentials } from "../validation/user.schema";

const router = Router();

router.get("/",userController.getUsers);
router.get("/details/:id", validateUUID, userController.getUsersDetails); 
router.post("/signup", validateCredentials(SingUp) , userController.singUp);
router.get("/signin", validateCredentials(singIn), userController.singIn);
router.get("/:id", validateUUID, userController.getUser);
router.put("/credentials/:id", validateUUID, validateCredentials(updateUserCredentials), userController.updateUser);
router.put("/address/:id", validateUUID, validateCredentials(updateUserAddress), userController.updateUser);
router.post("/email_verification", userController.verify_email);

// router.post()

export default router;
