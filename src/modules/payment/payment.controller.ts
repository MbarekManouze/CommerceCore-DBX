// src/modules/payment/payment.controller.ts
import { Response } from "express";
import { AuthRequest } from "../../middlware/auth";
import Stripe from "stripe";
import { paymentService } from "./payment.service";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY as string);


export class paymentController {
  /**
   * Create Stripe Checkout Session for an order
   * Body: { order_id: string, method_id: number }
   */
  static async createCheckoutSession(req: AuthRequest, res: Response) {
    try {
      const { order_id, method_id } = req.body;
      const user_id = req.user!.user_id;

      if (!order_id || !method_id) {
        return res.status(400).json({ msg: "order_id and method_id are required" });
      }

      // 1. Load and validate order (belongs to user, status pending, etc.)
      const order = await paymentService.getOrderForPayment(order_id, user_id);
      if (!order) {
        return res.status(404).json({ msg: "Order not found or not payable" });
      }
      console.log("order : " + order);
      // 2. Create pending payment record in DB
      const payment = await paymentService.createPendingPayment({
        order_id,
        method_id,
        amount: Number(order.total), // NUMERIC from DB
        provider: "stripe_checkout",
      });
      console.log("payment : " + payment);

      // 3. Create Stripe Checkout Session
      const session = await stripe.checkout.sessions.create({
        mode: "payment",
        payment_method_types: ["card"],

        
        // You can build real line_items based on order_items later.
        // For now, one line with total amount:
        line_items: [
          {
            price_data: {
              currency: "usd", // or "mad" if enabled
              unit_amount: Math.round(Number(order.total) * 100), // cents
              product_data: {
                name: `Order ${order_id}`,
              },
            },
            quantity: 1,
          },
        ],

        // These URLs should be your frontend URLs
        success_url: `${process.env.FRONTEND_URL}/checkout/success?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: `${process.env.FRONTEND_URL}/checkout/cancel?order_id=${order_id}`,

        metadata: {
          order_id,
          payment_id: payment.payment_id,
          user_id,
        },
      });

      console.log("session : " + session);
      // 4. Save Stripe session id to payment row
      await paymentService.attachStripeSession(payment.payment_id, session.id);

      return res.status(200).json({
        checkout_url: session.url,
        payment_id: payment.payment_id,
      });
    } catch (err: any) {
      console.error("[createCheckoutSession] error:", err);
      return res.status(500).json({ msg: "Failed to create checkout session" });
    }
  }

  static async getPaymentById(req: AuthRequest, res: Response) {
    try {
      const payment_id = req.params.id;
      const user_id = req.user!.user_id;

      const payment = await paymentService.getPaymentById(payment_id, user_id);
      if (!payment) return res.status(404).json({ msg: "Payment not found" });

      return res.json(payment);
    } catch (err: any) {
      console.error("[getPaymentById] error:", err);
      return res.status(500).json({ msg: "Failed to get payment" });
    }
  }

  static async getPaymentByOrderId(req: AuthRequest, res: Response) {
    try {
      const order_id = req.params.id;
      const user_id = req.user!.user_id;
        console.log(user_id)
        console.log(order_id)

      const payment = await paymentService.getPaymentByOrderId(order_id, user_id);
    
      if (!payment) return res.status(404).json({ msg: "Payment not found" });

      return res.json(payment);
    } catch (err: any) {
      console.error("[getPaymentByOrderId] error:", err);
      return res.status(500).json({ msg: "Failed to get payment" });
    }
  }
}
