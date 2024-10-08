# ConstrainedShortestPaths.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://BatyLeo.github.io/ConstrainedShortestPaths.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://BatyLeo.github.io/ConstrainedShortestPaths.jl/dev)
[![Build Status](https://github.com/BatyLeo/ConstrainedShortestPaths.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/BatyLeo/ConstrainedShortestPaths.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/BatyLeo/ConstrainedShortestPaths.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/BatyLeo/ConstrainedShortestPaths.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

## Overview

This package implements algorithms for solving (resource) **Constrained Shortest Paths** problems. 
It implements a generalized A star algorithm with label dominance and optional bounding.
It is currently restricted to acyclic directed graphs.
Reference: [https://arxiv.org/abs/1504.07880](https://arxiv.org/abs/1504.07880).

Let $D=(V, A)$ an **acyclic directed graph**, $o, d\in V$ **origin** and **destination** vertices, $c$ a **cost function**, and $\mathcal{P} \subset \mathcal{P}_{od}$ a subset of $o-d$ paths in $G$. This package can compute the corresponding **constrained shortest path**:

$$
\boxed{\begin{aligned}
P^\star = \arg\min\quad & c(P)\\
\text{s.t.}\quad & P\in \mathcal{P}
\end{aligned}}
$$

See the [documentation](https://batyleo.github.io/ConstrainedShortestPaths.jl) for more details.

## Installation

To install this package, open a julia REPL and run the following command:

```bash
]add ConstrainedShortestPaths
```
