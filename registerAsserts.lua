local moses = require 'moses'
local say = require 'say'
local Vector = require 'stuart-ml.linalg.Vector'

local registerAsserts = function(assert)

  -----------------------------------------------------------------------------
  say:set('assertion.contains.positive', 'Expected %s to contain %s')
  say:set('assertion.contains.negative', 'Expected %s to not contain %s')
  assert:register('assertion', 'contains', function(state, arguments)
    local collection = arguments[1]
    local searchFor = arguments[2]
    return moses.findIndex(collection, function(i,v) return v == searchFor end) ~= nil
  end, 'assertion.contains.positive', 'assertion.contains.negative')
  
  -----------------------------------------------------------------------------
  say:set('assertion.equal_abstol.positive', 'Expected %s to equal %s within absolute tolerance %s')
  say:set('assertion.equal_abstol.negative', 'Expected %s to not equal %s within absolute tolerance %s')
  assert:register('assertion', 'equal_abstol', function(state, arguments)
    local x = arguments[1]
    local y = arguments[2]
    local eps = arguments[3]
    if x == y then return true end
    
    if moses.isTable(x) and x.isInstanceOf and x:isInstanceOf(Vector) and y.isInstanceOf and y:isInstanceOf(Vector) then
      if x:size() ~= y:size() then return false end
      for _,e in ipairs(moses.zip(x:toArray(), y:toArray())) do
        local a = e[1]
        local b = e[2]
        local absA = math.abs(a)
        local absB = math.abs(b)
        if math.abs(a - b) >= eps then return false end
      end
      return true
    end
    
    return math.abs(x - y) < eps
  end, 'assertion.equal_abstol.positive', 'assertion.equal_abstol.negative')
  
  -----------------------------------------------------------------------------
  say:set('assertion.equal_reltol.positive', 'Expected %s to equal %s within relative tolerance %s')
  say:set('assertion.equal_reltol.negative', 'Expected %s to not equal %s within relative tolerance %s')
  assert:register('assertion', 'equal_reltol', function(state, arguments)
    local x = arguments[1]
    local y = arguments[2]
    local eps = arguments[3]
    if x == y then return true end
    
    if moses.isTable(x) and x.isInstanceOf and x:isInstanceOf(Vector) and y.isInstanceOf and y:isInstanceOf(Vector) then
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
  end, 'assertion.equal_reltol.positive', 'assertion.equal_reltol.negative')
  
end

return registerAsserts
