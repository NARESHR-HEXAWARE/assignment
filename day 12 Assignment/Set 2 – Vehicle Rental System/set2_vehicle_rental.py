from abc import ABC, abstractmethod
from enum import Enum
from dataclasses import dataclass

class VehicleType(Enum):
    CAR = 'Car'
    BIKE = 'Bike'
    VAN = 'Van'

class Vehicle(ABC):
    def __init__(self, registration_number, mileage):
        self.registration_number = registration_number
        self.mileage = mileage

    @property
    def registration_number(self):
        return self.__registration_number

    @registration_number.setter
    def registration_number(self, value):
        if not isinstance(value, str) or not value.strip():
            raise ValueError('Registration number required')
        self.__registration_number = value.strip().upper()

    @property
    def mileage(self):
        return self.__mileage

    @mileage.setter
    def mileage(self, value):
        if value < 0:
            raise ValueError('Mileage cannot be negative')
        self.__mileage = value

    @abstractmethod
    def daily_rate(self):
        pass

    @abstractmethod
    def late_fee(self, days):
        pass

# Sample rates in INR; days in late_fee are overdue days.
class Car(Vehicle):
    vehicle_type = VehicleType.CAR
    def daily_rate(self): return 1500
    def late_fee(self, days): return 500 * days

class Bike(Vehicle):
    vehicle_type = VehicleType.BIKE
    def daily_rate(self): return 500
    def late_fee(self, days): return 150 * days

class Van(Vehicle):
    vehicle_type = VehicleType.VAN
    def daily_rate(self): return 2500
    def late_fee(self, days): return 800 * days

@dataclass(frozen=True)
class Customer:
    customer_id: str
    name: str

class Rental:
    def __init__(self, vehicle, customer, days, late_days=0):
        if not isinstance(days, int) or not isinstance(late_days, int) or days <= 0 or late_days < 0:
            raise ValueError('Invalid rental duration')
        self.vehicle = vehicle
        self.customer = customer
        self.days = days
        self.late_days = late_days

    def calculate_amount(self):
        return self.days * self.vehicle.daily_rate() + self.vehicle.late_fee(self.late_days)

# Refactored responsibilities: rental data, billing and printing.
class BillingService:
    def calculate(self, rental):
        return rental.calculate_amount()

class RentalReport:
    def print_report(self, rentals, billing):
        total = 0
        for rental in rentals:
            amount = billing.calculate(rental)
            total += amount
            print(f'{rental.customer.name} | {rental.vehicle.vehicle_type.value} | {rental.vehicle.registration_number} | INR {amount:.2f}')
        print(f'Total rental revenue: INR {total:.2f}')


def main():
    rentals = [Rental(Car('TN01AB1234', 18), Customer('C01', 'Arun'), 3, 1),
               Rental(Bike('TN02CD5678', 45), Customer('C02', 'Bala'), 2),
               Rental(Van('TN03EF9012', 12), Customer('C03', 'Charan'), 4, 2)]
    RentalReport().print_report(rentals, BillingService())
    print('Single responsibility principle: Rental models the rental, BillingService handles billing, RentalReport prints reports.')
    print('Inheritance: Car, Bike and Van are Vehicles. Composition (HAS-A): Rental holds Vehicle and Customer objects.')

if __name__ == '__main__':
    main()
