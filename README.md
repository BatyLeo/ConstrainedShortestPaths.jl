# ConstrainedShortestPaths.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://BatyLeo.github.io/ConstrainedShortestPaths.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://BatyLeo.github.io/ConstrainedShortestPaths.jl/dev)
[![Build Status](https://github.com/BatyLeo/ConstrainedShortestPaths.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/BatyLeo/ConstrainedShortestPaths.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/BatyLeo/ConstrainedShortestPaths.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/BatyLeo/ConstrainedShortestPaths.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

This package implements algorithms for solving **Generalized Constrained Shortest Paths** problems. It implements a simplified version of the framework from [Parmentier 2017](https://arxiv.org/abs/1504.07880), restricted to acyclic directed graphs.

If you have any question/suggestion, feel free to [create an issue](https://github.com/BatyLeo/ConstrainedShortestPaths.jl/issues/new/choose) or [contact me](mailto:leo.baty@enpc.fr).

## Overview

This package supports the following setting:
- Let ``D=(V, A)`` an **acyclic directed graph**.
- Let ``o, d\in V`` **origin** and **destination** vertices.
- Let ``\mathcal{P} \subset \mathcal{P}_{od}`` a subset of ``o-d`` paths in ``D``.
- Let ``c`` a **cost function** you want to minimize on ``\mathcal{P}``.

The [`generalized_constrained_shortest_path`](@ref) algorithm is able to solve the following shortest path problem:

```math
\begin{aligned}
\arg\min\quad & c(P)\\
\text{s.t.}\quad & P\in \mathcal{P}
\end{aligned}
```

## Installation

To install this package, open a julia REPL and run the following command in pkg mode:

```bash
add ConstrainedShortestPaths
```

---

## Basic usage

Currently, this package implements three applications examples ready to use:
- The [Usual shortest path](@ref) problem ([`basic_shortest_path`](@ref)).
- The [Shortest path with linear resource constraints](@ref) resource constraints ([`resource_shortest_path`](@ref)).
- The [Stochastic Vehicle Scheduling](@ref) subproblem for the column generation formulation ([`stochastic_routing_shortest_path`](@ref)).

## Advanced usage

If your shortest path problem is not one of those listed in the [Basic usage](@ref) section, it is still possible to solve it with this package. To do this, first read the [Mathematical background](@ref) section, then follow the [Implement a custom problem](@ref) tutorial.
