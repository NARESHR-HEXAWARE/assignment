"""Day 1 Set 1: Retail Order Desk. Python 3.10+; standard library only."""
import csv, random, time
from datetime import datetime, timedelta
from collections import deque
from pathlib import Path

BASE = Path(__file__).parent

def make_orders(path=BASE/'orders.csv', n=50000):
    if path.exists(): return
    rng = random.Random(17)
    start = datetime(2026, 10, 14, 8)
    with path.open('w', newline='') as f:
        writer = csv.writer(f); writer.writerow(['orderId','customerId','amount','createdAt'])
        for i in range(n):
            writer.writerow([100000+i, rng.randint(1,8000), rng.randint(100,25000)/100,
                             (start+timedelta(seconds=i)).isoformat()])

def read_orders(path=BASE/'orders.csv'):
    with path.open(newline='') as f:
        return [dict(orderId=int(r['orderId']), customerId=int(r['customerId']),
                     amount=float(r['amount']), createdAt=r['createdAt']) for r in csv.DictReader(f)]

def linear_search(rows, key):
    for row in rows:
        if row['orderId']==key: return row
    return None

def binary_search(rows, key):
    lo,hi=0,len(rows)-1
    while lo<=hi:
        mid=(lo+hi)//2
        if rows[mid]['orderId']==key:return rows[mid]
        if rows[mid]['orderId']<key:lo=mid+1
        else:hi=mid-1
    return None

def insertion_sort_desc(rows):
    a=rows.copy()
    for i in range(1,len(a)):
        key=a[i];j=i-1
        while j>=0 and a[j]['amount']<key['amount']:
            a[j+1]=a[j];j-=1
        a[j+1]=key
    return a

def merge_sort_desc(a):
    if len(a)<=1:return a[:]
    m=len(a)//2;l=merge_sort_desc(a[:m]);r=merge_sort_desc(a[m:]);out=[];i=j=0
    while i<len(l) and j<len(r):
        if l[i]['amount']>=r[j]['amount']:out.append(l[i]);i+=1
        else:out.append(r[j]);j+=1
    return out+l[i:]+r[j:]

def insertion_first_three_passes(rows):
    a=rows[:]
    for i in range(1,min(4,len(a))):
        key=a[i];j=i-1
        while j>=0 and a[j]['amount']<key['amount']:a[j+1]=a[j];j-=1
        a[j+1]=key
        print('Insertion pass',i,':',[v['amount'] for v in a])

def duplicates(rows):
    seen=set();out=[]
    for r in rows:
        key=(r['customerId'],r['amount'],r['createdAt'][:16])
        if key in seen:out.append(r)
        else:seen.add(key)
    return out

class Stack:
    def __init__(self):self.a=[]
    def push(self,x):self.a.append(x)
    def pop(self):return self.a.pop()
class Queue:
    def __init__(self):self.a=[];self.head=0
    def enqueue(self,x):self.a.append(x)
    def dequeue(self):
        if self.head>=len(self.a):raise IndexError('empty queue')
        x=self.a[self.head];self.head+=1;return x

def greedy(amount, denoms):
    out=[]
    for d in sorted(denoms, reverse=True):
        q,amount=divmod(amount,d);out.extend([d]*q)
    return out if amount==0 else None

def min_coins_dp(amount, denoms):
    dp=[float('inf')]*(amount+1);choice=[0]*(amount+1);dp[0]=0
    for v in range(1,amount+1):
        for d in denoms:
            if d<=v and dp[v-d]+1<dp[v]:dp[v]=dp[v-d]+1;choice[v]=d
    if dp[amount]==float('inf'):return None
    result=[]
    while amount:result.append(choice[amount]);amount-=choice[amount]
    return result

def timed(f):
    t=time.perf_counter();res=f();return res,time.perf_counter()-t

def main():
    make_orders();rows=read_orders();assert len(rows)==50000
    keys=[rows[i]['orderId'] for i in range(0,50000,997)]
    _,linear_t=timed(lambda:[linear_search(rows,k) for k in keys])
    _,binary_t=timed(lambda:[binary_search(rows,k) for k in keys])
    print('SET 1 | 50,000 orders |',len(keys),'lookups | linear',round(linear_t,5),'s | binary',round(binary_t,5),'s')
    sample=[{'amount':x} for x in [20,60,10,50,30]]
    insertion_first_three_passes(sample)
    sub=rows[:10000]
    inserted,ti=timed(lambda:insertion_sort_desc(sub))
    merged,tm=timed(lambda:merge_sort_desc(sub))
    builtin,tb=timed(lambda:sorted(sub,key=lambda r:r['amount'],reverse=True))
    assert [r['amount'] for r in inserted]==[r['amount'] for r in merged]==[r['amount'] for r in builtin]
    print('10,000-row descending sorts (s): insertion',round(ti,4),'merge',round(tm,4),'built-in',round(tb,4))
    augmented=rows[:8]+[dict(rows[0],orderId=999999)]
    print('Duplicate submissions in test:',len(duplicates(augmented)))
    stack=Stack();stack.push('edit amount');stack.push('edit address');print('Undo:',stack.pop())
    queue=Queue();queue.enqueue('order A');queue.enqueue('order B');print('Dispatch:',queue.dequeue())
    ds=deque(['order A','order B']);print('Built-in deque dispatch:',ds.popleft())
    print('Built-in list undo:', ['edit A','edit B'].pop())
    print('Greedy [1,3,4] for 6:',greedy(6,[1,3,4]),'optimal DP:',min_coins_dp(6,[1,3,4]))
    print('Standard refund [1,2,5,10,20,50,100] for 186:',greedy(186,[1,2,5,10,20,50,100]))
if __name__=='__main__':main()
