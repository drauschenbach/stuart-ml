print('Begin test')

local DenseMatrix = require 'stuart-ml.linalg.DenseMatrix'
local Matrices = require 'stuart-ml.linalg.Matrices'
local moses = require 'moses'
local SparseMatrix = require 'stuart-ml.linalg.SparseMatrix'


-- ============================================================================
-- Mini test framework
-- ============================================================================

local failures = 0

local function assertEquals(expected,actual,message)
  message = message or string.format('Expected %s but got %s', tostring(expected), tostring(actual))
  assert(actual==expected, message)
end

local function assertError(testFn, message)
  local status, _ = pcall(testFn)
  assert(not status, message or 'Expected error but got none')
end

local function assertNotEquals(expected,actual,message)
  message = message or string.format('Expected %s but got %s', tostring(expected), tostring(actual))
  assert(actual~=expected, message)
end

local function assertSame(expected,actual,message)
  message = message or string.format('Expected %s but got %s', tostring(expected), tostring(actual))
  assert(moses.isEqual(expected, actual), message)
end

local function it(message, testFn)
  local status, err =  pcall(testFn)
  if status then
    print(string.format('✓ %s', message))
  else
    print(string.format('✖ %s', message))
    print(string.format('  FAILED: %s', err))
    failures = failures + 1
  end
end


-- ============================================================================
-- stuart-ml.linalg.Vectors
-- ============================================================================

it('dense matrix construction', function()
  local m = 3
  local n = 2
  local values = {0.0, 1.0, 2.0, 3.0, 4.0, 5.0}
  local mat = Matrices.dense(m, n, values)
  assertEquals(m, mat.numRows)
  assertEquals(n, mat.numCols)
  assertSame(values, mat.values)
end)

