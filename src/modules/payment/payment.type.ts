export interface PendingPaymentParams {
    order_id: string;
    method_id: number;
    amount: number;
    provider: string;
}
export interface OrderForPayment {
    order_id: string;
    user_id: string;
    total: string; // NUMERIC from pg comes as string
    status: string;
}

export interface PaymentRow {
    payment_id: string;
    order_id: string | null;
    method_id: number | null;
    amount: string;
    status: string;
    provider: string | null;
    provider_payment_id: string | null;
    metadata: any;
    created_at: Date;
    paid_at: Date | null;
}

  