import { ProductRepository } from "./product.repository";
import { products } from "./product.type";


export class productService {

    static async allProducts(limit: number, offset: number) : Promise<any | null>{
        const response = ProductRepository.all(limit, offset, "");
        return response; 
    }
    
    static async createProduct(user_id: string, product_data: products) : Promise<any | null> {
        const response = await ProductRepository.create(user_id, product_data);
        return response;
    }
    
    static async updateProduct(product_id: string, product_data: products): Promise<any | null> {
        const response = await ProductRepository.update(product_id, product_data);
        return response;
    }
    
    static async deleteProduct(product_id: string): Promise<any | null> {
        const response = await ProductRepository.delete(product_id);
        return response;
    }

    static async userProducts(limit: number, offset: number, user_id: number) : Promise<any | null> {

    }
}