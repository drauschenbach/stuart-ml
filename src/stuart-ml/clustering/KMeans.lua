local class = require 'middleclass'
local MLUtils = require 'stuart-ml.util.MLUtils'

local RANDOM = "random"
local K_MEANS_PARALLEL = "k-means||"

local KMeans = class('KMeans')
KMeans.RANDOM = RANDOM
KMeans.K_MEANS_PARALLEL = K_MEANS_PARALLEL

function KMeans:initialize(k, maxIterations, initializationMode, initializationSteps, epsilon, seed)
  self.k = k or 2
  self.maxIterations = maxIterations or 20
  self.initializationMode = initializationMode or K_MEANS_PARALLEL
  self.initializationSteps = initializationSteps or 2
  self.epsilon = epsilon or 1e-4
  self.seed = seed or math.random(32000)
end

-- Returns the squared Euclidean distance between two vectors
function KMeans.fastSquaredDistance(vectorWithNorm1, vectorWithNorm2)
  return MLUtils.fastSquaredDistance(vectorWithNorm1.vector, vectorWithNorm1.norm, vectorWithNorm2.vector, vectorWithNorm2.norm)
end

-- returns a Lua 1-based index
function KMeans.findClosest(centers, point)
  local bestDistance = math.huge
  local bestIndex = 1
  for i,center in ipairs(centers) do
    local lowerBoundOfSqDist = center.norm - point.norm
    lowerBoundOfSqDist = lowerBoundOfSqDist * lowerBoundOfSqDist
    if lowerBoundOfSqDist < bestDistance then
      local distance = KMeans.fastSquaredDistance(center, point)
      if distance < bestDistance then
        bestDistance = distance
        bestIndex = i
      end
    end
  end
  return bestIndex, bestDistance
end

function KMeans:getInitializationMode()
  return self.initializationMode
end

function KMeans:getInitializationSteps()
  return self.initializationSteps
end

function KMeans:getK()
  return self.k
end

function KMeans:getMaxIterations()
  return self.maxIterations
end

function KMeans:getSeed()
  return self.seed
end

function KMeans:initKMeansParallel()
  error('not implemented yet')
end

function KMeans:initRandom(vectorsWithNormsRDD)
  return vectorsWithNormsRDD:takeSample(false, self.k, os.clock()*1e6)
end

function KMeans.pointCost(centers, point)
  local _, bestDistance = KMeans.findClosest(centers, point)
  return bestDistance
end

function KMeans:setInitialModel(model)
  assert(model.k == self.k, 'mismatched cluster count')
  self.initialModel = model
  return self
end

function KMeans:setInitializationMode(initializationMode)
  assert(initializationMode == KMeans.RANDOM or KMeans.RANDOM == KMeans.K_MEANS_PARALLEL)
  self.initializationMode = initializationMode
  return self
end

function KMeans:setInitializationSteps(initializationSteps)
  assert(initializationSteps > 0, 'Number of initialization steps must be positive but got ' .. initializationSteps)
  self.initializationSteps = initializationSteps
  return self
end

function KMeans:setK(k)
  assert(k > 0, 'Number of clusters must be positive but got ' .. k)
  self.k = k
  return self
end

function KMeans:setMaxIterations(maxIterations)
  assert(maxIterations >= 0, 'Maximum of iterations must be nonnegative but got ' .. maxIterations)
  self.maxIterations = maxIterations
  return self
end

function KMeans:setSeed(seed)
  self.seed = seed
  return self
end

function KMeans.train(rdd, k, maxIterations, initializationMode, seed)
  return KMeans:new()
    :setK(k)
    :setMaxIterations(maxIterations)
    :setInitializationMode(initializationMode)
    :setSeed(seed)
    :run(rdd)
end

return KMeans
