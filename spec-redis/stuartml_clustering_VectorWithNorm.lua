print('Begin test')

local Vectors = require 'stuart-ml.linalg.Vectors'
local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
local moses = require 'moses'


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
-- stuart-ml.clustering.VectorWithNorm
-- ============================================================================

it('constructs a DenseVector from an array', function()
  local values = {0.1, 0.3, 4}
  local norm = 2
  local vecWithNorm = VectorWithNorm.new(values, norm)
  local expected = '((0.1,0.3,4),2)'
  local actual = tostring(vecWithNorm)
  assertEquals(expected, actual)
end)

it('stringifies a DenseVector', function()
  local values = {0.1, 0.3, 4}
  local norm = 2
  local vec = Vectors.dense(values)
  local vecWithNorm = VectorWithNorm.new(vec, norm)
  local expected = '((0.1,0.3,4),2)'
  local actual = tostring(vecWithNorm)
  assertEquals(expected, actual)
end)

it('stringifies a SparseVector', function()
  local indices = {1, 3, 4}
  local values = {0.1, 0.3, 4}
  local norm = 2
  local vec = Vectors.sparse(3, indices, values)
  local vecWithNorm = VectorWithNorm.new(vec, norm)
  local expected = '((3,(1,3,4),(0.1,0.3,4)),2)'
  local actual = tostring(vecWithNorm)
  assertEquals(expected, actual)
end)

it('converts to DenseVector', function()
  local indices = {0, 2, 3}
  local values = {0.1, 0.3, 4}
  local norm = 3
  local vec = Vectors.sparse(3, indices, values)
  local vecWithNorm = VectorWithNorm.new(vec, norm):toDense()
  local expected = '((0.1,0,0.3,4),3)'
  local actual = tostring(vecWithNorm)
  assertEquals(expected, actual)
end)

it('equality', function()
  local a = VectorWithNorm.new(Vectors.sparse(3, {1,3,5}, {1,3,5}), 3)
  local b = VectorWithNorm.new(Vectors.sparse(3, {1,3,5}, {1,3,5}), 3)
  assertEquals(a, b)
  
  b = VectorWithNorm.new(Vectors.sparse(3, {1,3,5}, {1,3,6}), 3)
  assertEquals(false, a == b)
end)

-- ============================================================================
-- Mini test framework -- report results
-- ============================================================================

print(string.format('End of test: %d failures', failures))
