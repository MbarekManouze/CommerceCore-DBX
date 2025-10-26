import { Request, RequestParamHandler, Response } from "express";
import { userService } from "./user.service";
import { signin, Userinfos, UserUpdate } from "./user.type";
import { number } from "zod";

export const singUp = async (req: Request, res:Response) => {
    const body : Userinfos = req.body;
    // console.log(body)
    const result = await userService.register(body);
    res.json(result).status(result.stat_code);
    // res.json(body);
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

// export const userInfos = async (req: Request, res: Response) => {
//     const body : 
// }

export const getUsers = async (req:Request, res:Response) => {

    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 10;
    const offset = (page - 1) * limit;

    const users = await userService.getAllUsers(limit, offset);
    res.json(users);
    // res.json("khdaam");
}

export const getUser = async (req: Request, res: Response) => {
    const id = req.params.id;
    if (id) {
        const user = await userService.getUser(id);
        res.json(user);
    }
    res.json("id not found in url").status(400);
}


export const updateUser = async (req: Request, res: Response) => {
    const id = req.params.id;
    if (id) {
        const body = req.body;
        const data = await userService.updateUser(id, body);
    
        res.json(data).status(202);
    }
    res.json("id not found in url").status(400);
}

export const verify_email = async (req: Request, res: Response) => {

    // last thing to work on in User APIs

}

