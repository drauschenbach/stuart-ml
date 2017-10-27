local registerAsserts = require 'registerAsserts'
local Vectors = require 'stuart-ml.linalg.Vectors'
local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'

registerAsserts(assert)

describe('clustering.VectorWithNorm', function()

  it('constructs a DenseVector from an array', function()
    local values = {0.1, 0.3, 4}
    local norm = 2
    local vecWithNorm = VectorWithNorm:new(values, norm)
    local expected = '([0.1,0.3,4],2)'
    local actual = tostring(vecWithNorm)
    assert.equal(expected, actual)
  end)
  
  it('stringifies a DenseVector', function()
    local values = {0.1, 0.3, 4}
    local norm = 2
    local vec = Vectors.dense(values)
    local vecWithNorm = VectorWithNorm:new(vec, norm)
    local expected = '([0.1,0.3,4],2)'
    local actual = tostring(vecWithNorm)
    assert.equal(expected, actual)
  end)
  
  it('stringifies a SparseVector', function()
    local indices = {1, 3, 4}
    local values = {0.1, 0.3, 4}
    local norm = 2
    local vec = Vectors.sparse(3, indices, values)
    local vecWithNorm = VectorWithNorm:new(vec, norm)
    local expected = '((3,[1,3,4],[0.1,0.3,4]),2)'
    local actual = tostring(vecWithNorm)
    assert.equal(expected, actual)
  end)
  
  it('converts to DenseVector', function()
    local indices = {1, 3, 4}
    local values = {0.1, 0.3, 4}
    local norm = 3
    local vec = Vectors.sparse(3, indices, values)
    local vecWithNorm = VectorWithNorm:new(vec, norm):toDense()
    local expected = '([0.1,0,0.3,4],3)'
    local actual = tostring(vecWithNorm)
    assert.equal(expected, actual)
  end)
  
end)
