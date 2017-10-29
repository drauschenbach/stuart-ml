local registerAsserts = require 'registerAsserts'

registerAsserts(assert)

describe('Apache Spark TestingUtilsSuite', function()

  it('Comparing numbers using relative error', function()
    assert.equal_reltol(23.1, 23.52, 0.02)
    assert.equal_reltol(23.1, 22.74, 0.02)
    
    assert.equal_reltol_not(23.1, 23.63, 0.02)
    assert.equal_reltol_not(23.1, 22.34, 0.02)
  end)

  it('Comparing numbers using absolute error', function()
    assert.equal_abstol(17.8, 17.99, 0.2)
    assert.equal_abstol(17.8, 17.61, 0.2)
    
    assert.equal_abstol_not(17.8, 18.01, 0.2)
    assert.equal_abstol_not(17.8, 17.59, 0.2)
  end)

end)
