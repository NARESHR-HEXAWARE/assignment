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

import re


def scan_lookup(scans):
    lookup={}; seen=set(); repeats=[]
    for tracking,hub in scans:
        lookup.setdefault(tracking,[]).append(hub)
        key=(tracking,hub)
        if key in seen: repeats.append(key)
        seen.add(key)
    return lookup,repeats


def reachable(graph,start):
    if start not in graph: return []
    seen=set(); order=[]
    def dfs(u):
        if u in seen: return
        seen.add(u); order.append(u)
        for v in graph[u]: dfs(v)
    dfs(start); return order


def palindrome(route):
    # Hub codes are alphanumeric tokens separated by non-alphanumeric characters.
    tokens=re.findall(r'[A-Za-z0-9]+',route.upper())
    i,j=0,len(tokens)-1
    while i<j:
        if tokens[i]!=tokens[j]: return False
        i+=1; j-=1
    return True


def main():
    print('SET 3 - LOGISTICS NETWORK AND DELIVERY WINDOWS')
    print('TASK 1: BST')
    codes=['H05','H02','H08','H01','H03','H06','H09','H04','H07','H10']
    tree=BST(); sorted_tree=BST()
    for code in codes: tree.insert(code)
    for code in sorted(codes): sorted_tree.insert(code)
    print('Insertion order:',codes,'Height (edges):',tree.height())
    print('Sorted insertion height:',sorted_tree.height(),'Search H07:',tree.search('H07'))
    assert tree.height()==3 and sorted_tree.height()==9 and tree.search('H07')
    print('Sorted input creates a chain; search can degrade from O(log n) in balanced trees to O(n).')
    print('TASK 2: Parcel hashing')
    scans=[('P001','H01'),('P002','H01'),('P001','H03'),('P001','H01'),('P002','H04'),('P002','H04')]
    lookup,repeats=scan_lookup(scans); print('Lookup:',lookup,'P001:',lookup.get('P001'),'Repeated scans:',repeats)
    assert repeats==[('P001','H01'),('P002','H04')]
    print('TASK 3: Ten-hub graph')
    graph={code:[] for code in codes}
    edges=[('H01','H02'),('H01','H03'),('H02','H04'),('H02','H05'),('H03','H06'),('H04','H07'),('H05','H08'),('H06','H08'),('H07','H09'),('H08','H10'),('H09','H10')]
    for a,b in edges: graph[a].append(b); graph[b].append(a)
    for u,neighbors in sorted(graph.items()): print(u,':',neighbors)
    path=shortest_path(graph,'H01','H10'); print('BFS path:',path,'Hops:',len(path)-1)
    order=reachable(graph,'H01'); print('DFS reachable:',order)
    assert len(path)-1==4 and set(order)==set(codes)
    print('TASK 4: Sliding window')
    counts=[12,18,15,20,25,40,55,80,90,110,120,130,125,100,90,75,65,50,45,35,30,25,20,15]
    a,b,total=max_window(counts,4); print('Hourly counts:',counts,'Best window:',a,b,'(end exclusive), average:',total/4)
    assert total==max(sum(counts[i:i+4]) for i in range(21))
    print('TASK 5: Two pointers')
    for route in ['H01 -> h02 / H03, h02 - h01','H01 -> H02 -> H03','H01','']:
        print(repr(route),palindrome(route))
    assert palindrome('H01 -> h02 / H01') and not palindrome('H01-H02')
    print('ALGORITHM CHOICES')
    print('BST: ordered hub codes, O(h) search/insert, O(n) storage; height O(n) time and O(h) stack.')
    print('Hash map/set: expected O(n) total scan processing, O(n) space; worst O(n²) with collisions.')
    print('BFS finds fewest hops in unweighted graph; DFS explores reachability. O(V+E) time, O(V) auxiliary space each.')
    print('Sliding window updates the sum in O(1) per hour; O(n) time, O(1) extra space.')
    print('Two pointers compare whole hub codes, ignoring case and separators; O(L) time and O(L) space for tokenization of L characters.')
    print('All tests passed')

if __name__=='__main__': main()
