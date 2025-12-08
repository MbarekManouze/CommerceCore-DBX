import { orderRepository } from "./order.repository";
import { createOrder, modifyOrder } from "./order.type";


export class orderService {

    static async getOrder(order_id: string, user_id: string): Promise<any> {
        return await orderRepository.getOrder(order_id, user_id);
    }

    static async create(user_id: string, order: createOrder): Promise<any> {
        return await orderRepository.create(user_id, order);
    }

    static async modifyOrder(order_id: string, new_order: modifyOrder): Promise<any> {
        return await orderRepository.modifyOrder(order_id, new_order);
    }

    static async modifyAddress(address_id: number, order_id: string): Promise<any> {
        return await orderRepository.modifyAddress(address_id, order_id);
    }

    static async deleteProduct(order_id: string, product_id: string): Promise<any> {
        return await orderRepository.deleteProduct(order_id, product_id);
    }

    static async deleteOrder(order_id: string): Promise<any> {
        return await orderRepository.deleteOrder(order_id);
    }   

    static async track() {
        
    }

}