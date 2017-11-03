local moses = require 'moses'
moses.range = require 'stuart-ml.util.mosesPatchedRange'
local registerAsserts = require 'registerAsserts'
local Vectors = require 'stuart-ml.linalg.Vectors'

registerAsserts(assert)

describe('Apache Spark MLlib VectorsSuite', function()
  local arr = {0.1, 0.0, 0.3, 0.4}
  local n = 4
  local indices = {0, 2, 3}
  local values = {0.1, 0.3, 0.4}

  it('dense vector construction with varargs', function()
    local vec = Vectors.dense(arr)
    assert.equal(#arr, vec:size())
    assert.same(arr, vec.values)
  end)

--  it('dense vector construction from a double array', function()
--   val vec = Vectors.dense(arr).asInstanceOf[DenseVector]
--    assert(vec.size === arr.length)
--    assert(vec.values.eq(arr))
--  end)

  it('sparse vector construction', function()
    local vec = Vectors.sparse(n, indices, values)
    assert.equal(n, vec:size())
    assert.same(indices, vec.indices)
    assert.same(values, vec.values)
  end)

  it('sparse vector construction with unordered elements', function()
    local vec = Vectors.sparse(n, moses.reverse(moses.zip(indices, values)))
    assert.equal(n, vec:size())
    assert.same(indices, vec.indices)
    assert.same(values, vec.values)
  end)

  it('sparse vector construction with mismatched indices/values array', function()
    assert.error(function() Vectors.sparse(4, {1,2,3}, {3.0,5.0,7.0,9.0}) end)
    assert.error(function() Vectors.sparse(4, {1,2,3}, {3.0,5.0}) end)
  end)

  it('sparse vector construction with too many indices vs size', function()
    assert.error(function() Vectors.sparse(3, {1,2,3,4}, {3.0,5.0,7.0,9.0}) end)
  end)

  it('dense to array', function()
    local vec = Vectors.dense(arr)
    assert.same(arr, vec:toArray())
  end)

  it('dense argmax', function()
    local vec = Vectors.dense({})
    assert.equal(-1, vec:argmax())

    local vec2 = Vectors.dense(arr)
    assert.equal(4, vec2:argmax()) -- 3 in Scala, 4 in Lua and its 1-based indexes

    local vec3 = Vectors.dense({-1.0, 0.0, -2.0, 1.0})
    assert.equal(4, vec3:argmax()) -- 3 in Scala, 4 in Lua and its 1-based indexes
  end)

  it('sparse to array', function()
    local vec = Vectors.sparse(n, indices, values)
    assert.same(arr, vec:toArray())
  end)

  it('sparse argmax', function()
    local vec = Vectors.sparse(0, {}, {})
    assert.equal(-1, vec:argmax())

    local vec2 = Vectors.sparse(n, indices, values)
    assert.equal(3, vec2:argmax())

    local vec3 = Vectors.sparse(5, {2,3,4}, {1.0,0.0,-.7})
    assert.equal(2, vec3:argmax())

    -- check for case that sparse vector is created with
    -- only negative values {0.0, 0.0,-1.0, -0.7, 0.0}
    local vec4 = Vectors.sparse(5, {2,3}, {-1.0,-.7})
    assert.equal(0, vec4:argmax())

    local vec5 = Vectors.sparse(11, {0,3,10}, {-1.0,-.7,0.0})
    assert.equal(1, vec5:argmax())

    local vec6 = Vectors.sparse(11, {0,1,2}, {-1.0,-.7,0.0})
    assert.equal(2, vec6:argmax())

    local vec7 = Vectors.sparse(5, {0,1,3}, {-1.0,0.0,-.7})
    assert.equal(1, vec7:argmax())

    local vec8 = Vectors.sparse(5, {1,2}, {0.0,-1.0})
    assert.equal(0, vec8:argmax())

    -- Check for case when sparse vector is non-empty but the values are empty
    local vec9 = Vectors.sparse(100, {}, {})
    assert.equal(0, vec9:argmax())

    local vec10 = Vectors.sparse(1, {}, {})
    assert.equal(0, vec10:argmax())
  end)

  it('vector equals', function()
    local dv1 = Vectors.dense(moses.clone(arr))
    local dv2 = Vectors.dense(moses.clone(arr))
    local sv1 = Vectors.sparse(n, moses.clone(indices), moses.clone(values))
    local sv2 = Vectors.sparse(n, moses.clone(indices), moses.clone(values))

    local vectors = {dv1, dv2, sv1, sv2}

    assert.equal(dv1, dv2)
    assert.equal(sv1, sv2)
    
    local another = Vectors.dense(0.1, 0.2, 0.3, 0.4)

    for _,vector in ipairs(vectors) do
      assert.not_equal(vector, another)
    end

  end)

  it('vectors equals with explicit 0', function()
    local dv1 = Vectors.dense({0, 0.9, 0, 0.8, 0})
    local sv1 = Vectors.sparse(5, {1, 3}, {0.9, 0.8})
    local sv2 = Vectors.sparse(5, {0, 1, 2, 3, 4}, {0, 0.9, 0, 0.8, 0})

    local vectors = {dv1, sv1, sv2}
    for i=1,#vectors do
      assert.equal(vectors[i], vectors[i])
    end

    local another = Vectors.sparse(5, {0, 1, 3}, {0, 0.9, 0.2})
    for i,vector in ipairs(vectors) do
      assert.not_equal(vector, another)
    end
  end)

  it('indexing dense vectors', function()
    local vec = Vectors.dense(1.0, 2.0, 3.0, 4.0)
    assert.equal(1.0, vec[1])
    assert.equal(4.0, vec[4])
  end)

  it('indexing sparse vectors', function()
    local vec = Vectors.sparse(7, {0,2,4,6}, {1.0,2.0,3.0,4.0})
    assert.equal(1.0, vec[0])
    assert.equal(0.0, vec[1])
    assert.equal(2.0, vec[2])
    assert.equal(0.0, vec[3])
    assert.equal(4.0, vec[6])
    
    local vec2 = Vectors.sparse(8, {0,2,4,6}, {1.0,2.0,3.0,4.0})
    assert.equal(4.0, vec2[6])
    assert.equal(0.0, vec2[7])
  end)

--  it('parse vectors', function()
--    val vectors = Seq(
--      Vectors.dense(Array.empty[Double]),
--      Vectors.dense(1.0),
--      Vectors.dense(1.0E6, 0.0, -2.0e-7),
--      Vectors.sparse(0, Array.empty[Int], Array.empty[Double]),
--      Vectors.sparse(1, Array(0), Array(1.0)),
--      Vectors.sparse(3, Array(0, 2), Array(1.0, -2.0)))
--    vectors.foreach { v =>
--      val v1 = Vectors.parse(v.toString)
--      assert(v.getClass === v1.getClass)
--      assert(v === v1)
--    }
--
--    val malformatted = Seq("1", "[1,,]", "[1,2b]", "(1,[1,2])", "([1],[2.0,1.0])")
--    malformatted.foreach { s =>
--      intercept[SparkException] {
--        Vectors.parse(s)
--        logInfo(s"Didn't detect malformatted string $s.")
--      }
--    }
--  end)

  it('zeros', function()
    assert.same(Vectors.dense(0.0, 0.0, 0.0), Vectors.zeros(3))
  end)

  it('Vector.copy', function()
    local sv = Vectors.sparse(4, {0, 2}, {1.0, 2.0})
    local svCopy = sv:copy()
    assert.equal(sv:size(), svCopy:size())
    assert.same(sv.indices, svCopy.indices)
    assert.same(sv.values, svCopy.values)
    assert.not_equal(sv.indices, svCopy.indices)
    assert.not_equal(sv.values, svCopy.values)

    local dv = Vectors.dense(1.0, 0.0, 2.0)
    local dvCopy = dv:copy()
    assert.equal(dv:size(), dvCopy:size())
    assert.same(dv.values, dvCopy.values)
    assert.not_equal(dv.values, dvCopy.values)
  end)

--  it('VectorUDT', function()
--    val dv0 = Vectors.dense(Array.empty[Double])
--    val dv1 = Vectors.dense(1.0, 2.0)
--    val sv0 = Vectors.sparse(2, Array.empty, Array.empty)
--    val sv1 = Vectors.sparse(2, Array(1), Array(2.0))
--    val udt = new VectorUDT()
--    for (v <- Seq(dv0, dv1, sv0, sv1)) {
--      assert(v === udt.deserialize(udt.serialize(v)))
--    }
--    assert(udt.typeName == "vector")
--    assert(udt.simpleString == "vector")
--  end)

--  it('fromBreeze', function()
--    val x = BDM.zeros[Double](10, 10)
--    val v = Vectors.fromBreeze(x(::, 0))
--    assert(v.size === x.rows)
--  end)

  it('sqdist', function()
      math.randomseed(os.clock())
    for m=1,1000,100 do
      local nnz = 0; if m > 1 then nnz = math.random(m-1) end
      
      local indices1 = moses.slice(moses.shuffle(moses.range(1,m)), 1, nnz)
      local values1 = moses.map(moses.range(1,nnz), function() return math.random() end)
      local sparseVector1 = Vectors.sparse(m, indices1, values1)
      
      local indices2 = moses.slice(moses.shuffle(moses.range(m)), 1, nnz)
      local values2 = moses.map(moses.range(1,nnz), function() return math.random() end)
      local sparseVector2 = Vectors.sparse(m, indices2, values2)
      
      local denseVector1 = Vectors.dense(sparseVector1:toArray())
      assert.is_not_nil(denseVector1)
      local denseVector2 = Vectors.dense(sparseVector2:toArray())
      assert.is_not_nil(denseVector2)
      
      -- The following Scala tests make use of Breeze as an independent linear algebra function provider.
      -- There does not appear to be any independent linear algebra libs on LuaRocks.
      -- https://luarocks.org/modules/shakesoda/cpml comes close but it's only in the DEV repo.
      
      -- TODO val squaredDist = breezeSquaredDistance(sparseVector1.asBreeze, sparseVector2.asBreeze)
      
      -- SparseVector vs. SparseVector
      -- TODO assert(Vectors.sqdist(sparseVector1, sparseVector2) ~== squaredDist relTol 1E-8)
      Vectors.sqdist(sparseVector1, sparseVector2)
      -- DenseVector  vs. SparseVector
      -- TODO assert(Vectors.sqdist(denseVector1, sparseVector2) ~== squaredDist relTol 1E-8)
      Vectors.sqdist(sparseVector1, sparseVector2)
      -- DenseVector  vs. DenseVector
      -- TODO assert(Vectors.sqdist(denseVector1, denseVector2) ~== squaredDist relTol 1E-8)
      Vectors.sqdist(sparseVector1, sparseVector2)
    end
  end)

  it('foreachActive', function()
    local dv = Vectors.dense(0.0, 1.2, 3.1, 0.0)
    local sv = Vectors.sparse(4, {{1,1.2}, {2,3.1}, {3,0.0}})

    local dvMap = {}
    dv:foreachActive(function(index,value)
      dvMap[index+1] = value
    end)
    assert.equal(4, moses.size(dvMap))
    assert.equal(0.0, dvMap[1])
    assert.equal(1.2, dvMap[2])
    assert.equal(3.1, dvMap[3])
    assert.equal(0.0, dvMap[4])

    local svMap = {}
    sv:foreachActive(function(index,value)
      svMap[index] = value
    end)
    assert.equal(3, #svMap)
    assert.equal(1.2, svMap[1])
    assert.equal(3.1, svMap[2])
    assert.equal(0.0, svMap[3])
  end)

  it('vector p-norm', function()
    local dv = Vectors.dense(0.0, -1.2, 3.1, 0.0, -4.5, 1.9)
    local sv = Vectors.sparse(6, {{1, -1.2}, {2, 3.1}, {3, 0.0}, {4, -4.5}, {5, 1.9}})

    local expected = moses.reduce(dv:toArray(), function(a,v)
      return a + math.abs(v)
    end, 0.0)
    local actual = Vectors.norm(dv, 1.0)
    assert.equal_relTol(expected, actual, 1e-8)
      
    expected = moses.reduce(sv:toArray(), function(a,v)
      return a + math.abs(v)
    end, 0.0)
    actual = Vectors.norm(sv, 1.0)
    assert.equal_relTol(expected, actual, 1e-8)

    expected = math.sqrt(moses.reduce(dv:toArray(), function(a,v)
      return a + v * v
    end, 0.0))
    actual = Vectors.norm(dv, 2.0)
    assert.equal_relTol(expected, actual, 1e-8)

    expected = math.sqrt(moses.reduce(sv:toArray(), function(a,v)
      return a + v * v
    end, 0.0))
    actual = Vectors.norm(sv, 2.0)
    assert.equal_relTol(expected, actual, 1e-8)

    expected = moses.reduce(dv:toArray(), function(a,v)
      return math.max(a, math.abs(v))
    end, 0.0)
    actual = Vectors.norm(dv, math.huge)
    assert.equal_relTol(expected, actual, 1e-8)

    expected = moses.reduce(sv:toArray(), function(a,v)
      return math.max(a, math.abs(v))
    end, 0.0)
    actual = Vectors.norm(sv, math.huge)
    assert.equal_relTol(expected, actual, 1e-8)

    expected = math.pow(moses.reduce(dv:toArray(), function(a,v)
      return a + math.pow(math.abs(v), 3.7)
    end, 0.0), 1.0 / 3.7)
    actual = Vectors.norm(dv, 3.7)
    assert.equal_relTol(expected, actual, 1e-8)

    expected = math.pow(moses.reduce(sv:toArray(), function(a,v)
      return a + math.pow(math.abs(v), 3.7)
    end, 0.0), 1.0 / 3.7)
    actual = Vectors.norm(sv, 3.7)
    assert.equal_relTol(expected, actual, 1e-8)
  end)

  it('Vector numActive and numNonzeros', function()
    local dv = Vectors.dense(0.0, 2.0, 3.0, 0.0)
    assert.equal(4, dv.numActives)
    assert.equal(2, dv.numNonzeros)

    local sv = Vectors.sparse(4, {0, 1, 2}, {0.0, 2.0, 3.0})
    assert.equal(3, sv.numActives)
    assert.equal(2, sv.numNonzeros)
  end)

  it('Vector toSparse and toDense', function()
    local dv0 = Vectors.dense(0.0, 2.0, 3.0, 0.0)
    assert.same(dv0, dv0:toDense())
    local dv0s = dv0:toSparse()
    assert.equal(2, dv0s.numActives)
    
    -- This next compare doesn't work, because Lua < 5.3 automatically treats two tables
    -- as unequal if they have different metamethod tables. A search for a different
    -- class library might be necessary in order to try and achieve SparseVector and
    -- DenseVector having the same metatable, and therefore becoming comparable with __eq.
    --assert.equal(dv0, dv0s)
    
    -- here's a substitute test, for now
    assert.same(dv0:toArray(), dv0s:toArray())

    local sv0 = Vectors.sparse(4, {0,1,2}, {0.0,2.0,3.0})
    --assert.equal(sv0, sv0:toDense())
    assert.same(sv0:toArray(), sv0:toDense():toArray())
    
    local sv0s = sv0:toSparse()
    assert.equal(2, sv0s.numActives)
    --assert.same(sv0, sv0s)
    assert.same(sv0:toArray(), sv0s:toArray())
  end)

--  it('Vector.compressed', function()
--    val dv0 = Vectors.dense(1.0, 2.0, 3.0, 0.0)
--    val dv0c = dv0.compressed.asInstanceOf[DenseVector]
--    assert(dv0c === dv0)
--
--    val dv1 = Vectors.dense(0.0, 2.0, 0.0, 0.0)
--    val dv1c = dv1.compressed.asInstanceOf[SparseVector]
--    assert(dv1 === dv1c)
--    assert(dv1c.numActives === 1)
--
--    val sv0 = Vectors.sparse(4, Array(1, 2), Array(2.0, 0.0))
--    val sv0c = sv0.compressed.asInstanceOf[SparseVector]
--    assert(sv0 === sv0c)
--    assert(sv0c.numActives === 1)
--
--    val sv1 = Vectors.sparse(4, Array(0, 1, 2), Array(1.0, 2.0, 3.0))
--    val sv1c = sv1.compressed.asInstanceOf[DenseVector]
--    assert(sv1 === sv1c)
--  end)

--  it('SparseVector.slice', function()
--    val v = new SparseVector(5, Array(1, 2, 4), Array(1.1, 2.2, 4.4))
--    assert(v.slice(Array(0, 2)) === new SparseVector(2, Array(1), Array(2.2)))
--    assert(v.slice(Array(2, 0)) === new SparseVector(2, Array(0), Array(2.2)))
--    assert(v.slice(Array(2, 0, 3, 4)) === new SparseVector(4, Array(0, 3), Array(2.2, 4.4)))
--  end)

--  it('toJson/fromJson', function()
--    val sv0 = Vectors.sparse(0, Array.empty, Array.empty)
--    val sv1 = Vectors.sparse(1, Array.empty, Array.empty)
--    val sv2 = Vectors.sparse(2, Array(1), Array(2.0))
--    val dv0 = Vectors.dense(Array.empty[Double])
--    val dv1 = Vectors.dense(1.0)
--    val dv2 = Vectors.dense(0.0, 2.0)
--    for (v <- Seq(sv0, sv1, sv2, dv0, dv1, dv2)) {
--      val json = v.toJson
--      parseJson(json) // `json` should be a valid JSON string
--      val u = Vectors.fromJson(json)
--      assert(u.getClass === v.getClass, "toJson/fromJson should preserve vector types.")
--      assert(u === v, "toJson/fromJson should preserve vector values.")
--    }
--  end)

--  it('conversions between new local linalg and mllib linalg', function()
--    val dv: DenseVector = new DenseVector(Array(1.0, 2.0, 3.5))
--    val sv: SparseVector = new SparseVector(5, Array(1, 2, 4), Array(1.1, 2.2, 4.4))
--    val sv0: Vector = sv.asInstanceOf[Vector]
--    val dv0: Vector = dv.asInstanceOf[Vector]
--
--    val newSV: newlinalg.SparseVector = sv.asML
--    val newDV: newlinalg.DenseVector = dv.asML
--    val newSV0: newlinalg.Vector = sv0.asML
--    val newDV0: newlinalg.Vector = dv0.asML
--    assert(newSV0.isInstanceOf[newlinalg.SparseVector])
--    assert(newDV0.isInstanceOf[newlinalg.DenseVector])
--    assert(sv.toArray === newSV.toArray)
--    assert(dv.toArray === newDV.toArray)
--    assert(sv0.toArray === newSV0.toArray)
--    assert(dv0.toArray === newDV0.toArray)
--
--    val oldSV: SparseVector = SparseVector.fromML(newSV)
--    val oldDV: DenseVector = DenseVector.fromML(newDV)
--    val oldSV0: Vector = Vectors.fromML(newSV0)
--    val oldDV0: Vector = Vectors.fromML(newDV0)
--    assert(oldSV0.isInstanceOf[SparseVector])
--    assert(oldDV0.isInstanceOf[DenseVector])
--    assert(oldSV.toArray === newSV.toArray)
--    assert(oldDV.toArray === newDV.toArray)
--    assert(oldSV0.toArray === newSV0.toArray)
--    assert(oldDV0.toArray === newDV0.toArray)
--  end)

--  it('implicit conversions between new local linalg and mllib linalg', function()
--
--    def mllibVectorToArray(v: Vector): Array[Double] = v.toArray
--
--    def mllibDenseVectorToArray(v: DenseVector): Array[Double] = v.toArray
--
--    def mllibSparseVectorToArray(v: SparseVector): Array[Double] = v.toArray
--
--    def mlVectorToArray(v: newlinalg.Vector): Array[Double] = v.toArray
--
--    def mlDenseVectorToArray(v: newlinalg.DenseVector): Array[Double] = v.toArray
--
--    def mlSparseVectorToArray(v: newlinalg.SparseVector): Array[Double] = v.toArray
--
--    val dv: DenseVector = new DenseVector(Array(1.0, 2.0, 3.5))
--    val sv: SparseVector = new SparseVector(5, Array(1, 2, 4), Array(1.1, 2.2, 4.4))
--    val sv0: Vector = sv.asInstanceOf[Vector]
--    val dv0: Vector = dv.asInstanceOf[Vector]
--
--    val newSV: newlinalg.SparseVector = sv.asML
--    val newDV: newlinalg.DenseVector = dv.asML
--    val newSV0: newlinalg.Vector = sv0.asML
--    val newDV0: newlinalg.Vector = dv0.asML
--
--    import org.apache.spark.mllib.linalg.VectorImplicits._
--
--    assert(mllibVectorToArray(dv0) === mllibVectorToArray(newDV0))
--    assert(mllibVectorToArray(sv0) === mllibVectorToArray(newSV0))
--
--    assert(mllibDenseVectorToArray(dv) === mllibDenseVectorToArray(newDV))
--    assert(mllibSparseVectorToArray(sv) === mllibSparseVectorToArray(newSV))
--
--    assert(mlVectorToArray(dv0) === mlVectorToArray(newDV0))
--    assert(mlVectorToArray(sv0) === mlVectorToArray(newSV0))
--
--    assert(mlDenseVectorToArray(dv) === mlDenseVectorToArray(newDV))
--    assert(mlSparseVectorToArray(sv) === mlSparseVectorToArray(newSV))
--  end)
  
end)
