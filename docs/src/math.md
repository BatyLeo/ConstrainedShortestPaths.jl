# Theoretical framework

This page explains the mathematical framework used by `ConstrainedShortestPath.jl`, and its application to a few examples It's simplified version of the framework from [Parmentier 2017](https://arxiv.org/abs/1504.07880), retricted to acyclic graphs.

## Generalized constrained shortest path

### Problem formulation

Let ``D = (V, A)`` be an acyclic digraph. Let ``o, d`` two vertices, and ``\mathcal{P}_{od}`` the set of ``o-d`` path in ``D``. We want to find a path in ``P^\star \in\mathcal{P}_{od}`` minimizing a cost function ``P\mapsto c_P``:
```math
\boxed{\min_{P\in\mathcal{P}_{od}}c_P}
```

### Setting

We define the two following set of resources:
- Set of **forward resources** ``Q^F``, with a partial order ``\leq^F``
- Set of **backward resources** ``Q^B``, with a partial order ``\leq^B``

A partially ordered set ``(S,\leq)`` is a *lattice* if any pair ``s, s'\in S``, admits a greatest lower bound ``s\wedge s'``, i.e. ``\forall b,\, b\leq s\wedge s'``, ``b \leq s`` and ``b\leq s'``.

``(Q^F, \leq^F)`` and ``(Q^B, \leq^B)`` are *lattice*.

For every arc ``a\in A``, we define two functions:
  - **Forward extension function** : ``f^F_a:Q^F \to Q^F`` increasing
  - **Backward extension function** : ``f^B_a : Q^B \to Q^B`` increasing

We also define:
- A **cost function** : ``c:Q^F\times Q^B \to \mathbb{R}\cup\{+\infty\}`` increasing
- An origin vertex ``o``, with a corresponding ressource ``q^F_o\in Q^F``
- A destination vertex ``d``, with a corresponding ressource ``q^B_d\in Q^B``

Finally need the following (equivalent) properties to hold:
- For all ``o-d`` path ``P = (o=v_0, a_1, v_1, \dots, a_k, v_k=d)``, we have :
  ```math
  \boxed{\forall i, i'\in [k],\, c(f^F_i \circ f^F_{i-1}\circ\dots\circ f^F_1(q^F_o), f^B_{i+1} \circ f^B_{i+2}\circ\dots\circ f^B_k(q^B_d)) = c_P\in\mathbb{R}\cup\{+\infty\}}
  ```
- For all ``o-d`` path ``P`` and every decomposition of ``P`` as ``(R_1, R_2)``, we have ``c_P=c(q^F_{R_1}, q^B_{R_2})``, with:
  - For all ``o-v`` path ``R_1 = (o=v_0, a_1, v_1, \dots, a_i, v_i=v)``:
    ```math
    \boxed{q^F_{R_1} = f^F_{a_i} \circ f^F_{a_{i-1}}\circ\dots \circ f^F_{a_1}(q^F_o)}
    ```
  - For all ``v-d`` path ``R_2 = (v=v_0, a_1, v_1, \dots, a_j, v_j=d)``:
    ```math
    \boxed{q^B_{R_2} = f^B_{a_1} \circ f^B_{a_{2}}\circ\dots \circ f^B_{a_j}(q^B_d)}
    ```

---

## Algorithms

We first assume that we have accesss to a lower bound ``b^B_v\in Q^B`` for every vertex ``v``, such that ``b^B_v\leq^B q^B_R`` for all ``v-d`` path ``R``.
- Lemma 1 (**Cut using bounds**) : let ``R_1`` an ``o-v`` path. Then :
  ```math
  \forall P = (R_1, R_2)\in \mathcal{P}_{od},\, c(q^F_{R_1}, b^B_v)\leq c_P
  ```
  - Proof : ``b^B_v\leq^B q^B_{R_2} \implies c(q^F_{R_1}, b^B_v) \leq c(q^F_{R_1}, q^B_{R_2})`` par croissance de ``c``
- Lemma 2 (**Dominance**) : if ``q^F_{R_1} \leq^F q^F_{R'_1}``, then for all ``R_2`` :
  ```math
  c(q^F_{R_1}, q^B_{R_2})\leq c(q^F_{R'_1}, q^B_{R_2})
  ```
  i.e. (``P=(R_1, R_2),\, P'=(R'_1, R_2)``)
  ```math
  c_P \leq c_{P'}
  ```
	
### Generalized ``A^\star``
- Initialization :
  - ``L \leftarrow \{\text{Chemin vide en }o\}``: partial paths to process
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
