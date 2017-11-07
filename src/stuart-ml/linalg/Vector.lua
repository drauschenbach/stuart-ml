local class = require 'middleclass'
local moses = require 'moses'

local Vector = class('Vector')

function Vector:numActives()
  return #self.values
end

function Vector:numNonzeros()
  local nnz = moses.reduce(self.values, function(r,v)
    if v ~= 0 then r = r + 1 end
    return r
  end, 0)
  return nnz
end

return Vector
