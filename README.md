# 🧊 **CommerceCore DBX — A Production-Grade E-Commerce Backend with Integrated Database Engineering**

*A full-stack backend system built not only to sell products — but to showcase **serious database engineering, transaction integrity, and real-world operational DBAs skills** inside a modern API.*

---

## 📌 **Overview**

**CommerceCore DBX** is a realistic, production-oriented backend for an e-commerce system built with:

* **Node.js + TypeScript**
* **PostgreSQL 17** with advanced DB engineering
* **Stripe Checkout**
* **PL/pgSQL transactional logic**
* **Database monitoring, tuning & RBAC security**

This project intentionally blurs the line between **Backend Engineer** and **Database Administrator**, proving the ability to architect systems that are:

✔ Durable
✔ Secure
✔ Transaction-safe
✔ Observable
✔ Ready for real-world scale

---

## 🧱 **Tech Stack**

### **Backend**

* Node.js + Express
* TypeScript
* SQL Template Strings (fully parameterized)
* JWT Authentication (HttpOnly Cookies)

### **Database**

* PostgreSQL 17
* PL/pgSQL Stored Procedures
* Functions, Constraints & Triggers
* Secure Views
* RBAC (Role-Based Access Control)
* `pg_stat_statements` performance monitoring
* Docker Compose reproducible environment

### **Payments**

* Stripe Checkout Session
* Webhooks for reconciliation
* Internal payment state machine

---

## 🛠 **Key Features**

### 👤 Users

* Login / Signup
* Profile management
* Address handling
* Secure sessions with JWT cookies

### 📦 Products

* Product creation & updates
* Inventory tracking
* Filtering & pagination

### 🛒 Orders

* Atomic order creation via SQL transaction
* Inventory validation & locking
* Modify item quantities safely
* Automatic inventory restoration when items removed

### 💳 Payments (Stripe)

* Hosted Stripe Checkout
* Webhook confirms/declines payment
* Multiple payment attempts
* Idempotent operations

---

# 🗄 **Advanced Database Engineering (Core of the Project)**

## 🔥 **Transactional Business Logic (PL/pgSQL)**

All critical workflows run at the database layer:

* `create_order()` → Creates order + items + deducts stock *atomically*
* `modify_order()` → Adjusts quantities with row-level locking
* `delete_product_in_order()` → Restores stock & updates totals
* `mark_payment_completed()` / `mark_payment_failed()`

**Benefits:**
✔ Zero race conditions
✔ Guaranteed consistency
✔ Backend stays simple & clean

Here is a **clean, friendly, professional, GitHub-ready section** rewritten based on your actual scripts:

---

## 🛡️ Backup & Restore (Production-Style Safety)

The project includes simple yet powerful **backup and restore automation** located in:

```
/db/backups/
├── backup.sh
└── restore.sh
```

### 🔹 `backup.sh` — Create Timestamped Snapshots

This script generates a **consistent PostgreSQL backup** from inside the Docker container:

* Uses `pg_dump`
* Automatically timestamps each file
* Saves backups in the current directory

**Example backup file:**

```
backup_myapp_20250110_193045.sql
```

Run it anytime:

```bash
./backup.sh
```

You get an instant snapshot of your entire database — perfect for testing, migration safety, and disaster-recovery drills.

---

### 🔹 `restore.sh` — Clean, Safe Database Restore

The restore script:

1. Drops the target database
2. Recreates it cleanly
3. Imports the selected `.sql` backup

Usage:

```bash
./restore.sh backup_myapp_<timestamp>.sql
```

This ensures a **fully isolated, deterministic restore**, ideal for:

* Rolling back development changes
* Testing schema upgrades
* Recovering from accidental data corruption

---

## 📊 **Performance Monitoring with `pg_stat_statements`**

Enabled by default to examine slow queries, execution frequency, and total cost.

Top 10 most expensive queries:

```sql
SELECT
  calls,
  round(total_time::numeric, 2) AS total_ms,
  round((total_time / calls)::numeric, 2) AS avg_ms,
  query
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

Additional DBA utilities:

```sql
-- Index usage overview
SELECT * FROM pg_stat_user_indexes;

-- Approximate bloat check
SELECT * FROM pgstattuple('orders');
```

This shows **your ability to monitor, diagnose, and tune production databases**.

---

## 🔐 **Role-Based Access Control (RBAC)**

Custom roles ensure realistic database security:

* `app_readonly` — can read only safe views
* `app_readwrite` — standard API operations
* `app_admin` — elevated restricted operations
* Internal tables locked from public access

This mirrors enterprise-level DB governance.

---

## 🛡 **Secure Views for Sensitive Data**

Example: masking payment identifiers for frontend access.

```sql
CREATE VIEW v_payments_safe AS
SELECT
  p.payment_id,
  p.order_id,
  p.amount,
  p.status,
  p.paid_at,
  left(p.provider_payment_id, 6) || '******' AS provider_payment_id_masked,
  regexp_replace(
    u.email,
    '(^.).*(@.*$)',
    '\1***\2'
  ) AS customer_email_masked
FROM payments p;
```

Prevents accidental PII exposure while keeping analytics available internally.

---

## 🧩 **Architecture**

```
Controller → Service → Repository → SQL Queries
```

Benefits:
✔ Clear separation of concerns
✔ Easier to test
✔ Straightforward to scale

---

## 💳 **Stripe Integration Workflow**

* Backend creates Stripe Checkout session
* User pays → Stripe triggers webhook
* Webhook updates the internal payment state
* DB validates & updates order status securely

A real-world payment lifecycle.

---

## 🧪 **Project Status**

| Module         | Status                               |
| -------------- | ------------------------------------ |
| Authentication | ✔ Complete                           |
| Users          | ✔ Complete                           |
| Products       | ✔ Complete                           |
| Orders         | ✔ Transactional SQL done             |
| Payments       | ✔ Stripe checkout + webhook          |
| DBA Features   | ✔ Monitoring, Views, Functions       |
                     Triggers, Materialized Views       
                     Logs Tracing, Transactions, ...etc 