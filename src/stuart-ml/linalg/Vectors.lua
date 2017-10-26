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

_M.sparse = function(size, arg2, arg3)
  if arg3 == nil then
    -- arg2 is elements
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
  else
    -- arg2 is indices, arg3 is values
    return SparseVector:new(size, arg2, arg3)
  end
end

_M.zeros = function(size)
  local data = moses.rep(0, size)
  return DenseVector:new(data)
end

return _M
