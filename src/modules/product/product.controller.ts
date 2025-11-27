import { Response, Request } from "express";
import { AuthRequest } from "../../middlware/auth";
import { productService } from "./product.service";

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

    // get some one's products
    static async allProducts() {
        
    }
    
    // get my products
    static async userProducts() {

    }

    // post products
    static async newProducts() {

    }

    // modify products
    static async modifyProduct() {

    }

    // delete products
    static async deleteProduct() {

    }

    // most selling products
    static async analyzeproducts() {
        
    }
}