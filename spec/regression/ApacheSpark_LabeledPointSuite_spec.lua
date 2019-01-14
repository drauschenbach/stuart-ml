local LabeledPoint = require 'stuart-ml.regression.LabeledPoint'
local moses = require 'moses'
local registerAsserts = require 'registerAsserts'
local Vectors = require 'stuart-ml.linalg.Vectors'

registerAsserts(assert)

describe('Apache Spark MLlib LabeledPointSuite', function()

  it('parse labeled points', function()
    local points = {
      LabeledPoint.new(1.0, Vectors.dense(1.0, 0.0)),
      LabeledPoint.new(0.0, Vectors.sparse(2, {1}, {-1.0}))
    }
    moses.forEach(points, function(p)
      assert.same(p, LabeledPoint.parse(tostring(p)))
    end)
  end)

  it('parse labeled points with whitespaces', function()
    local point = LabeledPoint.parse('(0.0, [1.0, 2.0])')
    assert.same(LabeledPoint.new(0.0, Vectors.dense(1.0, 2.0)), point)
  end)
  
  it('parse labeled points with v0.9 format', function()
    local point = LabeledPoint.parse('1.0,1.0 0.0 -2.0')
    assert.same(LabeledPoint.new(1.0, Vectors.dense(1.0, 0.0, -2.0)), point)
  end)
  
--  it('conversions between new ml LabeledPoint and mllib LabeledPoint', function()
--  end)
  
end)
