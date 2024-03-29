local Matrices = require 'stuart-ml.linalg.Matrices'
local RandomRDDs = require 'stuart-ml.random.RandomRDDs'
local registerAsserts = require 'registerAsserts'
local RowMatrix = require 'stuart-ml.linalg.distributed.RowMatrix'
local stuart = require 'stuart'
local Vectors = require 'stuart-ml.linalg.Vectors'

registerAsserts(assert)

describe('linalg.distributed.RowMatrixSuite', function()

  local sc = stuart.NewContext()

  local m = 4
  local n = 3
  --local arr = {0.0, 3.0, 6.0, 9.0, 1.0, 4.0, 7.0, 0.0, 2.0, 5.0, 8.0, 1.0}
  local denseData = {
    Vectors.dense(0.0, 1.0, 2.0),
    Vectors.dense(3.0, 4.0, 5.0),
    Vectors.dense(6.0, 7.0, 8.0),
    Vectors.dense(9.0, 0.0, 1.0)
  }
  local sparseData = {
    Vectors.sparse(3, {{1,1.0}, {2,2.0}}),
    Vectors.sparse(3, {{0,3.0}, {1,4.0}, {2,5.0}}),
    Vectors.sparse(3, {{0,6.0}, {1,7.0}, {2,8.0}}),
    Vectors.sparse(3, {{0,9.0}, {2,1.0}})
  }

--  val principalComponents = BDM(
--    (0.0, 1.0, 0.0),
--    (math.sqrt(2.0) / 2.0, 0.0, math.sqrt(2.0) / 2.0),
--    (math.sqrt(2.0) / 2.0, 0.0, - math.sqrt(2.0) / 2.0))
--  val explainedVariance = BDV(4.0 / 7.0, 3.0 / 7.0, 0.0)

  local denseMat, sparseMat

  setup(function()
    denseMat = RowMatrix.new(sc:parallelize(denseData, 2))
    sparseMat = RowMatrix.new(sc:parallelize(sparseData, 2))
  end)

  it('size', function()
    assert.equal(m, denseMat:numRows())
    assert.equal(n, denseMat:numCols())
    assert.equal(m, sparseMat:numRows())
    assert.equal(n, sparseMat:numCols())
  end)

  it('empty rows', function()
    local rows = sc:parallelize({}, 1)
    local emptyMat = RowMatrix.new(rows)
    assert.error(function()
      emptyMat:numCols()
    end)
    assert.error(function()
      emptyMat:numRows()
    end)
  end)

--  it('toBreeze', function()
--    val expected = BDM(
--      (0.0, 1.0, 2.0),
--      (3.0, 4.0, 5.0),
--      (6.0, 7.0, 8.0),
--      (9.0, 0.0, 1.0))
--    for (mat <- Seq(denseMat, sparseMat)) {
--      assert(mat.toBreeze() === expected)
--    }
--  }

  it('gram', function()
    local expected = Matrices.dense(n, n, {126.0, 54.0, 72.0, 54.0, 66.0, 78.0, 72.0, 78.0, 94.0})
    for _, mat in pairs{denseMat, sparseMat} do
      local G = mat:computeGramianMatrix()
      assert.equal(expected, G)
    end
  end)

--  it('similar columns', function()
--    val colMags = Vectors.dense(math.sqrt(126), math.sqrt(66), math.sqrt(94))
--    val expected = BDM(
--      (0.0, 54.0, 72.0),
--      (0.0, 0.0, 78.0),
--      (0.0, 0.0, 0.0))
--
--    for (i <- 0 until n; j <- 0 until n) {
--      expected(i, j) /= (colMags(i) * colMags(j))
--    }
--
--    for (mat <- Seq(denseMat, sparseMat)) {
--      val G = mat.columnSimilarities(0.11).toBreeze()
--      for (i <- 0 until n; j <- 0 until n) {
--        if (expected(i, j) > 0) {
--          val actual = expected(i, j)
--          val estimate = G(i, j)
--          assert(math.abs(actual - estimate) / actual < 0.2,
--            s"Similarities not close enough: $actual vs $estimate")
--        }
--      }
--    }
--
--    for (mat <- Seq(denseMat, sparseMat)) {
--      val G = mat.columnSimilarities()
--      assert(closeToZero(G.toBreeze() - expected))
--    }
--
--    for (mat <- Seq(denseMat, sparseMat)) {
--      val G = mat.columnSimilaritiesDIMSUM(colMags.toArray, 150.0)
--      assert(closeToZero(G.toBreeze() - expected))
--    }
--  }
--
--  it('svd of a full-rank matrix', function()
--    for (mat <- Seq(denseMat, sparseMat)) {
--      for (mode <- Seq("auto", "local-svd", "local-eigs", "dist-eigs")) {
--        val localMat = mat.toBreeze()
--        val brzSvd.SVD(localU, localSigma, localVt) = brzSvd(localMat)
--        val localV: BDM[Double] = localVt.t.toDenseMatrix
--        for (k <- 1 to n) {
--          val skip = (mode == "local-eigs" || mode == "dist-eigs") && k == n
--          if (!skip) {
--            val svd = mat.computeSVD(k, computeU = true, 1e-9, 300, 1e-10, mode)
--            val U = svd.U
--            val s = svd.s
--            val V = svd.V
--            assert(U.numRows() === m)
--            assert(U.numCols() === k)
--            assert(s.size === k)
--            assert(V.numRows === n)
--            assert(V.numCols === k)
--            assertColumnEqualUpToSign(U.toBreeze(), localU, k)
--            assertColumnEqualUpToSign(V.asBreeze.asInstanceOf[BDM[Double]], localV, k)
--            assert(closeToZero(s.asBreeze.asInstanceOf[BDV[Double]] - localSigma(0 until k)))
--          }
--        }
--        val svdWithoutU = mat.computeSVD(1, computeU = false, 1e-9, 300, 1e-10, mode)
--        assert(svdWithoutU.U === null)
--      }
--    }
--  }
--
--  it('svd of a low-rank matrix', function()
--    val rows = sc.parallelize(Array.fill(4)(Vectors.dense(1.0, 1.0, 1.0)), 2)
--    val mat = new RowMatrix(rows, 4, 3)
--    for (mode <- Seq("auto", "local-svd", "local-eigs", "dist-eigs")) {
--      val svd = mat.computeSVD(2, computeU = true, 1e-6, 300, 1e-10, mode)
--      assert(svd.s.size === 1, s"should not return zero singular values but got ${svd.s}")
--      assert(svd.U.numRows() === 4)
--      assert(svd.U.numCols() === 1)
--      assert(svd.V.numRows === 3)
--      assert(svd.V.numCols === 1)
--    }
--  }
--
--  it('validate k in svd', function()
--    for (mat <- Seq(denseMat, sparseMat)) {
--      intercept[IllegalArgumentException] {
--        mat.computeSVD(-1)
--      }
--    }
--  }
--
--  def closeToZero(G: BDM[Double]): Boolean = {
--    G.valuesIterator.map(math.abs).sum < 1e-6
--  }
--
--  def closeToZero(v: BDV[Double]): Boolean = {
--    brzNorm(v, 1.0) < 1e-6
--  }
--
--  def assertColumnEqualUpToSign(A: BDM[Double], B: BDM[Double], k: Int) {
--    assert(A.rows === B.rows)
--    for (j <- 0 until k) {
--      val aj = A(::, j)
--      val bj = B(::, j)
--      assert(closeToZero(aj - bj) || closeToZero(aj + bj),
--        s"The $j-th columns mismatch: $aj and $bj")
--    }
--  }
--
--  it('pca', function()
--    for (mat <- Seq(denseMat, sparseMat); k <- 1 to n) {
--      val (pc, expVariance) = mat.computePrincipalComponentsAndExplainedVariance(k)
--      assert(pc.numRows === n)
--      assert(pc.numCols === k)
--      assertColumnEqualUpToSign(pc.asBreeze.asInstanceOf[BDM[Double]], principalComponents, k)
--      assert(
--        closeToZero(BDV(expVariance.toArray) -
--        BDV(Arrays.copyOfRange(explainedVariance.data, 0, k))))
--      // Check that this method returns the same answer
--      assert(pc === mat.computePrincipalComponents(k))
--    }
--  }
--
--  it('multiply a local matrix', function()
--    val B = Matrices.dense(n, 2, Array(0.0, 1.0, 2.0, 3.0, 4.0, 5.0))
--    for (mat <- Seq(denseMat, sparseMat)) {
--      val AB = mat.multiply(B)
--      assert(AB.numRows() === m)
--      assert(AB.numCols() === 2)
--      assert(AB.rows.collect().toSeq === Seq(
--        Vectors.dense(5.0, 14.0),
--        Vectors.dense(14.0, 50.0),
--        Vectors.dense(23.0, 86.0),
--        Vectors.dense(2.0, 32.0)
--      ))
--    }
--  }

  test('compute column summary statistics', function()
    for _, mat in pairs{denseMat, sparseMat} do
      local summary = mat:computeColumnSummaryStatistics()
      -- Run twice to make sure no internal states are changed.
      for k=0,1 do
        assert.equals(Vectors.dense(4.5, 3.0, 4.0), summary:mean())
        --TODO assert.equals(Vectors.dense(15.0, 10.0, 10.0), summary:variance())
        assert.equals(m, summary:count())
        assert.equals(Vectors.dense(3.0, 3.0, 4.0), summary:numNonzeros())
        assert.equals(Vectors.dense(9.0, 7.0, 8.0), summary:max())
        assert.equals(Vectors.dense(0.0, 0.0, 1.0), summary:min())
        assert.equals(Vectors.dense(math.sqrt(126), math.sqrt(66), math.sqrt(94)), summary:normL2())
        assert.equals(Vectors.dense(18.0, 12.0, 16.0), summary:normL1())
      end
    end
  end)

--  it('QR Decomposition', function()
--    for (mat <- Seq(denseMat, sparseMat)) {
--      val result = mat.tallSkinnyQR(true)
--      val expected = breeze.linalg.qr.reduced(mat.toBreeze())
--      val calcQ = result.Q
--      val calcR = result.R
--      assert(closeToZero(abs(expected.q) - abs(calcQ.toBreeze())))
--      assert(closeToZero(abs(expected.r) - abs(calcR.asBreeze.asInstanceOf[BDM[Double]])))
--      assert(closeToZero(calcQ.multiply(calcR).toBreeze - mat.toBreeze()))
--      // Decomposition without computing Q
--      val rOnly = mat.tallSkinnyQR(computeQ = false)
--      assert(rOnly.Q == null)
--      assert(closeToZero(abs(expected.r) - abs(rOnly.R.asBreeze.asInstanceOf[BDM[Double]])))
--    }
--  }

  it('compute covariance', function()
    for _, mat in pairs{denseMat, sparseMat} do
      mat:computeCovariance()
      -- val expected = breeze.linalg.cov(mat.toBreeze())
      -- assert(closeToZero(abs(expected) - abs(result.asBreeze.asInstanceOf[BDM[Double]])))
    end
  end)

  it('covariance matrix is symmetric (SPARK-10875)', function()
    local rdd = RandomRDDs.normalVectorRDD(sc, 100, 10, 0, 0)
    local matrix = RowMatrix.new(rdd)
    local cov = matrix:computeCovariance()
    for i = 0, cov.numRows-1 do
      for j = 0, cov.numCols-1 do
        assert.equals(cov:get(i,j), cov:get(j,i))
      end
    end
  end)

--  it('QR decomposition should aware of empty partition (SPARK-16369)', function()
--    val mat: RowMatrix = new RowMatrix(sc.parallelize(denseData, 1))
--    val qrResult = mat.tallSkinnyQR(true)
--
--    val matWithEmptyPartition = new RowMatrix(sc.parallelize(denseData, 8))
--    val qrResult2 = matWithEmptyPartition.tallSkinnyQR(true)
--
--    assert(qrResult.Q.numCols() === qrResult2.Q.numCols(), "Q matrix ncol not match")
--    assert(qrResult.Q.numRows() === qrResult2.Q.numRows(), "Q matrix nrow not match")
--    qrResult.Q.rows.collect().zip(qrResult2.Q.rows.collect())
--      .foreach(x => assert(x._1 ~== x._2 relTol 1E-8, "Q matrix not match"))
--
--    qrResult.R.toArray.zip(qrResult2.R.toArray)
--      .foreach(x => assert(x._1 ~== x._2 relTol 1E-8, "R matrix not match"))
--  }
--}
--
--class RowMatrixClusterSuite extends SparkFunSuite with LocalClusterSparkContext {
--
--  var mat: RowMatrix = _
--
--  override def beforeAll() {
--    super.beforeAll()
--    val m = 4
--    val n = 200000
--    val rows = sc.parallelize(0 until m, 2).mapPartitionsWithIndex { (idx, iter) =>
--      val random = new Random(idx)
--      iter.map(i => Vectors.dense(Array.fill(n)(random.nextDouble())))
--    }
--    mat = new RowMatrix(rows)
--  }
--
--  it('task size should be small in svd', function()
--    val svd = mat.computeSVD(1, computeU = true)
--  }
--
--  it('task size should be small in summarize', function()
--    val summary = mat.computeColumnSummaryStatistics()
--  }
--}

end)
