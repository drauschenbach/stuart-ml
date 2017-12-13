local Loader = require 'stuart-ml.util.Loader'
local stuart = require 'stuart'

describe('util.Loader', function()

  it('returns correct data path', function()
    local dataPath = Loader.dataPath('spec-fixtures/model2')
    assert.equal('spec-fixtures/model2/data', dataPath)
  end)
  
  it('returns correct metadata path', function()
    local metadataPath = Loader.metadataPath('spec-fixtures/model2')
    assert.equal('spec-fixtures/model2/metadata', metadataPath)
  end)
  
  it('returns metadata', function()
    local sc = stuart.NewContext()
    local class, version, metadata = Loader.loadMetadata(sc, 'spec-fixtures/model2')
    assert.equal('org.apache.spark.mllib.clustering.KMeansModel', class)
    assert.equal('1.0', version)
    assert.equal(1, metadata.k)
  end)
  
end)
