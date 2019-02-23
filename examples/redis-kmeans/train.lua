local KMeans = require 'stuart-ml.clustering.KMeans'
local stuart = require 'stuart'
local Vectors = require 'stuart-ml.linalg.Vectors'

local sc = stuart.NewContext('local[1]', 'K-means')

local points = {
  Vectors.dense(0.0, 0.0),
  Vectors.dense(0.0, 0.1),
  Vectors.dense(0.1, 0.0),
  Vectors.dense(9.0, 0.0),
  Vectors.dense(9.0, 0.2),
  Vectors.dense(9.2, 0.0)
}
local rdd = sc:parallelize(points, 1)

local k = 2
local maxIterations = 5
local model = KMeans.train(rdd, k, maxIterations, KMeans.K_MEANS_PARALLEL)

print()
print('Model:', model)
for i, center in ipairs(model.clusterCenters) do
  print(string.format('  center %d %s', i, tostring(center)))
end

print()
print('Predicts:')
local predicts = model:predict(rdd):collect()
for i, predict in ipairs(predicts) do
  local msg = string.format(
    '  point %s\t==> center %d %s', tostring(points[i]), predict, tostring(model.clusterCenters[predict])
  )
  print(msg)
end
