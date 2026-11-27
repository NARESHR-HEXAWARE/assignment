# Illustrative classroom premium rules, not real insurance underwriting.
from math import isfinite

def premium(age: int, smoker: bool, weight: float, height: float, term: int):
    # Comparisons bind before logical and/or; not applies to the parenthesized range.
    if not (18 <= age <= 65 and 5 <= term <= 30) or not all(map(isfinite,(weight,height))) or weight <= 0 or height <= 0:
        raise ValueError('Ineligible age/term or invalid measurements')
    # Exponentiation precedes division.
    bmi = weight / height ** 2
    if bmi < 25:
        if bmi < 18.5:
            category, loading = 'Underweight', 0.10
        else:
            category, loading = 'Normal', 0.0
    else:
        if bmi < 30:
            category, loading = 'Overweight', 0.15
        else:
            category, loading = 'Obese', 0.30
    match (age, term):
        case x if x[0] < 30 and x[1] <= 15: base = 4000
        case x if x[0] < 30: base = 5000
        case x if x[0] < 50 and x[1] <= 15: base = 6000
        case x if x[0] < 50: base = 7500
        case x if x[1] <= 15: base = 10000
        case _: base = 12000
    smoker_loading = 0.25 if smoker else 0.0
    # Parentheses are evaluated first, then multiplication; loadings are additive.
    final = base * (1 + loading + smoker_loading)
    return bmi, category, base, final

APPLICANTS = [
 ('Arun',24,False,52,1.75,10), ('Bala',29,True,70,1.75,20),
 ('Charan',35,False,82,1.75,15), ('Divya',42,True,95,1.65,20),
 ('Esha',50,False,65,1.65,10), ('Farhan',60,True,80,1.70,25),
 ('Gita',18,False,60,1.70,5), ('Hari',65,False,70,1.70,30),
]

def validate_batch(records):
    for name, *details in records:
        try:
            premium(*details)
        except ValueError as exc:
            print(f'Batch stopped at {name}: {exc}')
            break
    else:
        print('All applicants in batch are valid.')

def main():
    print(f"{'Name':12}{'BMI':>7} {'Band':15}{'Base':>10}{'Premium':>12}")
    for name, *details in APPLICANTS:
        bmi, category, base, total = premium(*details)
        print(f'{name:12}{bmi:7.2f} {category:15}{base:10.2f}{total:12.2f}')
    validate_batch(APPLICANTS)
    validate_batch(APPLICANTS + [('Invalid',17,False,60,1.7,10)])
    for raw in ('abc',''):
        try:
            print(int(raw))
        except ValueError as exc:
            # int cannot parse either string; the interpreter raises ValueError.
            print(f'Conversion of {raw!r} handled: {type(exc).__name__}: {exc}')
    assert premium(24,False,70,1.75,10)[-1] == 4000

if __name__ == '__main__':
    main()
