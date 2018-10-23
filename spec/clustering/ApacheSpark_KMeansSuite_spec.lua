local KMeans = require 'stuart-ml.clustering.KMeans'
local registerAsserts = require 'registerAsserts'
local stuart = require 'stuart'
local Vectors = require 'stuart-ml.linalg.Vectors'
--local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'

registerAsserts(assert)

describe('Apache Spark MLlib KMeansSuite', function()
  --local seed = 42
  local sc = stuart.NewContext()

  it('single cluster', function()
    local data = sc:parallelize({
      Vectors.dense(1.0, 2.0, 6.0),
      Vectors.dense(1.0, 3.0, 0.0),
      Vectors.dense(1.0, 4.0, 6.0)
    })

    local center = Vectors.dense(1.0, 3.0, 4.0)

    -- No matter how many iterations we use, we should get one cluster,
    -- centered at the mean of the points

    local k, maxIterations = 1, 1
    local model = KMeans.train(data, k, maxIterations)
    assert.equal_absTol(center, model.clusterCenters[1], 1e-5)

    k, maxIterations = 1, 2
    model = KMeans.train(data, k, maxIterations)
    assert.equal_absTol(center, model.clusterCenters[1], 1e-5)

    k, maxIterations = 1, 5
    model = KMeans.train(data, k, maxIterations)
    assert.equal_absTol(center, model.clusterCenters[1], 1e-5)

    k, maxIterations = 1, 1
    model = KMeans.train(data, k, maxIterations, KMeans.RANDOM)
    assert.equal_absTol(center, model.clusterCenters[1], 1e-5)

    k, maxIterations = 1, 1
    model = KMeans.train(data, k, maxIterations, KMeans.K_MEANS_PARALLEL)
    assert.equal_absTol(center, model.clusterCenters[1], 1e-5)
  end)

--  it('two clusters', function()
--    local points = {
--      Vectors.dense(0.0, 0.0),
--      Vectors.dense(0.0, 0.1),
--      Vectors.dense(0.1, 0.0),
--      Vectors.dense(9.0, 0.0),
--      Vectors.dense(9.0, 0.2),
--      Vectors.dense(9.2, 0.0)
--    }
--    local rdd = sc:parallelize(points, 1)
--
--    local KMeansLocal = require 'stuart-ml.clustering.KMeans'
--    function KMeansLocal:initRandom()
--      local center1 = VectorWithNorm:new(Vectors.dense({0.03333333333333333,0.03333333333333333}), 0.04714045207910317)
--      local center2 = VectorWithNorm:new(Vectors.dense({9.066666666666666,0.06666666666666667}), 9.06691176139312)
--      return {center1, center2}
--    end
--    function KMeansLocal:initKMeansParallel()
--      local center1 = VectorWithNorm:new(points[6], 9.2)
--      local center2 = VectorWithNorm:new(points[4], 9.0)
--      return {center1, center2}
--    end
--    for _, initMode in ipairs({KMeans.RANDOM, KMeans.K_MEANS_PARALLEL}) do
--      -- Two iterations are sufficient no matter where the initial centers are
--      local k = 2
--      local maxIterations = 2
--      local model = KMeansLocal.train(rdd, k, maxIterations, initMode)
--
--      local predicts = model:predict(rdd):collect()
--
--      assert.equal(predicts[2], predicts[1])
--      assert.equal(predicts[3], predicts[1])
--      assert.equal(predicts[5], predicts[4])
--      assert.equal(predicts[6], predicts[4])
--      assert.not_equal(predicts[4], predicts[1])
--    end
--  end)

end)
