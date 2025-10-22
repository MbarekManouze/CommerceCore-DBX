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

export interface Userinfos {
    email?: string,
    username?: string,
    password?: string,
    role?: string,
    full_name?: string,
    phone?: string,
    street?: string,
    city?: string,
    state?: string,
    postal_code?: string,
    country?: string,
    // is_default?: boolean
}

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