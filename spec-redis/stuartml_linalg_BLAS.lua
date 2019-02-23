print('Begin test')

local BLAS = require 'stuart-ml.linalg.BLAS'
local Vectors = require 'stuart-ml.linalg.Vectors'
local moses = require 'moses'


-- ============================================================================
-- Mini test framework
-- ============================================================================

local failures = 0

local function assertEquals(expected,actual,message)
  message = message or string.format('Expected %s but got %s', tostring(expected), tostring(actual))
  assert(actual == expected, message)
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
-- stuart-ml.linalg.BLAS
-- ============================================================================

it('numNonzeros is accurate after axpy() changes the vector', function()
  local vectorY = Vectors.zeros(3)
  assertSame({0,0,0}, vectorY.values)
  assertEquals(0, vectorY:numNonzeros())

  local vectorX = Vectors.dense({1,2,3})
  assertSame({1,2,3}, vectorX.values)
  assertEquals(3, vectorX:numNonzeros())
  
  local alpha = 10
  BLAS.axpy(alpha, vectorX, vectorY)
  
  assertSame({10,20,30}, vectorY.values)
  assertEquals(3, vectorY:numNonzeros())
end)


-- ============================================================================
-- Mini test framework -- report results
-- ============================================================================

print(string.format('End of test: %d failures', failures))
