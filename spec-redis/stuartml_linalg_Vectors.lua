print('Begin test')

local class = require 'stuart.class' 
local Vector = require 'stuart-ml.linalg.Vector'
local Vectors = require 'stuart-ml.linalg.Vectors'
local moses = require 'moses'


-- ============================================================================
-- Mini test framework
-- ============================================================================

local failures = 0

local function assertEquals(expected,actual,message)
  message = message or string.format('Expected %s but got %s', tostring(expected), tostring(actual))
  if type(expected) == 'table' and type(actual) == 'table' then
    assert(moses.same(actual, expected), message)
  else
    assert(actual == expected, message)
  end
end

local function assertError(testFn, message)
  local status, _ = pcall(testFn)
  assert(not status, message or 'Expected error but got none')
end

local function assertSame(expected,actual,message)
  message = message or string.format('Expected %s but got %s', tostring(expected), tostring(actual))
  assert(moses.isEqual(expected, actual), message)
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
-- stuart-ml.linalg.Vectors
-- ============================================================================

local arr = {0.1, 0.0, 0.3, 0.4}
local n = 4
local indices = {0, 2, 3}
local values = {0.1, 0.3, 0.4}

it('dense vector construction with varargs', function()
  local unpack = table.unpack or unpack
  local vec = Vectors.dense(unpack(arr))
  assertEquals(#arr, vec:size())
  assertSame(arr, vec.values)
  assertEquals(true, class.istype(vec, Vector))
end)

it('sparse vector construction', function()
  local vec = Vectors.sparse(n, indices, values)
  assertEquals(n, vec:size())
  assertSame(indices, vec.indices)
  assertSame(values, vec.values)
end)

it('sparse vector construction with unordered elements', function()
  local vec = Vectors.sparse(n, moses.reverse(moses.zip(indices, values)))
  assertEquals(n, vec:size())
  assertSame(indices, vec.indices)
  assertSame(values, vec.values)
end)

it('sparse vector construction with mismatched indices/values array', function()
  assertError(function() Vectors.sparse(4, {1,2,3}, {3.0,5.0,7.0,9.0}) end)
  assertError(function() Vectors.sparse(4, {1,2,3}, {3.0,5.0}) end)
end)

it('sparse vector construction with too many indices vs size', function()
  assertError(function() Vectors.sparse(3, {1,2,3,4}, {3.0,5.0,7.0,9.0}) end)
end)

it('dense to array', function()
  local vec = Vectors.dense(arr)
  assertSame(arr, vec:toArray())
end)

it('dense argmax', function()
  local vec = Vectors.dense({})
  assertEquals(-1, vec:argmax())

  local vec2 = Vectors.dense(arr)
  assertEquals(4, vec2:argmax()) -- 3 in Scala, 4 in Lua and its 1-based indexes

  local vec3 = Vectors.dense({-1.0, 0.0, -2.0, 1.0})
  assertEquals(4, vec3:argmax()) -- 3 in Scala, 4 in Lua and its 1-based indexes
end)

it('sparse to array', function()
  local vec = Vectors.sparse(n, indices, values)
  assertSame(arr, vec:toArray())
end)

it('sparse argmax', function()
  local vec = Vectors.sparse(0, {}, {})
  assertEquals(-1, vec:argmax())

  local vec2 = Vectors.sparse(n, indices, values)
  assertEquals(3, vec2:argmax())

  local vec3 = Vectors.sparse(5, {2,3,4}, {1.0,0.0,-.7})
  assertEquals(2, vec3:argmax())

  -- check for case that sparse vector is created with
  -- only negative values {0.0, 0.0,-1.0, -0.7, 0.0}
  local vec4 = Vectors.sparse(5, {2,3}, {-1.0,-.7})
  assertEquals(0, vec4:argmax())

  local vec5 = Vectors.sparse(11, {0,3,10}, {-1.0,-.7,0.0})
  assertEquals(1, vec5:argmax())

  local vec6 = Vectors.sparse(11, {0,1,2}, {-1.0,-.7,0.0})
  assertEquals(2, vec6:argmax())

  local vec7 = Vectors.sparse(5, {0,1,3}, {-1.0,0.0,-.7})
  assertEquals(1, vec7:argmax())

  local vec8 = Vectors.sparse(5, {1,2}, {0.0,-1.0})
  assertEquals(0, vec8:argmax())

  -- Check for case when sparse vector is non-empty but the values are empty
  local vec9 = Vectors.sparse(100, {}, {})
  assertEquals(0, vec9:argmax())

  local vec10 = Vectors.sparse(1, {}, {})
  assertEquals(0, vec10:argmax())
end)

it('vector equals', function()
  local dv1 = Vectors.dense(moses.clone(arr))
  local dv2 = Vectors.dense(moses.clone(arr))
  local sv1 = Vectors.sparse(n, moses.clone(indices), moses.clone(values))
  local sv2 = Vectors.sparse(n, moses.clone(indices), moses.clone(values))

  local vectors = {dv1, dv2, sv1, sv2}

  assertEquals(dv1, dv2)
  assertEquals(sv1, sv2)
  
  local another = Vectors.dense(0.1, 0.2, 0.3, 0.4)

  for _,vector in ipairs(vectors) do
    assertEquals(false, vector == another)
  end

end)

it('vectors equals with explicit 0', function()
  local dv1 = Vectors.dense({0, 0.9, 0, 0.8, 0})
  local sv1 = Vectors.sparse(5, {1, 3}, {0.9, 0.8})
  local sv2 = Vectors.sparse(5, {0, 1, 2, 3, 4}, {0, 0.9, 0, 0.8, 0})

  local vectors = {dv1, sv1, sv2}
  for i=1,#vectors do
    assertEquals(vectors[i], vectors[i])
  end

  local another = Vectors.sparse(5, {0, 1, 3}, {0, 0.9, 0.2})
  for i,vector in ipairs(vectors) do
    assertEquals(false, vector == another)
  end
end)

it('indexing dense vectors', function()
  local vec = Vectors.dense(1.0, 2.0, 3.0, 4.0)
  assertEquals(1.0, vec[1])
  assertEquals(4.0, vec[4])
end)

it('indexing sparse vectors', function()
  local vec = Vectors.sparse(7, {0,2,4,6}, {1.0,2.0,3.0,4.0})
  assertEquals(1.0, vec[0])
  assertEquals(0.0, vec[1])
  assertEquals(2.0, vec[2])
  assertEquals(0.0, vec[3])
  assertEquals(4.0, vec[6])
  
  local vec2 = Vectors.sparse(8, {0,2,4,6}, {1.0,2.0,3.0,4.0})
  assertEquals(4.0, vec2[6])
  assertEquals(0.0, vec2[7])
end)

-- ============================================================================
-- Mini test framework -- report results
-- ============================================================================

print(string.format('End of test: %d failures', failures))
