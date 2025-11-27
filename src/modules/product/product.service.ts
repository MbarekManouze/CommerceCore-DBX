import { ProductRepository } from "./product.repository";


export class productService {

    static async allProducts(limit: number, offset: number) : Promise<any | null>{
        const response = ProductRepository.all(limit, offset, "");
        return response; 
    }

    static async userProducts(limit: number, offset: number, user_id: number) : Promise<any | null> {
        
    }

}