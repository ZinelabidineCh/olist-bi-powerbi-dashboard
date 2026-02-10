/* LAYER 1: ENTERPRISE RFM SEGMENTATION
   Objective: Classify customers to identify "At Risk" vs "Champions" 
*/

-- 1. Create a cleaned dataset of delivered orders
WITH Clean_Sales AS (
    SELECT 
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        p.payment_value
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
),

-- 2. Aggregate metrics per customer
Customer_Stats AS (
    SELECT 
        customer_unique_id,
        MAX(order_purchase_timestamp) as last_purchase,
        COUNT(DISTINCT order_id) as frequency,
        SUM(payment_value) as monetary
    FROM Clean_Sales
    GROUP BY 1
),

-- 3. Calculate Scores (The Complex Part)
-- We use NTILE to split customers into 5 equal groups (1-5)
RFM_Scores AS (
    SELECT 
        customer_unique_id,
        frequency,
        monetary,
        /* Scoring: 5 is best, 1 is worst */
        NTILE(5) OVER (ORDER BY last_purchase ASC) as r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) as f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) as m_score
    FROM Customer_Stats
)

-- 4. Final Segmentation logic for Power BI
SELECT 
    *,
    (r_score + f_score + m_score) as total_score,
    CASE 
        WHEN (r_score + f_score + m_score) >= 12 THEN 'Champion'
        WHEN (r_score + f_score + m_score) >= 8 THEN 'Loyal'
        WHEN (r_score + f_score + m_score) >= 5 THEN 'At Risk'
        ELSE 'Lost'
    END as customer_segment
FROM RFM_Scores;