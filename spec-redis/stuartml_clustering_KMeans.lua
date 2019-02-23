print('Begin test')

local KMeans = require 'stuart-ml.clustering.KMeans'
local Vectors = require 'stuart-ml.linalg.Vectors'
local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'


-- ============================================================================
-- Mini test framework
-- ============================================================================

local failures = 0

local function assertEquals(expected,actual,message)
  message = message or string.format('Expected %s but got %s', tostring(expected), tostring(actual))
  assert(actual == expected, message)
end

local function it(message, testFn)
  local status, err =  pcall(testFn)
  if status then
    print(string.format('✓ %s', message))
  else
    print(string.format('✖ %s', message))
    print(string.format('  FAILED: %s', err))
    failures = failures + 1
  end
end


-- ============================================================================
-- stuart-ml.clustering.KMeans
-- ============================================================================

it('findClosest() with exact match works', function()
  local centers = {
    VectorWithNorm.new(Vectors.dense(1,2,6))
  }
  local point = VectorWithNorm.new(Vectors.dense(1,2,6))
  local bestIndex, bestDistance = KMeans.findClosest(centers, point)
  assertEquals(1, bestIndex)
  assertEquals(0, bestDistance)
end)

it('findClosest() with near match works', function()
  local centers = {
    VectorWithNorm.new(Vectors.dense(1,2,6))
  }
  local point = VectorWithNorm.new(Vectors.dense(1,3,0))
  local bestIndex, bestDistance = KMeans.findClosest(centers, point)
  assertEquals(1, bestIndex)
  assertEquals(37, bestDistance)
end)


-- ============================================================================
-- Mini test framework -- report results
-- ============================================================================

print(string.format('End of test: %d failures', failures))
