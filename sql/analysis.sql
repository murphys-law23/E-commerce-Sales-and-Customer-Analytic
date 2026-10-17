-- PostgreSQL: import data/orders.csv into orders
CREATE TABLE IF NOT EXISTS orders (order_id TEXT PRIMARY KEY, order_date DATE, customer_id TEXT, category TEXT, quantity INTEGER, unit_price NUMERIC(12,2), discount_pct NUMERIC(5,2), status TEXT, region TEXT);
-- 1. Monthly net sales and order counts (completed only)
SELECT DATE_TRUNC('month',order_date)::date AS month, COUNT(*) AS orders, ROUND(SUM(quantity*unit_price*(1-discount_pct)),2) AS net_sales FROM orders WHERE status='Completed' GROUP BY 1 ORDER BY 1;
-- 2. Category performance
SELECT category, COUNT(*) AS orders, ROUND(SUM(quantity*unit_price*(1-discount_pct)),2) AS net_sales FROM orders WHERE status='Completed' GROUP BY category ORDER BY net_sales DESC;
-- 3. Repeat-customer rate
WITH customer_orders AS (SELECT customer_id,COUNT(*) AS n FROM orders WHERE status='Completed' GROUP BY customer_id) SELECT ROUND(100.0*COUNT(*) FILTER (WHERE n>=2)/NULLIF(COUNT(*),0),2) AS repeat_customer_pct FROM customer_orders;
-- 4. Customer RFM-style summary
SELECT customer_id, MAX(order_date) AS last_order_date, COUNT(*) AS frequency, ROUND(SUM(quantity*unit_price*(1-discount_pct)),2) AS monetary_value FROM orders WHERE status='Completed' GROUP BY customer_id ORDER BY monetary_value DESC LIMIT 20;
-- 5. Status / operational risk
SELECT status,COUNT(*) AS orders,ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (),2) AS share_pct FROM orders GROUP BY status ORDER BY orders DESC;
-- 6. Region performance
SELECT region,ROUND(SUM(quantity*unit_price*(1-discount_pct)),2) AS net_sales FROM orders WHERE status='Completed' GROUP BY region ORDER BY net_sales DESC;
