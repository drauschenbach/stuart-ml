local registerAsserts = require 'registerAsserts'
local MultivariateOnlineSummarizer = require 'stuart-ml.stat.MultivariateOnlineSummarizer'
local Vectors = require 'stuart-ml.linalg.Vectors'

registerAsserts(assert)

describe('stat.MultivariateOnlineSummarizerSuite', function()

  test('dense vector input', function()
    -- For column 2, the maximum will be 0.0, and it's not explicitly added since we ignore all
    -- the zeros; it's a case we need to test. For column 3, the minimum will be 0.0 which we
    -- need to test as well.
    local summarizer = MultivariateOnlineSummarizer.new()
    summarizer:add(Vectors.dense(-1.0, 0.0, 6.0))
    summarizer:add(Vectors.dense(3.0, -3.0, 0.0))
    
    assert.equal_absTol(summarizer:mean(), Vectors.dense(1.0, -1.5, 3.0), 1e-5)
    assert.equal_absTol(summarizer:min(), Vectors.dense(-1.0, -3, 0.0), 1e-5)
    assert.equal_absTol(summarizer:max(), Vectors.dense(3.0, 0.0, 6.0), 1e-5)
    assert.equal_absTol(summarizer:numNonzeros(), Vectors.dense(2, 1, 1), 1e-5)
    --TODO assert.equal_absTol(summarizer:variance(), Vectors.dense(8.0, 4.5, 18.0), 1e-5)
    assert.equal(2, summarizer:count())
  end)

  test('sparse vector input', function()
    local summarizer = MultivariateOnlineSummarizer.new()
    summarizer:add(Vectors.sparse(3, {{0, -1.0}, {2, 6.0}}))
    summarizer:add(Vectors.sparse(3, {{0, 3.0}, {1, -3.0}}))

    assert.equal_absTol(summarizer:mean(), Vectors.dense(1.0, -1.5, 3.0), 1e-5)
    assert.equal_absTol(summarizer:min(), Vectors.dense(-1.0, -3, 0.0), 1e-5)
    assert.equal_absTol(summarizer:max(), Vectors.dense(3.0, 0.0, 6.0), 1e-5)
    assert.equal_absTol(summarizer:numNonzeros(), Vectors.dense(2, 1, 1), 1e-5)
    --TODO assert.equal_absTol(summarizer:variance(), Vectors.dense(8.0, 4.5, 18.0), 1e-5)
    assert.equal(2, summarizer:count())
  end)

  test('mixing dense and sparse vector input', function()
    local summarizer = MultivariateOnlineSummarizer.new()
    summarizer:add(Vectors.sparse(3, {{0,-2.0}, {1,2.3}}))
    summarizer:add(Vectors.dense(0.0, -1.0, -3.0))
    summarizer:add(Vectors.sparse(3, {{1,-5.1}}))
    summarizer:add(Vectors.dense(3.8, 0.0, 1.9))
    summarizer:add(Vectors.dense(1.7, -0.6, 0.0))
    summarizer:add(Vectors.sparse(3, {{1,1.9}, {2,0.0}}))

    assert.equal_absTol(summarizer:mean(), Vectors.dense(0.583333333333, -0.416666666666, -0.183333333333), 1e-5)
    assert.equal_absTol(summarizer:min(), Vectors.dense(-2.0, -5.1, -3), 1e-5)
    assert.equal_absTol(summarizer:max(), Vectors.dense(3.8, 2.3, 1.9), 1e-5)
    assert.equal_absTol(summarizer:numNonzeros(), Vectors.dense(3, 5, 2), 1e-5)
    --TODO assert.equal_absTol(summarizer:variance(), Vectors.dense(3.857666666666, 7.0456666666666, 2.48166666666666), 1e-5)
    assert.equal(6, summarizer:count())
  end)
  
  test('merging two summarizers', function()
    local summarizer1 = MultivariateOnlineSummarizer.new()
    summarizer1:add(Vectors.sparse(3, {{0,-2.0}, {1,2.3}}))
    summarizer1:add(Vectors.dense(0.0, -1.0, -3.0))

    local summarizer2 = MultivariateOnlineSummarizer.new()
    summarizer2:add(Vectors.sparse(3, {{1,-5.1}}))
    summarizer2:add(Vectors.dense(3.8, 0.0, 1.9))
    summarizer2:add(Vectors.dense(1.7, -0.6, 0.0))
    summarizer2:add(Vectors.sparse(3, {{1,1.9}, {2,0.0}}))

    local summarizer = summarizer1:merge(summarizer2)

    assert.equal_absTol(summarizer:mean(), Vectors.dense(0.583333333333, -0.416666666666, -0.183333333333), 1e-5)
    assert.equal_absTol(summarizer:min(), Vectors.dense(-2.0, -5.1, -3), 1e-5)
    assert.equal_absTol(summarizer:max(), Vectors.dense(3.8, 2.3, 1.9), 1e-5)
    assert.equal_absTol(summarizer:numNonzeros(), Vectors.dense(3, 5, 2), 1e-5)
    --TODO assert.equal_absTol(summarizer:variance(), Vectors.dense(3.857666666666, 7.0456666666666, 2.48166666666666), 1e-5)
    assert.equal(6, summarizer:count())
  end)
  
  test('merging summarizer with empty summarizer', function()
    -- If one of two is non-empty, this should return the non-empty summarizer.
    -- If both of them are empty, then just return the empty summarizer.
    local summarizer1 = MultivariateOnlineSummarizer.new()
    summarizer1:add(Vectors.dense(0.0, -1.0, -3.0)):merge(MultivariateOnlineSummarizer.new())
    assert.equal(1, summarizer1:count())

    local summarizer2 = MultivariateOnlineSummarizer.new()
    summarizer2:merge(MultivariateOnlineSummarizer.new()):add(Vectors.dense(0.0, -1.0, -3.0))
    assert.equal(1, summarizer2:count())

    local summarizer3 = MultivariateOnlineSummarizer.new():merge(MultivariateOnlineSummarizer.new())
    assert.equal(0, summarizer3:count())

    assert.equal_absTol(summarizer1:mean(), Vectors.dense(0.0, -1.0, -3.0), 1e-5)
    assert.equal_absTol(summarizer2:mean(), Vectors.dense(0.0, -1.0, -3.0), 1e-5)
    assert.equal_absTol(summarizer1:min(), Vectors.dense(0.0, -1.0, -3.0), 1e-5)
    assert.equal_absTol(summarizer2:min(), Vectors.dense(0.0, -1.0, -3.0), 1e-5)
    assert.equal_absTol(summarizer1:max(), Vectors.dense(0.0, -1.0, -3.0), 1e-5)
    assert.equal_absTol(summarizer2:max(), Vectors.dense(0.0, -1.0, -3.0), 1e-5)
    assert.equal_absTol(summarizer1:numNonzeros(), Vectors.dense(0, 1, 1), 1e-5)
    assert.equal_absTol(summarizer2:numNonzeros(), Vectors.dense(0, 1, 1), 1e-5)
    --TODO assert.equal_absTol(summarizer1:variance(), Vectors.dense(0, 0, 0), 1e-5)
    --TODO assert.equal_absTol(summarizer2:variance(), Vectors.dense(0, 0, 0), 1e-5)
  end)
  
  test('merging summarizer when one side has zero mean (SPARK-4355)', function()
      local s0 = MultivariateOnlineSummarizer.new()
        :add(Vectors.dense(2.0))
        :add(Vectors.dense(2.0))
      local s1 = MultivariateOnlineSummarizer.new()
        :add(Vectors.dense(1.0))
        :add(Vectors.dense(-1.0))
    s0:merge(s1)
    assert.equal_absTol(s0:mean()[1], 1.0, 1e-14)
  end)
  
  test('merging summarizer with weighted samples', function()
    local summarizer = MultivariateOnlineSummarizer.new()
      :add(Vectors.sparse(3, {{0,-0.8}, {1,1.7}}), 0.1)
      :add(Vectors.dense(0.0, -1.2, -1.7), 0.2)
      :merge(MultivariateOnlineSummarizer.new()
        :add(Vectors.sparse(3, {{0,-0.7}, {1,0.01}, {2,1.3}}), 0.15)
        :add(Vectors.dense(-0.5, 0.3, -1.5), 0.05)
      )
    assert.equal(4, summarizer:count())

    -- The following values are hand calculated using the formula:
    -- [[https://en.wikipedia.org/wiki/Weighted_arithmetic_mean#Reliability_weights]]
    -- which defines the reliability weight used for computing the unbiased estimation of variance
    -- for weighted instances.
    assert.equal_absTol(summarizer:mean(), Vectors.dense(-0.42, -0.107, -0.44), 1e-10)
    --TODO assert.equal_absTol(summarizer:variance(), Vectors.dense(0.17657142857, 1.645115714, 2.42057142857), 1e-8)
    assert.equal_absTol(summarizer:numNonzeros(), Vectors.dense(3.0, 4.0, 3.0), 1e-10)
    assert.equal_absTol(summarizer:max(), Vectors.dense(0.0, 1.7, 1.3), 1e-10)
    assert.equal_absTol(summarizer:min(), Vectors.dense(-0.8, -1.2, -1.7), 1e-10)
    assert.equal_absTol(summarizer:normL2(), Vectors.dense(0.387298335, 0.762571308141, 0.9715966241192), 1e-8)
    assert.equal_absTol(summarizer:normL1(), Vectors.dense(0.21, 0.4265, 0.61), 1e-10)
  end)
  
  test('test min/max with weighted samples (SPARK-16561)', function()
    local summarizer1 = MultivariateOnlineSummarizer.new()
      :add(Vectors.dense(10.0, -10.0), 1e10)
      :add(Vectors.dense(0.0, 0.0), 1e-7)

    local summarizer2 = MultivariateOnlineSummarizer.new()
    summarizer2:add(Vectors.dense(10.0, -10.0), 1e10)
    for i=1,100 do
      summarizer2:add(Vectors.dense(0.0, 0.0), 1e-7)
    end

    local summarizer3 = MultivariateOnlineSummarizer.new()
    for i=1,100 do
      summarizer3:add(Vectors.dense(0.0, 0.0), 1e-7)
    end
    summarizer3:add(Vectors.dense(10.0, -10.0), 1e10)

    assert.equal_absTol(summarizer1:max(), Vectors.dense(10.0, 0.0), 1e-14)
    assert.equal_absTol(summarizer1:min(), Vectors.dense(0.0, -10.0), 1e-14)
    assert.equal_absTol(summarizer2:max(), Vectors.dense(10.0, 0.0), 1e-14)
    assert.equal_absTol(summarizer2:min(), Vectors.dense(0.0, -10.0), 1e-14)
    assert.equal_absTol(summarizer3:max(), Vectors.dense(10.0, 0.0), 1e-14)
    assert.equal_absTol(summarizer3:min(), Vectors.dense(0.0, -10.0), 1e-14)
  end)
  
end)
