local hasSparkSession, _ = pcall(require, 'stuart-sql.SparkSession')
local KMeansModel = require 'stuart-ml.clustering.KMeansModel'
local registerAsserts = require 'registerAsserts'
local stuart = require 'stuart'
local Vectors = require 'stuart-ml.linalg.Vectors'

registerAsserts(assert)

describe('clustering.KMeansModel', function()

  it('loads', function()
    if not hasSparkSession then return pending('No stuart-sql is present') end
    local sc = stuart.NewContext()
    local model = KMeansModel.load(sc, 'spec-fixtures/model2')
    assert.equal(1, #model.clusterCenters)
    assert.same({3,4,5}, model.clusterCenters[1]:toArray())
  end)

  it('predicts', function()
    if not hasSparkSession then return pending('No stuart-sql is present') end
    local sc = stuart.NewContext()
    local model = KMeansModel.load(sc, 'spec-fixtures/model4')
    assert.equal(2, #model.clusterCenters)
    assert.same({5,6,7}, model.clusterCenters[1]:toArray())
    assert.same({1,2,3}, model.clusterCenters[2]:toArray())
    assert.equal(1, model:predict(Vectors.dense({5,6,7})))
  end)

end)
