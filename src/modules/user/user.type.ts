import { UUID } from "crypto";

// export interface totalUsers {
//     total: number
// };

export interface User {
    id: UUID,
    email: string,
    username: string,
    password?: string,
    createda_at: Date
};

export interface UserUpdate {
    email?: string,
    email_verified?: boolean,
    username?: string,
    password?: string,
    updated_at?: Date
};

export interface signin {
    email: string,
    password: string
};

export interface RegisterResponse {
    msg: string,
    status: boolean
};

export interface Bagination {
    offset: number,
    limit: number
};