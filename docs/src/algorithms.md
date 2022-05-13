# Algorithms

We first assume that we have accesss to a lower bound ``b^B_v\in Q^B`` for every vertex ``v``, such that ``b^B_v\leq^B q^B_R`` for all ``v-d`` path ``R``.
- Lemma 1 (**Cut using bounds**) : let ``R_1`` an ``o-v`` path. Then :
  ```math
  \forall P = (R_1, R_2)\in \mathcal{P}_{od},\, c(q^F_{R_1}, b^B_v)\leq c_P
  ```
- Lemma 2 (**Dominance**) : if ``q^F_{R_1} \leq^F q^F_{R'_1}``, then for all ``R_2`` :
  ```math
  c(q^F_{R_1}, q^B_{R_2})\leq c(q^F_{R'_1}, q^B_{R_2})
  ```
  i.e. (``P=(R_1, R_2),\, P'=(R'_1, R_2)``)
  ```math
  c_P \leq c_{P'}
  ```
	
## Generalized ``A^\star``
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

## Computing bounds
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
