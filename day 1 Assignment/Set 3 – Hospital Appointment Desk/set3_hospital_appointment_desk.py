from time import perf_counter
from random import Random
from bisect import bisect_right

class Node:
    def __init__(self, value):
        self.value, self.next = value, None

class Stack:
    def __init__(self): self.top = None
    def push(self, value):
        node = Node(value); node.next = self.top; self.top = node
    def pop(self):
        if self.top is None: raise IndexError('empty stack')
        value = self.top.value; self.top = self.top.next; return value

class Queue:
    def __init__(self): self.head = self.tail = None
    def enqueue(self, value):
        node = Node(value)
        if self.tail: self.tail.next = node
        else: self.head = node
        self.tail = node
    def dequeue(self):
        if self.head is None: raise IndexError('empty queue')
        value = self.head.value; self.head = self.head.next
        if self.head is None: self.tail = None
        return value

def linear_search(rows, target, key=lambda x:x):
    for count, row in enumerate(rows, 1):
        if key(row) == target: return row, count
    return None, len(rows)

def binary_search(rows, target, key=lambda x:x):
    lo, hi, count = 0, len(rows)-1, 0
    while lo <= hi:
        mid = (lo+hi)//2; value = key(rows[mid]); count += 1
        if value == target: return rows[mid], count
        if value < target: lo = mid+1
        else: hi = mid-1
    return None, count

def merge_sort(rows, key):
    if len(rows) <= 1: return rows[:]
    mid = len(rows)//2
    a,b = merge_sort(rows[:mid],key), merge_sort(rows[mid:],key)
    out=[]; i=j=0
    while i<len(a) and j<len(b):
        if key(a[i]) <= key(b[j]): out.append(a[i]); i+=1
        else: out.append(b[j]); j+=1
    return out+a[i:]+b[j:]

def timed(fn, *args):
    start=perf_counter(); result=fn(*args)
    return result, perf_counter()-start

def selection_sort(rows,key,trace=False):
    a=rows[:]; swaps=0
    for i in range(len(a)-1):
        m=i
        for j in range(i+1,len(a)):
            if key(a[j])<key(a[m]):m=j
        if m!=i:a[i],a[m]=a[m],a[i]; swaps+=1
        if trace:print('Pass',i+1,a)
    return a,swaps

def quick_sort(rows,key):
    a=rows[:]; swaps=0; rng=Random(9); pending=[(0,len(a)-1)]
    def swap(i,j):
        nonlocal swaps
        if i!=j:a[i],a[j]=a[j],a[i]; swaps+=1
    while pending:
        lo,hi=pending.pop()
        if lo>=hi:continue
        pivot=key(a[rng.randint(lo,hi)]); lt=i=lo; gt=hi
        while i<=gt:
            k=key(a[i])
            if k<pivot:swap(lt,i); lt+=1;i+=1
            elif k>pivot:swap(i,gt);gt-=1
            else:i+=1
        pending.extend([(lo,lt-1),(gt+1,hi)])
    return a,swaps

def double_bookings(rows):
    seen=set(); out=[]
    for patient,slot in rows:
        k=(patient,slot)
        if k in seen:out.append(k)
        else:seen.add(k)
    return out

def schedule_dp(slots):
    # Unweighted interval scheduling, half-open intervals [start,end).
    a=sorted(slots,key=lambda s:s[1]); ends=[s[1] for s in a]; n=len(a)
    dp=[0]*(n+1); prev=[0]*n
    for i,(start,end) in enumerate(a):
        p=bisect_right(ends,start,0,i); prev[i]=p
        dp[i+1]=max(dp[i],1+dp[p])
    chosen=[]; i=n
    while i:
        if 1+dp[prev[i-1]]>dp[i-1]:chosen.append(a[i-1]);i=prev[i-1]
        else:i-=1
    return chosen[::-1]

def schedule_greedy(slots):
    chosen=[]; end=float('-inf')
    for s,e in sorted(slots,key=lambda x:x[1]):
        if s>=end:chosen.append((s,e));end=e
    return chosen

def main():
    rng=Random(42); patients=[(i,f'Patient {i}') for i in range(1,20001)]; targets=[rng.randint(1,20000) for _ in range(1000)]
    print('TASK 1: 1000 lookups on 20,000 patients')
    for fn in (linear_search,binary_search):
        result,t=timed(lambda:[fn(patients,x,lambda r:r[0]) for x in targets]); assert all(r[0] for r in result); print(fn.__name__,t,'seconds')
    print('Binary search halves the sorted range; linear scans it.')
    print('TASK 2: Urgency 1 is highest; arrival time breaks ties')
    key=lambda r:(r[1],r[2]); sample=[('A',3,10),('B',1,15),('C',1,5),('D',2,3)]
    selection_sort(sample,key,True)
    rows=[(i,rng.randint(1,5),rng.randint(0,480)) for i in range(2000)]
    for fn in (selection_sort,quick_sort):
        (result,swaps),t=timed(fn,rows,key); assert list(map(key,result))==sorted(map(key,rows)); print(fn.__name__,swaps,'swaps',t,'seconds')
    print('TASK 3:',double_bookings([(1,'09:00'),(2,'09:00'),(1,'09:00'),(1,'10:00')]))
    print('Hash set expected O(n) total, versus repeated list scans O(n²).')
    print('TASK 4: Token queue and recent patient stack'); q=Queue(); s=Stack()
    for i in [101,102,103]:q.enqueue(i);s.push(i)
    print('Next token',q.dequeue(),'Most recent patient',s.pop())
    print('TASK 5: Shift 0–480 minutes; overlapping slots of varying lengths')
    slots=[(0,120),(0,30),(30,80),(60,150),(80,120),(120,180),(150,210),(180,240),(240,480),(240,300),(300,360),(360,480)]
    dp=schedule_dp(slots); greedy=schedule_greedy(slots); assert len(dp)==len(greedy)
    print('DP',len(dp),dp,'Greedy earliest finish',len(greedy),greedy)
    print('Both are optimal for maximum count of fixed, unweighted intervals; DP also supports extensions to weighted scheduling.')
    print('Complexities: linear O(n), binary O(log n), both O(1) space; selection O(n²)/O(n) copy; quicksort expected O(n log n), worst O(n²), O(n) copy plus pending stack; hash O(n) expected time/space; linked stack/queue O(1) operations; DP O(n log n)/O(n); greedy O(n log n)/O(n) including sorting and output.')
if __name__=='__main__':main()
