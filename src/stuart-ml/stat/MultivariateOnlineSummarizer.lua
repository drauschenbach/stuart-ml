local class = require 'middleclass'
local moses = require 'moses'
local Vectors = require 'stuart-ml.linalg.Vectors'

local MultivariateOnlineSummarizer = class('MultivariateOnlineSummarizer')

function MultivariateOnlineSummarizer:initialize()
  self.n = 0
  self.currMean = {}
  self.currM2n = {}
  self.currM2 = {}
  self.currL1 = {}
  self.totalCnt = 0
  self.totalWeightSum = 0.0
  self.totalSquareSum = 0.0
  self.weightSquareSum = 0.0
  self.weightSum = {}
  self.nnz = {}
  self.currMax = {}
  self.currMin = {}
  getmetatable(self).__tostring = function()
    print(string.format('n=%d totalCnt=%d totalWeightSum=%d totalSquareSum=%d weightSquareSum=%d',
      self.n, self.totalCnt, self.totalWeightSum, self.totalSquareSum, self.weightSquareSum))
  end
end

--[[
  Add a new sample to this summarizer, and update the statistical summary.

  @param instance The sample in dense/sparse vector format to be added into this summarizer.
  @return This MultivariateOnlineSummarizer object.
--]]
function MultivariateOnlineSummarizer:add(instance, weight)
  weight = weight or 1.0
  assert(weight >= 0.0, 'sample weight has to be >= 0.0')
  if weight == 0.0 then return self end

  if self.n == 0 then
    self.n = instance:size()
    assert(self.n > 0, 'Vector should have dimension larger than zero')

    self.currMean = moses.fill({}, 0.0, 1, self.n)
    self.currM2n = moses.fill({}, 0.0, 1, self.n)
    self.currM2 = moses.fill({}, 0.0, 1, self.n)
    self.currL1 = moses.fill({}, 0.0, 1, self.n)
    self.weightSum = moses.fill({}, 0.0, 1, self.n)
    self.nnz = moses.zeros(self.n)
    self.currMax = moses.fill({}, -math.huge, 1, self.n)
    self.currMin = moses.fill({}, math.huge, 1, self.n)
  end

  assert(self.n == instance:size(), 'Dimensions mismatch when adding new sample')

  instance:foreachActive(function(index, value)
    if value ~= 0.0 then
      if self.currMax[index+1] < value then
        self.currMax[index+1] = value
      end
      if self.currMin[index+1] > value then
        self.currMin[index+1] = value
      end
      
      local prevMean = self.currMean[index+1]
        
      local diff = value - prevMean
      self.currMean[index+1] = prevMean + weight * diff / (self.weightSum[index+1] + weight)
      self.currM2n[index+1] = weight * (value - self.currMean[index+1]) * diff
      self.currM2[index+1] = self.currM2[index+1] + weight * value * value
      self.currL1[index+1] = self.currL1[index+1] + weight * math.abs(value)
      
      self.weightSum[index+1] = self.weightSum[index+1] + weight
      self.nnz[index+1] = self.nnz[index+1] + 1
    end
  end)

  self.totalWeightSum = self.totalWeightSum + weight
  self.weightSquareSum = self.weightSquareSum + weight * weight
  self.totalCnt = self.totalCnt + 1
  return self
end

