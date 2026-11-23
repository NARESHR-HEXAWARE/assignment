"""Day 1 Set 3: Hospital Appointment Desk."""
import random,time,bisect
from datetime import datetime,timedelta

def linear_search(a,k):
    for r in a:
        if r['patientId']==k:return r
    return None

def binary_search(a,k):
    lo=0;hi=len(a)-1
    while lo<=hi:
        m=(lo+hi)//2
        if a[m]['patientId']==k:return a[m]
        if a[m]['patientId']<k:lo=m+1
        else:hi=m-1
    return None

def sort_key(r):return (-r['urgency'],r['arrival'])

def selection_sort(a):
    a=a[:];swaps=0
    for i in range(len(a)):
        m=i
        for j in range(i+1,len(a)):
            if sort_key(a[j])<sort_key(a[m]):m=j
        if i!=m:a[i],a[m]=a[m],a[i];swaps+=1
    return a,swaps

def quick_sort(a):
    a=a[:];swaps=0
    def sort(lo,hi):
        nonlocal swaps
        if lo>=hi:return
        pivot=sort_key(a[(lo+hi)//2]);i,j=lo,hi
        while i<=j:
            while sort_key(a[i])<pivot:i+=1
            while sort_key(a[j])>pivot:j-=1
            if i<=j:
                if i!=j:a[i],a[j]=a[j],a[i];swaps+=1
                i+=1;j-=1
        if lo<j:sort(lo,j)
        if i<hi:sort(i,hi)
    if a:sort(0,len(a)-1)
    return a,swaps

def double_bookings(appointments):
    seen=set();duplicates=[]
    for a in appointments:
        key=(a['patientId'],a['slot'])
        if key in seen:duplicates.append(a)
        else:seen.add(key)
    return duplicates

class Queue:
    def __init__(self):self.items=[];self.head=0
    def add(self,x):self.items.append(x)
    def next(self):
        if self.head==len(self.items):raise IndexError('empty')
        x=self.items[self.head];self.head+=1;return x
class Stack:
    def __init__(self):self.items=[]
    def push(self,x):self.items.append(x)
    def pop(self):return self.items.pop()

def max_appointments(intervals):
    # Weighted interval scheduling with every appointment valued at 1.
    # Intervals are (start_minute,end_minute); a non-overlap schedule is returned.
    a=sorted(intervals,key=lambda x:x[1]);ends=[x[1] for x in a];n=len(a)
    dp=[0]*(n+1);prev=[]
    for i,(s,e) in enumerate(a):
        p=bisect.bisect_right(ends,s,hi=i);prev.append(p)
        dp[i+1]=max(dp[i],dp[p]+1)
    chosen=[];i=n
    while i>0:
        if dp[prev[i-1]]+1>dp[i-1]:chosen.append(a[i-1]);i=prev[i-1]
        else:i-=1
    return list(reversed(chosen))

def greedy_earliest_finish(intervals):
    selected=[];end=-1
    for s,e in sorted(intervals,key=lambda r:r[1]):
        if s>=end:selected.append((s,e));end=e
    return selected

def main():
    rng=random.Random(31)
    patients=[{'patientId':i,'name':f'Patient {i}'} for i in range(100001,120001)]
    ids=rng.choices([r['patientId'] for r in patients],k=1000)
    t=time.perf_counter();[linear_search(patients,i) for i in ids];lt=time.perf_counter()-t
    t=time.perf_counter();[binary_search(patients,i) for i in ids];bt=time.perf_counter()-t
    print('SET 3 | 20,000 patients | 1,000 lookups | linear',round(lt,5),'s | binary',round(bt,5),'s')
    now=datetime(2026,10,14,8)
    appointments=[{'patientId':100001+i,'urgency':rng.randint(1,5),
                   'arrival':now+timedelta(minutes=rng.randint(0,180)), 'slot':f'S{i}'} for i in range(1000)]
    t=time.perf_counter();selection,ss=selection_sort(appointments);st=time.perf_counter()-t
    t=time.perf_counter();quick,qs=quick_sort(appointments);qt=time.perf_counter()-t
    assert list(map(sort_key,selection))==list(map(sort_key,quick))
    print('Sort | selection:',round(st,5),'s',ss,'swaps | quick:',round(qt,5),'s',qs,'swaps')
    test=appointments[:5]+[appointments[0].copy()]
    print('Double bookings in test:',len(double_bookings(test)))
    q=Queue();q.add('W001');q.add('W002');print('Next walk-in:',q.next())
    s=Stack();s.push('P001');s.push('P002');print('Recently viewed:',s.pop())
    intervals=[(0,50),(0,15),(15,35),(35,55),(55,75),(65,90),(75,95)]
    result=max_appointments(intervals);greedy=greedy_earliest_finish(intervals)
    assert len(result)==len(greedy)
    print('Max compatible appointments (DP):',len(result),result)
    print('Earliest-finish greedy:',len(greedy),greedy)
    print('For unweighted interval scheduling, earliest-finish greedy is also optimal.')
if __name__=='__main__':main()
