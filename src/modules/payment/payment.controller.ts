// src/modules/payment/payment.controller.ts
import { Request, Response } from "express";
import { AuthRequest } from "../../middlware/auth";
import Stripe from "stripe";
import { paymentService } from "./payment.service";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export class paymentController {
    
    /**
     * Create a PaymentIntent for an order
     */
    static async createCheckout(req: AuthRequest, res: Response) {
        try {
            const { order_id, method_id } = req.body;
            const user_id = req.user!.user_id;

            if (!order_id || !method_id) {
                return res.status(400).json({ msg: "Missing required fields" });
            }

            // 1. Validate and retrieve order
            const order = await paymentService.getOrder(order_id, user_id);

            if (!order) return res.status(404).json({ msg: "Order not found" });

            // 2. Create Stripe PaymentIntent
            const paymentIntent = await stripe.paymentIntents.create({
                amount: Math.round(order.total * 100), // cents
                currency: "usd",
                metadata: {
                    order_id: order_id,
                    user_id: user_id,
                },
            });

            // 3. Store pending payment entry in DB
            await paymentService.storePendingPayment({
                order_id,
                method_id,
                amount: order.total,
                stripe_payment_intent: paymentIntent.id,
            });

            res.json({
                clientSecret: paymentIntent.client_secret,
                paymentIntentId: paymentIntent.id,
            });

        } catch (e: any) {
            console.error("Checkout Error:", e);
            return res.status(500).json({ msg: e.message });
        }
    }

    /**
     * Get payment details
     */
    static async getPaymentById(req: AuthRequest, res: Response) {
        try {
            const payment_id = req.params.id;
            const result = await paymentService.getPayment(payment_id);

            if (!result) return res.status(404).json({ msg: "Payment not found" });

            res.json(result);

        } catch (e: any) {
            return res.status(500).json({ msg: e.message });
        }
    }

    
    static async getPaymentByOrderId(req: AuthRequest, res: Response) {
        try {
            const order_id = req.params.orderId;
            const result = await paymentService.getPaymentByOrder(order_id);

            if (!result) return res.status(404).json({ msg: "Payment not found" });

            res.json(result);

        } catch (e: any) {
            return res.status(500).json({ msg: e.message });
        }
    }
}
