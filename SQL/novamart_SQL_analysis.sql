USE novamart_db;

-- ============================================================
-- LEVEL 1 — BASIC JOIN QUERIES
-- ============================================================

-- A1.1 First 10 orders with customer name and region
SELECT
    f.OrderID,
    c.CustomerName,
    c.CustomerRegion,
    f.DeliveryStatus,
    f.Is_Late
FROM fact_deliveries f
JOIN dim_customers c
ON f.CustomerID = c.CustomerID
LIMIT 10;


-- A1.2 Orders delivered by BlueDart Express
SELECT
    f.OrderID,
    f.OrderDate,
    f.DeliveryStatus,
    f.Delay_Days
FROM fact_deliveries f
JOIN dim_delivery_partners p
ON f.PartnerID = p.PartnerID
WHERE p.PartnerName = 'BlueDart Express';


-- A1.3 Warehouse dispatch count
SELECT
    w.WarehouseCity,
    w.WarehouseRegion,
    COUNT(*) AS Total_Orders
FROM fact_deliveries f
JOIN dim_warehouses w
ON f.WarehouseID = w.WarehouseID
GROUP BY w.WarehouseCity, w.WarehouseRegion
ORDER BY Total_Orders DESC;


-- A1.4 Long distance late deliveries
SELECT
    f.OrderID,
    r.OriginCity,
    r.DestinationCity,
    r.Distance_km,
    f.Delay_Days
FROM fact_deliveries f
JOIN dim_routes r
ON f.RouteID = r.RouteID
WHERE r.Distance_km > 1000
AND f.Is_Late = 1
ORDER BY r.Distance_km DESC;


-- ============================================================
-- LEVEL 2 — BUSINESS ANALYSIS QUERIES
-- ============================================================

-- A2.1 Late rate by delivery partner
SELECT
    p.PartnerName,
    p.ServiceTier,
    p.OnTimeDeliveryRate_pct AS Stated_OTR_pct,
    COUNT(*) AS Total_Orders,
    SUM(f.Is_Late) AS Late_Orders,
    ROUND(SUM(f.Is_Late)*100.0/COUNT(*),2) AS Actual_LateRate_pct,
    ROUND(AVG(f.CustomerFeedbackScore),2) AS Avg_Feedback
FROM fact_deliveries f
JOIN dim_delivery_partners p
ON f.PartnerID = p.PartnerID
GROUP BY p.PartnerName, p.ServiceTier, p.OnTimeDeliveryRate_pct
ORDER BY Actual_LateRate_pct DESC;


-- A2.2 Late rate by customer region
SELECT
    c.CustomerRegion,
    COUNT(*) AS Total_Orders,
    SUM(f.Is_Late) AS Late_Orders,
    ROUND(SUM(f.Is_Late)*100.0/COUNT(*),2) AS Late_Rate_pct,
    ROUND(AVG(f.CustomerFeedbackScore),2) AS Avg_Feedback_Score
FROM fact_deliveries f
JOIN dim_customers c
ON f.CustomerID = c.CustomerID
GROUP BY c.CustomerRegion
ORDER BY Late_Rate_pct DESC;


-- A2.3 Warehouse efficiency vs delay
SELECT
    w.WarehouseCity,
    w.WarehouseRegion,
    w.WarehouseStatus,
    w.DispatchEfficiencyScore,
    COUNT(*) AS Total_Orders,
    SUM(f.Is_Late) AS Late_Orders,
    ROUND(SUM(f.Is_Late)*100.0/COUNT(*),2) AS Late_Rate_pct,
    ROUND(AVG(f.DispatchDelay_hrs),1) AS Avg_DispatchDelay_hrs
FROM fact_deliveries f
JOIN dim_warehouses w
ON f.WarehouseID = w.WarehouseID
GROUP BY w.WarehouseCity, w.WarehouseRegion, w.WarehouseStatus, w.DispatchEfficiencyScore
ORDER BY Late_Rate_pct DESC;


