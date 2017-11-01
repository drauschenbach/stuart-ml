local BLAS = require 'stuart-ml.linalg.BLAS'
local moses = require 'moses'
local registerAsserts = require 'registerAsserts'
local Vectors = require 'stuart-ml.linalg.Vectors'

registerAsserts(assert)

describe('linalg.BLASSuite', function()

  test('axpy', function()
    local alpha = 0.1
    local sx = Vectors.sparse(3, {1,3}, {1.0,-2.0})
    local dx = Vectors.dense(1.0, 0.0, -2.0)
    local dy = {2.0, 1.0, 0.0}
    local expected = Vectors.dense(2.1, 1.0, -0.2)

    local dy1 = Vectors.dense(moses.clone(dy))
    BLAS.axpy(alpha, sx, dy1)
    assert.equal_abstol(expected, dy1, 1e-15)

    local dy2 = Vectors.dense(moses.clone(dy))
    BLAS.axpy(alpha, dx, dy2)
    assert.equal_abstol(expected, dy2, 1e-15)

    local sy = Vectors.sparse(4, {1,2}, {2.0,1.0})

    assert.has_error(function() BLAS.axpy(alpha, sx, sy) end)
    assert.has_error(function() BLAS.axpy(alpha, dx, sy) end)
    assert.has_error(function() BLAS.axpy(alpha, sx, Vectors:dense(1.0, 2.0)) end, 'vector sizes must match')
  end)

end)
