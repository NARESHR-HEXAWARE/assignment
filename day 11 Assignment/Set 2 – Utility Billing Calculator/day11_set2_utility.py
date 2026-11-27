# Illustrative progressive slab rates and fixed charges in INR.
from math import isfinite

def energy_charge(units: float) -> float:
    if not isfinite(units) or units < 0:
        raise ValueError('Consumption must be finite and non-negative')
    if units <= 100:
        return units * 2
    elif units <= 200:
        return 200 + (units - 100) * 3
    elif units <= 400:
        return 500 + (units - 200) * 5
    else:
        return 1500 + (units - 400) * 7

def bill(units: float, category: str, late: bool = False, online: bool = False) -> float:
    match category.lower():
        case 'domestic': fixed = 50
        case 'commercial': fixed = 150
        case 'industrial': fixed = 300
        case _: raise ValueError('Unknown consumer category')
    subtotal = energy_charge(units) + fixed
    surcharge = subtotal * 0.05 if late else 0
    rebate = subtotal * 0.02 if online else 0
    # Multiplication precedes addition; both adjustments use the subtotal.
    return subtotal + surcharge - rebate

def main():
    print(f"{'Month':<10}{'Units':>10}{'Bill (INR)':>15}")
    for month, units in enumerate([90,110,150,180,220,260,310,420,390,200,100,80], 1):
        print(f'{month:<10}{units:>10.2f}{bill(units,"domestic"):>15.2f}')
    print('\nBoundary tests:')
    for units, expected in zip([100,101,200,201,400,401],[200,203,500,505,1500,1507]):
        assert energy_charge(units) == expected
        print(f'{units:>5} units: {bill(units,"domestic"):>10.2f}')
    while True:
        try:
            raw = input('Consumption (q to quit): ').strip()
            if raw.lower() == 'q':
                break
            units = float(raw)
            category = input('Category: ').strip()
            late = input('Late payment (y/n): ').strip().lower()
            online = input('Online payment (y/n): ').strip().lower()
            if late not in ('y','n') or online not in ('y','n'):
                raise ValueError('Enter y or n')
            print(f'{"Total bill (INR)":<22}{bill(units, category, late=="y", online=="y"):>12.2f}')
        except ValueError as exc:
            print(f'Invalid input: {exc}')
        except (EOFError, KeyboardInterrupt):
            break

if __name__ == '__main__':
    main()
