USE AirlineDB;
GO

INSERT INTO Bookings
(BookingID, PassengerName, FlightID, SeatNumber, Fare)
VALUES
(102, 'Bala', 1001, 'A2', 6000),
(103, 'Charan', 1001, 'A3', 6000);

-- RANK and DENSE_RANK
SELECT
    PassengerName,
    FlightID,
    Fare,
    RANK() OVER (
        PARTITION BY FlightID
        ORDER BY Fare DESC
    ) AS FareRank,
    DENSE_RANK() OVER (
        PARTITION BY FlightID
        ORDER BY Fare DESC
    ) AS DenseRank
FROM Bookings;

-- CTE with running revenue
WITH PassengerRanking AS (
    SELECT
        BookingID,
        PassengerName,
        FlightID,
        Fare,
        RANK() OVER (
            PARTITION BY FlightID
            ORDER BY Fare DESC
        ) AS FareRank,
        DENSE_RANK() OVER (
            PARTITION BY FlightID
            ORDER BY Fare DESC
        ) AS DenseRank,
        SUM(Fare) OVER (
            PARTITION BY FlightID
            ORDER BY BookingID
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS RunningRevenue
    FROM Bookings
)
SELECT *
FROM PassengerRanking
ORDER BY FlightID, FareRank, BookingID;