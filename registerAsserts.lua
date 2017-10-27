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
  say:set('assertion.equal_within_relative_tolerance.positive', 'Expected %s to equal %s within relative tolerance %s')
  say:set('assertion.equal_within_relative_tolerance.negative', 'Expected %s to not equal %s within relative tolerance %s')
  assert:register('assertion', 'equal_within_relative_tolerance', function(state, arguments)
    local value1 = arguments[1]
    local value2 = arguments[2]
    local tolerance = arguments[3]
    return math.abs(value1 - value2) <= tolerance
  end, 'assertion.equal_within_relative_tolerance.positive', 'assertion.equal_within_relative_tolerance.negative')
  
end

return registerAsserts
