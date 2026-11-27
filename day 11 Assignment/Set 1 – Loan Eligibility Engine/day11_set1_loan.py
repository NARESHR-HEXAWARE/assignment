# Setup: python -m venv .venv; activate it, then run this script.
# Illustrative rules, not actual bank lending criteria.
from math import isfinite

def assess(age: int, income: float, emi: float, score: int, employment: str, loans: int):
    if age < 0 or not 300 <= score <= 900 or not all(map(isfinite, (income, emi))) or income <= 0 or emi < 0 or loans < 0:
        return 'INVALID', '-', '-', 'Invalid record'
    if score >= 750:
        band: str = 'Excellent'
    elif score >= 650:
        band = 'Good'
    else:
        band = 'Poor'
    match band:
        case 'Excellent': rate, product = '8%', 'Prime'
        case 'Good': rate, product = '12%', 'Standard'
        case _: rate, product = '-', '-'
    ratio: float = emi / income
    if not 21 <= age <= 60:
        reason = 'Age outside range'
    elif ratio > 0.40:
        reason = 'EMI exceeds 40% of income'
    elif band == 'Poor':
        reason = 'Low credit score'
    elif employment not in ('salaried', 'self-employed'):
        reason = 'Employment not eligible'
    elif loans > 2:
        reason = 'Too many existing loans'
    else:
        if employment == 'self-employed' and income < 40000:
            reason = 'Self-employed income below minimum'
        else:
            return 'APPROVED', rate, product, 'All rules passed'
    return 'REJECTED', '-', '-', reason

APPLICANTS = [
 ('Arun',25,50000,10000,780,'salaried',1),
 ('Bala',-1,40000,5000,700,'salaried',0),
 ('Charan',30,0,0,720,'salaried',0),
 ('Divya',35,60000,10000,950,'salaried',0),
 ('Esha',20,45000,5000,700,'salaried',0),
 ('Farhan',40,50000,25000,710,'salaried',1),
 ('Gita',45,60000,10000,620,'salaried',0),
 ('Hari',32,35000,5000,710,'self-employed',0),
 ('Isha',28,55000,10000,730,'salaried',3),
 ('Jai',50,80000,15000,760,'self-employed',1),
]
EXPECTED = ['APPROVED','INVALID','INVALID','INVALID','REJECTED','REJECTED','REJECTED','REJECTED','REJECTED','APPROVED']

def main(limit: int = 2):
    approved: int = 0
    print(f"{'Name':12} {'Decision':12} {'Rate':8} {'Product':12} Reason")
    for name, *details in APPLICANTS:
        decision, rate, product, reason = assess(*details)
        print(f'{name:12} {decision:12} {rate:8} {product:12} {reason}')
        if decision == 'INVALID':
            continue
        if decision == 'APPROVED':
            approved += 1
            if approved >= limit:
                print(f'Daily approval limit reached: {approved}')
                break
    else:
        print(f'All applicants processed; limit not reached.')
    print(f'Approved: {approved}')

if __name__ == '__main__':
    for record, expected in zip(APPLICANTS, EXPECTED):
        assert assess(*record[1:])[0] == expected
    main()
    print(f'\nLoop-else demonstration:')
    main(10)
