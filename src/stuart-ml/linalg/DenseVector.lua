local class = require 'middleclass'
local moses = require 'moses'
moses.range = require 'stuart-ml.util.mosesPatchedRange'
local SparseVector = require 'stuart-ml.linalg.SparseVector'
local Vector = require 'stuart-ml.linalg.Vector'

local DenseVector = class('DenseVector', Vector)

function DenseVector:initialize(values)
  Vector.initialize(self)
  self.values = values
  self.numActives = #values
  
  local nnz = 0
  for _,v in ipairs(values) do
    if v ~= 0.0 then nnz = nnz + 1 end
  end
  self.numNonzeros = nnz
end

function DenseVector.__eq(a, b)
  if a:size() ~= b:size() then return false end
  return moses.same(a.values, b.values)
end

function DenseVector:__index(key)
  return self.values[key]
end

function DenseVector:__tostring()
  return '{' .. table.concat(self.values,',') .. '}'
end

function DenseVector:argmax()
  if self:size() == 0 then
    return -1
  else
    local maxIdx = -1
    local maxValue = self.values[1]
    for i, value in ipairs(self.values) do
      if value > maxValue then
        maxIdx = i
        maxValue = value
      end
    end
    return maxIdx
  end
end

function DenseVector:copy()
  return DenseVector:new(moses.clone(self.values))
end

function DenseVector:foreachActive(f)
  for i,value in ipairs(self.values) do
    f(i-1, value)
  end
end

function DenseVector:size()
  return #self.values
end

function DenseVector:toArray()
  return self.values
end

function DenseVector:toDense()
  return self
end

function DenseVector:toSparse()
  local ii = {}
  local vv = {}
  self:foreachActive(function(i,v)
    if v ~= 0 then
      ii[#ii+1] = i
      vv[#vv+1] = v
    end
  end)
  return SparseVector:new(self:size(), ii, vv)
end

return DenseVector
