import { Request, Response } from "express";
import { AuthRequest } from "../../middlware/auth";
import { userService } from "./user.service";
import { signin, Userinfos, UserUpdate } from "./user.type";
import { signToken } from "../../utils/jwt";

export const singUp = async (req: Request, res:Response) => {
    const body : Userinfos = req.body;
    // console.log(body)
    const result = await userService.register(body);
    res.json(result).status(Number(result.stat_code));
    // res.json(body);
}

export const singIn = async (req: Request, res:Response) => {
    const body : signin = req.body;
    if (body.email && body.password) {
        const data = await userService.checkIfUserExists(body);
        if (data == null)
            res.json("user with such credentials is not found").status(400);

        const token = signToken(String(data?.user_id), String(data?.role));
        // Attach cookie
        res.cookie("token", token, {
            httpOnly: true,      // cannot be accessed by JS
            secure: false,       // true in production with HTTPS
            sameSite: "strict",
            maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
        });

        res.json({data:data, token: token}).status(200);
    }
    else
        res.json("email or password is missing").status(404);
}


export const logout = (req: Request, res: Response) => {
    res.clearCookie("token", {
        httpOnly: true,
        sameSite: "strict",
        secure: process.env.NODE_ENV === "production",
      });
    return res.status(200).json({ msg: "Logged out" });
};
  
// export const userInfos = async (req: Request, res: Response) => {
//     const body : 
// }

export const getUsers = async (req: AuthRequest, res:Response) => {
    if (req.user?.role == 'admin') {
        const page = parseInt(req.query.page as string) || 1;
        const limit = parseInt(req.query.limit as string) || 10;
        const offset = (page - 1) * limit;
    
        const users = await userService.getAllUsers(limit, offset);
        res.json(users);
    }
    // res.json("khdaam");
}

export const getUsersDetails = async(req: AuthRequest, res: Response) => {
    const id = req.user?.user_id;
    if (id) {
        const user = await userService.getUserDetails(id);
        res.status(200).json(user);
    }
    else
       res.status(400).json("id not found in url");
}

export const getUser = async (req: AuthRequest, res: Response) => {
    const id = req.user?.user_id;
    if (id) {
        const user = await userService.getUser(id);
        res.status(200).json(user);
    }
    else
       res.status(400).json("id not found in url");
}

export const updateUser = async (req: AuthRequest, res: Response) => {
    const id = req.user?.user_id;
    if (id) {
        const body = req.body;
        const data = await userService.updateUser(id, body);
    
        res.json(data).status(202);
    }
    else
        res.json("id not found in url").status(400);
}

export const updateUserAddressesInfos = async (req: AuthRequest, res: Response) => {
    const id = Number(req.user?.user_id);
    if (id) {
        const body = req.body;
        const data = await userService.updateUserAddresses(id, body);

        res.status(200).json(data);
    }
}

export const verify_email = async (req: Request, res: Response) => {

    // last thing to work on in User APIs

}

