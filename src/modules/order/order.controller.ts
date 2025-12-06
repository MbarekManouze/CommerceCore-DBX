import { AuthRequest } from "../../middlware/auth";
import { Request, Response } from "express";
import { createOrder, modifyOrder, shipping_address_id } from "./order.type";
import { orderService } from "./order.service";
import { product_id } from "../product/product.type";

export class ordreController {

    static async createOrder(req: AuthRequest, res: Response) {
        const order : createOrder = req.body;
        const user_id : string = String(req.user?.user_id);
        
        const response = await orderService.create(user_id, order); 
        res.json(response);
    }

    static async modifyOrder(req: AuthRequest, res: Response) {
        const order_id: string = String(req.params.id);
        const new_order: modifyOrder = req.body;

        const response = await orderService.modifyOrder(order_id, new_order);
        res.json(response);
    }

    static async modifyOrder_address(req: AuthRequest, res: Response) {
        const address_id: number = req.body.shipping_address_id;
        console.log(address_id)
        const order_id: string = String(req.params.id);
        
        const response = await orderService.modifyAddress(Number(address_id), order_id);
        res.json(response);
    }

    static async deleteProduct(req: AuthRequest, res: Response) {
        const product_id: string = req.body.product_id;
        const order_id: string = String(req.params.id);

        const response = await orderService.deleteProduct(order_id, String(product_id));
        res.json(response);
    }

    static async deleteOrder(req: AuthRequest, res: Response) {
        const order_id: string = String(req.params.id);

        const response = await orderService.deleteOrder(order_id);
        res.json(response);   
    }

    static async trackOrder(req: AuthRequest, res: Response) {

        
    }

}