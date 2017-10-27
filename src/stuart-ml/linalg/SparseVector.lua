local class = require 'middleclass'
local moses = require 'moses'
local Vector = require 'stuart-ml.linalg.Vector'

local SparseVector = class('SparseVector', Vector)

function SparseVector:initialize(size, indices, values)
  Vector.initialize(self)
  self._size = size
  self.indices = indices
  self.values = values
  self.numActives = #values
  self.numNonzeros = moses.reduce(values, function(r,v)
    if v ~= 0 then r = r + 1 end
    return r
  end, 0)
end

function SparseVector.__eq(a, b)
  if a:size() ~= b:size() then return false end
  if b:isInstanceOf(SparseVector) then
    if not moses.same(a.indices, b.indices) then return false end
    return moses.same(a.values, b.values)
  end
  
  -- This next section only runs in Lua 5.3+, and supports the equality test
  -- of a SparseVector against a DenseVector
  local DenseVector = require 'stuart-ml.linalg.DenseVector'
  if b:isInstanceOf(DenseVector) then
    if not moses.same(a.values, b.values) then return false end
    local bIndices = moses.range(1, a:size())
    return moses.same(a.indices, bIndices)
  end
  
  return false
end

function SparseVector:__index(key)
  local i = moses.indexOf(self.indices, key)
  if i == nil then return 0 end
  return self.values[i]
end

function SparseVector:__tostring()
  return '(' .. self._size .. ',['
    .. table.concat(self.indices,',') .. '],['
    .. table.concat(self.values,',') .. '])'
end

function SparseVector:argmax()
  if self._size == 0 then return -1 end
  if self.numActives == 0 then return 0 end
  -- Find the max active entry.
  local maxIdx = self.indices[1]
  local maxValue = self.values[1]
  local maxJ = 0
  local na = self.numActives
  for j=1,na do
    local v = self.values[j]
    if v > maxValue then
      maxValue = v
      maxIdx = self.indices[j]
      maxJ = j
    end
  end

  -- If the max active entry is nonpositive and there exists inactive ones, find the first zero.
  if maxValue <= 0.0 and na < self._size then
    if maxValue == 0.0 then
      -- If there exists an inactive entry before maxIdx, find it and return its index.
      if maxJ < maxIdx then
        local k = 1
        while k < maxJ and self.indices[k] == k do k = k + 1 end
        maxIdx = k
      end
    else
      local k = 0
      while k < na and self.indices[k] == k do k = k + 1 end
      maxIdx = k
    end
  end

  return maxIdx
end

function SparseVector:copy()
  return SparseVector:new(self._size, moses.clone(self.indices), moses.clone(self.values))
end

function SparseVector:foreachActive(f)
  for i,value in ipairs(self.values) do
    f(self.indices[i], value)
  end
end

function SparseVector:size()
  return self._size
end

function SparseVector:toArray()
  local data = moses.rep(0, self._size)
  for i,k in ipairs(self.indices) do
    data[k] = self.values[i]
  end
  return data
end

function SparseVector:toDense()
  local DenseVector = require 'stuart-ml.linalg.DenseVector'
  return DenseVector:new(self:toArray())
end

function SparseVector:toSparse()
  if self.numActives == self.numNonzeros then return self end
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

return SparseVector
