local DenseVector = require 'stuart-ml.linalg.DenseVector'
local isInstanceOf = require 'stuart.util.isInstanceOf'
local SparseVector = require 'stuart-ml.linalg.SparseVector'
local Vector = require 'stuart-ml.linalg.Vector'

local M = {}

--[[ y += a * x
@param a number
@param vectorX Vector
@param vectorY Vector
--]]
M.axpy = function(a, vectorX, vectorY)
  assert(isInstanceOf(vectorX, Vector))
  assert(isInstanceOf(vectorY, Vector))
  assert(vectorX:size() == vectorY:size())
  if vectorY:isInstanceOf(DenseVector) then
    if vectorX:isInstanceOf(SparseVector) then
      return M.axpy_sparse_dense(a,vectorX,vectorY)
    elseif vectorX:isInstanceOf(DenseVector) then
      return M.axpy_sparse_dense(a,vectorX:toSparse(),vectorY)
    else
      error('axpy doesn\t support vectorX type ' .. vectorX.class)
    end
  end
  error('axpy only supports adding to a DenseVector but got type ' .. vectorY.class)
end

M.axpy_sparse_dense = function(a, x, y)
  local nnz = #x.indices
  if a == 1.0 then
    for k=1,nnz do
      y.values[x.indices[k]+1] = y.values[x.indices[k]+1] + x.values[k]
    end
  else
    for k=1,nnz do
      y.values[x.indices[k]+1] = y.values[x.indices[k]+1] + a * x.values[k]
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
  local nnz = #x.indices
  local sum = 0.0
  for k=1,nnz do
    sum = sum + x.values[k] * y.values[x.indices[k]+1]
  end
  return sum
end

M.dot_sparse_sparse = function(x, y)
  local nnzx = #x.indices
  local nnzy = #y.indices
  local kx = 0
  local ky = 0
  local sum = 0.0
  while kx < nnzx and ky < nnzy do
    local ix = x.indices[kx+1]
    while ky < nnzy and y.indices[ky+1] < ix do
      ky = ky + 1
    end
    if ky < nnzy and y.indices[ky+1] == ix then
      sum = sum + x.values[kx+1] * y.values[ky+1]
      ky = ky + 1
    end
    kx = kx + 1
  end
  return sum
end

--[[ x = a * x
--]]
M.scal = function(a, x)
  for i=1,#x.values do
    x.values[i] = a * x.values[i]
  end
end

return M
