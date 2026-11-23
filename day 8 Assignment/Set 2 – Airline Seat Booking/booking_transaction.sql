CREATE DATABASE AirlineDB;
GO

USE AirlineDB;
GO

CREATE TABLE Seats (
    SeatID INT PRIMARY KEY,
    FlightID INT,
    SeatNumber VARCHAR(10),
    SeatStatus VARCHAR(20) DEFAULT 'AVAILABLE',
    UNIQUE (FlightID, SeatNumber)
);

CREATE TABLE Bookings (
    BookingID INT PRIMARY KEY,
    PassengerName VARCHAR(50),
    FlightID INT,
    SeatNumber VARCHAR(10),
    Fare DECIMAL(10,2),
    BookingDate DATETIME DEFAULT GETDATE(),
    UNIQUE (FlightID, SeatNumber)
);

INSERT INTO Seats VALUES
(1, 1001, 'A1', 'AVAILABLE'),
(2, 1001, 'A2', 'AVAILABLE'),
(3, 1001, 'A3', 'AVAILABLE');

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1
        FROM Seats WITH (UPDLOCK, HOLDLOCK)
        WHERE FlightID = 1001
          AND SeatNumber = 'A1'
          AND SeatStatus = 'AVAILABLE'
    )
        THROW 50001, 'Seat is unavailable', 1;

    INSERT INTO Bookings
    (BookingID, PassengerName, FlightID, SeatNumber, Fare)
    VALUES
    (101, 'Arun', 1001, 'A1', 5000);

    UPDATE Seats
    SET SeatStatus = 'BOOKED'
    WHERE FlightID = 1001
      AND SeatNumber = 'A1'
      AND SeatStatus = 'AVAILABLE';

    IF @@ROWCOUNT = 0
        THROW 50002, 'Seat booking failed', 1;

    COMMIT TRANSACTION;
    PRINT 'Booking successful';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT ERROR_MESSAGE();
END CATCH;

SELECT * FROM Seats;
SELECT * FROM Bookings;