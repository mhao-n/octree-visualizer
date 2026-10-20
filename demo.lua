local Vec3 = {}
function Vec3.new(x, y, z) return { x = x, y = y, z = z } end
function Vec3.distanceSquared(a, b)
  local x, y, z = a.x - b.x, a.y - b.y, a.z - b.z
  return x * x + y * y + z * z
end

local function newRng(seed)
  local state = seed % 2147483647
  return {
    number = function(_, low, high)
      state = (state * 48271) % 2147483647
      return low + (high - low) * (state / 2147483647)
    end,
  }
end

local Octree = {}
Octree.__index = Octree

local offsets = {
  {-0.5, -0.5, -0.5}, {0.5, -0.5, -0.5},
  {-0.5, 0.5, -0.5}, {0.5, 0.5, -0.5},
  {-0.5, -0.5, 0.5}, {0.5, -0.5, 0.5},
  {-0.5, 0.5, 0.5}, {0.5, 0.5, 0.5},
}

local function node(size, center, maxDepth, maxObjects, depth)
  return setmetatable({ center = center, halfSize = size / 2, maxDepth = maxDepth,
    maxObjects = maxObjects, depth = depth or 0, objects = {}, children = nil }, Octree)
end

function Octree.new(size, center, maxDepth, maxObjects)
  return node(size, center or Vec3.new(0, 0, 0), maxDepth or 8, maxObjects or 12, 0)
end

local function childIndex(self, position)
  local index = 1
  if position.x > self.center.x then index = index + 1 end
  if position.y > self.center.y then index = index + 2 end
  if position.z > self.center.z then index = index + 4 end
  return index
end

local function subdivide(self)
  self.children = {}
  for index, offset in ipairs(offsets) do
    self.children[index] = node(self.halfSize, Vec3.new(
      self.center.x + offset[1] * self.halfSize,
      self.center.y + offset[2] * self.halfSize,
      self.center.z + offset[3] * self.halfSize
    ), self.maxDepth, self.maxObjects, self.depth + 1)
  end
  local old = self.objects
  self.objects = {}
  for _, record in ipairs(old) do
    self.children[childIndex(self, record.position)]:insert(record.object, record.position)
  end
end

function Octree:insert(object, position)
  if self.children then
    self.children[childIndex(self, position)]:insert(object, position)
    return
  end
  self.objects[#self.objects + 1] = { object = object, position = position }
  if #self.objects > self.maxObjects and self.depth < self.maxDepth then subdivide(self) end
end

local function cubeDistanceSquared(center, halfSize, point)
  local dx = math.max(math.abs(point.x - center.x) - halfSize, 0)
  local dy = math.max(math.abs(point.y - center.y) - halfSize, 0)
  local dz = math.max(math.abs(point.z - center.z) - halfSize, 0)
  return dx * dx + dy * dy + dz * dz
end

function Octree:radius(position, radius, result)
  result = result or {}
  if cubeDistanceSquared(self.center, self.halfSize, position) > radius * radius then return result end
  if self.children then
    for _, child in ipairs(self.children) do child:radius(position, radius, result) end
  else
    for _, record in ipairs(self.objects) do
      if Vec3.distanceSquared(record.position, position) <= radius * radius then
        result[#result + 1] = record.object
      end
    end
  end
  return result
end

function Octree:nearest(position, maxDistance)
  local bestObject = nil
  local bestSquared = maxDistance and maxDistance * maxDistance or math.huge
  local function visit(current)
    if cubeDistanceSquared(current.center, current.halfSize, position) > bestSquared then return end
    if current.children then
      local preferred = childIndex(current, position)
      visit(current.children[preferred])
      for index, child in ipairs(current.children) do if index ~= preferred then visit(child) end end
    else
      for _, record in ipairs(current.objects) do
        local distanceSquared = Vec3.distanceSquared(record.position, position)
        if distanceSquared < bestSquared then bestObject, bestSquared = record.object, distanceSquared end
      end
    end
  end
  visit(self)
  return bestObject, math.sqrt(bestSquared)
end

local rng = newRng(44021)
local points, tree = {}, Octree.new(2000, Vec3.new(0, 0, 0), 9, 10)
local buildStart = os.clock()
for id = 1, 20000 do
  local position = Vec3.new(rng:number(-1000, 1000), rng:number(-1000, 1000), rng:number(-1000, 1000))
  points[id] = { id = id, position = position }
  tree:insert(points[id], position)
end
local buildTime = os.clock() - buildStart

local queryStart, totalRadiusHits = os.clock(), 0
for _ = 1, 500 do
  local query = Vec3.new(rng:number(-900, 900), rng:number(-900, 900), rng:number(-900, 900))
  totalRadiusHits = totalRadiusHits + #tree:radius(query, 120)
  assert(tree:nearest(query))
end
local queryTime = os.clock() - queryStart

for _ = 1, 25 do
  local query = Vec3.new(rng:number(-900, 900), rng:number(-900, 900), rng:number(-900, 900))
  local octreeObject = tree:nearest(query)
  local bruteObject, bruteDistance = nil, math.huge
  for _, point in ipairs(points) do
    local distance = Vec3.distanceSquared(point.position, query)
    if distance < bruteDistance then bruteObject, bruteDistance = point, distance end
  end
  assert(octreeObject == bruteObject, "octree result disagreed with brute force")
end

print("Octree spatial-query demo")
print(string.format("  indexed points:     %d", #points))
print(string.format("  build time:         %.4f s", buildTime))
print(string.format("  1,000 queries:      %.4f s", queryTime))
print(string.format("  total radius hits:  %d", totalRadiusHits))
print("  verification:       25/25 nearest queries matched brute force")