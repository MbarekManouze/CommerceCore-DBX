import { Pool } from "pg";

const pool = new Pool({
  host: "localhost",     // ✅ You're connecting from your local machine
  port: 5342,            // ✅ The host port you exposed above
  database: "myapp",
  user: "dbuser",
  password: "dbpassword",
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

export default pool;
