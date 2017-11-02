local registerAsserts = require 'registerAsserts'
local Vectors = require 'stuart-ml.linalg.Vectors'

registerAsserts(assert)

describe('Apache Spark TestingUtilsSuite', function()

  it('Comparing numbers using relative error', function()
    assert.equal_relTol(23.1, 23.52, 0.02)
    assert.equal_relTol(23.1, 22.74, 0.02)
    
    assert.equal_relTol_not(23.1, 23.63, 0.02)
    assert.equal_relTol_not(23.1, 22.34, 0.02)
  end)

  it('Comparing numbers using absolute error', function()
    assert.equal_absTol(17.8, 17.99, 0.2)
    assert.equal_absTol(17.8, 17.61, 0.2)
    
    assert.equal_absTol_not(17.8, 18.01, 0.2)
    assert.equal_absTol_not(17.8, 17.59, 0.2)
  end)

  it('Comparing vectors using relative error', function()
    -- comparisons of two dense vectors
    assert.equal_relTol(Vectors.dense({3.1,3.5}), Vectors.dense({3.130,3.534}), 0.01)
    assert.equal_relTol_not(Vectors.dense({3.1,3.5}), Vectors.dense({3.135,3.534}), 0.01)
    
    -- comparison of a dense vector and a sparse vector
    assert.equal_relTol(Vectors.dense({3.1,3.5}), Vectors.sparse(2, {0,1}, {3.130,3.534}), 0.01)
    assert.equal_relTol_not(Vectors.dense({3.1,3.5}), Vectors.sparse(2, {0,1}, {3.135,3.534}), 0.01)
  end)

  it('Comparing vectors using absolute error', function()
    -- comparisons of two dense vectors
    assert.equal_absTol(Vectors.dense({3.1, 3.5, 0.0}), Vectors.dense({3.1+1e-8, 3.5+2e-7, 1e-8}), 1e-6)
    assert.equal_absTol_not(Vectors.dense({3.1, 3.5, 0.0}), Vectors.dense({3.1+1e-5,3.5+2e-7,1+1e-3}), 1e-6)
    
    -- comparisons of two sparse vectors
    assert.equal_absTol(Vectors.sparse(3, {0,2}, {3.1,2.4}), Vectors.sparse(3, {0,2}, {3.1,2.4}), 1e-6)
    assert.equal_absTol(Vectors.sparse(3, {0,2}, {3.1+1e-8, 2.4+1e-7}), Vectors.sparse(3, {0,2}, {3.1,2.4}), 1e-6)
    assert.equal_absTol_not(Vectors.sparse(3, {0,2}, {3.1,2.4}), Vectors.sparse(3, {0,2}, {3.1+1e-3, 2.4}), 1e-6)
    assert.equal_absTol_not(Vectors.sparse(3, {0,2}, {3.1+1e-3, 2.4}), Vectors.sparse(3, {0,2}, {3.1, 2.4}), 1e-6)
    
    -- comparison of a dense vector and a sparse vector
    assert.equal_absTol(Vectors.sparse(3, {0,2}, {3.1,2.4}), Vectors.dense({3.1+1e-8, 0, 2.4+1e-7}), 1e-6)
    assert.equal_absTol(Vectors.dense({3.1+1e-8, 0, 2.4+1e-7}), Vectors.sparse(3, {0,2}, {3.1,2.4}), 1e-6)
    assert.equal_absTol_not(Vectors.sparse(3, {0,2}, {3.1,2.4}), Vectors.dense({3.1, 1e-3, 2.4}), 1e-6)
  end)

end)
