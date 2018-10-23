local M = {}

M.iterator = function(table)
  local i = 0
  return function()
    i = i + 1
    if i <= #table then return table[i] end
  end
end

return M
