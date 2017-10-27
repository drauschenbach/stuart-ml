local DenseVector = require 'stuart-ml.linalg.DenseVector'
local moses = require 'moses'
local SparseVector = require 'stuart-ml.linalg.SparseVector'
local unzip = require 'stuart-ml.util.unzip'

local unpack = table.unpack or unpack

local _M = {}

_M.dense = function(...)
  if moses.isTable(...) then
    return DenseVector:new(...)
  else
    local values = table.pack(...)
    values.n = nil
    return DenseVector:new(values)
  end
end

_M.norm = function(vector, p)
  assert(p >= 1.0, 'To compute the p-norm of the vector, we require that you specify a p>=1. You specified ' .. p)
  local values = vector.values
  local size = #values

  if p == 1 then
    local sum = 0.0
    for i=1,size do
      sum = sum + math.abs(values[i])
    end
    return sum
  elseif p == 2 then
    local sum = 0.0
    for i=1,size do
      sum = sum + values[i] * values[i]
    end
    return math.sqrt(sum)
  elseif p == math.huge then
    local max = 0.0
    for i=1,size do
      local value = math.abs(values[i])
      if value > max then max = value end
    end
    return max
  else
    local sum = 0.0
    for i=1,size do
      sum = sum + math.pow(math.abs(values[i]), p)
    end
    return math.pow(sum, 1.0 / p)
  end
end

_M.sparse = function(size, arg2, arg3)
  if arg3 == nil then -- arg2 is elements
    local elements = moses.sort(arg2, function(a,b)
      if moses.isTable(a) and moses.isTable(b) then return a[1] < b[1] end
    end)
    local indices, values = unpack(unzip(elements))
--    var prev = -1
--    indices.foreach { i =>
--      require(prev < i, s"Found duplicate indices: $i.")
--      prev = i
--    }
--    require(prev < size, s"You may not write an element to index $prev because the declared " +
--      s"size of your vector is $size")
    return SparseVector:new(size, indices, values)
  else -- arg2 is indices, arg3 is values
    return SparseVector:new(size, arg2, arg3)
  end
end

_M.zeros = function(size)
  local data = moses.rep(0, size)
  return DenseVector:new(data)
end

return _M
