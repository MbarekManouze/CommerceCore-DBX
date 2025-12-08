import { QueryResult } from "pg";
import pool from "../../db/config";
import { OrderForPayment, PaymentRow } from "./payment.type";
import { PaymentQueries } from "./payment.queries";

export class paymentRepository {
  /**
   * Get order for payment:
   * - must exist
   * - must belong to user
   * - must be in 'pending' status
   */
  static async getOrderForPayment(order_id: string, user_id: string): Promise<OrderForPayment | null> {
    const query = PaymentQueries.getOrderForPayment(order_id, user_id);
    const result: QueryResult<OrderForPayment> = await pool.query(query);

    return result.rows[0] || null;
  }

  /**
   * Create a new pending payment attempt for this order.
   * Multiple attempts per order are allowed.
   */
  static async createPendingPayment(params: {
    order_id: string;
    method_id: number;
    amount: number;
    provider: string;
  }): Promise<PaymentRow> {
    const { order_id, method_id, amount, provider } = params;
    const query = PaymentQueries.createPendingPayment(order_id, method_id, amount, provider);
    const result: QueryResult<PaymentRow> = await pool.query(query);

    return result.rows[0];
  }

  /**
   * Attach Stripe Checkout session id to a payment attempt.
   */
  static async attachStripeSession( payment_id: string, session_id: string): Promise<void> {
    const query = PaymentQueries.attachStripeSession(payment_id, session_id);
    await pool.query(query);
  }

  /**
   * Get a payment by its id, making sure it belongs to this user
   * (via joining orders.user_id).
   */
  static async getPaymentById(payment_id: string, user_id: string ): Promise<PaymentRow | null> {
    const query = PaymentQueries.getPaymentById(payment_id, user_id);
    const result: QueryResult<PaymentRow> = await pool.query(query);

    return result.rows[0] || null;
  }

  /**
   * Get the latest payment attempt for a given order (for this user).
   */
  static async getLatestPaymentByOrderId(order_id: string,user_id: string): Promise<PaymentRow | null> {
    const query = PaymentQueries.getLatestPaymentByOrderId(order_id, user_id);
    const result: QueryResult<PaymentRow> = await pool.query(query);

    return result.rows[0] || null;
  }

  /**
   * Mark a payment as completed using the Stripe session id.
   * Returns the updated payment row (including its order_id).
   */
  static async markPaymentCompletedBySession(session_id: string): Promise<PaymentRow | null> {
    const query = PaymentQueries.markPaymentCompletedBySession(session_id);
    const result: QueryResult<PaymentRow> = await pool.query(query);

    return result.rows[0] || null;
  }

  /**
   * Mark a payment as failed using the Stripe session id.
   */
  static async markPaymentFailedBySession(session_id: string): Promise<PaymentRow | null> {
    const query = PaymentQueries.markPaymentFailedBySession(session_id);
    const result: QueryResult<PaymentRow> = await pool.query(query);

    return result.rows[0] || null;
  }

  /**
   * Update order status (e.g. to 'paid', 'cancelled', etc.)
   */
  static async updateOrderStatus(order_id: string,status: string): Promise<void> {
    const query = PaymentQueries.updateOrderStatus(order_id, status);
    await pool.query(query);
  }
}
