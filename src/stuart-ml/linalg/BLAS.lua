local M = {}

--[[ y += a * x
@param a number
@param vectorX Vector
@param vectorY Vector
--]]
M.axpy = function(a, vectorX, vectorY)
  local class = require 'stuart.class'
  local istype = class.istype
  local Vector = require 'stuart-ml.linalg.Vector'
  assert(istype(vectorX, Vector))
  assert(istype(vectorY, Vector))
  assert(vectorX:size() == vectorY:size())
  local DenseVector = require 'stuart-ml.linalg.DenseVector'
  if istype(vectorY,DenseVector) then
    local SparseVector = require 'stuart-ml.linalg.SparseVector'
    if istype(vectorX,SparseVector) then
      return M.axpy_sparse_dense(a,vectorX,vectorY)
    elseif istype(vectorX,DenseVector) then
      return M.axpy_sparse_dense(a,vectorX:toSparse(),vectorY)
    else
      error('axpy doesn\'t support vectorX type ' .. vectorX.class)
    end
  end
  error('axpy only supports adding to a DenseVector but got type ' .. class.type(vectorY))
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
  local class = require 'stuart.class'
  local istype = class.istype
  local DenseVector = require 'stuart-ml.linalg.DenseVector'
  if istype(x,DenseVector) and istype(y,DenseVector) then
    return M.dot_sparse_dense(x:toSparse(), y)
  end
  local SparseVector = require 'stuart-ml.linalg.SparseVector'
  if istype(x,SparseVector) and istype(y,DenseVector) then
      return M.dot_sparse_dense(x, y)
  elseif istype(x,DenseVector) and istype(y,SparseVector) then
      return M.dot_sparse_dense(y, x)
  elseif istype(x,SparseVector) and istype(y,SparseVector) then
      return M.dot_sparse_sparse(x, y)
  else
    error(string.format("dot doesn't support (%s,%s)", class.type(x), class.type(y)))
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
