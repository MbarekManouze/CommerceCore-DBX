import { Request, RequestParamHandler, Response } from "express";
import { userService } from "./user.service";
import { signin, UserUpdate } from "./user.type";

export const singUp = async (req: Request, res:Response) => {
    const body : UserUpdate = req.body;
    if (body.email && body.password && body.username) {
        const result = await userService.register(body);
        res.json(result).status(200);
    }
    else
        res.json("email ,password or username is missing").status(404);
}

export const singIn = async (req: Request, res:Response) => {
    const body : signin = req.body;
    if (body.email && body.password) {
        const data = await userService.checkIfUserExists(body);
        res.json(data).status(200);
    }
    else
        res.json("email or password is missing").status(404);
}

export const getUsers = async (req:Request, res:Response) => {
    const users = await userService.getAllUsers();
    res.json(users);
}

export const getUser = async (req: Request, res: Response) => {
    const user = await userService.getUser();
    res.json(user);
}


export const updateUser = async (req: Request, res: Response) => {
    const body = req.body;
    const data = await userService.updateUser(body);

    res.json(data);
}

export const verify_email = async (req: Request, res: Response) => {

}

