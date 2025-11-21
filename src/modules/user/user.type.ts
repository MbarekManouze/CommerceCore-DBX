import { UUID } from "crypto";

// export interface totalUsers {
//     total: number
// };

export interface User {
    user_id: UUID,
    email: string,
    username: string,
    password_hash?: string,
    role?: string, 
    created_at: Date
};

export interface role {
    roles: string
};

export interface address_id {
    address_id: number,
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

// export interface UserAdrress {
//     full_name: string,
//     phone: string,
//     street: string,
//     city: string,
//     state: string,
//     postal_code: string,
//     country: string
// }

export interface UserUpdate {
    email?: string,
    username?: string,
    password?: string,
};


export interface UserAdrress {
    full_name?: string,
    phone?: string,
    street?: string,
    city?: string,
    state?: string,
    postal_code?: string,
    country?: string,
}

export interface signin {
    email: string,
    password: string
};

export interface RegisterResponse {
    msg: string,
    status: boolean,

};

export interface Bagination {
    offset: number,
    limit: number
};