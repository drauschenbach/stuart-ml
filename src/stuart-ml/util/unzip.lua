local moses = require 'moses'

local unpack = table.unpack or unpack

local unzip = function(array)
  return moses.zip(unpack(array))
end

return unzip
