local DenseMatrix = require 'stuart-ml.linalg.DenseMatrix'
local Matrices = require 'stuart-ml.linalg.Matrices'
local moses = require 'moses'
local registerAsserts = require 'registerAsserts'
local SparseMatrix = require 'stuart-ml.linalg.SparseMatrix'

registerAsserts(assert)

describe('linalg.MatricesSuite', function()

  it('dense matrix construction', function()
    local m = 3
    local n = 2
    local values = {0.0, 1.0, 2.0, 3.0, 4.0, 5.0}
    local mat = Matrices.dense(m, n, values)
    assert.equal(m, mat.numRows)
    assert.equal(n, mat.numCols)
    assert.same(values, mat.values)
  end)
  
  it('dense matrix construction with wrong dimension', function()
    assert.has_error(function()
      Matrices.dense(3, 2, {0.0, 1.0, 2.0})
    end)
  end)
  
  it('sparse matrix construction', function()
    local m = 3
    local n = 4
    local values = {1.0, 2.0, 4.0, 5.0}
    local colPtrs = {0, 2, 2, 4, 4}
    local rowIndices = {1, 2, 1, 2}
    local mat = Matrices.sparse(m, n, colPtrs, rowIndices, values)
    assert.equal(m, mat.numRows)
    assert.equal(n, mat.numCols)
    assert.same(values, mat.values)
    assert.same(colPtrs, mat.colPtrs)
    assert.same(rowIndices, mat.rowIndices)
  
    -- asBreeze NIY
    -- local entries = {{2, 2, 3.0}, {1, 0, 1.0}, {2, 0, 2.0},
    --  {1, 2, 2.0}, {2, 2, 2.0}, {1, 2, 2.0}, {0, 0, 0.0}}
    -- local mat2 = SparseMatrix.fromCOO(m, n, entries)
    -- assert(mat.asBreeze === mat2.asBreeze)
    -- assert.equal(4, #mat2.values)
  end)
  
  test('sparse matrix construction with wrong number of elements', function()
    assert.has_error(function()
      Matrices.sparse(3, 2, {0,1}, {1,2,1}, {0.0,1.0,2.0})
    end)
    assert.has_error(function()
      Matrices.sparse(3, 2, {0,1,2}, {1,2}, {0.0,1.0,2.0})
    end)
  end)
  
  test('index in matrices incorrect input', function()
    local sm = Matrices.sparse(3, 2, {0, 2, 3}, {1, 2, 1}, {0.0, 1.0, 2.0})
    local dm = Matrices.dense(3, 2, {0.0, 2.3, 1.4, 3.2, 1.0, 9.1})
    for _, mat in ipairs({sm,dm}) do
      assert.has_error(function() mat:index(4,1) end)
      assert.has_error(function() mat:index(1,4) end)
      assert.has_error(function() mat:index(-1,2) end)
      assert.has_error(function() mat:index(1,-2) end)
    end
  end)
  
--  test('equals', function()
--    local dm1 = Matrices.dense(2, 2, {0.0, 1.0, 2.0, 3.0})
--    assert.is_true(dm1 == dm1)
--    assert.is_false(dm1 == dm1:transpose())
--
--    local dm2 = Matrices.dense(2, 2, {0.0, 2.0, 1.0, 3.0})
--    assert.is_true(dm1 == dm2:transpose())
--
--    local sm1 = dm1:toSparse()
--    assert.is_true(sm1 == sm1)
--    assert.is_true(sm1 == dm1)
--    assert.is_false(sm1 == sm1:transpose())
--
--  --  local sm2 = dm2.asInstanceOf[DenseMatrix].toSparse
--  --  assert(sm1 === sm2.transpose)
--  --  assert(sm1 === dm2.transpose)
--  end)
  
  --test("matrix copies are deep copies") {
  --  local m = 3
  --  local n = 2
  --
  --  local denseMat = Matrices.dense(m, n, Array(0.0, 1.0, 2.0, 3.0, 4.0, 5.0))
  --  local denseCopy = denseMat.copy
  --
  --  assert(!denseMat.toArray.eq(denseCopy.toArray))
  --
  --  local values = Array(1.0, 2.0, 4.0, 5.0)
  --  local colPtrs = Array(0, 2, 4)
  --  local rowIndices = Array(1, 2, 1, 2)
  --  local sparseMat = Matrices.sparse(m, n, colPtrs, rowIndices, values)
  --  local sparseCopy = sparseMat.copy
  --
  --  assert(!sparseMat.toArray.eq(sparseCopy.toArray))
  --}
  --
  --test("matrix indexing and updating") {
  --  local m = 3
  --  local n = 2
  --  local allValues = Array(0.0, 1.0, 2.0, 3.0, 4.0, 0.0)
  --
  --  local denseMat = new DenseMatrix(m, n, allValues)
  --
  --  assert(denseMat(0, 1) === 3.0)
  --  assert(denseMat(0, 1) === denseMat.values(3))
  --  assert(denseMat(0, 1) === denseMat(3))
  --  assert(denseMat(0, 0) === 0.0)
  --
  --  denseMat.update(0, 0, 10.0)
  --  assert(denseMat(0, 0) === 10.0)
  --  assert(denseMat.values(0) === 10.0)
  --
  --  local sparseValues = Array(1.0, 2.0, 3.0, 4.0)
  --  local colPtrs = Array(0, 2, 4)
  --  local rowIndices = Array(1, 2, 0, 1)
  --  local sparseMat = new SparseMatrix(m, n, colPtrs, rowIndices, sparseValues)
  --
  --  assert(sparseMat(0, 1) === 3.0)
  --  assert(sparseMat(0, 1) === sparseMat.values(2))
  --  assert(sparseMat(0, 0) === 0.0)
  --
  --  intercept[NoSuchElementException] {
  --    sparseMat.update(0, 0, 10.0)
  --  }
  --
  --  intercept[NoSuchElementException] {
  --    sparseMat.update(2, 1, 10.0)
  --  }
  --
  --  sparseMat.update(0, 1, 10.0)
  --  assert(sparseMat(0, 1) === 10.0)
  --  assert(sparseMat.values(2) === 10.0)
  --}
  
  test('toSparse, toDense', function()
    local m = 3
    local n = 2
    local values = {1.0, 2.0, 4.0, 5.0}
    local allValues = {1.0, 2.0, 0.0, 0.0, 4.0, 5.0}
    local colPtrs = {0, 2, 4}
    local rowIndices = {0, 1, 1, 2}

    local spMat1 = SparseMatrix.new(m, n, colPtrs, rowIndices, values)
    local deMat1 = DenseMatrix.new(m, n, allValues)

    deMat1:toSparse()
    spMat1:toDense()

    -- assert(spMat1.asBreeze === spMat2.asBreeze)
    -- assert(deMat1.asBreeze === deMat2.asBreeze)
  end)
  
  --test("map, update") {
  --  local m = 3
  --  local n = 2
  --  local values = Array(1.0, 2.0, 4.0, 5.0)
  --  local allValues = Array(1.0, 2.0, 0.0, 0.0, 4.0, 5.0)
  --  local colPtrs = Array(0, 2, 4)
  --  local rowIndices = Array(0, 1, 1, 2)
  --
  --  local spMat1 = new SparseMatrix(m, n, colPtrs, rowIndices, values)
  --  local deMat1 = new DenseMatrix(m, n, allValues)
  --  local deMat2 = deMat1.map(_ * 2)
  --  local spMat2 = spMat1.map(_ * 2)
  --  deMat1.update(_ * 2)
  --  spMat1.update(_ * 2)
  --
  --  assert(spMat1.toArray === spMat2.toArray)
  --  assert(deMat1.toArray === deMat2.toArray)
  --}
  --
  --test("transpose") {
  --  local dA =
  --    new DenseMatrix(4, 3, Array(0.0, 1.0, 0.0, 0.0, 2.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 3.0))
  --  local sA = new SparseMatrix(4, 3, Array(0, 1, 3, 4), Array(1, 0, 2, 3), Array(1.0, 2.0, 1.0, 3.0))
  --
  --  local dAT = dA.transpose.asInstanceOf[DenseMatrix]
  --  local sAT = sA.transpose.asInstanceOf[SparseMatrix]
  --  local dATexpected =
  --    new DenseMatrix(3, 4, Array(0.0, 2.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 3.0))
  --  local sATexpected =
  --    new SparseMatrix(3, 4, Array(0, 1, 2, 3, 4), Array(1, 0, 1, 2), Array(2.0, 1.0, 1.0, 3.0))
  --
  --  assert(dAT.asBreeze === dATexpected.asBreeze)
  --  assert(sAT.asBreeze === sATexpected.asBreeze)
  --  assert(dA(1, 0) === dAT(0, 1))
  --  assert(dA(2, 1) === dAT(1, 2))
  --  assert(sA(1, 0) === sAT(0, 1))
  --  assert(sA(2, 1) === sAT(1, 2))
  --
  --  assert(!dA.toArray.eq(dAT.toArray), "has to have a new array")
  --  assert(dA.values.eq(dAT.transpose.asInstanceOf[DenseMatrix].values), "should not copy array")
  --
  --  assert(dAT.toSparse.asBreeze === sATexpected.asBreeze)
  --  assert(sAT.toDense.asBreeze === dATexpected.asBreeze)
  --}
  
  test('foreachActive', function()
    local m = 3
    local n = 2
    local values = {1.0, 2.0, 4.0, 5.0}
    local allValues = {1.0, 2.0, 0.0, 0.0, 4.0, 5.0}
    local colPtrs = {0, 2, 4}
    local rowIndices = {0, 1, 1, 2}
  
    local sp = SparseMatrix.new(m, n, colPtrs, rowIndices, values)
    local dn = DenseMatrix.new(m, n, allValues)
  
    local dnMap = {}
    dn:foreachActive(function(i, j, value)
      dnMap[string.format('%s,%s', i, j)] = value
    end)
    assert.equals(6, #moses.keys(dnMap))
    assert.equals(1.0, dnMap['0,0'])
    assert.equals(2.0, dnMap['1,0'])
    assert.equals(0.0, dnMap['2,0'])
    assert.equals(0.0, dnMap['0,1'])
    assert.equals(4.0, dnMap['1,1'])
    assert.equals(5.0, dnMap['2,1'])
  
    local spMap = {}
    sp:foreachActive(function(i, j, value)
      spMap[string.format('%s,%s', i, j)] = value
    end)
    assert.equals(4, #moses.keys(spMap))
    assert.equals(1.0, spMap['0,0'])
    assert.equals(2.0, spMap['1,0'])
    assert.equals(4.0, spMap['1,1'])
    assert.equals(5.0, spMap['2,1'])
  end)
  
  --test("horzcat, vertcat, eye, speye") {
  --  local m = 3
  --  local n = 2
  --  local values = Array(1.0, 2.0, 4.0, 5.0)
  --  local allValues = Array(1.0, 2.0, 0.0, 0.0, 4.0, 5.0)
  --  local colPtrs = Array(0, 2, 4)
  --  local rowIndices = Array(0, 1, 1, 2)
  --  // transposed versions
  --  local allValuesT = Array(1.0, 0.0, 2.0, 4.0, 0.0, 5.0)
  --  local colPtrsT = Array(0, 1, 3, 4)
  --  local rowIndicesT = Array(0, 0, 1, 1)
  --
  --  local spMat1 = new SparseMatrix(m, n, colPtrs, rowIndices, values)
  --  local deMat1 = new DenseMatrix(m, n, allValues)
  --  local spMat1T = new SparseMatrix(n, m, colPtrsT, rowIndicesT, values)
  --  local deMat1T = new DenseMatrix(n, m, allValuesT)
  --
  --  // should equal spMat1 & deMat1 respectively
  --  local spMat1TT = spMat1T.transpose
  --  local deMat1TT = deMat1T.transpose
  --
  --  local deMat2 = Matrices.eye(3)
  --  local spMat2 = Matrices.speye(3)
  --  local deMat3 = Matrices.eye(2)
  --  local spMat3 = Matrices.speye(2)
  --
  --  local spHorz = Matrices.horzcat(Array(spMat1, spMat2))
  --  local spHorz2 = Matrices.horzcat(Array(spMat1, deMat2))
  --  local spHorz3 = Matrices.horzcat(Array(deMat1, spMat2))
  --  local deHorz1 = Matrices.horzcat(Array(deMat1, deMat2))
  --  local deHorz2 = Matrices.horzcat(Array.empty[Matrix])
  --
  --  assert(deHorz1.numRows === 3)
  --  assert(spHorz2.numRows === 3)
  --  assert(spHorz3.numRows === 3)
  --  assert(spHorz.numRows === 3)
  --  assert(deHorz1.numCols === 5)
  --  assert(spHorz2.numCols === 5)
  --  assert(spHorz3.numCols === 5)
  --  assert(spHorz.numCols === 5)
  --  assert(deHorz2.numRows === 0)
  --  assert(deHorz2.numCols === 0)
  --  assert(deHorz2.toArray.length === 0)
  --
  --  assert(deHorz1 ~== spHorz2.asInstanceOf[SparseMatrix].toDense absTol 1e-15)
  --  assert(spHorz2 ~== spHorz3 absTol 1e-15)
  --  assert(spHorz(0, 0) === 1.0)
  --  assert(spHorz(2, 1) === 5.0)
  --  assert(spHorz(0, 2) === 1.0)
  --  assert(spHorz(1, 2) === 0.0)
  --  assert(spHorz(1, 3) === 1.0)
  --  assert(spHorz(2, 4) === 1.0)
  --  assert(spHorz(1, 4) === 0.0)
  --  assert(deHorz1(0, 0) === 1.0)
  --  assert(deHorz1(2, 1) === 5.0)
  --  assert(deHorz1(0, 2) === 1.0)
  --  assert(deHorz1(1, 2) == 0.0)
  --  assert(deHorz1(1, 3) === 1.0)
  --  assert(deHorz1(2, 4) === 1.0)
  --  assert(deHorz1(1, 4) === 0.0)
  --
  --  // containing transposed matrices
  --  local spHorzT = Matrices.horzcat(Array(spMat1TT, spMat2))
  --  local spHorz2T = Matrices.horzcat(Array(spMat1TT, deMat2))
  --  local spHorz3T = Matrices.horzcat(Array(deMat1TT, spMat2))
  --  local deHorz1T = Matrices.horzcat(Array(deMat1TT, deMat2))
  --
  --  assert(deHorz1T ~== deHorz1 absTol 1e-15)
  --  assert(spHorzT ~== spHorz absTol 1e-15)
  --  assert(spHorz2T ~== spHorz2 absTol 1e-15)
  --  assert(spHorz3T ~== spHorz3 absTol 1e-15)
  --
  --  intercept[IllegalArgumentException] {
  --    Matrices.horzcat(Array(spMat1, spMat3))
  --  }
  --
  --  intercept[IllegalArgumentException] {
  --    Matrices.horzcat(Array(deMat1, spMat3))
  --  }
  --
  --  local spVert = Matrices.vertcat(Array(spMat1, spMat3))
  --  local deVert1 = Matrices.vertcat(Array(deMat1, deMat3))
  --  local spVert2 = Matrices.vertcat(Array(spMat1, deMat3))
  --  local spVert3 = Matrices.vertcat(Array(deMat1, spMat3))
  --  local deVert2 = Matrices.vertcat(Array.empty[Matrix])
  --
  --  assert(deVert1.numRows === 5)
  --  assert(spVert2.numRows === 5)
  --  assert(spVert3.numRows === 5)
  --  assert(spVert.numRows === 5)
  --  assert(deVert1.numCols === 2)
  --  assert(spVert2.numCols === 2)
  --  assert(spVert3.numCols === 2)
  --  assert(spVert.numCols === 2)
  --  assert(deVert2.numRows === 0)
  --  assert(deVert2.numCols === 0)
  --  assert(deVert2.toArray.length === 0)
  --
  --  assert(deVert1 ~== spVert2.asInstanceOf[SparseMatrix].toDense absTol 1e-15)
  --  assert(spVert2 ~== spVert3 absTol 1e-15)
  --  assert(spVert(0, 0) === 1.0)
  --  assert(spVert(2, 1) === 5.0)
  --  assert(spVert(3, 0) === 1.0)
  --  assert(spVert(3, 1) === 0.0)
  --  assert(spVert(4, 1) === 1.0)
  --  assert(deVert1(0, 0) === 1.0)
  --  assert(deVert1(2, 1) === 5.0)
  --  assert(deVert1(3, 0) === 1.0)
  --  assert(deVert1(3, 1) === 0.0)
  --  assert(deVert1(4, 1) === 1.0)
  --
  --  // containing transposed matrices
  --  local spVertT = Matrices.vertcat(Array(spMat1TT, spMat3))
  --  local deVert1T = Matrices.vertcat(Array(deMat1TT, deMat3))
  --  local spVert2T = Matrices.vertcat(Array(spMat1TT, deMat3))
  --  local spVert3T = Matrices.vertcat(Array(deMat1TT, spMat3))
  --
  --  assert(deVert1T ~== deVert1 absTol 1e-15)
  --  assert(spVertT ~== spVert absTol 1e-15)
  --  assert(spVert2T ~== spVert2 absTol 1e-15)
  --  assert(spVert3T ~== spVert3 absTol 1e-15)
  --
  --  intercept[IllegalArgumentException] {
  --    Matrices.vertcat(Array(spMat1, spMat2))
  --  }
  --
  --  intercept[IllegalArgumentException] {
  --    Matrices.vertcat(Array(deMat1, spMat2))
  --  }
  --}
  
  test('zeros', function()
    local mat = Matrices.zeros(2, 3)
    assert.equals(2, mat.numRows)
    assert.equals(3, mat.numCols)
    for _, v in ipairs(mat.values) do assert.equals(0.0, v) end
  end)
  
  test('ones', function()
    local mat = Matrices.ones(2, 3)
    assert.equals(2, mat.numRows)
    assert.equals(3, mat.numCols)
    for _, v in ipairs(mat.values) do assert.equals(1.0, v) end
  end)
  
  --test("eye") {
  --  local mat = Matrices.eye(2).asInstanceOf[DenseMatrix]
  --  assert(mat.numCols === 2)
  --  assert(mat.numCols === 2)
  --  assert(mat.values.toSeq === Seq(1.0, 0.0, 0.0, 1.0))
  --}
  --
  --test("rand") {
  --  local rng = mock[Random]
  --  when(rng.nextDouble()).thenReturn(1.0, 2.0, 3.0, 4.0)
  --  local mat = Matrices.rand(2, 2, rng).asInstanceOf[DenseMatrix]
  --  assert(mat.numRows === 2)
  --  assert(mat.numCols === 2)
  --  assert(mat.values.toSeq === Seq(1.0, 2.0, 3.0, 4.0))
  --}
  --
  --test("randn") {
  --  local rng = mock[Random]
  --  when(rng.nextGaussian()).thenReturn(1.0, 2.0, 3.0, 4.0)
  --  local mat = Matrices.randn(2, 2, rng).asInstanceOf[DenseMatrix]
  --  assert(mat.numRows === 2)
  --  assert(mat.numCols === 2)
  --  assert(mat.values.toSeq === Seq(1.0, 2.0, 3.0, 4.0))
  --}
  --
  --test("diag") {
  --  local mat = Matrices.diag(Vectors.dense(1.0, 2.0)).asInstanceOf[DenseMatrix]
  --  assert(mat.numRows === 2)
  --  assert(mat.numCols === 2)
  --  assert(mat.values.toSeq === Seq(1.0, 0.0, 0.0, 2.0))
  --}
  --
  --test("sprand") {
  --  local rng = mock[Random]
  --  when(rng.nextInt(4)).thenReturn(0, 1, 1, 3, 2, 2, 0, 1, 3, 0)
  --  when(rng.nextDouble()).thenReturn(1.0, 2.0, 3.0, 4.0, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0)
  --  local mat = SparseMatrix.sprand(4, 4, 0.25, rng)
  --  assert(mat.numRows === 4)
  --  assert(mat.numCols === 4)
  --  assert(mat.rowIndices.toSeq === Seq(3, 0, 2, 1))
  --  assert(mat.values.toSeq === Seq(1.0, 2.0, 3.0, 4.0))
  --  local mat2 = SparseMatrix.sprand(2, 3, 1.0, rng)
  --  assert(mat2.rowIndices.toSeq === Seq(0, 1, 0, 1, 0, 1))
  --  assert(mat2.colPtrs.toSeq === Seq(0, 2, 4, 6))
  --}
  --
  --test("sprandn") {
  --  local rng = mock[Random]
  --  when(rng.nextInt(4)).thenReturn(0, 1, 1, 3, 2, 2, 0, 1, 3, 0)
  --  when(rng.nextGaussian()).thenReturn(1.0, 2.0, 3.0, 4.0)
  --  local mat = SparseMatrix.sprandn(4, 4, 0.25, rng)
  --  assert(mat.numRows === 4)
  --  assert(mat.numCols === 4)
  --  assert(mat.rowIndices.toSeq === Seq(3, 0, 2, 1))
  --  assert(mat.values.toSeq === Seq(1.0, 2.0, 3.0, 4.0))
  --}
  --
  --test("MatrixUDT") {
  --  local dm1 = new DenseMatrix(2, 2, Array(0.9, 1.2, 2.3, 9.8))
  --  local dm2 = new DenseMatrix(3, 2, Array(0.0, 1.21, 2.3, 9.8, 9.0, 0.0))
  --  local dm3 = new DenseMatrix(0, 0, Array())
  --  local sm1 = dm1.toSparse
  --  local sm2 = dm2.toSparse
  --  local sm3 = dm3.toSparse
  --  local mUDT = new MatrixUDT()
  --  Seq(dm1, dm2, dm3, sm1, sm2, sm3).foreach {
  --      mat => assert(mat.toArray === mUDT.deserialize(mUDT.serialize(mat)).toArray)
  --  }
  --  assert(mUDT.typeName == "matrix")
  --  assert(mUDT.simpleString == "matrix")
  --}
  --
  --test("toString") {
  --  local empty = Matrices.ones(0, 0)
  --  empty.toString(0, 0)
  --
  --  local mat = Matrices.rand(5, 10, new Random())
  --  mat.toString(-1, -5)
  --  mat.toString(0, 0)
  --  mat.toString(Int.MinValue, Int.MinValue)
  --  mat.toString(Int.MaxValue, Int.MaxValue)
  --  var lines = mat.toString(6, 50).lines.toArray
  --  assert(lines.size == 5 && lines.forall(_.size <= 50))
  --
  --  lines = mat.toString(5, 100).lines.toArray
  --  assert(lines.size == 5 && lines.forall(_.size <= 100))
  --}
  
  test('numNonzeros and numActives', function()
    local dm1 = Matrices.dense(3, 2, {0, 0, -1, 1, 0, 1})
    assert.equals(3, dm1:numNonzeros())
    assert.equals(6, dm1:numActives())
  
    local sm1 = Matrices.sparse(3, 2, {0, 2, 3}, {0, 2, 1}, {0.0, -1.2, 0.0})
    assert.equals(1, sm1:numNonzeros())
    assert.equals(3, sm1:numActives())
  end)
  
  --test("fromBreeze with sparse matrix") {
  --  // colPtr.last does NOT always equal to values.length in breeze SCSMatrix and
  --  // invocation of compact() may be necessary. Refer to SPARK-11507
  --  local bm1: BM[Double] = new CSCMatrix[Double](
  --    Array(1.0, 1, 1), 3, 3, Array(0, 1, 2, 3), Array(0, 1, 2))
  --  local bm2: BM[Double] = new CSCMatrix[Double](
  --    Array(1.0, 2, 2, 4), 3, 3, Array(0, 0, 2, 4), Array(1, 2, 1, 2))
  --  local sum = bm1 + bm2
  --  Matrices.fromBreeze(sum)
  --}
  --
  --test("Test FromBreeze when Breeze.CSCMatrix.rowIndices has trailing zeros. - SPARK-20687") {
  --  // (2, 0, 0)
  --  // (2, 0, 0)
  --  local mat1Brz = Matrices.sparse(2, 3, Array(0, 2, 2, 2), Array(0, 1), Array(2, 2)).asBreeze
  --  // (2, 1E-15, 1E-15)
  --  // (2, 1E-15, 1E-15)
  --  local mat2Brz = Matrices.sparse(2, 3,
  --    Array(0, 2, 4, 6),
  --    Array(0, 0, 0, 1, 1, 1),
  --    Array(2, 1E-15, 1E-15, 2, 1E-15, 1E-15)).asBreeze
  --  local t1Brz = mat1Brz - mat2Brz
  --  local t2Brz = mat2Brz - mat1Brz
  --  // The following operations raise exceptions on un-patch Matrices.fromBreeze
  --  local t1 = Matrices.fromBreeze(t1Brz)
  --  local t2 = Matrices.fromBreeze(t2Brz)
  --  // t1 == t1Brz && t2 == t2Brz
  --  assert((t1.asBreeze - t1Brz).iterator.map((x) => math.abs(x._2)).sum < 1E-15)
  --  assert((t2.asBreeze - t2Brz).iterator.map((x) => math.abs(x._2)).sum < 1E-15)
  --}
  --
  --test("row/col iterator") {
  --  local dm = new DenseMatrix(3, 2, Array(0, 1, 2, 3, 4, 0))
  --  local sm = dm.toSparse
  --  local rows = Seq(Vectors.dense(0, 3), Vectors.dense(1, 4), Vectors.dense(2, 0))
  --  local cols = Seq(Vectors.dense(0, 1, 2), Vectors.dense(3, 4, 0))
  --  for (m <- Seq(dm, sm)) {
  --    assert(m.rowIter.toSeq === rows)
  --    assert(m.colIter.toSeq === cols)
  --    assert(m.transpose.rowIter.toSeq === cols)
  --    assert(m.transpose.colIter.toSeq === rows)
  --  }
  --}
  --
  --test("conversions between new local linalg and mllib linalg") {
  --  local dm: DenseMatrix = new DenseMatrix(3, 2, Array(0.0, 0.0, 1.0, 0.0, 2.0, 3.5))
  --  local sm: SparseMatrix = dm.toSparse
  --  local sm0: Matrix = sm.asInstanceOf[Matrix]
  --  local dm0: Matrix = dm.asInstanceOf[Matrix]
  --
  --  def compare(oldM: Matrix, newM: newlinalg.Matrix): Unit = {
  --    assert(oldM.toArray === newM.toArray)
  --    assert(oldM.numCols === newM.numCols)
  --    assert(oldM.numRows === newM.numRows)
  --  }
  --
  --  local newSM: newlinalg.SparseMatrix = sm.asML
  --  local newDM: newlinalg.DenseMatrix = dm.asML
  --  local newSM0: newlinalg.Matrix = sm0.asML
  --  local newDM0: newlinalg.Matrix = dm0.asML
  --  assert(newSM0.isInstanceOf[newlinalg.SparseMatrix])
  --  assert(newDM0.isInstanceOf[newlinalg.DenseMatrix])
  --  compare(sm, newSM)
  --  compare(dm, newDM)
  --  compare(sm0, newSM0)
  --  compare(dm0, newDM0)
  --
  --  local oldSM: SparseMatrix = SparseMatrix.fromML(newSM)
  --  local oldDM: DenseMatrix = DenseMatrix.fromML(newDM)
  --  local oldSM0: Matrix = Matrices.fromML(newSM0)
  --  local oldDM0: Matrix = Matrices.fromML(newDM0)
  --  assert(oldSM0.isInstanceOf[SparseMatrix])
  --  assert(oldDM0.isInstanceOf[DenseMatrix])
  --  compare(oldSM, newSM)
  --  compare(oldDM, newDM)
  --  compare(oldSM0, newSM0)
  --  compare(oldDM0, newDM0)
  --}
  --
  --test("implicit conversions between new local linalg and mllib linalg") {
  --
  --  def mllibMatrixToTriple(m: Matrix): (Array[Double], Int, Int) =
  --    (m.toArray, m.numCols, m.numRows)
  --
  --  def mllibDenseMatrixToTriple(m: DenseMatrix): (Array[Double], Int, Int) =
  --    (m.toArray, m.numCols, m.numRows)
  --
  --  def mllibSparseMatrixToTriple(m: SparseMatrix): (Array[Double], Int, Int) =
  --    (m.toArray, m.numCols, m.numRows)
  --
  --  def mlMatrixToTriple(m: newlinalg.Matrix): (Array[Double], Int, Int) =
  --    (m.toArray, m.numCols, m.numRows)
  --
  --  def mlDenseMatrixToTriple(m: newlinalg.DenseMatrix): (Array[Double], Int, Int) =
  --    (m.toArray, m.numCols, m.numRows)
  --
  --  def mlSparseMatrixToTriple(m: newlinalg.SparseMatrix): (Array[Double], Int, Int) =
  --    (m.toArray, m.numCols, m.numRows)
  --
  --  def compare(m1: (Array[Double], Int, Int), m2: (Array[Double], Int, Int)): Unit = {
  --    assert(m1._1 === m2._1)
  --    assert(m1._2 === m2._2)
  --    assert(m1._3 === m2._3)
  --  }
  --
  --  local dm: DenseMatrix = new DenseMatrix(3, 2, Array(0.0, 0.0, 1.0, 0.0, 2.0, 3.5))
  --  local sm: SparseMatrix = dm.toSparse
  --  local sm0: Matrix = sm.asInstanceOf[Matrix]
  --  local dm0: Matrix = dm.asInstanceOf[Matrix]
  --
  --  local newSM: newlinalg.SparseMatrix = sm.asML
  --  local newDM: newlinalg.DenseMatrix = dm.asML
  --  local newSM0: newlinalg.Matrix = sm0.asML
  --  local newDM0: newlinalg.Matrix = dm0.asML
  --
  --  import org.apache.spark.mllib.linalg.MatrixImplicits._
  --
  --  compare(mllibMatrixToTriple(dm0), mllibMatrixToTriple(newDM0))
  --  compare(mllibMatrixToTriple(sm0), mllibMatrixToTriple(newSM0))
  --
  --  compare(mllibDenseMatrixToTriple(dm), mllibDenseMatrixToTriple(newDM))
  --  compare(mllibSparseMatrixToTriple(sm), mllibSparseMatrixToTriple(newSM))
  --
  --  compare(mlMatrixToTriple(dm0), mlMatrixToTriple(newDM))
  --  compare(mlMatrixToTriple(sm0), mlMatrixToTriple(newSM0))
  --
  --  compare(mlDenseMatrixToTriple(dm), mlDenseMatrixToTriple(newDM))
  --  compare(mlSparseMatrixToTriple(sm), mlSparseMatrixToTriple(newSM))
  --}
end)
