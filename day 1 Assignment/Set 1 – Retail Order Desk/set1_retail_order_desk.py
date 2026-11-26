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

import csv
from pathlib import Path
from datetime import datetime, timedelta
from decimal import Decimal
from collections import deque

def load_orders(path):
    if not path.exists():
        rng=Random(42); start=datetime(2026,1,1)
        with path.open('w',newline='') as f:
            w=csv.writer(f); w.writerow(['orderId','customerId','amount','createdAt'])
            for i in range(1,50001):
                customer, amount, date = rng.randint(1,2000), rng.randint(1,5000), start+timedelta(seconds=i)
                if i==1: first=(customer,amount,date)
                if i==2: customer,amount,date=first
                w.writerow([i,customer,amount,date.isoformat()])
    with path.open(newline='') as f:
        return [(int(r['orderId']),r['customerId'],Decimal(r['amount']),datetime.fromisoformat(r['createdAt'])) for r in csv.DictReader(f)]

def bubble_sort(rows,key,trace=False):
    a=rows[:]
    for i in range(len(a)-1):
        changed=False
        for j in range(len(a)-1-i):
            if key(a[j])>key(a[j+1]): a[j],a[j+1]=a[j+1],a[j]; changed=True
        if trace and i<3: print('Pass',i+1,a)
        if not changed: break
    return a

def duplicates(rows):
    seen={}; out=[]
    for oid,cid,amount,date in rows:
        k=(cid,amount,date.replace(second=0,microsecond=0))
        if k in seen: out.append((seen[k],oid))
        else: seen[k]=oid
    return out

def greedy(amount,coins):
    result=[]
    for c in sorted(coins,reverse=True):
        n,amount=divmod(amount,c); result.extend([c]*n)
    return result if amount==0 else None

def coin_dp(amount,coins):
    dp=[0]+[float('inf')]*amount; prev=[0]*(amount+1)
    for x in range(1,amount+1):
        for c in coins:
            if c<=x and dp[x-c]+1<dp[x]: dp[x]=dp[x-c]+1; prev[x]=c
    if not prev[amount] and amount: return None
    out=[]
    while amount: out.append(prev[amount]); amount-=prev[amount]
    return out

def main():
    rows=load_orders(Path(__file__).with_name('orders.csv'))
    if len(rows)<50000: raise ValueError('orders.csv needs at least 50,000 rows')
    rows=rows[:50000]; ordered=sorted(rows,key=lambda r:r[0]); targets=[r[0] for r in Random(7).sample(rows,100)]
    print('TASK 1: Search on 50,000 orders; 100 identical targets')
    for fn,data in [(linear_search,rows),(binary_search,ordered)]:
        result,t=timed(lambda:[fn(data,x,lambda r:r[0]) for x in targets]); assert all(r[0] is not None for r in result)
        print(fn.__name__,t,'seconds; mean comparisons',sum(r[1] for r in result)/len(result))
    print('Binary search halves the sorted range; sorting preprocessing excluded.')
    print('TASK 2: Bubble trace (amounts descending)'); bubble_sort([40,10,30,20,50],lambda x:-x,True)
    sample=rows[:10000]; key=lambda r:-r[2]; expected=sorted(sample,key=key)
    for fn in (bubble_sort,merge_sort,lambda a,k:sorted(a,key=k)):
        result,t=timed(fn,sample,key); assert result==expected; print(fn.__name__,t,'seconds')
    print('TASK 3: Duplicate pairs',duplicates(rows)[:10], 'total',len(duplicates(rows)))
    print('TASK 4: Undo and dispatch')
    s=Stack(); q=Queue(); edits=[('order 1',100),('order 1',200)]; dispatch=[1,2,3]
    for e in edits:s.push(e)
    for x in dispatch:q.enqueue(x)
    print('Custom undo restores',s.pop(),'; dispatch',q.dequeue())
    s2=edits[:]; q2=deque(dispatch); print('Built-in undo',s2.pop(),'; dispatch',q2.popleft())
    print('Linked structures and list stack/deque queue have O(1) operations (list push amortized).')
    print('TASK 5: Refund 786',greedy(786,[500,200,100,50,20,10,5,2,1]))
    print('Greedy failure for 6 with [1,3,4]:',greedy(6,[1,3,4]),'DP:',coin_dp(6,[1,3,4]))
    print('Complexity: linear O(n)/O(1) space; binary O(log n)/O(1); bubble best O(n), worst O(n²), O(n) copy; merge O(n log n)/O(n); hash duplicates expected O(n)/O(n); stack/queue O(1) per operation, O(n) storage; greedy O(k log k + output); DP O(amount*k)/O(amount).')
if __name__=='__main__': main()
