CREATE MATERIALIZED VIEW IF NOT EXISTS mv_daily_revenue AS
SELECT
    date(created_at) AS day,
    COUNT(*)         AS orders_count,
    SUM(total)       AS total_revenue
FROM orders
WHERE status = 'paid'
GROUP BY date(created_at);

CREATE INDEX IF NOT EXISTS idx_mv_daily_revenue_day
ON mv_daily_revenue(day);
