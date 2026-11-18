

USE LogisticsDB;
GO

SELECT
    s.shipment_id,
    c.carrier_name,
    s.expected_delivery_at,
    s.actual_delivery_at,
    DATEDIFF(DAY, s.expected_delivery_at, s.actual_delivery_at) AS delay_days
FROM Shipments AS s
INNER JOIN Carriers AS c
    ON c.carrier_id = s.carrier_id
WHERE s.actual_delivery_at IS NOT NULL
  AND DATEDIFF(DAY, s.expected_delivery_at, s.actual_delivery_at) > 2
ORDER BY delay_days DESC;
GO

SELECT
    h.hub_id,
    h.hub_name,
    COUNT(s.shipment_id) AS outbound_shipment_count
FROM Hubs AS h
LEFT JOIN Shipments AS s
    ON s.origin_hub_id = h.hub_id
GROUP BY h.hub_id, h.hub_name
ORDER BY h.hub_name;
GO

SELECT
    h.hub_id,
    h.hub_name,
    h.city
FROM Hubs AS h
LEFT JOIN Shipments AS s
    ON s.origin_hub_id = h.hub_id
WHERE s.shipment_id IS NULL;
GO

SELECT
    e.employee_id,
    e.employee_name AS employee_name,
    m.employee_name AS supervisor_name
FROM Employees AS e
LEFT JOIN Employees AS m
    ON m.employee_id = e.supervisor_id
ORDER BY e.employee_name;
GO

SELECT
    s.shipment_id,
    cu.customer_name,
    ca.carrier_name,
    s.shipping_cost,
    s.shipped_at
FROM Shipments AS s
INNER JOIN Customers AS cu
    ON cu.customer_id = s.customer_id
INNER JOIN Carriers AS ca
    ON ca.carrier_id = s.carrier_id;
GO

SELECT
    h.hub_id,
    h.hub_name,
    s.shipment_id,
    s.origin_hub_id,
    s.destination_hub_id
FROM Hubs AS h
FULL OUTER JOIN Shipments AS s
    ON h.hub_id = s.origin_hub_id
    OR h.hub_id = s.destination_hub_id
ORDER BY h.hub_id, s.shipment_id;
GO

-- Q7. Show every customer and any shipments they have made.
-- Join: LEFT JOIN retains customers who have never shipped.
SELECT
    cu.customer_id,
    cu.customer_name,
    s.shipment_id,
    s.shipping_cost
FROM Customers AS cu
LEFT JOIN Shipments AS s
    ON s.customer_id = cu.customer_id
ORDER BY cu.customer_name, s.shipment_id;
GO

SELECT
    ca.carrier_id,
    ca.carrier_name,
    s.shipment_id,
    s.actual_delivery_at
FROM Carriers AS ca
LEFT JOIN Shipments AS s
    ON s.carrier_id = ca.carrier_id
ORDER BY ca.carrier_name, s.shipment_id;
GO

-- Q9. Show shipment details with their delivery events, if any.
-- Join: LEFT JOIN retains shipments that have no tracking events.
SELECT
    s.shipment_id,
    s.customer_id,
    de.event_type,
    de.event_at,
    de.location,
    de.remarks
FROM Shipments AS s
LEFT JOIN DeliveryEvents AS de
    ON de.shipment_id = s.shipment_id
ORDER BY s.shipment_id, de.event_at;
GO

SELECT
    s.shipment_id,
    origin.hub_name AS origin_hub,
    destination.hub_name AS destination_hub
FROM Shipments AS s
INNER JOIN Hubs AS origin
    ON origin.hub_id = s.origin_hub_id
INNER JOIN Hubs AS destination
    ON destination.hub_id = s.destination_hub_id
ORDER BY s.shipment_id;
GO


SELECT
    cu.customer_id,
    cu.customer_name
