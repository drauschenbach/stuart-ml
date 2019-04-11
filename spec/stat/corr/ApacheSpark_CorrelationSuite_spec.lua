local moses = require 'moses'
local registerAsserts = require 'registerAsserts'
local statistics = require 'stuart-ml.stat.statistics'
local stuart = require 'stuart'
local Vectors = require 'stuart-ml.linalg.Vectors'

registerAsserts(assert)

describe('Apache Spark MLLib CorrelationSuite', function()

  local sc = stuart.NewContext()

  -- test input data
  local xData = {1.0, 0.0, -2.0}
  local yData = {4.0, 5.0, 3.0}
  local zeros = moses.zeros(3)
  local data = {
    Vectors.dense(1.0, 0.0, 0.0, -2.0),
    Vectors.dense(4.0, 5.0, 0.0, 3.0),
    Vectors.dense(6.0, 7.0, 0.0, 8.0),
    Vectors.dense(9.0, 0.0, 0.0, 1.0)
  }

  it('corr(x, y) pearson, 1 value in data', function()
    local x = sc:parallelize({1.0})
    local y = sc:parallelize({4.0})
    assert.error(function()
      statistics.corr(x, y, 'pearson')
    end)
    assert.error(function()
      statistics.corr(x, y, 'spearman')
    end)
  end)

  it('corr(x, y) default, pearson', function()
    local x = sc:parallelize(xData)
    local y = sc:parallelize(yData)
    local expected = 0.6546537
    local default = statistics.corr(x, y)
    local p1 = statistics.corr(x, y, 'pearson')
    assert.equal_abstol(expected, default, 1e6)
    assert.equal_abstol(expected, p1, 1e6)

    -- numPartitions >= size for input RDDs
    for _, numParts in ipairs({#xData, #xData*2}) do
      local x1 = sc:parallelize(xData, numParts)
      local y1 = sc:parallelize(yData, numParts)
      local p2 = statistics.corr(x1, y1)
      assert.equal_abstol(expected, p2, 1e6)
    end

    -- RDD of zero variance
    local z = sc:parallelize(zeros)
    assert.equals(nil, statistics.corr(x, z))
  end)

--  it('corr(x, y) spearman', function()
--    val x = sc.parallelize(xData)
--    val y = sc.parallelize(yData)
--    val expected = 0.5
--    val s1 = Statistics.corr(x, y, "spearman")
--    assert(approxEqual(expected, s1))
--
--    // numPartitions >= size for input RDDs
--    for (numParts <- List(xData.size, xData.size * 2)) {
--      val x1 = sc.parallelize(xData, numParts)
--      val y1 = sc.parallelize(yData, numParts)
--      val s2 = Statistics.corr(x1, y1, "spearman")
--      assert(approxEqual(expected, s2))
--    }
--
--    // RDD of zero variance => zero variance in ranks
--    val z = sc.parallelize(zeros)
--    assert(Statistics.corr(x, z, "spearman").isNaN)
--  }

  it('corr(X) default, pearson', function()
    local X = sc:parallelize(data)
    statistics.corr(X)
    statistics.corr(X, 'pearson')
--    val expected = BDM(
--      (1.00000000, 0.05564149, Double.NaN, 0.4004714),
--      (0.05564149, 1.00000000, Double.NaN, 0.9135959),
--      (Double.NaN, Double.NaN, 1.00000000, Double.NaN),
--      (0.40047142, 0.91359586, Double.NaN, 1.0000000))
--    assert(matrixApproxEqual(defaultMat.asBreeze, expected))
--    assert(matrixApproxEqual(pearsonMat.asBreeze, expected))
  end)

--  it('corr(X) spearman', function()
--    val X = sc.parallelize(data)
--    val spearmanMat = Statistics.corr(X, "spearman")
--    // scalastyle:off
--    val expected = BDM(
--      (1.0000000,  0.1054093,  Double.NaN, 0.4000000),
--      (0.1054093,  1.0000000,  Double.NaN, 0.9486833),
--      (Double.NaN, Double.NaN, 1.00000000, Double.NaN),
--      (0.4000000,  0.9486833,  Double.NaN, 1.0000000))
--    // scalastyle:on
--    assert(matrixApproxEqual(spearmanMat.asBreeze, expected))
--  }
--
--  it('method identification', function()
--    val pearson = PearsonCorrelation
--    val spearman = SpearmanCorrelation
--
--    assert(Correlations.getCorrelationFromName("pearson") === pearson)
--    assert(Correlations.getCorrelationFromName("spearman") === spearman)
--
--    intercept[IllegalArgumentException] {
--      Correlations.getCorrelationFromName("kendall")
--    }
--  }
--
--  ignore("Pearson correlation of very large uncorrelated values (SPARK-14533)', function()
--    // The two RDDs should have 0 correlation because they're random;
--    // this should stay the same after shifting them by any amount
--    // In practice a large shift produces very large values which can reveal
--    // round-off problems
--    val a = RandomRDDs.normalRDD(sc, 100000, 10).map(_ + 1000000000.0)
--    val b = RandomRDDs.normalRDD(sc, 100000, 10).map(_ + 1000000000.0)
--    val p = Statistics.corr(a, b, method = "pearson")
--    assert(approxEqual(p, 0.0, 0.01))
--  }
--
--  def matrixApproxEqual(A: BM[Double], B: BM[Double], threshold: Double = 1e-6): Boolean = {
--    for (i <- 0 until A.rows; j <- 0 until A.cols) {
--      if (!approxEqual(A(i, j), B(i, j), threshold)) {
--        logInfo("i, j = " + i + ", " + j + " actual: " + A(i, j) + " expected:" + B(i, j))
--        return false
--      }
--    }
--    true
--  }
end)
