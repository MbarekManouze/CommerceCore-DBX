import { UUID } from "crypto";
import { verifyPassword } from "../../utils/passwords";
import { UserRepository } from "./user.repository";
import { RegisterResponse, signin, User, UserUpdate } from "./user.type";

export class userService {

    static async register(user_data: any): Promise<RegisterResponse> {
        
        const existing_user = await this.checkIfUserExists(user_data);
        console.log(existing_user);
        // if (existing_user) {
        //     if (existing_user.email && existing_user.username == user_data.username)
        //         return {msg: "Both email and username exists", status: false};
        //     if (existing_user.username == user_data.username)
        //         return {msg: "username already exists", status: false};
        //     else if (existing_user.email)
        //         return {msg: "email already exists", status: false};
        // } else {
        //     const user = await UserRepository.create(user_data);
        //     if (user?.id)
        //         return {msg: "Client created succesfully", status: true};
        // }

        return {msg: "Some Thing went wrong", status: false};
    }

    static async checkIfUserExists(user_data: signin): Promise<User | null> {
        const user = await UserRepository.findOne_email(user_data.email);
        if (user?.password && await verifyPassword(user_data.password, user?.password))
            return user;
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
        const data = await UserRepository.update(id, updates);
        return data || null;
    }

    static async getUser(id: string): Promise<User | null> {
        const data = await UserRepository.findOne_id(id);
        return data || null;
    }


    static async email_verification() {

    }
}