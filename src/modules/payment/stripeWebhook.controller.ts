// src/modules/payment/stripeWebhook.controller.ts
import Stripe from "stripe";
import { Request, Response } from "express";
import { paymentService } from "./payment.service";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export class stripeWebhookController {
    static async handleStripeWebhook(req: Request, res: Response) {
        const sig = req.headers["stripe-signature"];

        try {
            const event = stripe.webhooks.constructEvent(
                req.body,
                sig!,
                process.env.STRIPE_WEBHOOK_SECRET!
            );

            switch (event.type) {

                case "payment_intent.succeeded": {
                    const intent = event.data.object;
                    const payment_intent_id = intent.id;
                    const order_id = intent.metadata.order_id;

                    await paymentService.markPaymentCompleted(payment_intent_id);
                    await paymentService.updateOrderStatus(order_id, "paid");

                    break;
                }

                case "payment_intent.payment_failed": {
                    const intent = event.data.object;
                    await paymentService.markPaymentFailed(intent.id);
                    break;
                }

                default:
                    console.log(`Unhandled event: ${event.type}`);
            }

            res.json({ received: true });

        } catch (err: any) {
            console.error("Webhook Error:", err.message);
            return res.status(400).send(`Webhook Error: ${err.message}`);
        }
    }
}