FROM Customers AS cu
WHERE NOT EXISTS (
    SELECT 1
    FROM Hubs AS h
    WHERE NOT EXISTS (
        SELECT 1
        FROM Shipments AS s
        WHERE s.customer_id = cu.customer_id
          AND s.destination_hub_id = h.hub_id
    )
);
GO

-- Q12. Customers who shipped to at least one hub in Chennai.
-- IN uses a subquery to supply destination hub IDs.
SELECT
    cu.customer_id,
    cu.customer_name
FROM Customers AS cu
WHERE cu.customer_id IN (
    SELECT s.customer_id
    FROM Shipments AS s
    INNER JOIN Hubs AS h
        ON h.hub_id = s.destination_hub_id
    WHERE h.city = 'Chennai'
);
GO

SELECT
    ca.carrier_id,
    ca.carrier_name,
    AVG(CAST(DATEDIFF(DAY, s.expected_delivery_at, s.actual_delivery_at) AS DECIMAL(10,2)))
        AS average_delay_days
FROM Carriers AS ca
INNER JOIN Shipments AS s
    ON s.carrier_id = ca.carrier_id
WHERE s.actual_delivery_at IS NOT NULL
GROUP BY ca.carrier_id, ca.carrier_name
HAVING AVG(CAST(DATEDIFF(DAY, s.expected_delivery_at, s.actual_delivery_at) AS DECIMAL(10,2)))
    > (
        SELECT AVG(CAST(DATEDIFF(DAY, expected_delivery_at, actual_delivery_at) AS DECIMAL(10,2)))
        FROM Shipments
        WHERE actual_delivery_at IS NOT NULL
      );
GO

SELECT
    shipment_id,
    origin_hub_id,
    shipping_cost
FROM Shipments
WHERE shipping_cost > ANY (
    SELECT shipping_cost
    FROM Shipments
    WHERE origin_hub_id = 1
);
GO

SELECT
    shipment_id,
    origin_hub_id,
    shipping_cost
FROM Shipments
WHERE shipping_cost > ALL (
    SELECT shipping_cost
    FROM Shipments
    WHERE origin_hub_id = 1
);
GO


SELECT
    cu.customer_id,
    cu.customer_name
FROM Customers AS cu
WHERE cu.customer_id IN (
    SELECT s.customer_id
    FROM Shipments AS s
);
GO

SELECT DISTINCT
    cu.customer_id,
    cu.customer_name
FROM Customers AS cu
INNER JOIN Shipments AS s
    ON s.customer_id = cu.customer_id;
GO

SELECT
    ca.carrier_id,
    ca.carrier_name
FROM Carriers AS ca
WHERE EXISTS (
    SELECT 1
    FROM Shipments AS s
    WHERE s.carrier_id = ca.carrier_id
);
GO

SELECT DISTINCT
    ca.carrier_id,
    ca.carrier_name
FROM Carriers AS ca
INNER JOIN Shipments AS s
    ON s.carrier_id = ca.carrier_id;
GO
SELECT
    h.hub_id,
    h.hub_name,
    ranked.shipping_cost AS second_highest_shipping_cost
FROM Hubs AS h
OUTER APPLY (
    SELECT
        cost_rows.shipping_cost
    FROM (
        SELECT
            s.shipping_cost,
            DENSE_RANK() OVER (ORDER BY s.shipping_cost DESC) AS cost_rank
        FROM Shipments AS s
        WHERE s.origin_hub_id = h.hub_id
    ) AS cost_rows
    WHERE cost_rows.cost_rank = 2
) AS ranked
ORDER BY h.hub_name;
GO


SELECT
    h.hub_id,
    h.hub_name,
    (
        SELECT MAX(s1.shipping_cost)
        FROM Shipments AS s1
        WHERE s1.origin_hub_id = h.hub_id
          AND s1.shipping_cost < (
              SELECT MAX(s2.shipping_cost)
              FROM Shipments AS s2
              WHERE s2.origin_hub_id = h.hub_id
          )
    ) AS second_highest_shipping_cost
FROM Hubs AS h
ORDER BY h.hub_name;
GO


