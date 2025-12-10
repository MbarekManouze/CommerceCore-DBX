import express from "express";
import morgan from "morgan";
import routes from "./routes";
import cookieParser from "cookie-parser";
import paymentRoutes from "./routes/payment.routes"
import { stripeWebhookController } from "./modules/payment/stripeWebhook.controller";

const app = express();

app.use((req, res, next) => {
    console.log("REQUEST →", req.method, req.url);
    next();
  });
  
app.post(
    "/api/payments/webhooks/stripe",
    express.raw({ type: "application/json" }),
    stripeWebhookController.handleStripeWebhook
);
  


// Middlewares
app.use(cookieParser());
app.use(morgan("dev"));
app.use(express.json());

// Routes
app.use("/api", routes);

export default app;
