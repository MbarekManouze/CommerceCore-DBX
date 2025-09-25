import { Pool } from "pg";

const pool = new Pool({
  host: "localhost",
  port: 5432,
  database: "your_db_name",
  user: "your_user",
  password: "your_password",
  max: 10,            // max connections
  idleTimeoutMillis: 30000, // 30 seconds
  connectionTimeoutMillis: 2000, // 2 seconds
});

export default pool;
