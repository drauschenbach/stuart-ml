local registerAsserts = require 'registerAsserts'
local KMeans = require 'stuart-ml.clustering.KMeans'

registerAsserts(assert)

describe('clustering.KMeans', function()

  it('default parameters', function()
    local kmeans = KMeans:new()
    assert.equal(2, kmeans:getK())
    assert.equal(20, kmeans:getMaxIterations())
    assert.equal(KMeans.K_MEANS_PARALLEL, kmeans:getInitializationMode())
    assert.equal(2, kmeans:getInitializationSteps())
  end)

  it('set parameters', function()
    local kmeans = KMeans:new()
      :setK(9)
      :setMaxIterations(33)
      :setInitializationMode(KMeans.RANDOM)
      :setInitializationSteps(3)
      :setSeed(123)
    assert.equal(9, kmeans:getK())
    assert.equal(33, kmeans:getMaxIterations())
    assert.equal(KMeans.RANDOM, kmeans:getInitializationMode())
    assert.equal(3, kmeans:getInitializationSteps())
    assert.equal(123, kmeans:getSeed())
  end)

  it('parameters validation', function()
    assert.has_error(function()
      KMeans:new():setK(0)
    end)
    assert.has_error(function()
      KMeans:new():setInitializationMode('no_such_a_mode')
    end)
    assert.has_error(function()
      KMeans:new():setInitializationSteps(0)
    end)
  end)
  
end)
