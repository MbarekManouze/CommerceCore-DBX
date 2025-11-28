import { Response, Request } from "express";
import { AuthRequest } from "../../middlware/auth";
import { productService } from "./product.service";
import { products } from "./product.type";

export class productController {

    // get all products
    static async products(req: AuthRequest, res: Response) {
        if (req.user?.role == "costumer" 
            || req.user?.role == "seller"
            || req.user?.role == "admin") {
                const page = parseInt(req.query.page as string) || 1;
                const limit = parseInt(req.query.limit as string) || 10;
                const offset = (page - 1) * limit;
                
                const prodcust = productService.allProducts(limit, offset);
                res.json(prodcust);
            }
    }

    // post products
    static async newProducts(req: AuthRequest, res: Response) {
        const user_id = String(req.user?.user_id);
        const product_data: products = req.body;
        const response = await productService.createProduct(user_id, product_data)
        res.json(response);
    }

    // modify products
    static async modifyProduct(req: AuthRequest, res: Response) {
        const product_id = String(req.query.id);
        const product_data = req.body;
        const response = productService.updateProduct(product_id, product_data);
        res.json(response);
    }

    // delete products
    static async deleteProduct(req: AuthRequest, res: Response) {
        const product_id = String(req.query.id);
        const response = productService.deleteProduct(product_id);
        res.json(response);
    }

    // get some one's products
    static async allProducts() {

    }
    
    // get my products
    static async userProducts() {

    }

    // most selling products
    static async analyzeproducts() {
        
    }
}