import express from "express";
import morgan from "morgan";
import routes from "./routes";

const app = express();

// Middlewares
app.use(express.json());
app.use(morgan("dev"));

// Routes
app.use("/api", routes);

export default app;
