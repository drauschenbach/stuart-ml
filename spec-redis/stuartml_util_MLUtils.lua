print('Begin test')

local MLUtils = require 'stuart-ml.util.MLUtils'
local moses = require 'moses'
local mosesRange = require 'stuart-ml.util'.mosesPatchedRange
local Vectors = require 'stuart-ml.linalg.Vectors'


-- ============================================================================
-- Mini test framework
-- ============================================================================

local failures = 0

local function assertEquals(expected,actual,message)
  message = message or string.format('Expected %s but got %s', tostring(expected), tostring(actual))
  assert(actual==expected, message)
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
-- stuart-ml.util.MLUtils
-- ============================================================================

it('epsilon computation', function()
  assertEquals(true, 1.0 + MLUtils.EPSILON > 1.0, 'EPSILON is too small: ' .. MLUtils.EPSILON)
  assertEquals(1.0, 1.0 + MLUtils.EPSILON / 2.0, 'EPSILON is too big')
end)

it('fast squared distance', function()
  local a = moses.map(mosesRange(30,0,-1), function(v) return math.pow(2.0, v) end)
  local breezeSquaredDistance_v1_v2 = { -- pre-computed using MLUtilsSuite.scala
    3.843071682022823E17,
    9.6076792050570576E16,
    2.4019198012642644E16,
    6.004799503160661E15,
    1.501199875790165E15,
    3.75299968947541E14,
    9.3824992236885E13,
    2.3456248059221E13,
    5.864062014805E12,
    1.466015503701E12,
    3.66503875925E11,
    9.1625968981E10,
    2.2906492245E10,
    5.726623061E9,
    1.431655765E9,
    3.57913941E8,
    8.9478485E7,
    2.2369621E7,
    5592405.0,
    1398101.0,
    349525.0,
    87381.0,
    21845.0,
    5461.0,
    1365.0,
    341.0,
    85.0,
    21.0,
    5.0,
    1.0,
    0.0,
  }
  local breezeSquaredDistance_v2_v3 = { -- pre-computed using MLUtilsSuite.scala
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
    2.25,
    2.5,
    2.75,
    3.0,
    3.25,
    3.5,
    3.75,
    4.0,
    4.25,
    4.5,
    4.75,
    5.0,
    5.25,
    5.5,
    5.75,
    6.0,
    6.25,
    6.5,
    6.75,
    7.0,
    7.25,
    7.5,
    7.75
  }
  local breezeSquaredDistance_v2_v4 = { -- pre-computed using MLUtilsSuite.scala
    0,0,0,0,0,0,0,0,0,0,0,
    3.8430707657631334E17,
    9.6076769144078336E16,
    2.4019192286019584E16,
    6.004798071504897E15,
    1.5011995178762252E15,
    3.752998794690575E14,
    9.382496986726575E13,
    2.3456242466818E13,
    5.86406061670625E12,
    1.4660151541785E12,
    3.6650378854675E11,
    9.1625947139E10,
    2.290648678725E10,
    5.7266216995E9,
    1.43165542775E9,
    3.5791386E8,
    8.947846825E7,
    2.23696205E7,
    5592408.75,
    1398106.0
  }
  local n = #a
  local v1 = Vectors.dense(a)
  local norm1 = Vectors.norm(v1, 2.0)
  local precision = 1e-6
  for m=0,n-1 do
    local indices; if m == 0 then indices = {0} else indices = mosesRange(m) end
    local values = moses.map(indices, function(_,i) return a[indices[i]+1] end)
    local v2 = Vectors.sparse(n, indices, values)
    local norm2 = Vectors.norm(v2, 2.0)
    local v3 = Vectors.sparse(n, indices, moses.map(indices, function(v) return a[v+1] + 0.5 end))
    local norm3 = Vectors.norm(v3, 2.0)
    local squaredDist = breezeSquaredDistance_v1_v2[m+1]
    local fastSquaredDist1 = MLUtils.fastSquaredDistance(v1, norm1, v2, norm2, precision)
    assertEquals(true, (fastSquaredDist1 - squaredDist) <= precision * squaredDist)
    local fastSquaredDist2 = MLUtils.fastSquaredDistance(v1, norm1, Vectors.dense(v2:toArray()), norm2, precision)
    assertEquals(true, (fastSquaredDist2 - squaredDist) <= precision * squaredDist)
    local squaredDist2 = breezeSquaredDistance_v2_v3[m+1]
    local fastSquaredDist3 = MLUtils.fastSquaredDistance(v2, norm2, v3, norm3, precision)
    assertEquals(true, (fastSquaredDist3 - squaredDist2) <= precision * squaredDist2)
    if m > 10 then
      local v4 = Vectors.sparse(n, moses.slice(indices, 0, m-10),
        moses.slice(moses.map(indices, function(v) return a[v+1] + 0.5 end), 0, m-10))
      local norm4 = Vectors.norm(v4, 2.0)
      squaredDist = breezeSquaredDistance_v2_v4[m+1]
      local fastSquaredDist = MLUtils.fastSquaredDistance(v2, norm2, v4, norm4, precision)
    assertEquals(true, (fastSquaredDist - squaredDist) <= precision * squaredDist)
    end
  end
end)


-- ============================================================================
-- Mini test framework -- report results
-- ============================================================================

print(string.format('End of test: %d failures', failures))
