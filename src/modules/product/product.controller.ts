import { Response, Request } from "express";
import { AuthRequest } from "../../middlware/auth";
import { productService } from "./product.service";
import { products } from "./product.type";
import { off } from "process";

export class productController {

    // get all products
    static async products(req: AuthRequest, res: Response) {
        if (req.user?.role == "costumer" 
            || req.user?.role == "seller"
            || req.user?.role == "admin") {
                const page = parseInt(req.query.page as string) || 1;
                const limit = parseInt(req.query.limit as string) || 10;
                const offset = (page - 1) * limit;
                console.log(limit);
                console.log(offset);

                const prodcust = await productService.allProducts(limit, offset, "");
                res.json(prodcust);
            }
        else res.json({msg: 'waloo'});
    }

    // post products
    static async newProducts(req: AuthRequest, res: Response) {
        const user_id = String(req.user?.user_id);
        const product_data : products = req.body;
        // console.log(product_data);
        const response = await productService.createProduct(user_id, product_data)
        res.json(response);
    }

    // modify products
    static async modifyProduct(req: AuthRequest, res: Response) {
        const product_id = String(req.params.id);
        const product_data : products = req.body;
        const response = await productService.updateProduct(product_id, product_data);
        res.json(response);
    }

    // delete products
    static async deleteProduct(req: AuthRequest, res: Response) {
        const product_id = String(req.params.id);
        const response = await productService.deleteProduct(product_id);
        res.json(response);
    }
    
    // get my products
    static async userProducts(req: AuthRequest, res: Response) {
        const user_id = String(req.user?.user_id);
        
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 10;
        const offset = (page - 1) * limit;

        const response = await productService.allProducts(limit, offset, user_id);
        res.json(response);
    }

    // get some one's products
    static async othersProducts(req: AuthRequest, res: Response) {
        const user_id = String(req.query.id);

        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 10;
        const offset = (page - 1) * limit;

        const response = await productService.userProducts(limit, offset, user_id);
        res.json(response);
    }

    // implemeting this EP would need 
    // the definition of sales and order APIs first
    static async analyzeproducts() {
        
    }
}