local class = require 'stuart.class'
local Matrix = require 'stuart-ml.linalg.Matrix'

--[[
  Column-major dense matrix.
  The entry values are stored in a single array of doubles with columns listed in sequence.
  For example, the following matrix
  {{{
    1.0 2.0
    3.0 4.0
    5.0 6.0
  }}}
  is stored as `[1.0, 3.0, 5.0, 2.0, 4.0, 6.0]`.
--]]
local DenseMatrix = class.new(Matrix)

--[[
  @param numRows number of rows
  @param numCols number of columns
  @param values matrix entries in column major if not transposed or in row major otherwise
  @param isTransposed whether the matrix is transposed. If true, `values` stores the matrix in
                      row major.
--]]
function DenseMatrix:_init(numRows, numCols, values, isTransposed)
  assert(#values == numRows * numCols)
  Matrix:_init(self)
  self.numRows = numRows
  self.numCols = numCols
  self.values = values
  self.isTransposed = isTransposed or false
end

function DenseMatrix:__eq(other)
  if not class.istype(other, Matrix) then return false end
  if self.numRows ~= other.numRows or self.numCols ~= other.numCols then return false end
  for row = 0, self.numRows-1 do
    for col = 0, self.numCols-1 do
      if self.values[self:index(row,col)] ~= other.values[other:index(row,col)] then return false end
    end
  end
  return true
end

function DenseMatrix:apply()
  error('NIY')
end

function DenseMatrix:asBreeze()
  error('NIY')
end

function DenseMatrix:copy()
  error('NIY')
end

function DenseMatrix:foreachActive()
  error('NIY')
end

function DenseMatrix:index(i, j)
  assert(i >= 0 and i < self.numRows)
  assert(j >= 0 and j < self.numCols)
  if not self.isTransposed then
    return 1 + i + self.numRows * j
  else
    return 1 + j + self.numCols * i
  end
end

function DenseMatrix:map()
  error('NIY')
end

function DenseMatrix:numActives()
  return #self.values
end

function DenseMatrix:numNonzeros()
  local moses = require 'moses'
  return moses.countf(self.values, function(x) return x ~= 0 end)
end

function DenseMatrix.ones(numRows, numCols)
  local moses = require 'moses'
  return DenseMatrix.new(numRows, numCols, moses.ones(numRows*numCols))
end

--[[
  Generate a `SparseMatrix` from the given `DenseMatrix`. The new matrix will have isTransposed
  set to false.
--]]
function DenseMatrix:toSparse()
  local spVals = {}
  local moses = require 'moses'
  local colPtrs = moses.zeros(self.numCols+1)
  local rowIndices = {}
  local nnz = 0
  for j = 0, self.numCols-1 do
    for i = 0, self.numRows-1 do
      local v = self.values[self:index(i,j)]
      if v ~= 0.0 then
        rowIndices[#rowIndices+1] = i
        spVals[#spVals+1] = v
        nnz = nnz + 1
      end
    end
    colPtrs[j+2] = nnz
  end
  local SparseMatrix = require 'stuart-ml.linalg.SparseMatrix'
  return SparseMatrix.new(self.numRows, self.numCols, colPtrs, rowIndices, spVals)
end

function DenseMatrix:transpose()
  return DenseMatrix.new(self.numCols, self.numRows, self.values, not self.isTransposed)
end

function DenseMatrix:update()
  error('NIY')
end

function DenseMatrix.zeros(numRows, numCols)
  local moses = require 'moses'
  return DenseMatrix.new(numRows, numCols, moses.zeros(numRows*numCols))
end

return DenseMatrix
