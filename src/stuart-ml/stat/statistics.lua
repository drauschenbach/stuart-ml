local RowMatrix = require 'stuart-ml.linalg.distributed.RowMatrix'

local M = {}

--[[
  Computes column-wise summary statistics for the input RDD.
  
  @param X an RDD for which column-wise summary statistics are to be computed.
  @return table containing column-wise summary statistics.
--]]
M.colStats = function(rdd)
  return RowMatrix:new(rdd):computeColumnSummaryStatistics()
end

return M
