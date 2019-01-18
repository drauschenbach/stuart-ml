local registerAsserts = require 'registerAsserts'
local unzip = require 'stuart-ml.util'.unzip

registerAsserts(assert)

describe('util/unzip', function()

  it('unzips according to lodash spec', function()
    local actual = unzip({{'a',1,true}, {'b',2,false}})
    local expected = {{'a','b'}, {1,2}, {true,false}}
    assert.same(expected, actual)
  end)
  
  it('unzips like lodash.js with empty array', function()
    local actual = unzip({})
    local expected = {}
    assert.same(expected, actual)
  end)
  
end)
