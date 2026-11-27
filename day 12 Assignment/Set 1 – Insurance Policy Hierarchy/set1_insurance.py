from abc import ABC, abstractmethod
from enum import Enum
import re

class PolicyStatus(Enum):
    DRAFT = 'Draft'
    ACTIVE = 'Active'
    LAPSED = 'Lapsed'
    CANCELLED = 'Cancelled'

class Policy(ABC):
    def __init__(self, policy_number, amount, status=PolicyStatus.ACTIVE):
        self.policy_number = policy_number
        if amount <= 0 or not isinstance(status, PolicyStatus):
            raise ValueError('Invalid amount or status')
        self.amount = amount
        self.status = status

    @property
    def policy_number(self):
        return self.__policy_number

    @policy_number.setter
    def policy_number(self, value):
        if not isinstance(value, str) or not re.fullmatch(r'POL-\d{4}', value):
            raise ValueError('Policy number must follow POL-1234 format')
        self.__policy_number = value

    @abstractmethod
    def calculate_premium(self):
        pass

# Illustrative premium formulas, since no rates are specified.
class MotorPolicy(Policy):
    def calculate_premium(self):
        return self.amount * 0.03

class HealthPolicy(Policy):
    def calculate_premium(self):
        return self.amount * 0.02

class TravelPolicy(Policy):
    def calculate_premium(self):
        return self.amount * 0.01

class HomePolicy(Policy):
    def calculate_premium(self):
        return self.amount * 0.005


def main():
    policies = [MotorPolicy('POL-1001', 500000), HealthPolicy('POL-1002', 300000),
                TravelPolicy('POL-1003', 100000), MotorPolicy('POL-1004', 700000),
                HealthPolicy('POL-1005', 400000, PolicyStatus.DRAFT),
                TravelPolicy('POL-1006', 200000, PolicyStatus.LAPSED),
                MotorPolicy('POL-1007', 600000, PolicyStatus.CANCELLED),
                HomePolicy('POL-1008', 2000000)]
    print('POLICY PREMIUM REPORT (quoted premiums, all statuses)')
    for policy in policies:
        print(f'{policy.policy_number} | {type(policy).__name__} | {policy.status.value} | INR {policy.calculate_premium():.2f}')
    regions = ['North', 'South', 'East']
    months = ['Jan', 'Feb', 'Mar']
    collections = [[12000, 15000, 18000], [20000, 22000, 25000], [10000, 11000, 13000]]
    print('\nMonthly collections (sample data):', months)
    for region, row in zip(regions, collections):
        print(region, row, 'Total:', sum(row))
    print('Month totals:', [sum(col) for col in zip(*collections)])
    print('Grand total:', sum(map(sum, collections)))
    print('Open/closed principle: HomePolicy extends Policy without changing existing classes or the report loop.')

if __name__ == '__main__':
    main()
