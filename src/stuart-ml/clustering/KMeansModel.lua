local class = require 'middleclass'
local hasSparkSession, SparkSession = pcall(require, 'stuart-sql.SparkSession')
local isInstanceOf = require 'stuart.util'.isInstanceOf
local KMeans = require 'stuart-ml.clustering.KMeans'
local Loader = require 'stuart-ml.util.Loader'
local moses = require 'moses'
local RDD = require 'stuart.RDD'
local Vector = require 'stuart-ml.linalg.Vector'
local Vectors = require 'stuart-ml.linalg.Vectors'
local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'

local KMeansModel = class('KMeansModel')

function KMeansModel:initialize(clusterCenters)
  self.clusterCenters = clusterCenters
  if clusterCenters ~= nil then
    self.clusterCentersWithNorm = moses.map(clusterCenters, function(center) return VectorWithNorm:new(center) end)
    self.k = #clusterCenters
  end
end

function KMeansModel:__tostring()
  return string.format('KMeansModel(clusterCenters=%s)',
    table.concat(moses.map(self.clusterCenters, function(_,vector) return tostring(vector) end), ','))
end

--[[
  Return the K-means cost (sum of squared distances of points to their nearest center) for this
  model on the given data.
--]]
function KMeansModel:computeCost(rddOfVectors)
  return rddOfVectors:map(function(vector)
    return KMeans.pointCost(self.clusterCentersWithNorm, VectorWithNorm:new(vector))
  end):sum()
end

function KMeansModel.load(sc, path)
  assert(hasSparkSession)
  local spark = SparkSession.builder():sparkContext(sc):getOrCreate()
  local className, formatVersion, metadata = Loader.loadMetadata(sc, path)
  assert(className == 'org.apache.spark.mllib.clustering.KMeansModel')
  assert(formatVersion == '1.0')
  local centroids = spark.read:parquet(Loader.dataPath(path))
  --TODO Loader.checkSchema[Cluster](centroids.schema)
  local localCentroids = centroids:rdd():map(function(e) return {e[1], Vectors.dense(e[2])} end)
  assert(metadata.k == localCentroids:count())
  return KMeansModel:new(localCentroids:sortByKey():map(function(e) return e[2] end):collect())
end

function KMeansModel:predict(arg)
  -- Returns the cluster index that a given point belongs to.
  if isInstanceOf(arg, Vector) then
    local point = arg
    return KMeans.findClosest(self.clusterCentersWithNorm, VectorWithNorm:new(point))
  end
  
  -- Maps given RDD of points to their cluster indices.
  assert(isInstanceOf(arg, RDD))
  local points = arg
  return points:map(function(p)
    local bestIndex, _ = KMeans.findClosest(self.clusterCentersWithNorm, VectorWithNorm:new(p))
    return bestIndex
  end)
end

return KMeansModel
