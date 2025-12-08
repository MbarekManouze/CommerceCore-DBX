import { paymentRepository } from "./payment.repository";
import { PendingPaymentParams } from "./payment.type";
import { OrderForPayment, PaymentRow } from "./payment.type";
  
export class paymentService {
    /**
     * Load order for payment, ensuring:
     * - exists
     * - belongs to user
     * - status = 'pending'
     */
    static async getOrderForPayment(order_id: string,user_id: string): Promise<OrderForPayment | null> {
      return await paymentRepository.getOrderForPayment(order_id, user_id);
    }
  
    /**
     * Create a new pending payment attempt for this order.
     */
    static async createPendingPayment(params: PendingPaymentParams ): Promise<PaymentRow> {
      return await paymentRepository.createPendingPayment(params);
    }

    /**
     * Attach Stripe Checkout session id to internal payment record.
     */
    static async attachStripeSession(payment_id: string,session_id: string): Promise<void> {
      await paymentRepository.attachStripeSession(payment_id, session_id);
    }
  
    /**
     * Get a single payment by id, checking that it belongs to this user.
     */
    static async getPaymentById(payment_id: string,user_id: string): Promise<PaymentRow | null> {
      return await paymentRepository.getPaymentById(payment_id, user_id);
    }
  
    /**
     * Get the latest payment attempt for an order, for this user.
     */
    static async getPaymentByOrderId(order_id: string,user_id: string): Promise<PaymentRow | null> {
      return await paymentRepository.getLatestPaymentByOrderId(order_id, user_id);
    }
  
    /**
     * Called from Stripe webhook when checkout.session.completed (paid)
     */
    static async markPaymentCompletedBySession(session_id: string): Promise<void> {
      const payment = await paymentRepository.markPaymentCompletedBySession(
        session_id
      );
  
      if (!payment || !payment.order_id) {
        console.warn(
          "[markPaymentCompletedBySession] payment not found or has no order_id for session:",
          session_id
        );
        return;
      }
  
      // For now, mark order as 'paid'
      await paymentRepository.updateOrderStatus(payment.order_id, "paid");
    }
  
    /**
     * Called from Stripe webhook when payment fails (if you handle that event)
     */
    static async markPaymentFailedBySession(session_id: string): Promise<void> {
      const payment = await paymentRepository.markPaymentFailedBySession(
        session_id
      );
  
      if (!payment || !payment.order_id) {
        console.warn(
          "[markPaymentFailedBySession] payment not found or has no order_id for session:",
          session_id
        );
        return;
      }
  
      // Usually you keep order as 'pending' so user can retry.
      // But you could also add an 'payment_failed' status in the orders table.
    }
  }
  