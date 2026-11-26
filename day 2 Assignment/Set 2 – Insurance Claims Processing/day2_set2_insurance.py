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

def duplicates(claims):
    seen, result = {}, []
    for claim_id, policy, date in claims:
        key = (''.join(policy.casefold().split()), ''.join(date.casefold().split()))
        if key in seen: result.append((seen[key],claim_id))
        else: seen[key]=claim_id
    return result


def longest_run(values):
    left=0; best=(0,0)
    for right, value in enumerate(values):
        if value <= 100: left=right+1
        elif right+1-left > best[1]-best[0]: best=(left,right+1)
    return best


def merge(a,b):
    i=j=0; result=[]
    while i<len(a) and j<len(b):
        if a[i]<=b[j]: result.append(a[i]); i+=1
        else: result.append(b[j]); j+=1
    result.extend(a[i:]); result.extend(b[j:])
    return result


def main():
    print('SET 2 - INSURANCE CLAIMS PROCESSING')
    print('TASK 1: BST')
    tree=BST(); ids=[105,102,108,101,104,107,110,104]
    for x in ids: tree.insert(x)
    for order in ('inorder','preorder','postorder'): print(order,tree.traversal(order))
    print('Search 104:',tree.search(104),'Inorder returns sorted distinct IDs.')
    assert tree.traversal('inorder')==sorted(set(ids)) and not BST().search(1)
    assert BST().traversal('inorder')==[] and not tree.search(999)
    print('TASK 2: Duplicate claims')
    claims=[('C1','POL 123','2026-11-01'),('C2',' pol123 ','2026-11-01 '),('C3','POL123','2026-11-02'),('C4','POL123','2026-11-01')]
    print('Claims:',claims,'Duplicates:',duplicates(claims))
    assert duplicates(claims)==[('C1','C2'),('C1','C4')] and duplicates([])==[]
    print('Dictionary handles hash collisions by probing and checking key equality; normalization removes spaces and case differences.')
    print('TASK 3: Approval graph')
    graph={'registration':['assessment'],'assessment':['surveyor','settlement'],'surveyor':['settlement'],'settlement':[]}
    print(graph); path=shortest_path(graph,'registration','settlement'); print('BFS shortest path:',path)
    assert path==['registration','assessment','settlement'] and not has_cycle(graph)
    assert shortest_path({},'a','b') is None and not has_cycle({})
    graph['settlement']=['registration']; print('DFS loop:',has_cycle(graph)); assert has_cycle(graph)
    print('TASK 4: Sliding window')
    counts=[80,110,120,100,105,130,140,150,90]; a,b=longest_run(counts)
    print(counts,'Longest run:',b-a,'days; day numbers:',list(range(a+1,b+1)))
    assert (a,b)==(4,8) and longest_run([])==(0,0) and longest_run([100])==(0,0)
    print('TASK 5: Two-pointer merge')
    a=[101,103,105,105]; b=[102,105,109]; print(a,b,merge(a,b))
    assert merge(a,b)==sorted(a+b) and merge([],[])==[] and merge([],b)==b
    print('COMPLEXITY TABLE: Algorithm | Time | Auxiliary space')
    print('BST search/insert | O(h), balanced O(log n), worst O(n) | search O(1), insert O(h)')
    print('Traversal | O(n) | O(h) excluding output')
    print('Hash duplicate detection | expected O(n), worst O(n²) | O(n) (bounded key length)')
    print('BFS/DFS | O(V+E) | O(V)')
    print('Sliding window | O(n) | O(1)')
    print('Merge | O(n+m) | O(n+m) output')
    print('All tests passed, including empty input and duplicates')

if __name__=='__main__': main()
