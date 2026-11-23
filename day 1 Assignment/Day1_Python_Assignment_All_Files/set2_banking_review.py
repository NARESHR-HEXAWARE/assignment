"""Day 1 Set 2: Retail Banking Transaction Review."""
import random,time
from datetime import datetime,timedelta

def linear(a,target):
    for n,x in enumerate(a,1):
        if x==target:return n
    return len(a)
def binary(a,target):
    lo,hi=0,len(a)-1;count=0
    while lo<=hi:
        m=(lo+hi)//2;count+=1
        if a[m]==target:return count
        if a[m]<target:lo=m+1
        else:hi=m-1
    return count

def insertion_sort(a):
    a=a[:]
    for i in range(1,len(a)):
        x=a[i];j=i-1
        while j>=0 and a[j]['postedAt']>x['postedAt']:a[j+1]=a[j];j-=1
        a[j+1]=x
    return a

def merge_sort(a):
    if len(a)<2:return a[:]
    m=len(a)//2;left=merge_sort(a[:m]);right=merge_sort(a[m:]);i=j=0;out=[]
    while i<len(left) and j<len(right):
        if left[i]['postedAt']<=right[j]['postedAt']:out.append(left[i]);i+=1
        else:out.append(right[j]);j+=1
    return out+left[i:]+right[j:]

def duplicate_postings(rows):
    # Hold last timestamps for each key; dates are sorted ascending.
    last={};found=[]
    for r in sorted(rows,key=lambda x:x['postedAt']):
        k=(r['account'],r['amount'],r['merchant'])
        if k in last and (r['postedAt']-last[k]).total_seconds()<=60:found.append(r)
        last[k]=r['postedAt']
    return found

class Queue:
    def __init__(self):self.data=[];self.head=0
    def add(self,v):self.data.append(v)
    def remove(self):
        if self.head==len(self.data):raise IndexError('empty')
        v=self.data[self.head];self.head+=1;return v
class Stack:
    def __init__(self):self.data=[]
    def push(self,v):self.data.append(v)
    def pop(self):return self.data.pop()

def divide_min_max(a):
    if len(a)==1:return a[0],a[0]
    if len(a)==2:return (min(a),max(a))
    mid=len(a)//2;mn1,mx1=divide_min_max(a[:mid]);mn2,mx2=divide_min_max(a[mid:])
    return min(mn1,mn2),max(mx1,mx2)

def main():
    ids=list(range(100000,200000))
    best=ids[(len(ids)-1)//2];worst=ids[-1]
    rng=random.Random(12);sample=rng.sample(ids,1000)
    print('SET 2 | 100,000 sorted transaction IDs')
    for label,target in [('best binary',best),('last ID',worst)]:
        print(label,'binary comparisons:',binary(ids,target),'linear comparisons:',linear(ids,target))
    print('Sample average comparisons | binary:',round(sum(binary(ids,k) for k in sample)/len(sample),2),
          '| linear:',round(sum(linear(ids,k) for k in sample)/len(sample),2))
    now=datetime(2026,10,14,10)
    statement=[{'id':x,'postedAt':now+timedelta(minutes=m)} for x,m in [(1,2),(2,1),(3,1),(4,3)]]
    print('Insertion sorted IDs:',[r['id'] for r in insertion_sort(statement)])
    print('Merge sorted IDs:',[r['id'] for r in merge_sort(statement)])
    rows=[{'account':'A1','amount':125.00,'merchant':'Shop', 'postedAt':now},
          {'account':'A1','amount':125.00,'merchant':'Shop', 'postedAt':now+timedelta(seconds=30)},
          {'account':'A1','amount':125.00,'merchant':'Shop', 'postedAt':now+timedelta(seconds=120)}]
    print('Duplicates within 60 seconds:',len(duplicate_postings(rows)))
    q=Queue();q.add('review 1');q.add('review 2');print('Next review:',q.remove())
    s=Stack();s.push('adjustment 1');s.push('adjustment 2');print('Reverse:',s.pop())
    amounts=[round(rng.uniform(-1000,10000),2) for _ in range(10000)]
    t=time.perf_counter();pair=divide_min_max(amounts);dt=time.perf_counter()-t
    t=time.perf_counter();scan=(min(amounts),max(amounts));st=time.perf_counter()-t
    assert pair==scan
    print('Divide-conquer min,max:',pair,'time:',round(dt,6),'s')
    print('Brute scan min,max:',scan,'time:',round(st,6),'s')
if __name__=='__main__':main()
