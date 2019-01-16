local arrays = require 'stuart-ml.util.java.arrays'

describe('Java Utils :: Arrays', function()

  it('binarySearch() with odd number of elements', function()
    local t = {1,2,3}
    assert.equal(0 , arrays.binarySearch(t, 0, #t, 1))
    assert.equal(1 , arrays.binarySearch(t, 0, #t, 2))
    assert.equal(2 , arrays.binarySearch(t, 0, #t, 3))
    assert.equal(-3, arrays.binarySearch(t, 0, #t, 4))
  end)
  
  it('binarySearch() with even number of elements', function()
    local t = {1,2,3,4}
    assert.equal(0 , arrays.binarySearch(t, 0, #t, 1))
    assert.equal(1 , arrays.binarySearch(t, 0, #t, 2))
    assert.equal(2 , arrays.binarySearch(t, 0, #t, 3))
    assert.equal(3 , arrays.binarySearch(t, 0, #t, 4))
    assert.equal(-4, arrays.binarySearch(t, 0, #t, 5))
  end)
end)
