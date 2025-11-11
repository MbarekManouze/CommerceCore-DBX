import { UUID } from "crypto";
import { verifyPassword } from "../../utils/passwords";
import { UserRepository } from "./user.repository";
import { RegisterResponse, signin, User, UserAdrress, UserUpdate } from "./user.type";

export class userService {

    static async register(user_data: any): Promise<any> {
        
        const existing_user = await this.checkIfUserExists(user_data);
        // console.log(user_data.city)
        // console.log(existing_user);
        if (existing_user) {
            if (existing_user.email && existing_user.username == user_data.username)
                return {msg: "Both email and username exists", status: false};
            if (existing_user.username == user_data.username)
                return {msg: "username already exists", status: false};
            else if (existing_user.email)
                return {msg: "email already exists", status: false};
        } else {
            const data = await UserRepository.create(user_data);
            // console.log("user : ", data);

            if (data?.user_id)
                return {msg: "Client created succesfully", status: true, user_data: data, stat_code: 200};
            else
                return {msg: data.err_msg, status: false, stat_code: 422}
        }

        return {msg: "Some Thing went wrong", status: false, stat_code: 401};
    }

    static async checkIfUserExists(user_data: signin): Promise<User | null> {
        const user = await UserRepository.findOne_email(user_data.email);
        // console.log("user after retrieved : " ,user);
        if (user?.password_hash){
            const verify = await verifyPassword(user_data.password, user?.password_hash);
            // console.log("does passoword matvh : ", verify);
            if (user?.password_hash && verify){
                // return {user_id:user.user_id, username:user.username, email:user.email, created_at:user.created_at};
                return user;
            }
        }
        return null;
    }

    static async getAllUsers(limit: number, offset: number):  Promise<{ users: User[] | null; total: number }>{

        // const users = UserRepository.findall(limit, offset);
        // const total = UserRepository.countall();
        const [users, total] = await Promise.all([
            UserRepository.findall(limit, offset),
            UserRepository.countall()
        ]);

        return  { users, total: total ?? 0 };
    }

    static async updateUser(id: string, updates: UserUpdate) : Promise<User | null>{            
        const data = await UserRepository.updateCredentials(id, updates);
        return data || null;
    }

    static async updateUserAddresses(id: string, updates: UserAdrress) : Promise<any>{
        const data = await UserRepository.updateAddress(id, updates);
        return data || null;
    }

    static async getUserDetails(id: string): Promise<User | null> {
        const data = await UserRepository.user_details(id);
        return data || null;
    }

    static async getUser(id: string): Promise<User | null> {
        const data = await UserRepository.findOne_id(id);
        return data || null;
    }


    static async email_verification() {

    }
}