--[[
  Merge another MultivariateOnlineSummarizer, and update the statistical summary.
  (Note that it's in place merging; as a result, `this` object will be modified.)

  @param other The other MultivariateOnlineSummarizer to be merged.
  @return This MultivariateOnlineSummarizer object.
--]]
function MultivariateOnlineSummarizer:merge(other)
  if self.totalWeightSum ~= 0.0 and other.totalWeightSum ~= 0.0 then
    assert(self.n == other.n, 'Dimensions mismatch when merging with another summarizer')
    self.totalCnt = self.totalCnt + other.totalCnt
    self.totalWeightSum = self.totalWeightSum + other.totalWeightSum
    self.weightSquareSum = self.weightSquareSum + other.weightSquareSum
    for i=1,self.n do
      local thisNnz = self.weightSum[i]
      local otherNnz = other.weightSum[i]
      local totalNnz = thisNnz + otherNnz
      local totalCnnz = self.nnz[i] + other.nnz[i]
      if totalNnz ~= 0.0 then
        local deltaMean = other.currMean[i] - self.currMean[i]
        -- merge mean together
        self.currMean[i] = self.currMean[i] + deltaMean * otherNnz / totalNnz
        -- merge m2n together
        self.currM2n[i] = self.currM2n[i] + other.currM2n[i] + deltaMean * deltaMean * thisNnz * otherNnz / totalNnz
        -- merge m2 together
        self.currM2[i] = self.currM2[i] + other.currM2[i]
        -- merge l1 together
        self.currL1[i] = self.currL1[i] + other.currL1[i]
        -- merge max and min
        self.currMax[i] = math.max(self.currMax[i], other.currMax[i])
        self.currMin[i] = math.min(self.currMin[i], other.currMin[i])
      end
      self.weightSum[i] = totalNnz
      self.nnz[i] = totalCnnz
    end
  elseif self.totalWeightSum == 0.0 and other.totalWeightSum ~= 0.0 then
    self.n = other.n
    self.currMean = moses.clone(other.currMean)
    self.currM2n = moses.clone(other.currM2n)
    self.currM2 = moses.clone(other.currM2)
    self.currL1 = moses.clone(other.currL1)
    self.totalCnt = other.totalCnt
    self.totalWeightSum = other.totalWeightSum
    self.weightSquareSum = other.weightSquareSum
    self.weightSum = moses.clone(other.weightSum)
    self.nnz = moses.clone(other.nnz)
    self.currMax = moses.clone(other.currMax)
    self.currMin = moses.clone(other.currMin)
  end
  return self
end

-- Sample mean of each dimension.
function MultivariateOnlineSummarizer:mean()
  assert(self.totalWeightSum > 0, 'Nothing has been added to this summarizer')
  local realMean = moses.fill({}, 0.0, 1, self.n)
  for i=1,self.n do
    realMean[i] = self.currMean[i] * (self.weightSum[i] / self.totalWeightSum)
  end
  return Vectors.dense(realMean)
end

-- Unbiased estimate of sample variance of each dimension.
function MultivariateOnlineSummarizer:variance()
  assert(self.totalWeightSum > 0, 'Nothing has been added to this summarizer')
  local realVariance = moses.fill({}, 0.0, 1, self.n)
  local denominator = self.totalWeightSum - self.weightSquareSum / self.totalWeightSum

  -- Sample variance is computed, if the denominator is less than 0, the variance is just 0.
  if denominator > 0.0 then
    local deltaMean = moses.clone(self.currMean)
    for i=1, #self.currM2n do
      realVariance[i] = (self.currM2n[i] + deltaMean[i] * deltaMean[i] + self.weightSum[i]
        * (self.totalWeightSum - self.weightSum[i]) / self.totalWeightSum) / denominator
    end
  end
  return Vectors.dense(realVariance)
end

-- Sample size.
function MultivariateOnlineSummarizer:count()
  return self.totalCnt
end

-- Number of nonzero elements in each dimension.
function MultivariateOnlineSummarizer:numNonzeros()
  assert(self.totalWeightSum > 0, 'Nothing has been added to this summarizer')
  return Vectors.dense(self.nnz)
end

-- Maximum value of each dimension.
function MultivariateOnlineSummarizer:max()
  assert(self.totalWeightSum > 0, 'Nothing has been added to this summarizer')
  for i=1,self.n do
    if self.nnz[i] < self.totalCnt and self.currMax[i] < 0.0 then
      self.currMax[i] = 0.0
    end
  end
  return Vectors.dense(self.currMax)
end

-- Minimum value of each dimension.
function MultivariateOnlineSummarizer:min()
  assert(self.totalWeightSum > 0, 'Nothing has been added to this summarizer')
  for i=1,self.n do
    if (self.nnz[i] < self.totalCnt) and (self.currMin[i] > 0.0) then
      self.currMin[i] = 0.0
    end
  end
  return Vectors.dense(self.currMin)
end

-- L2 (Euclidian) norm of each dimension.
function MultivariateOnlineSummarizer:normL2()
  assert(self.totalWeightSum > 0, 'Nothing has been added to this summarizer')
  local realMagnitude = moses.fill({}, 0.0, 1, self.n)
  for i=1,#self.currM2 do
    realMagnitude[i] = math.sqrt(self.currM2[i])
  end
  return Vectors.dense(realMagnitude)
end

-- L1 norm of each dimension.
function MultivariateOnlineSummarizer:normL1()
  assert(self.totalWeightSum > 0, 'Nothing has been added to this summarizer')
  return Vectors.dense(self.currL1)
end

return MultivariateOnlineSummarizer
