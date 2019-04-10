local arrays = require 'stuart-ml.util.java.arrays'

describe('Java Utils :: Arrays', function()

  it('binarySearch() with odd number of elements', function()
    local t = {11,12,13}
    assert.equal(1 , arrays.binarySearch(t, 1, #t+1, 11))
    assert.equal(2 , arrays.binarySearch(t, 1, #t+1, 12))
    assert.equal(3 , arrays.binarySearch(t, 1, #t+1, 13))
    assert.equal(-4, arrays.binarySearch(t, 1, #t+1, 14))
  end)
  
  it('binarySearch() with even number of elements', function()
    local t = {11,12,13,14}
    assert.equal(1 , arrays.binarySearch(t, 1, #t+1, 11))
    assert.equal(2 , arrays.binarySearch(t, 1, #t+1, 12))
    assert.equal(3 , arrays.binarySearch(t, 1, #t+1, 13))
    assert.equal(4 , arrays.binarySearch(t, 1, #t+1, 14))
    assert.equal(-5, arrays.binarySearch(t, 1, #t+1, 15))
  end)
  
  -- https://alvinalexander.com/source-code/scala/scala-tabulate-method-use-list-array-vector-seq-and-more
  it('tabulate() works', function()
    assert.same({1,2,3,4,5}, arrays.tabulate(5, function(n) return n+1 end))
    assert.same({2,3,4,5,6}, arrays.tabulate(5, function(n) return n+2 end))
    assert.same({0,2,4,6,8}, arrays.tabulate(5, function(n) return n*2 end))
  end)
  
end)