it('dense matrix construction with wrong dimension', function()
  assertError(function()
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
  assertEquals(m, mat.numRows)
  assertEquals(n, mat.numCols)
  assertSame(values, mat.values)
  assertSame(colPtrs, mat.colPtrs)
  assertSame(rowIndices, mat.rowIndices)

  -- asBreeze NIY
  -- local entries = {{2, 2, 3.0}, {1, 0, 1.0}, {2, 0, 2.0},
  --  {1, 2, 2.0}, {2, 2, 2.0}, {1, 2, 2.0}, {0, 0, 0.0}}
  -- local mat2 = SparseMatrix.fromCOO(m, n, entries)
  -- assert(mat.asBreeze === mat2.asBreeze)
  -- assertEquals(4, #mat2.values)
end)

it('sparse matrix construction with wrong number of elements', function()
  assertError(function()
    Matrices.sparse(3, 2, {0,1}, {1,2,1}, {0.0,1.0,2.0})
  end)
  assertError(function()
    Matrices.sparse(3, 2, {0,1,2}, {1,2}, {0.0,1.0,2.0})
  end)
end)

it('index in matrices incorrect input', function()
  local sm = Matrices.sparse(3, 2, {0, 2, 3}, {1, 2, 1}, {0.0, 1.0, 2.0})
  local dm = Matrices.dense(3, 2, {0.0, 2.3, 1.4, 3.2, 1.0, 9.1})
  for _, mat in ipairs({sm,dm}) do
    assertError(function() mat:index(4,1) end)
    assertError(function() mat:index(1,4) end)
    assertError(function() mat:index(-1,2) end)
    assertError(function() mat:index(1,-2) end)
  end
end)

-- it('equals', function()

-- it("matrix copies are deep copies")

it('matrix indexing and updating', function()
  local m = 3
  local n = 2
  local allValues = {0.0, 1.0, 2.0, 3.0, 4.0, 0.0}

  local denseMat = DenseMatrix.new(m, n, allValues)

  assertEquals(3.0, denseMat:get(0, 1))
  assertEquals(denseMat.values[4], denseMat:get(0, 1))
  assertEquals(denseMat.values[4], denseMat:get(0, 1))
  assertEquals(0.0, denseMat:get(0, 0))

  denseMat:update(0, 0, 10.0)
  assertEquals(10.0, denseMat:get(0, 0))
  assertEquals(10.0, denseMat.values[1])

  local sparseValues = {1.0, 2.0, 3.0, 4.0}
  local colPtrs = {0, 2, 4}
  local rowIndices = {1, 2, 0, 1}
  local sparseMat = SparseMatrix.new(m, n, colPtrs, rowIndices, sparseValues)

--    assertEquals(3.0, sparseMat:get(0, 1))
--    assertEquals(sparseMat.values[3], sparseMat:get(0, 1))
--    assertEquals(0.0, sparseMat:get(0, 0))

  assertError(function()
    sparseMat:update(0, 0, 10.0)
  end)

--    assertError(function()
--      sparseMat:update(2, 1, 10.0)
--    end)
--
--    sparseMat:update(0, 1, 10.0)
--    assertEquals(10.0, sparseMat:get(0, 1))
--    assertEquals(10.0, sparseMat.values[3])
end)

it('toSparse, toDense', function()
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

it('map, update', function()
  local m = 3
  local n = 2
  local values = {1.0, 2.0, 4.0, 5.0}
  local allValues = {1.0, 2.0, 0.0, 0.0, 4.0, 5.0}
  local colPtrs = {0, 2, 4}
  local rowIndices = {0, 1, 1, 2}

  local spMat1 = SparseMatrix.new(m, n, colPtrs, rowIndices, values)
  local deMat1 = DenseMatrix.new(m, n, allValues)
  local deMat2 = deMat1:map(function(x) return x * 2 end)
  local spMat2 = spMat1:map(function(x) return x * 2 end)
  deMat1:update(function(x) return x * 2 end)
  spMat1:update(function(x) return x * 2 end)

  assertSame(spMat1:toArray(), spMat2:toArray())
  assertSame(deMat1:toArray(), deMat2:toArray())
end)

it('transpose', function()
  local dA = DenseMatrix.new(4, 3, {0.0, 1.0, 0.0, 0.0, 2.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 3.0})
  local sA = SparseMatrix.new(4, 3, {0, 1, 3, 4}, {1, 0, 2, 3}, {1.0, 2.0, 1.0, 3.0})

  local dAT = dA:transpose()
  local sAT = sA:transpose()
-- local dATexpected = DenseMatrix.new(3, 4, {0.0, 2.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 3.0})
-- local sATexpected = SparseMatrix.new(3, 4, {0, 1, 2, 3, 4}, {1, 0, 1, 2}, {2.0, 1.0, 1.0, 3.0})

--  assert(dAT.asBreeze === dATexpected.asBreeze)
--  assert(sAT.asBreeze === sATexpected.asBreeze)
  assertEquals(dA:get(1, 0), dAT:get(0, 1))
  assertEquals(dA:get(2, 1), dAT:get(1, 2))
  assertEquals(sA:get(1, 0), sAT:get(0, 1))
  assertEquals(sA:get(2, 1), sAT:get(1, 2))

  assertNotEquals(dA:toArray(), dAT:toArray()) -- has to have a new array
  assertEquals(dA.values, dAT:transpose().values) -- should not copy array

--  assert(dAT.toSparse.asBreeze === sATexpected.asBreeze)
--  assert(sAT.toDense.asBreeze === dATexpected.asBreeze)
end)

it('foreachActive', function()
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
  assertEquals(6, #moses.keys(dnMap))
  assertEquals(1.0, dnMap['0,0'])
  assertEquals(2.0, dnMap['1,0'])
  assertEquals(0.0, dnMap['2,0'])
  assertEquals(0.0, dnMap['0,1'])
  assertEquals(4.0, dnMap['1,1'])
  assertEquals(5.0, dnMap['2,1'])

  local spMap = {}
  sp:foreachActive(function(i, j, value)
    spMap[string.format('%s,%s', i, j)] = value
  end)
  assertEquals(4, #moses.keys(spMap))
  assertEquals(1.0, spMap['0,0'])
  assertEquals(2.0, spMap['1,0'])
  assertEquals(4.0, spMap['1,1'])
  assertEquals(5.0, spMap['2,1'])
end)

--it("horzcat, vertcat, eye, speye")

it('zeros', function()
  local mat = Matrices.zeros(2, 3)
  assertEquals(2, mat.numRows)
  assertEquals(3, mat.numCols)
  for _, v in ipairs(mat.values) do assertEquals(0.0, v) end
end)

it('ones', function()
  local mat = Matrices.ones(2, 3)
  assertEquals(2, mat.numRows)
  assertEquals(3, mat.numCols)
  for _, v in ipairs(mat.values) do assertEquals(1.0, v) end
end)

it('eye', function()
  local mat = Matrices.eye(2)
  assertEquals(2, mat.numCols)
  assertSame({1.0, 0.0, 0.0, 1.0}, mat.values)
end)

--it("rand")

--it("randn")

it('diag', function()
  local Vectors = require 'stuart-ml.linalg.Vectors'
  local mat = Matrices.diag(Vectors.dense(1.0, 2.0))
  assertEquals(2, mat.numRows)
  assertEquals(2, mat.numCols)
  assertSame({1.0, 0.0, 0.0, 2.0}, mat.values)
end)

--it("sprand")

--it("sprandn")

--it("MatrixUDT")

--it('toString')

it('numNonzeros and numActives', function()
  local dm1 = Matrices.dense(3, 2, {0, 0, -1, 1, 0, 1})
  assertEquals(3, dm1:numNonzeros())
  assertEquals(6, dm1:numActives())

  local sm1 = Matrices.sparse(3, 2, {0, 2, 3}, {0, 2, 1}, {0.0, -1.2, 0.0})
  assertEquals(1, sm1:numNonzeros())
  assertEquals(3, sm1:numActives())
end)

--it("fromBreeze with sparse matrix")

--it("row/col iterator")

--it("conversions between new local linalg and mllib linalg")

--it("implicit conversions between new local linalg and mllib linalg")

-- ============================================================================
-- Mini test framework -- report results
-- ============================================================================

print(string.format('End of test: %d failures', failures))
