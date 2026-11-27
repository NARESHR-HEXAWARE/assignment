from abc import ABC, abstractmethod
from enum import Enum
from dataclasses import dataclass

class VisitType(Enum):
    OUTPATIENT = 'Outpatient'
    INPATIENT = 'Inpatient'
    EMERGENCY = 'Emergency'

@dataclass(frozen=True)
class Patient:
    patient_id: str
    name: str

@dataclass(frozen=True)
class Doctor:
    doctor_id: str
    name: str
    department: str

class Visit(ABC):
    def __init__(self, patient, doctor, month, base_fee):
        if not patient.patient_id.strip() or base_fee < 0 or month not in (1, 2, 3):
            raise ValueError('Invalid patient ID, fee or reporting month')
        self.__patient = patient
        self.doctor = doctor
        self.month = month
        self.base_fee = base_fee

    @property
    def patient(self):
        return self.__patient

    @property
    def patient_id(self):
        return self.__patient.patient_id

    @abstractmethod
    def calculate_bill(self):
        pass

class OutPatientVisit(Visit):
    visit_type = VisitType.OUTPATIENT
    def calculate_bill(self):
        return self.base_fee

class InPatientVisit(Visit):
    visit_type = VisitType.INPATIENT
    def __init__(self, patient, doctor, month, base_fee, days, daily_charge):
        super().__init__(patient, doctor, month, base_fee)
        if not isinstance(days, int) or days <= 0 or daily_charge < 0:
            raise ValueError('Invalid inpatient charges')
        self.days = days
        self.daily_charge = daily_charge

    def calculate_bill(self):
        return self.base_fee + self.days * self.daily_charge

class EmergencyVisit(Visit):
    visit_type = VisitType.EMERGENCY
    def calculate_bill(self):
        return self.base_fee * 1.25  # Illustrative 25% surcharge


def main():
    doctors = [Doctor('D01', 'Dr. Ravi', 'General'), Doctor('D02', 'Dr. Priya', 'Cardiology')]
    patients = [Patient('P01', 'Arun'), Patient('P02', 'Bala'), Patient('P03', 'Charan')]
    visits = [OutPatientVisit(patients[0], doctors[0], 1, 500),
              InPatientVisit(patients[1], doctors[1], 2, 1000, 3, 2000),
              EmergencyVisit(patients[2], doctors[0], 3, 2000),
              OutPatientVisit(patients[1], doctors[1], 1, 800)]
    departments = list(dict.fromkeys(d.department for d in doctors))
    totals = [[0.0 for _ in range(3)] for _ in departments]
    print('HOSPITAL BILL SUMMARY')
    for visit in visits:
        bill = visit.calculate_bill()
        totals[departments.index(visit.doctor.department)][visit.month - 1] += bill
        print(f'{visit.patient_id} | {visit.patient.name} | {visit.doctor.name} | {visit.visit_type.value} | INR {bill:.2f}')
    print('\nDepartment totals: Jan, Feb, Mar')
    for department, row in zip(departments, totals):
        print(department, row, 'Total:', sum(row))
    print('Monthly totals:', [sum(col) for col in zip(*totals)])
    print('Grand total:', sum(map(sum, totals)))
    print('Incorrect inheritance: Visit should not inherit Patient or Doctor because a Visit is neither. Composition holds both objects instead.')

if __name__ == '__main__':
    main()
