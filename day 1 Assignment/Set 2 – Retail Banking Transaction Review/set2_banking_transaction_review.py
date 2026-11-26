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

def insertion_sort(rows,key):
    a=rows[:]
    for i in range(1,len(a)):
        x=a[i]; j=i-1
        while j>=0 and key(a[j])>key(x): a[j+1]=a[j]; j-=1
        a[j+1]=x
    return a

def duplicate_postings(rows):
    # (id, account, amount, merchant, timestamp in seconds)
    last={}; out=[]
    for row in sorted(rows,key=lambda r:r[4]):
        oid,account,amount,merchant,t=row; k=(account,amount,merchant)
        if k in last and t-last[k][4]<=60: out.append((last[k][0],oid))
        last[k]=row
    return out

def divide_minmax(a,lo,hi):
    if lo==hi:return a[lo],a[lo],0
    if hi==lo+1:return (a[lo],a[hi],1) if a[lo]<=a[hi] else (a[hi],a[lo],1)
    mid=(lo+hi)//2
    x,y,c=divide_minmax(a,lo,mid); p,q,d=divide_minmax(a,mid+1,hi)
    return min(x,p),max(y,q),c+d+2

def brute_minmax(a):
    low=high=a[0]; c=0
    for x in a[1:]:
        if x<low:low=x
        if x>high:high=x
        c+=2
    return low,high,c

def main():
    ids=list(range(1,100001))
    print('TASK 1: Exact successful-search comparison counts (one key probe = one comparison)')
    counts=[binary_search(ids,x)[1] for x in ids]
    print('Binary best/average/worst',min(counts),sum(counts)/len(ids),max(counts))
    # Linear successful search counts equal the 1-based position; avoid 5 billion probes.
    print('Linear best/average/worst',linear_search(ids,1)[1],(len(ids)+1)/2,linear_search(ids,ids[-1])[1])
    print('TASK 2: Stable statement sorting')
    rows=[('T1','A',500,'Shop',120),('T2','A',100,'Cafe',60),('T3','A',500,'Shop',120),('T4','A',500,'Shop',179),('T5','A',500,'Shop',241)]
    key=lambda r:r[4]; print('Input',rows)
    for fn in (insertion_sort,merge_sort):
        result,t=timed(fn,rows,key); print(fn.__name__,result,t); assert result==sorted(rows,key=key)
    print('T1 stays before T3 at the same timestamp, preserving original posting order.')
    print('TASK 3: Duplicate postings',duplicate_postings(rows)); assert duplicate_postings(rows)==[('T1','T3'),('T3','T4')]
    print('Hash map remembers latest posting per account/amount/merchant; sorting handles unsorted input.')
    print('TASK 4: Manual review FIFO and adjustments LIFO'); q=Queue(); s=Stack()
    for x in ['T1','T2','T3']:q.enqueue(x)
    for x in [100,-50,25]:s.push(x)
    print('Review',q.dequeue(),q.dequeue(),'Reverse adjustment',-s.pop())
    print('TASK 5: Min/max'); rng=Random(42); amounts=[rng.randint(1,100000) for _ in ids]
    for fn in (lambda a:divide_minmax(a,0,len(a)-1),brute_minmax):
        result,t=timed(fn,amounts); assert result[:2]==(min(amounts),max(amounts)); print(result,'seconds',t)
    print('Complexity table: algorithm | best | average | worst | auxiliary space')
    for line in ['Linear | 1 | n | n | 1','Binary | 1 | log n | log n | 1','Insertion | n | n² | n² | n (copy)','Merge | n log n | n log n | n log n | n','Duplicate detection incl. sorting | n | n log n | n² (pathological hashing) | n','Stack/queue operation | 1 | 1 | 1 | n total','Divide min/max | n | n | n | log n','Brute min/max | n | n | n | n (slice)']:print(line)
    print('Binary uses sorted IDs; stable sorts preserve ties; hash avoids repeated scans; linked queue/stack preserve FIFO/LIFO; divide-and-conquer reduces comparisons.')
if __name__=='__main__':main()
