import { Router } from "express";
import * as userController from "../modules/user/user.controller"
import { validateCredentials, validateSerialId, validateUUID } from "../middlware/validate";
import { singIn, SingUp, updateUserAddress, updateUserCredentials } from "../validation/user.schema";

const router = Router();

router.get("/",userController.getUsers);

router.get("/signin", validateCredentials(singIn), userController.singIn);
router.post("/signup", validateCredentials(SingUp) , userController.singUp);

router.get("/:id", validateUUID, userController.getUser);
router.get("/details/:id", validateUUID, userController.getUsersDetails); 

router.post("/email_verification", userController.verify_email);

router.put("/address/:id", validateSerialId, validateCredentials(updateUserAddress), userController.updateUserAddressesInfos);
router.put("/credentials/:id", validateUUID, validateCredentials(updateUserCredentials), userController.updateUser);

// router.post()

export default router;
