local BLAS = require 'stuart-ml.linalg.BLAS'
local DenseVector = require 'stuart-ml.linalg.DenseVector'
local moses = require 'moses'
local registerAsserts = require 'registerAsserts'
local SparseVector = require 'stuart-ml.linalg.SparseVector'
local Vectors = require 'stuart-ml.linalg.Vectors'

registerAsserts(assert)

describe('linalg.BLASSuite', function()

  test('scal', function()
    local a = 0.1
    local sx = Vectors.sparse(3, {0,2}, {1.0, -2.0})
    local dx = Vectors.dense(1.0, 0.0, -2.0)

    BLAS.scal(a, sx)
    assert.equal_absTol(Vectors.sparse(3, {0,2}, {0.1, -0.2}), sx, 1e-15)

    BLAS.scal(a, dx)
    assert.equal_absTol(Vectors.dense(0.1, 0.0, -0.2), dx, 1e-15)
  end)

  test('axpy', function()
    local alpha = 0.1
    local sx = Vectors.sparse(3, {0,2}, {1.0, -2.0})
    local dx = Vectors.dense(1.0, 0.0, -2.0)
    local dy = {2.0, 1.0, 0.0}
    local expected = Vectors.dense(2.1, 1.0, -0.2)

    local dy1 = Vectors.dense(moses.clone(dy))
    BLAS.axpy(alpha, sx, dy1)
    assert.equal_absTol(expected, dy1, 1e-15)

    local dy2 = Vectors.dense(moses.clone(dy))
    BLAS.axpy(alpha, dx, dy2)
    assert.equal_absTol(expected, dy2, 1e-15)

    local sy = Vectors.sparse(4, {0,1}, {2.0, 1.0})

    assert.has_error(function() BLAS.axpy(alpha, sx, sy) end)
    assert.has_error(function() BLAS.axpy(alpha, dx, sy) end)
    assert.has_error(function() BLAS.axpy(alpha, sx, Vectors:dense(1.0, 2.0)) end)
  end)

  it('dot', function()
    local sx = Vectors.sparse(3, {0,2}, {1.0, -2.0})
    local dx = Vectors.dense(1.0, 0.0, -2.0)
    local sy = Vectors.sparse(3, {0,1}, {2.0, 1.0})
    local dy = Vectors.dense(2.0, 1.0, 0.0)

    assert.equal_absTol(2.0, BLAS.dot(sx, sy), 1e-15)
    assert.equal_absTol(2.0, BLAS.dot(sy, sx), 1e-15)
    assert.equal_absTol(2.0, BLAS.dot(sx, dy), 1e-15)
    assert.equal_absTol(2.0, BLAS.dot(dy, sx), 1e-15)
    assert.equal_absTol(2.0, BLAS.dot(dx, dy), 1e-15)
    assert.equal_absTol(2.0, BLAS.dot(dy, dx), 1e-15)

    assert.equal_absTol(5.0, BLAS.dot(sx, sx), 1e-15)
    assert.equal_absTol(5.0, BLAS.dot(dx, dx), 1e-15)
    assert.equal_absTol(5.0, BLAS.dot(sx, dx), 1e-15)
    assert.equal_absTol(5.0, BLAS.dot(dx, sx), 1e-15)

    local sx1 = Vectors.sparse(10, {1,4,6,8,9}, {1.0,2.0,3.0,4.0,5.0})
    local sx2 = Vectors.sparse(10, {2,4,7,8,10}, {1.0,2.0,3.0,4.0,5.0})
    assert.equal_absTol(20.0, BLAS.dot(sx1, sx2), 1e-15)
    assert.equal_absTol(20.0, BLAS.dot(sx2, sx1), 1e-15)

    assert.has_error(function() BLAS.dot(sx, Vectors.dense(2.0,1.0)) end)
  end)

  it('spr', function()
    -- test dense vector
    local alpha = 0.1
    local x = DenseVector.new({1.0, 2, 2.1, 4})
    local U = DenseVector.new({1.0, 2, 2, 3, 3, 3, 4, 4, 4, 4})
    local expected = DenseVector.new({1.1, 2.2, 2.4, 3.21, 3.42, 3.441, 4.4, 4.8, 4.84, 5.6})

    BLAS.spr(alpha, x, U)
    assert.equal_absTol(U, expected, 1e-9)

    local matrix33 = DenseVector.new({1.0, 2, 3, 4, 5})
    assert.error(function() -- Size of vector must match the rank of matrix
      BLAS.spr(alpha, x, matrix33)
    end)

    -- test sparse vector
    local sv = SparseVector.new(4, {0, 3}, {1.0, 2})
    local U2 = DenseVector.new({1.0, 2, 2, 3, 3, 3, 4, 4, 4, 4})
    BLAS.spr(0.1, sv, U2)
    local expectedSparse = DenseVector.new({1.1, 2.0, 2.0, 3.0, 3.0, 3.0, 4.2, 4.0, 4.0, 4.4})
    assert.equal_absTol(U2, expectedSparse, 1e-15)
  end)

end)
