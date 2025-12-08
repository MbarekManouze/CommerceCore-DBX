// src/modules/payment/stripeWebhook.controller.ts
import { Request, Response } from "express";
import Stripe from "stripe";
import { paymentService } from "./payment.service";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY as string);

export class stripeWebhookController {
static async handleStripeWebhook(req: Request, res: Response) {
    const sig = req.headers["stripe-signature"] as string | undefined;

    if (!sig) {
    return res.status(400).send("Missing Stripe-Signature header");
    }

    try {
    const event = stripe.webhooks.constructEvent(
        req.body, // raw body (express.raw())
        sig,
        process.env.STRIPE_WEBHOOK_SECRET as string
    );

    switch (event.type) {
        case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;

        const sessionId = session.id;
        const paymentStatus = session.payment_status; // 'paid' or 'unpaid'
        const metadata = session.metadata || {};

        const order_id = metadata.order_id;
        const payment_id = metadata.payment_id;

        if (paymentStatus === "paid") {
            // Mark payment as completed + order as paid
            await paymentService.markPaymentCompletedBySession(sessionId);
        }

        break;
        }

        // You can handle more events later if needed:
        // case "checkout.session.expired": ...
        // case "payment_intent.payment_failed": ...

        default:
        console.log(`Unhandled Stripe event type: ${event.type}`);
    }

    return res.json({ received: true });
    } catch (err: any) {
    console.error("[Stripe webhook] error:", err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
    }
}
}
