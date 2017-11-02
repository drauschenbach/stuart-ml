local moses = require 'moses'
local say = require 'say'
local Vector = require 'stuart-ml.linalg.Vector'

local isInstanceOf = function(x, type)
  if not moses.isTable(x) or x.isInstanceOf == nil then return false end
  return x:isInstanceOf(type)
end

local registerAsserts = function(assert)

  -----------------------------------------------------------------------------
  say:set('assertion.contains.positive', 'Expected %s to contain %s')
  say:set('assertion.contains.negative', 'Expected %s to not contain %s')
  assert:register('assertion', 'contains', function(_, arguments)
    local collection = arguments[1]
    local searchFor = arguments[2]
    return moses.findIndex(collection, function(_,v) return v == searchFor end) ~= nil
  end, 'assertion.contains.positive', 'assertion.contains.negative')
  
  -----------------------------------------------------------------------------
  say:set('assertion.equal_absTol.positive', 'Expected %s to equal %s within absolute tolerance %s')
  say:set('assertion.equal_absTol.negative', 'Expected %s to not equal %s within absolute tolerance %s')
  assert:register('assertion', 'equal_absTol', function(_, arguments)
    local x = arguments[1]
    local y = arguments[2]
    local eps = arguments[3]
    if x == y then return true end
    
    if isInstanceOf(x, Vector) and isInstanceOf(y, Vector) then
      if x:size() ~= y:size() then return false end
      for _,e in ipairs(moses.zip(x:toArray(), y:toArray())) do
        local a = e[1]
        local b = e[2]
        if math.abs(a - b) >= eps then return false end
      end
      return true
    end
    
    return math.abs(x - y) < eps
  end, 'assertion.equal_absTol.positive', 'assertion.equal_absTol.negative')
  
  -----------------------------------------------------------------------------
  say:set('assertion.equal_relTol.positive', 'Expected %s to equal %s within relative tolerance %s')
  say:set('assertion.equal_relTol.negative', 'Expected %s to not equal %s within relative tolerance %s')
  assert:register('assertion', 'equal_relTol', function(_, arguments)
    local x = arguments[1]
    local y = arguments[2]
    local eps = arguments[3]
    if x == y then return true end
    
    if isInstanceOf(x, Vector) and isInstanceOf(y, Vector) then
      if x:size() ~= y:size() then return false end
      for _,e in ipairs(moses.zip(x:toArray(), y:toArray())) do
        local a = e[1]
        local b = e[2]
        local absA = math.abs(a)
        local absB = math.abs(b)
        local diff = math.abs(a - b)
        if diff >= eps * math.min(absA, absB) then return false end
      end
      return true
    end
    
    local absX = math.abs(x)
    local absY = math.abs(y)
    local diff = math.abs(x - y)
    return diff < eps * math.min(absX, absY)
  end, 'assertion.equal_relTol.positive', 'assertion.equal_relTol.negative')
  
end

return registerAsserts
