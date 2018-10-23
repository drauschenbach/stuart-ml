local M = {}

M.nextDouble = function()
  return M.nextFloat(0, 1)
end

M.nextFloat = function(lower, upper)
  return lower + math.random() * (upper - lower)
end

M.nextInt = function(n)
  if n ~= nil then
    return math.random(0, n)
  else
    return math.random(-math.huge, math.huge)
  end
end

return M
