local class = require 'middleclass'
local Vector = require 'stuart-ml.linalg.Vector'
local Vectors = require 'stuart-ml.linalg.Vectors'

-- A vector with its norm for fast distance computation.
--
-- @see [[org.apache.spark.mllib.clustering.KMeans#fastSquaredDistance]]

local VectorWithNorm = class('VectorWithNorm')

function VectorWithNorm:initialize(arg1, norm)
  if not arg1.isInstanceOf or not arg1:isInstanceOf(Vector) then
    -- arg1 is an array
    self.vector = Vectors.dense(arg1)
  else
    -- arg1 is a Vector
    self.vector = arg1
  end
  self.norm = norm or 2.0
end

function VectorWithNorm:__tostring()
  return '(' .. tostring(self.vector) .. ',' .. self.norm .. ')'
end

function VectorWithNorm:toDense()
  return VectorWithNorm:new(self.vector:toDense(), self.norm)
end

return VectorWithNorm
