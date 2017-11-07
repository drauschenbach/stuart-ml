local BLAS = require 'stuart-ml.linalg.BLAS'
local registerAsserts = require 'registerAsserts'
local Vectors = require 'stuart-ml.linalg.Vectors'

registerAsserts(assert)

describe('linalg.BLAS', function()

  test('numNonzeros is accurate after axpy() changes the vector', function()
    local vectorY = Vectors.zeros(3)
    assert.same({0,0,0}, vectorY.values)
    assert.equal(0, vectorY:numNonzeros())

    local vectorX = Vectors.dense({1,2,3})
    assert.same({1,2,3}, vectorX.values)
    assert.equal(3, vectorX:numNonzeros())
    
    local alpha = 10
    BLAS.axpy(alpha, vectorX, vectorY)
    
    assert.same({10,20,30}, vectorY.values)
    assert.equal(3, vectorY:numNonzeros())
  end)

end)
