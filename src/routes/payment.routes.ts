// src/routes/payment.routes.ts
import express, { Router } from "express";
import { auth } from "../middlware/auth";
import { validateUUID } from "../middlware/validate";
import { paymentController } from "../modules/payment/payment.controller";
import { stripeWebhookController } from "../modules/payment/stripeWebhook.controller";

const router = Router();

/**
 * Create Stripe PaymentIntent for an order (checkout start)
 * Body: { order_id: string, method_id: number }
 */
router.post("/checkout", auth, paymentController.createCheckoutSession);

/**
 * Get payment details by internal payment_id
 * GET /api/payments/:id
 */
router.get("/:id", auth, validateUUID, paymentController.getPaymentById);

/**
 * Get payment details by order_id
 * GET /api/payments/order/:orderId
 */
router.get(
  "/order/:id",
  auth,
  validateUUID,
  paymentController.getPaymentByOrderId
);


export default router;