-- A2.4 Weather impact on delays
SELECT
    f.WeatherCondition,
    COUNT(*) AS Total_Orders,
    SUM(f.Is_Late) AS Late_Orders,
    ROUND(SUM(f.Is_Late)*100.0/COUNT(*),2) AS Late_Rate_pct,
    ROUND(AVG(f.Delay_Days),2) AS Avg_Delay_Days
FROM fact_deliveries f
GROUP BY f.WeatherCondition
ORDER BY Late_Rate_pct DESC;


-- A2.5 Monthly trend (2023)
SELECT
    YEAR(f.OrderDate) AS Year,
    MONTH(f.OrderDate) AS Month_Num,
    MONTHNAME(f.OrderDate) AS Month,
    COUNT(*) AS Total_Orders,
    SUM(f.Is_Late) AS Late_Orders,
    ROUND(SUM(f.Is_Late)*100.0/COUNT(*),2) AS Late_Rate_pct
FROM fact_deliveries f
WHERE YEAR(f.OrderDate) = 2023
GROUP BY YEAR(f.OrderDate), MONTH(f.OrderDate), MONTHNAME(f.OrderDate)
ORDER BY Month_Num;


-- A2.6 High value failures
SELECT
    f.OrderID,
    f.OrderValue_INR,
    f.DeliveryStatus,
    f.Is_Late,
    c.CustomerName,
    c.CustomerTier,
    p.PartnerName
FROM fact_deliveries f
JOIN dim_customers c
ON f.CustomerID = c.CustomerID
JOIN dim_delivery_partners p
ON f.PartnerID = p.PartnerID
WHERE f.OrderValue_INR > 15000
AND (f.DeliveryStatus = 'Failed' OR f.Is_Late = 1)
ORDER BY f.OrderValue_INR DESC;


-- ============================================================
-- LEVEL 3 — ADVANCED ANALYSIS QUERIES
-- ============================================================

-- A3.1 Partner vs region late rate matrix
SELECT
    p.PartnerName,
    ROUND(SUM(CASE WHEN c.CustomerRegion='North' AND f.Is_Late=1 THEN 1 ELSE 0 END)*100.0 /
          NULLIF(SUM(CASE WHEN c.CustomerRegion='North' THEN 1 ELSE 0 END),0),1) AS North_LateRate,
    ROUND(SUM(CASE WHEN c.CustomerRegion='South' AND f.Is_Late=1 THEN 1 ELSE 0 END)*100.0 /
          NULLIF(SUM(CASE WHEN c.CustomerRegion='South' THEN 1 ELSE 0 END),0),1) AS South_LateRate,
    ROUND(SUM(CASE WHEN c.CustomerRegion='East' AND f.Is_Late=1 THEN 1 ELSE 0 END)*100.0 /
          NULLIF(SUM(CASE WHEN c.CustomerRegion='East' THEN 1 ELSE 0 END),0),1) AS East_LateRate,
    ROUND(SUM(CASE WHEN c.CustomerRegion='West' AND f.Is_Late=1 THEN 1 ELSE 0 END)*100.0 /
          NULLIF(SUM(CASE WHEN c.CustomerRegion='West' THEN 1 ELSE 0 END),0),1) AS West_LateRate,
    ROUND(SUM(CASE WHEN c.CustomerRegion='Central' AND f.Is_Late=1 THEN 1 ELSE 0 END)*100.0 /
          NULLIF(SUM(CASE WHEN c.CustomerRegion='Central' THEN 1 ELSE 0 END),0),1) AS Central_LateRate
FROM fact_deliveries f
JOIN dim_delivery_partners p
ON f.PartnerID = p.PartnerID
JOIN dim_customers c
ON f.CustomerID = c.CustomerID
GROUP BY p.PartnerName
ORDER BY p.PartnerName;


-- A3.2 Warehouse bottleneck score
SELECT
    w.WarehouseCity,
    w.WarehouseRegion,
    w.WarehouseStatus,
    w.DispatchEfficiencyScore,
    ROUND(SUM(f.Is_Late)*100.0/COUNT(*),2) AS Late_Rate_pct,
    ROUND((SUM(f.Is_Late)*100.0/COUNT(*))*0.5 + (100-w.DispatchEfficiencyScore)*0.5,2) AS Bottleneck_Score,
    CASE
        WHEN ((SUM(f.Is_Late)*100.0/COUNT(*))*0.5 + (100-w.DispatchEfficiencyScore)*0.5) > 40 THEN 'Critical'
        WHEN ((SUM(f.Is_Late)*100.0/COUNT(*))*0.5 + (100-w.DispatchEfficiencyScore)*0.5) > 25 THEN 'At Risk'
        ELSE 'Healthy'
    END AS Health_Label
