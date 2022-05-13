# Setting

This page explains the mathematical framework used by `ConstrainedShortestPath.jl`, and its application to a few examples It's simplified version of the framework from [Parmentier 2017](https://arxiv.org/abs/1504.07880), retricted to acyclic graphs.

## Generalized constrained shortest path: problem formulation

Let ``D = (V, A)`` be an acyclic digraph. Let ``o, d`` two vertices, and ``\mathcal{P}_{od}`` the set of ``o-d`` path in ``D``. We want to find a path ``P^\star \in\mathcal{P}_{od}`` minimizing a given cost function ``P\mapsto c_P``:
```math
\boxed{\min_{P\in\mathcal{P}_{od}}c_P}
```

## Setting

We define the two following set of resources:
- Set of **forward resources** ``Q^F``, with a partial order ``\leq^F``
- Set of **backward resources** ``Q^B``, with a partial order ``\leq^B``

A partially ordered set ``(S,\leq)`` is a *lattice* if any pair ``s, s'\in S``, admits a greatest lower bound ``s\wedge s'``, i.e. ``\forall b, s.t. 
b \leq s`` and ``b\leq s',\, b\leq s\wedge s'``.

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
