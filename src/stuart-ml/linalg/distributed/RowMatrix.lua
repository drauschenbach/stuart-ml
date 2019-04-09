local class = require 'stuart.class'

-- Represents a row-oriented distributed Matrix with no meaningful row indices.
local RowMatrix = class.new()

function RowMatrix:_init(rows, nRows, nCols)
  self.rows = rows
  self.nRows = nRows or 0
  self.nCols = nCols or 0
end

--[[
Compute all cosine similarities between columns of this matrix using the brute-force
approach of computing normalized dot products.
--]]
function RowMatrix:columnSimilarities()
  error('NIY')
end

-- Find all similar columns using the DIMSUM sampling algorithm, described in two papers
function RowMatrix:columnSimilaritiesDIMSUM()
  error('NIY')
end

--[[
  Computes column-wise summary statistics.
--]]
function RowMatrix:computeColumnSummaryStatistics()
  local seqOp = function(aggregator, data) return aggregator:add(data) end
  local combOp = function(aggregator1, aggregator2) return aggregator1:merge(aggregator2) end
  local MultivariateOnlineSummarizer = require 'stuart-ml.stat.MultivariateOnlineSummarizer'
  local summarizer = MultivariateOnlineSummarizer.new()
  local summary = self.rows:treeAggregate(summarizer, seqOp, combOp)
  self:updateNumRows(summary:count())
  return summary
end

-- Computes the covariance matrix, treating each row as an observation.
function RowMatrix:computeCovariance()
  error('NIY')
end

-- Computes the Gramian matrix `A^T A`.
function RowMatrix:computeGramianMatrix()
  error('NIY')
end

-- Computes the top k principal components only.
function RowMatrix:computePrincipalComponents()
  error('NIY')
end

--[[
Computes the top k principal components and a vector of proportions of
variance explained by each principal component.
--]]
function RowMatrix:computePrincipalComponentsAndExplainedVariance()
  error('NIY')
end

--[[
Computes singular value decomposition of this matrix. Denote this matrix by A (m x n). This
will compute matrices U, S, V such that A ~= U * S * V', where S contains the leading k
singular values, U and V contain the corresponding singular vectors.
--]]
function RowMatrix:computeSVD()
  error('NIY')
end

-- Multiply this matrix by a local matrix on the right.
function RowMatrix:multiply()
  error('NIY')
end

-- Multiplies the Gramian matrix `A^T A` by a dense vector on the right without computing `A^T A`.
function RowMatrix:multiplyGramianMatrixBy()
  error('NIY')
end

-- Gets or computes the number of columns.
function RowMatrix:numCols()
  if self.nCols <= 0 then
    -- Calling `first` will throw an exception if `rows` is empty.
    self.nCols = self.rows:first():size()
  end
  return self.nCols
end

-- Gets or computes the number of rows.
function RowMatrix:numRows()
  if self.nRows <= 0 then
    self.nRows = self.rows:count()
    if self.nRows == 0 then
      error('Cannot determine the number of rows because it is not specified in the constructor and the rows RDD is empty')
    end
  end
  return self.nRows
end

--[[
Compute QR decomposition for RowMatrix. The implementation is designed to optimize the QR
decomposition (factorization) for the RowMatrix of a tall and skinny shape.
Reference:
  Paul G. Constantine, David F. Gleich. "Tall and skinny QR factorizations in MapReduce
  architectures" (see <a href="http://dx.doi.org/10.1145/1996092.1996103">here</a>)
--]]
function RowMatrix:tallSkinnyQR()
  error('NIY')
end

-- Fills a full square matrix from its upper triangular part.
function RowMatrix:triuToFull()
  error('NIY')
end

-- Updates or verifies the number of rows.
function RowMatrix:updateNumRows(m)
  if self.nRows <= 0 then
    self.nRows = m
  else
    assert(self.nRows == m, string.format('The number of rows %d is different from what specified or previously computed: %d', m, self.nRows))
  end
end

return RowMatrix
