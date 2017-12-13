local KMeansModel = require 'stuart-ml.clustering.KMeansModel'
local registerAsserts = require 'registerAsserts'
local stuart = require 'stuart'

registerAsserts(assert)

describe('clustering.KMeansModel', function()

  it('loads', function()
    local sc = stuart.NewContext()
    local model = KMeansModel.load(sc, 'spec-fixtures/model2')
    assert.equal(1, #model.clusterCenters)
    assert.same({3,4,5}, model.clusterCenters[1]:toArray())
  end)

end)
