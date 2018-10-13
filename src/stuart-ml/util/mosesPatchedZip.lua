local moses = require 'moses'

-- Moses 2.1.0-1 has a bug in zip(). This temporary fix is sourced from
-- https://github.com/Yonaba/Moses/commit/14171d243b76c845c3a9001aee1a0e9d2056f95e
local zip = function(...)
  local args = {...}
  local n = moses.max(args, function(array) return #array end)
  local _ans = {}
  for i = 1,n do
    if not _ans[i] then _ans[i] = {} end
    for k, array in ipairs(args) do
      if (array[i]~=nil) then _ans[i][#_ans[i]+1] = array[i] end
    end
  end
  return _ans
end

return zip
