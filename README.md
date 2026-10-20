# Octree Spatial Query Demo

A standalone Lua 5.4 demonstration of spatial-query code from my Roblox game. This is a simplified, demo-adapted version of code I am currently using in the game, with generated points and small pure-Lua replacements for Roblox types so the core algorithms can run independently.

## Role in my game

The octree organizes objects by their positions in 3D space. Its role is to narrow spatial searches to relevant regions, providing the underlying queries needed for nearby-object checks and nearest-target selection without scanning every indexed object on each query.

- **Eight-way subdivision:** splits crowded regions into smaller cubes, grouping nearby positions while limiting tree depth.
- **Radius search:** returns indexed objects within a specified distance of a query position, supporting range-based gameplay checks.
- **Nearest-neighbor search:** finds the closest indexed object, with an optional distance limit, providing a building block for target selection.
- **Distance pruning:** skips cubes that cannot intersect the search radius or improve the current nearest result. The nearest search visits the query position’s preferred child first to help establish a useful distance bound early.

## What this demo includes

`demo.lua` builds an octree containing 20,000 deterministic sample points, times construction and 500 pairs of radius/nearest queries, and checks 25 nearest-neighbor results against a brute-force search. It prints timings, radius-hit totals, and the verification result to the terminal.

The game’s code uses Roblox `Vector3` values and instances; this demo substitutes small Lua tables and sample objects. It isolates insertion and spatial queries rather than including the complete game, its assets, or its runtime integration. Benchmark timings depend on the machine and sample workload.

## Run

```bash
lua demo.lua
```

Requires Lua 5.4. No Roblox Studio, Rojo, packages, or external assets are required. See [LUA_EQUIVALENTS.md](LUA_EQUIVALENTS.md) for the pure-Lua replacements used in the demo.