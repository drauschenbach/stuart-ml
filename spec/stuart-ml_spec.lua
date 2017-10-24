local registerAsserts = require 'registerAsserts'

registerAsserts(assert)

describe('stuart-ml module', function()

  it('loads', function()
    local stuartml = require 'stuart-ml'
    assert.is_true(stuartml ~= nil)
  end)
  
end)
