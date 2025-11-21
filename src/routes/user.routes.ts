import { Router } from "express";
import * as userController from "../modules/user/user.controller";
import { validateCredentials, validateSerialId, validateUUID } from "../middlware/validate";
import { singIn, SingUp, updateUserAddress, updateUserCredentials } from "../validation/user.schema";
import { auth } from "../middlware/auth";

const router = Router();

// Public routes
router.post("/signin", validateCredentials(singIn), userController.singIn);  // use POST, not GET, for credentials
router.post("/signup", validateCredentials(SingUp), userController.singUp);
router.post("/logout", auth, userController.logout); // only logged-in user can logout
router.post("/email_verification", userController.verify_email);

// Protected routes (must be authenticated via JWT cookie)
router.get("/", auth, userController.getUsers);

// More specific route first
router.get("/details/:id", auth, validateUUID, userController.getUsersDetails);

// Get single user by id (you can also check here that req.user.user_id === params.id if needed)
router.get("/:id", auth, validateUUID, userController.getUser);

// Update address: id is a SERIAL (number)
router.put(
  "/address/:id",
  auth,
  validateSerialId,
  validateCredentials(updateUserAddress),
  userController.updateUserAddressesInfos
);

// Update credentials: id is UUID
router.put(
  "/credentials/:id",
  auth,
  validateUUID,
  validateCredentials(updateUserCredentials),
  userController.updateUser
);

export default router;
