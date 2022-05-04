# Examples

## Usual shortest path
- ``q_o^F = 0,\, q^B_d = 0``
- ``f^F_a(q) = f^B_a(q) = c_a + q``
- ``c(q^F, q^B) = q^F + q^B``

## Usual resource constrained shortest path
- ``q_o^F = 0,\, q^B_d = 0``
- ``f^F_a(q) = f^B_a(q) = c_a + q``
- ``c(q^F, q^B) = q^F + q^B + \mathbb{I}_{\{q^F + q^B \leq W\}}``

## Stochastic routing
- ``c_p = \mathbb{E}[\sum_{v\in p}R_v] = \sum_{v\in p} \mathbb{E}[R_v] = \sum_{v\in p}\frac{1}{m}\sum_{j=1}^mR_v^j`` (``m`` scenarios)
- ``s_{a=(u,v)}`` : slack between ``u`` and ``v``
- ``a=(u,v) \rightarrow R_v^j = \max(R_u^j - s_{uv}, 0) + \varepsilon_v^j``
- ``q^F_u = \begin{bmatrix}C\\ R_u^1\\ \vdots \\ R_u^m\end{bmatrix}\in \mathbb{R}_+^{m+1}``, ``q^B_v = \begin{bmatrix}g^1\\ \vdots \\ g^m\end{bmatrix}\in (\mathbb{R}_+^{\mathbb{R}_+})^m``
- ``q^F_o = 0,\, q^B_d = 0\mapsto 0``
- ``f^F_{a=(u, v)}(q_u^F) = \begin{bmatrix}C + \frac{1}{m}\sum_{j=1}^m R_v^j\\ R_v^1 = \max(R_u^1 - S_a, 0) + \varepsilon_v^1\\ \vdots \\ R_v^m = \max(R_u^m - S_a, 0) + \varepsilon_v^m\end{bmatrix}``
- Let ``r_{a=(u,v)}^j(R) = \max(R - S_a, 0) + \varepsilon_v^j``
- ``f^B_{a=(u,v)}(q_v^B) = \begin{bmatrix}R\mapsto r_a^1(R) + g^1(r_a^1(R)) \\ \vdots \\ R\mapsto r_a^m(R) + g^m(r_a^m(R))\end{bmatrix}``
- ``c\left(\begin{bmatrix}C\\ R_u^1\\ \vdots \\ R_u^m\end{bmatrix}, \begin{bmatrix}g^1\\ \vdots \\ g^m\end{bmatrix}\right) = C + \frac{1}{m}\sum_{j=1}^m g^j(R^j_u)``
