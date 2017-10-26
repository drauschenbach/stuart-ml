local moses = require 'moses'

local unzip = function(array)
  local length = 0
  array = moses.filter(array, function(_, v)
    if moses.isTable(v) then
      length = math.max(length, #v)
      return true
    end
  end)
  local result = {}
  for i=1,length do
    local t = {}
    for j=1,#array do
      t[#t+1] = array[j][i]
    end
    result[#result+1] = t
  end
  return result
end

return unzip
