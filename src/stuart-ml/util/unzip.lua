local moses = require 'moses'
moses.zip = require 'stuart-ml.util.mosesPatchedZip'

local unpack = table.unpack or unpack

local unzip = function(array)
  return moses.zip(unpack(array))
end

return unzip
