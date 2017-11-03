local registerAsserts = require 'registerAsserts'
local KMeans = require 'stuart-ml.clustering.KMeans'

registerAsserts(assert)

describe('clustering.KMeans', function()

  it('default parameters', function()
    local kmeans = KMeans:new()
    assert.equal(2, kmeans:getK())
    assert.equal(20, kmeans:getMaxIter())
    assert.equal(KMeans.K_MEANS_PARALLEL, kmeans:getInitMode())
    assert.equal(2, kmeans:getInitSteps())
  end)

  it('set parameters', function()
    local kmeans = KMeans:new()
      :setK(9)
      :setMaxIter(33)
      :setInitMode(KMeans.RANDOM)
      :setInitSteps(3)
      :setSeed(123)
    assert.equal(9, kmeans:getK())
    assert.equal(33, kmeans:getMaxIter())
    assert.equal(KMeans.RANDOM, kmeans:getInitMode())
    assert.equal(3, kmeans:getInitSteps())
    assert.equal(123, kmeans:getSeed())
  end)

  it('parameters validation', function()
    assert.has_error(function()
      KMeans:new():setK(0)
    end)
    assert.has_error(function()
      KMeans:new():setInitMode('no_such_a_mode')
    end)
    assert.has_error(function()
      KMeans:new():setInitSteps(0)
    end)
  end)
  
end)
