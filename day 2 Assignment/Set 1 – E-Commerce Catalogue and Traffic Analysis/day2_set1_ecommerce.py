from collections import deque

class BST:
    def __init__(self):
        self.root = None

    def insert(self, key):
        def add(node):
            if node is None: return [key, None, None]
            if key < node[0]: node[1] = add(node[1])
            elif key > node[0]: node[2] = add(node[2])
            return node
        self.root = add(self.root)

    def search(self, key):
        node = self.root
        while node is not None:
            if key == node[0]: return True
            node = node[1 if key < node[0] else 2]
        return False

    def traversal(self, order):
        result = []
        def visit(node):
            if node is None: return
            if order == 'preorder': result.append(node[0])
            visit(node[1])
            if order == 'inorder': result.append(node[0])
            visit(node[2])
            if order == 'postorder': result.append(node[0])
        visit(self.root)
        return result

    def height(self):
        def h(node):
            return -1 if node is None else 1 + max(h(node[1]), h(node[2]))
        return h(self.root)


def shortest_path(graph, start, end):
    if start not in graph or end not in graph: return None
    queue = deque([start])
    parent = {start: None}
    while queue:
        u = queue.popleft()
        if u == end:
            path = []
            while u is not None:
                path.append(u)
                u = parent[u]
            return path[::-1]
        for v in graph[u]:
            if v not in parent:
                parent[v] = u
                queue.append(v)
    return None


def has_cycle(graph):
    colors = {}
    def visit(u):
        if colors.get(u) == 1: return True
        if colors.get(u) == 2: return False
        colors[u] = 1
        if any(visit(v) for v in graph.get(u, [])): return True
        colors[u] = 2
        return False
    return any(visit(u) for u in graph)


def max_window(values, k):
    if k <= 0 or k > len(values): return None
    total = best = sum(values[:k])
    start = 0
    for i in range(k, len(values)):
        total += values[i] - values[i-k]
        if total > best:
            best, start = total, i-k+1
    return start, start+k, best

from time import perf_counter
from random import Random

class HashTable:
    def __init__(self, capacity):
        self.buckets = [[] for _ in range(capacity)]
    def index(self, key):
        return hash(key) % len(self.buckets)
    def put(self, key, value):
        bucket = self.buckets[self.index(key)]
        for i, (k, v) in enumerate(bucket):
            if k == key:
                bucket[i] = (key, value)
                return
        bucket.append((key, value))
    def get(self, key):
        for k, v in self.buckets[self.index(key)]:
            if k == key: return v
        return None


def deployment_order(graph):
    # Edges point from service to prerequisite; DFS postorder deploys prerequisites first.
    if has_cycle(graph): raise ValueError('Circular dependency')
    seen, order = set(), []
    def visit(u):
        if u in seen: return
        seen.add(u)
        for v in graph.get(u, []): visit(v)
        order.append(u)
    for u in graph: visit(u)
    return order


def pairs(values, target):
    # Unique value pairs, including equal values if two occurrences exist.
    i, j, result = 0, len(values)-1, []
    while i < j:
        a, b = values[i], values[j]
        if a+b < target: i += 1
        elif a+b > target: j -= 1
        else:
            result.append((a,b))
            while i < j and values[i] == a: i += 1
            while i < j and values[j] == b: j -= 1
    return result


def main():
    print('SET 1 - E-COMMERCE CATALOGUE AND TRAFFIC ANALYSIS')
    print('TASK 1: BST')
    categories = ['Home','Books','Sports','Art','Fashion','Music','Toys','Beauty','Electronics','Garden','Kitchen','Office','Shoes','Travel','Video']
    tree = BST()
    for x in categories: tree.insert(x)
    for order in ('inorder','preorder','postorder'): print(order, tree.traversal(order))
    assert tree.traversal('inorder') == sorted(categories)
    print('Search Electronics:', tree.search('Electronics'))
    print('TASK 2: Hash table chaining')
    small = HashTable(3)
    first = 'SKU-0'
    second = next(f'SKU-{i}' for i in range(1,100) if small.index(f'SKU-{i}') == small.index(first))
    small.put(first, 1); small.put(second, 2)
    print('Collision:', first, second, 'bucket:', small.buckets[small.index(first)])
    assert small.get(first)==1 and small.get(second)==2
    keys = [f'SKU-{i:06d}' for i in range(100000)]
    table = HashTable(131071); builtin = {}
    for i,k in enumerate(keys): table.put(k,i); builtin[k]=i
    Random(42).shuffle(keys)
    for name, lookup in [('Chaining',table.get), ('Dictionary',builtin.get)]:
        start=perf_counter(); result=[lookup(k) for k in keys]; elapsed=perf_counter()-start
        assert result == [int(k.split('-')[1]) for k in keys]
        print(name, '100000 lookups:', elapsed, 'seconds')
    print('TASK 3: Deployment graph')
    graph={'cart':['pricing'], 'pricing':['inventory'], 'inventory':['database'], 'database':[], 'checkout':['cart','payment'], 'payment':['database']}
    order=deployment_order(graph); print(graph, order)
    assert all(order.index(v)<order.index(u) for u in graph for v in graph[u])
    graph['database']=['cart']; print('Circular dependency:',has_cycle(graph)); assert has_cycle(graph)
    try: deployment_order(graph)
    except ValueError as e: print(e)
    print('TASK 4: Sliding window')
    rng=Random(7); traffic=[rng.randint(10,100)+(200 if 720<=i<900 else 0) for i in range(1440)]
    start,end,total=max_window(traffic,180)
    print('Busiest window (minutes, end exclusive):',start,end,'requests:',total)
    assert total == max(sum(traffic[i:i+180]) for i in range(1261))
    print('TASK 5: Two pointers')
    values=[10,20,20,30,40,50,50,60,70,90]; result=pairs(values,100)
    print(values,'target 100:',result); assert result==[(10,90),(30,70),(40,60),(50,50)]
    print('DECISION TABLE: Problem | Pattern | Reason | Complexity')
    print('Categories | BST | Ordered traversal | search/insert O(h), traversal O(n)')
    print('SKU | Hash chaining/dict | Expected O(1) lookup, worst O(n)')
    print('Deployment | DFS | Dependency ordering and cycle detection | O(V+E)')
    print('Traffic | Sliding window | Reuse previous sum | O(n) time, O(1) extra space')
    print('Gift card | Two pointers | Sorted values | O(n) time, O(1) extra excluding output')
    print('All tests passed')

if __name__ == '__main__': main()
