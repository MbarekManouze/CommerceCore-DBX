import express from "express";
import morgan from "morgan";
import routes from "./routes";
import cookieParser from "cookie-parser";
import paymentRoutes from "./routes/payment.routes"

const app = express();


// Middlewares
app.use(cookieParser());
app.use(morgan("dev"));
app.use("/api/payments/webhooks/stripe", paymentRoutes);
app.use(express.json());

// Routes
app.use("/api", routes);

export default app;
