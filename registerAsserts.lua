local moses = require 'moses'
local say = require 'say'

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
    local absX = math.abs(x)
    local absY = math.abs(y)
    local diff = math.abs(x - y)
    return diff < eps * math.min(absX, absY)
  end, 'assertion.equal_reltol.positive', 'assertion.equal_reltol.negative')
  
end

return registerAsserts
