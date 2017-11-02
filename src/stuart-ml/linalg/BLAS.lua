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
  assert(x:size() == y:size())
  if y:isInstanceOf(DenseVector) then
    if x:isInstanceOf(SparseVector) then
      return M.axpy_sparse_dense(a,x,y)
    elseif x:isInstanceOf(DenseVector) then
      return M.axpy_sparse_dense(a,x:toSparse(),y)
    else
      error('axpy doesn\t support x type ' .. x.class)
    end
  end
  error('axpy only supports adding to a DenseVector but got type ' .. y.class)
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

M.dot = function(x, y)
  assert(x:size() == y:size())
  if x:isInstanceOf(DenseVector) and y:isInstanceOf(DenseVector) then
    return M.dot_sparse_dense(x:toSparse(), y)
  elseif x:isInstanceOf(SparseVector) and y:isInstanceOf(DenseVector) then
      return M.dot_sparse_dense(x, y)
  elseif x:isInstanceOf(DenseVector) and y:isInstanceOf(SparseVector) then
      return M.dot_sparse_dense(y, x)
  elseif x:isInstanceOf(SparseVector) and y:isInstanceOf(SparseVector) then
      return M.dot_sparse_sparse(x, y)
  else
    error('dot doesn\'t support (' .. x.class ',' .. y.class .. ')')
  end
end

M.dot_sparse_dense = function(x, y)
  local xValues = x.values
  local xIndices = x.indices
  local yValues = y.values
  local nnz = #xIndices

  local sum = 0.0
  for k=0,nnz-1 do
    sum = sum + xValues[k+1] * yValues[xIndices[k+1]+1]
  end
  return sum
end

M.dot_sparse_sparse = function(x, y)
  local xValues = x.values
  local xIndices = x.indices
  local yValues = y.values
  local yIndices = y.indices
  local nnzx = #xIndices
  local nnzy = #yIndices

  local kx = 0
  local ky = 0
  local sum = 0.0
  while kx < nnzx and ky < nnzy do
    local ix = xIndices[kx+1]
    while ky < nnzy and yIndices[ky+1] < ix do
      ky = ky + 1
    end
    if ky < nnzy and yIndices[ky+1] == ix then
      sum = sum + xValues[kx+1] * yValues[ky+1]
      ky = ky + 1
    end
    kx = kx + 1
  end
  return sum
end

return M