FROM fact_deliveries f
JOIN dim_warehouses w
ON f.WarehouseID = w.WarehouseID
GROUP BY w.WarehouseCity, w.WarehouseRegion, w.WarehouseStatus, w.DispatchEfficiencyScore
ORDER BY Bottleneck_Score DESC;


-- A3.3 Same-Day SLA breach
SELECT
    f.OrderID,
    f.OrderPriority,
    f.Delay_Days,
    f.WeatherCondition,
    p.PartnerName,
    w.WarehouseCity,
    c.CustomerRegion,
    ROUND(
        (SELECT SUM(Is_Late) FROM fact_deliveries WHERE OrderPriority='Same-Day')*100.0 /
        (SELECT COUNT(*) FROM fact_deliveries WHERE OrderPriority='Same-Day'),2
    ) AS SameDay_SLA_Failure_Rate_pct
FROM fact_deliveries f
JOIN dim_delivery_partners p
ON f.PartnerID = p.PartnerID
JOIN dim_warehouses w
ON f.WarehouseID = w.WarehouseID
JOIN dim_customers c
ON f.CustomerID = c.CustomerID
WHERE f.OrderPriority = 'Same-Day'
AND f.SLA_Breached = 1
ORDER BY f.Delay_Days DESC;


-- A3.4 Top revenue risk routes
SELECT
    r.OriginCity,
    r.DestinationCity,
    r.Distance_km,
    r.RoadType,
    COUNT(*) AS Total_Orders,
    SUM(f.Is_Late) AS Late_Orders,
    ROUND(SUM(f.Is_Late)*100.0/COUNT(*),1) AS Late_Rate_pct,
    ROUND(AVG(f.Delay_Days),2) AS Avg_Delay_Days,
    ROUND(SUM(CASE WHEN f.Is_Late=1 THEN f.OrderValue_INR ELSE 0 END),2) AS Revenue_at_Risk_INR
FROM fact_deliveries f
JOIN dim_routes r
ON f.RouteID = r.RouteID
GROUP BY r.OriginCity, r.DestinationCity, r.Distance_km, r.RoadType
ORDER BY Revenue_at_Risk_INR DESC
LIMIT 10;


-- A3.5 Customer tier comparison
SELECT
    c.CustomerTier,
    COUNT(*) AS Total_Orders,
    ROUND(SUM(f.Is_Late)*100.0/COUNT(*),2) AS Late_Rate_pct,
    ROUND(AVG(f.CustomerFeedbackScore),2) AS Avg_Feedback,
    ROUND(SUM(CASE WHEN f.DeliveryStatus='Failed' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS Failed_Rate_pct,
    ROUND(AVG(f.OrderValue_INR),2) AS Avg_Order_Value_INR
FROM fact_deliveries f
JOIN dim_customers c
ON f.CustomerID = c.CustomerID
GROUP BY c.CustomerTier
ORDER BY FIELD(c.CustomerTier,'Platinum','Gold','Silver','Bronze');


SELECT
    p.PartnerName,
    p.ServiceTier,
    p.OnTimeDeliveryRate_pct AS Stated_OTR_pct,
    COUNT(*) AS Total_Orders,
    SUM(f.Is_Late) AS Late_Orders,
    ROUND(SUM(f.Is_Late)*100.0/COUNT(*),2) AS Actual_LateRate_pct,
    ROUND(AVG(f.CustomerFeedbackScore),2) AS Avg_Feedback
FROM fact_deliveries f
JOIN dim_delivery_partners p
ON f.PartnerID = p.PartnerID
GROUP BY p.PartnerName, p.ServiceTier, p.OnTimeDeliveryRate_pct
ORDER BY Actual_LateRate_pct DESC;
