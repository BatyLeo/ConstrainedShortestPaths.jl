# Mathematical background

This page explains the mathematical framework used by `ConstrainedShortestPath.jl`, and its application to a few examples It's simplified version of the framework from [Parmentier 2017](https://arxiv.org/abs/1504.07880), retricted to acyclic graphs.

## Generalized constrained shortest path: problem formulation

Let ``D = (V, A)`` be an acyclic digraph. Let ``o, d`` two vertices, and ``\mathcal{P}\in\mathcal{P}_{od}`` a set of ``o-d`` path in ``D``. We want to find a path ``P^\star \in\mathcal{P}`` minimizing a given cost function ``P\mapsto C(P)``:
```math
\min_{P\in\mathcal{P}}C(P)
```

### Setting

Before describing the details of the algorithms, we must first define some modeling elements specific to the treated problem.

1. We define the two following sets:
    - Set of **forward resources** ``Q^F``, provided with a partial order ``\leq^F``.
    - Set of **backward resources** ``Q^B``, provided with a partial order ``\leq^B``.
    ``(Q^F, \leq^F)`` and ``(Q^B, \leq^B)`` should be *lattices*: a partially ordered set ``(S,\leq)`` is a *lattice* if any pair ``s, s'\in S``, admits a greatest lower bound ``s\wedge s'`` (i.e. ``\forall b\in S,\, (b \leq s \text{ and } b\leq s') \implies b\leq s\wedge s'``)
2. For every arc ``a\in A``, we define two functions:
    - A **forward extension function** : ``f^F_a:Q^F \to Q^F``, increasing
    - A **backward extension function** : ``f^B_a : Q^B \to Q^B``, increasing
3. We also define:
    - A **cost function** : ``c:Q^F\times Q^B \to \mathbb{R}\cup\{+\infty\}``, increasing
    - Resources corresponding to vertices ``o`` an ``d``: ``q^F_o\in Q^F``, ``q^B_d\in Q^B`` 

All these new theoretical elements should be connected to the initial problem formulation by following one of these (equivalent) properties:
- For all ``o-d`` path ``P = (o=v_0, a_1, v_1, \dots, a_k, v_k=d)``, we have :
  ```math
  \forall i, i'\in [k],\, c(f^F_i \circ f^F_{i-1}\circ\dots\circ f^F_1(q^F_o), f^B_{i+1} \circ f^B_{i+2}\circ\dots\circ f^B_k(q^B_d)) = C(P)\in\mathbb{R}\cup\{+\infty\}
  ```
- For all ``o-d`` path ``P`` and every decomposition of ``P`` as ``(R_1, R_2)``, we have ``C(P)=c(q^F_{R_1}, q^B_{R_2})``, with:
    - For all ``o-v`` path ``R_1 = (o=v_0, a_1, v_1, \dots, a_i, v_i=v)``:
  ```math
  q^F_{R_1} = f^F_{a_i} \circ f^F_{a_{i-1}}\circ\dots \circ f^F_{a_1}(q^F_o)
  ```
  - For all ``v-d`` path ``R_2 = (v=v_0, a_1, v_1, \dots, a_j, v_j=d)``:
  ```math
  q^B_{R_2} = f^B_{a_1} \circ f^B_{a_{2}}\circ\dots \circ f^B_{a_j}(q^B_d)
  ```

For examples of resources sets, extension and cost functions, checkout the [Examples](@ref) section.

---

## Algorithms

We first assume that we have accesss to a lower bound ``b^B_v\in Q^B`` for every vertex ``v``, such that ``b^B_v\leq^B q^B_R`` for all ``v-d`` path ``R``.
- Lemma 1 (**Cut using bounds**) : let ``R_1`` an ``o-v`` path. Then :
  ```math
  \forall P = (R_1, R_2)\in \mathcal{P}_{od},\, c(q^F_{R_1}, b^B_v)\leq C(P)
  ```
- Lemma 2 (**Dominance**) : if ``q^F_{R_1} \leq^F q^F_{R'_1}``, then for all ``R_2`` :
  ```math
  c(q^F_{R_1}, q^B_{R_2})\leq c(q^F_{R'_1}, q^B_{R_2})
  ```
  i.e. ``C(P) \leq C(P')`` (``P=(R_1, R_2),\, P'=(R'_1, R_2)``)

### Generalized ``A^\star``
- Initialization :
  - ``L \leftarrow \{\text{Empty path in }o\}``: partial paths to process
  - ``M_v \leftarrow \{ q_o^F\}`` if ``v=o``, ``\emptyset`` else
  - ``c^\star = +\infty``
  - ``P^\star = \text{None}``
- While ``L \neq \emptyset``
  - Extract from ``L`` an ``o-v`` path ``P`` minimizing ``c(q^F_P, b^B_v)``
  - Extend ``P`` : For all ``a\in \delta^+(v)``
    - ``Q \leftarrow P + a`` (``w`` destination vertex of ``q``)
    - ``q^F_Q \leftarrow f^F_a(q^F_P)``
    - If ``w = d`` and ``c_Q < c^\star``
      - ``c^\star \leftarrow c_q``
      - ``P^\star \leftarrow Q``
    - Else, if ``q^F_q`` is not dominated by any path in ``M_w`` and ``c(q^F_Q, b^B_w) < c^\star``
      - Add ``q^F_Q`` to ``M_w``
      - Remove from ``M_w`` every path dominated by ``Q``
      - Add ``Q`` to ``L``

### Computing bounds
Generalized dynamic programming equation in ``b^B``:
```math
\boxed{\left\{\begin{aligned}
& b_d = q_d\\
& b_v = \bigwedge_{\substack{a = (v, w)\\ a\in\delta^+(v)}} f^B_a(b_w)
\end{aligned}\right.}
```
  - example : when ``(f^F_a(x) = )f^B_a(x) = c_a + x`` and ``\wedge = \min`` then ``b_v = \min_a c_a + b_w``
``\implies`` Iterative algorithm along inverse topological order

Proposition : the solution is a lower bound (it's even the greater: ``q_{b_v} = \bigwedge\limits_{p\in\mathcal{P_{vd}}}q^B_p``)

---

## Examples

!!! warning
    Work in progress

### Shortest path
- ``q_o^F = 0,\, q^B_d = 0``
- ``f^F_a(q) = f^B_a(q) = c_a + q``
- ``c(q^F, q^B) = q^F + q^B``

### Usual resource constrained shortest path
- ``q_o^F = 0,\, q^B_d = 0``
- ``f^F_a(q) = f^B_a(q) = c_a + q``
- ``c(q^F, q^B) = q^F + q^B + \mathbb{I}_{\{q^F + q^B \leq W\}}``

### Stochastic routing
- ``c_p = \mathbb{E}[\sum_{v\in p}R_v] = \sum_{v\in p} \mathbb{E}[R_v] = \sum_{v\in p}\frac{1}{m}\sum_{j=1}^mR_v^j`` (``m`` scenarios)
- ``s_{a=(u,v)}`` : slack between ``u`` and ``v``
- ``a=(u,v) \rightarrow R_v^j = \max(R_u^j - s_{uv}, 0) + \varepsilon_v^j``
- ``q^F_u = \begin{bmatrix}C\\ R_u^1\\ \vdots \\ R_u^m\end{bmatrix}\in \mathbb{R}_+^{m+1}``, ``q^B_v = \begin{bmatrix}g^1\\ \vdots \\ g^m\end{bmatrix}\in (\mathbb{R}_+^{\mathbb{R}_+})^m``
- ``q^F_o = 0,\, q^B_d = 0\mapsto 0``
- ``f^F_{a=(u, v)}(q_u^F) = \begin{bmatrix}C + \frac{1}{m}\sum_{j=1}^m R_v^j\\ R_v^1 = \max(R_u^1 - S_a, 0) + \varepsilon_v^1\\ \vdots \\ R_v^m = \max(R_u^m - S_a, 0) + \varepsilon_v^m\end{bmatrix}``
- Let ``r_{a=(u,v)}^j(R) = \max(R - S_a, 0) + \varepsilon_v^j``
- ``f^B_{a=(u,v)}(q_v^B) = \begin{bmatrix}R\mapsto r_a^1(R) + g^1(r_a^1(R)) \\ \vdots \\ R\mapsto r_a^m(R) + g^m(r_a^m(R))\end{bmatrix}``
- ``c\left(\begin{bmatrix}C\\ R_u^1\\ \vdots \\ R_u^m\end{bmatrix}, \begin{bmatrix}g^1\\ \vdots \\ g^m\end{bmatrix}\right) = C + \frac{1}{m}\sum_{j=1}^m g^j(R^j_u)``
