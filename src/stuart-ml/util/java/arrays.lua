local M = {}

-- interface: https://docs.oracle.com/javase/7/docs/api/java/util/Arrays.html#binarySearch(float[],%20int,%20int,%20float)
--            (but conforming to Lua 1-based table indexes instead of Java's 0-based indexes)
-- implementation: https://stackoverflow.com/questions/19522451/binary-search-of-an-array-of-arrays-in-lua
M.binarySearch = function(a, fromIndex, toIndex, key)
  fromIndex = fromIndex or 0
  assert(fromIndex >= 0, 'fromIndex must be >= 0')
  toIndex = toIndex or nil
  if toIndex == nil then toIndex = #a end
  while fromIndex < toIndex do
    local mid = math.floor((fromIndex+toIndex) / 2)
    local midVal = a[mid+1]
    if midVal < key then
      fromIndex = mid+1
    elseif midVal > key then
      toIndex = mid
    else
      return mid
    end
  end
  return -fromIndex
end

return M
