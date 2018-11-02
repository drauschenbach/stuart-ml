local M = {}

M.EPSILON = 1.0
while (1.0 + (M.EPSILON / 2.0)) ~= 1.0 do
  M.EPSILON = M.EPSILON / 2.0
end

--[[
 * Returns the squared Euclidean distance between two vectors. The following formula will be used
 * if it does not introduce too much numerical error:
 * <pre>
 *   \|a - b\|_2^2 = \|a\|_2^2 + \|b\|_2^2 - 2 a^T b.
 * </pre>
 * When both vector norms are given, this is faster than computing the squared distance directly,
 * especially when one of the vectors is a sparse vector.
 * @param v1 the first vector
 * @param norm1 the norm of the first vector, non-negative
 * @param v2 the second vector
 * @param norm2 the norm of the second vector, non-negative
 * @param precision desired relative precision for the squared distance
 * @return squared distance between v1 and v2 within the specified precision
--]]
M.fastSquaredDistance = function(v1, norm1, v2, norm2, precision)
  precision = precision or 1e-6
  local n = v1:size()
  assert(v2:size() == n)
  assert(norm1 >= 0.0 and norm2 >= 0.0)
  local sumSquaredNorm = norm1 * norm1 + norm2 * norm2
  local normDiff = norm1 - norm2
  local sqDist = 0.0
  local precisionBound1 = 2.0 * M.EPSILON * sumSquaredNorm / (normDiff * normDiff + M.EPSILON)
  local BLAS = require 'stuart-ml.linalg.BLAS'
  local SparseVector = require 'stuart-ml.linalg.SparseVector'
  local Vectors = require 'stuart-ml.linalg.Vectors'
  if precisionBound1 < precision then
    sqDist = sumSquaredNorm - 2.0 * BLAS.dot(v1, v2)
  elseif v1:isInstanceOf(SparseVector) or v2:isInstanceOf(SparseVector) then
    local dotValue = BLAS.dot(v1, v2)
    sqDist = math.max(sumSquaredNorm - 2.0 * dotValue, 0.0)
    local precisionBound2 = M.EPSILON * (sumSquaredNorm + 2.0 * math.abs(dotValue)) / (sqDist + M.EPSILON)
    if precisionBound2 > precision then
      sqDist = Vectors.sqdist(v1, v2)
    end
  else
    sqDist = Vectors.sqdist(v1, v2)
  end
  return sqDist
end

return M
