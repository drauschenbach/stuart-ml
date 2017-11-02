--[[
BLAS routines for MLlib's vectors and matrices.
--]]

local DenseVector = require 'stuart-ml.linalg.DenseVector'
local SparseVector = require 'stuart-ml.linalg.SparseVector'

local M = {}

--[[ y += a * x
@param a number
@param x Vector
@param y Vector
--]]
M.axpy = function(a, x, y)
  assert(x:size() == y:size(), 'vector sizes must match')
  if y:isInstanceOf(DenseVector) then
    if x:isInstanceOf(SparseVector) then
      return M.axpy_sparse_dense(a,x,y)
    elseif x:isInstanceOf(DenseVector) then
      return M.axpy_sparse_dense(a,x:toSparse(),y)
    else
      error('axpy doesn\t support x type ' .. x.class)
    end
  end
  error('axpy only supports adding to a dense vector but got type ' .. y.class)
end

--[[ y += a * x
@param a number
@param x SparseVector
@param y DenseVector
--]]
M.axpy_sparse_dense = function(a, x, y)
  local xValues = x.values
  local xIndices = x.indices
  local yValues = y.values
  local nnz = #xIndices

  if a == 1.0 then
    for k=0,nnz-1 do
      yValues[xIndices[k+1]+1] = yValues[xIndices[k+1]+1] + xValues[k+1]
    end
  else
    for k=0,nnz-1 do
      yValues[xIndices[k+1]+1] = yValues[xIndices[k+1]+1] + a * xValues[k+1]
    end
  end
end

return M
