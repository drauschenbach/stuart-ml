local class = require 'middleclass'
local Loader = require 'stuart-ml.util.Loader'
local moses = require 'moses'
local SparkSession = require 'stuart-sql.SparkSession'
local Vectors = require 'stuart-ml.linalg.Vectors'
local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'

local KMeansModel = class('KMeansModel')

function KMeansModel:initialize(clusterCenters)
  self.clusterCenters = clusterCenters
  if clusterCenters ~= nil then
    self.clusterCentersWithNorm = moses.map(clusterCenters, function(center) return VectorWithNorm:new(center) end)
  end
end

function KMeansModel.load(sc, path)
  local spark = SparkSession.builder():sparkContext(sc):getOrCreate()
  local className, formatVersion, metadata = Loader.loadMetadata(sc, path)
  assert(className == 'org.apache.spark.mllib.clustering.KMeansModel')
  assert(formatVersion == '1.0')
  local centroids = spark.read:parquet(Loader.dataPath(path))
  --Loader.checkSchema[Cluster](centroids.schema)
  local localCentroids = centroids:rdd():map(function(e) return {e[1], Vectors.dense(e[2])} end)
  assert(metadata.k == localCentroids:count())
  --new KMeansModel(localCentroids.sortBy(_.id).map(_.point))
  return KMeansModel:new(localCentroids:map(function(e) return e[2] end):collect())
end

return KMeansModel
