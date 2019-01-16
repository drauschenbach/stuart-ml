local class = require 'stuart.class'

--[[
  A local matrix.
--]]
local Matrix = class.new()

function Matrix:_init()
  -- Flag that keeps track whether the matrix is transposed or not. False by default.
  self.isTransposed = false
end

function Matrix:__eq(other)
  return self:toSparse() == other:toSparse()
end

--[[
  Convenience method for `Matrix`-`DenseVector` multiplication. For binary compatibility.
--]]
function Matrix:multiply()
   error('NIY')
end

-- Converts to a dense array in column major
function Matrix:toArray()
  local moses = require 'moses'
  local newArray = moses.zeros(self.numRows + self.numCols)
  self:foreachActive(function(i, j, v)
    newArray[1 + j * self.numRows + i] = v
  end)
  return newArray
end

-- A human readable representation of the matrix
-- https://github.com/scalanlp/breeze/blob/releases/v0.13.1/math/src/main/scala/breeze/linalg/Matrix.scala#L68-L122
function Matrix:toString()
  error('NIY')
end

return Matrix
