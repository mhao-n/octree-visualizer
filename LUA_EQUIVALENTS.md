# Small Lua equivalents

| Roblox/Luau feature | Pure Lua replacement in `demo.lua` |
|---|---|
| `Vector3.new(x, y, z)` | `Vec3.new(x, y, z)`, a three-number table |
| Vector subtraction and `.Magnitude` | `Vec3.distanceSquared(a, b)` and `math.sqrt` |
| `Random.new(seed)` | A local deterministic LCG object |
| Roblox `Instance` references | Plain point records with numeric IDs |
| `table.create` / `table.clear` | Ordinary tables and reassignment |
| Luau typed annotations | Runtime assertions and standard Lua tables |

These replacements intentionally cover only what the algorithm needs. They are not full emulations of Roblox APIs.