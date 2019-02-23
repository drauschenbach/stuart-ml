-- Begin Redis support
local builtins = {
  ['cjson'] = cjson,
  ['cmsgpack'] = cmsgpack,
  ['math'] = math,
  ['redis.breakpoint'] = redis.breakpoint,
  ['redis.debug'] = redis.debug,
  ['redis.sha1hex'] = redis.sha1hex,
  ['string'] = string,
  ['struct'] = struct,
  ['table'] = table
}
local package = {
  loaded={},
  preload={}
}
local function require(name)
  local builtin = builtins[name]
  if builtin then return builtin end
  if package.loaded[name] == nil then
    package.loaded[name] = package.preload[name]()
  end
  return package.loaded[name]
end
local arg = ARGV
local io = nil
local os = nil
-- End Redis support


package.preload["moses"] = function(...)
  local os = {}
  --- Utility-belt library for functional programming in Lua ([source](http://github.com/Yonaba/Moses))
  -- @author [Roland Yonaba](http://github.com/Yonaba)
  -- @copyright 2012-2018
  -- @license [MIT](http://www.opensource.org/licenses/mit-license.php)
  -- @release 2.1.0
  -- @module moses
  -- @set sort=true
  local _MODULEVERSION = '2.1.0'
  -- Internalisation
  local next, type, pcall          = next, type, pcall
  local setmetatable, getmetatable = setmetatable, getmetatable
  local t_insert, t_sort           = table.insert, table.sort
  local t_remove,t_concat          = table.remove, table.concat
  local randomseed, random, huge   = math.randomseed, math.random, math.huge
  local floor, max, min, ceil      = math.floor, math.max, math.min, math.ceil
  local wrap                       = coroutine.wrap
  local yield                      = coroutine.yield
  local rawget                     = rawget
  local unpack                     = table.unpack or unpack
  local pairs,ipairs               = pairs,ipairs
  local error                      = error
  local clock                      = os.clock
  local M                          = {}
  -- ======== Private helpers
  local function f_max(a,b) return a>b end
  local function f_min(a,b) return a<b end
  local function count(t)  -- raw count of items in an map-table
    local i = 0
      for k,v in pairs(t) do i = i + 1 end
    return i
  end
  local function extract(list,comp,transform,...) -- extracts value from a list
    transform = transform or M.identity
    local _ans  
    for k,v in pairs(list) do
      if not _ans then _ans = transform(v,...)
      else
        local val = transform(v,...)
        _ans = comp(_ans,val) and _ans or val
      end
    end
    return _ans
  end
  local function partgen(t, n, f, pad) -- generates array partitions
    for i = 0, #t, n do
      local s = M.slice(t, i+1, i+n)
      if #s>0 then 
  			while (#s < n and pad) do s[#s+1] = pad end			
  			f(s)
  		end
    end
  end
  local function partgen2(t, n, f, pad) -- generates overlapping array partitions
    for i = 0, #t, n-1 do
      local s = M.slice(t, i+1, i+n)
      if #s>0 and i+1<#t then 
  			while (#s < n and pad) do s[#s+1] = pad end
  			f(s)
  		end
    end
  end
  local function partgen3(t, n, f, pad) -- generates sliding array partitions
    for i = 0, #t, 1 do
      local s = M.slice(t, i+1, i+n)
      if #s>0 and i+n<=#t then 
  			while (#s < n and pad) do s[#s+1] = pad end
  			f(s)
  		end
    end
  end
  local function permgen(t, n, f) -- taken from PiL: http://www.lua.org/pil/9.3.html
    if n == 0 then f(t) end
    for i = 1,n do
      t[n], t[i] = t[i], t[n]
      permgen(t, n-1, f)
      t[n], t[i] = t[i], t[n]
    end
  end
  local function signum(a) return a>=0 and 1 or -1 end
  -- Internal counter for unique ids generation
  local unique_id_counter = -1
  --- Operator functions
  -- @section Operator functions
  M.operator = {}
  --- Returns a + b. <em>Aliased as `op.add`</em>.
  -- @name operator.add
  -- @param a a value
  -- @param b a value
  -- @return a + b
  M.operator.add = function(a,b) return a + b end
  --- Returns a - b. <em>Aliased as `op.sub`</em>.
  -- @name operator.sub
  -- @param a a value
  -- @param b a value
  -- @return a - b
  M.operator.sub = function(a,b) return a - b end
  --- Returns a * b. <em>Aliased as `op.mul`</em>.
  -- @name operator.mul
  -- @param a a value
  -- @param b a value
  -- @return a * b
  M.operator.mul = function(a,b) return a * b end
  --- Returns a / b. <em>Aliased as `op.div`</em>.
  -- @name operator.div
  -- @param a a value
  -- @param b a value
  -- @return a / b
  M.operator.div = function(a,b) return a / b end
  --- Returns a % b. <em>Aliased as `op.mod`</em>.
  -- @name operator.mod
  -- @param a a value
  -- @param b a value
  -- @return a % b
  M.operator.mod = function(a,b) return a % b end
  --- Returns a ^ b. <em>Aliased as `op.exp`, `op.pow`</em>.
  -- @name operator.exp
  -- @param a a value
  -- @param b a value
  -- @return a ^ b
  M.operator.exp = function(a,b) return a ^ b end
  M.operator.pow = M.operator.exp
  --- Returns -a. <em>Aliased as `op.unm`, `op.neg`</em>.
  -- @name operator.unm
  -- @param a a value
  -- @return -a
  M.operator.unm = function(a) return -a end
  M.operator.neg = M.operator.unm
  --- Performs floor division (//) between `a` and `b`. It rounds the quotient towards minus infinity.
  -- <em>Aliased as `op.floordiv`</em>.
  -- @name operator.floordiv
  -- @param a a value
  -- @param b a value
  -- @return a // b
  M.operator.floordiv = function(a, b) return floor(a/b) end 
  --- Performs integer division between `a` and `b`. <em>Aliased as `op.intdiv`</em>.
  -- @name operator.intdiv
  -- @param a a value
  -- @param b a value
  -- @return a / b
  M.operator.intdiv = function(a,b)
    return a>=0 and floor(a/b) or ceil(a/b) 
  end
  --- Checks if a equals b. <em>Aliased as `op.eq`</em>.
  -- @name operator.eq
  -- @param a a value
  -- @param b a value
  -- @return a == b
  M.operator.eq = function(a,b) return a == b end
  --- Checks if a not equals b. <em>Aliased as `op.neq`</em>.
  -- @name operator.neq
  -- @param a a value
  -- @param b a value
  -- @return a ~= b
  M.operator.neq = function(a,b) return a ~= b end
  --- Checks if a is strictly less than b. <em>Aliased as `op.lt`</em>.
  -- @name operator.lt
  -- @param a a value
  -- @param b a value
  -- @return a < b
  M.operator.lt = function(a,b) return a < b end
  --- Checks if a is strictly greater than b. <em>Aliased as `op.gt`</em>.
  -- @name operator.gt
  -- @param a a value
  -- @param b a value
  -- @return a > b
  M.operator.gt = function(a,b) return a > b end
  --- Checks if a is less or equal to b. <em>Aliased as `op.le`</em>.
  -- @name operator.le
  -- @param a a value
  -- @param b a value
  -- @return a <= b
  M.operator.le = function(a,b) return a <= b end
  --- Checks if a is greater or equal to b. <em>Aliased as `op.ge`</em>.
  -- @name operator.ge
  -- @param a a value
  -- @param b a value
  -- @return a >= b
  M.operator.ge = function(a,b) return a >= b end
  --- Returns logical a and b. <em>Aliased as `op.land`</em>.
  -- @name operator.ge
  -- @param a a value
  -- @param b a value
  -- @return a and b
  M.operator.land = function(a,b) return a and b end
  --- Returns logical a or b. <em>Aliased as `op.lor`</em>.
  -- @name operator.lor
  -- @param a a value
  -- @param b a value
  -- @return a or b
  M.operator.lor = function(a,b) return a or b end
  --- Returns logical not a. <em>Aliased as `op.lnot`</em>.
  -- @name operator.lnot
  -- @param a a value
  -- @return not a
  M.operator.lnot = function(a) return not a end
  --- Returns concatenation of a and b. <em>Aliased as `op.concat`</em>.
  -- @name operator.concat
  -- @param a a value
  -- @param b a value
  -- @return a .. b
  M.operator.concat = function(a,b) return a..b end
  --- Returns the length of a. <em>Aliased as `op.len`</em>.
  -- @name operator.length
  -- @param a a value
  -- @return #a
  M.operator.length = function(a) return #a end
  M.operator.len = M.operator.length
  --- Table functions
  -- @section Table functions
  --- Clears a table. All its values become nil.
  -- @name clear
  -- @param t a table
  -- @return the given table, cleared.
  function M.clear(t)
  	for k in pairs(t) do t[k] = nil end
  	return t
  end
  --- Iterates on key-value pairs, calling `f (v, k)` at every step.
  -- <br/><em>Aliased as `forEach`</em>.
  -- @name each
  -- @param t a table
  -- @param f a function, prototyped as `f (v, k)`
  -- @see eachi
  function M.each(t, f)
    for index,value in pairs(t) do
      f(value, index)
    end
  end
  --- Iterates on integer key-value pairs, calling `f(v, k)` every step. 
  -- Only applies to values located at integer keys. The table can be a sparse array. 
  -- Iteration will start from the lowest integer key found to the highest one.
  -- <br/><em>Aliased as `forEachi`</em>.
  -- @name eachi
  -- @param t a table
  -- @param f a function, prototyped as `f (v, k)`
  -- @see each
  function M.eachi(t, f)
    local lkeys = M.sort(M.select(M.keys(t), M.isInteger))
    for k, key in ipairs(lkeys) do
      f(t[key], key)
    end
  end
  --- Collects values at given keys and return them wrapped in an array.
  -- @name at
  -- @param t a table
  -- @param ... A variable number of keys to collect values
  -- @return an array-list of values
  function M.at(t, ...)
    local values = {}
    for i, key in ipairs({...}) do values[#values+1] = t[key] end
    return values
  end
  --- Adjusts the value at a given key using a function or a value. In case `f` is a function, 
  -- it should be prototyped `f(v)`. It does not mutate the given table, but rather
  -- returns a new array. In case the given `key` does not exist in `t`, it throws an error.
  -- @param t a table
  -- @param key a key
  -- @param f a function, prototyped as `f(v)` or a value
  function M.adjust(t, key, f)
    if (t[key] == nil) then error("key not existing in table") end
    local _t = M.clone(t)
    _t[key] = type(f) == 'function' and f(_t[key]) or f
    return _t
  end
  --- Counts occurrences of a given value in a table. Uses @{isEqual} to compare values.
  -- @name count
  -- @param t a table
  -- @param[opt] val a value to be searched in the table. If not given, the @{size} of the table will be returned
  -- @return the count of occurrences of the given value
  -- @see countf
  -- @see size
  function M.count(t, val)
    if val == nil then return M.size(t) end
    local count = 0
    for k, v in pairs(t) do
      if M.isEqual(v, val) then count = count + 1 end
    end
    return count
  end
  --- Counts the number of values passing a predicate test. Same as @{count}, but uses an iterator. 
  -- Returns the count for values passing the test `f (v, k)`
  -- @name countf
  -- @param t a table
  -- @param f an iterator function, prototyped as `f (v, k)`
  -- @return the count of values validating the predicate
  -- @see count
  -- @see size
  function M.countf(t, f)
    local count = 0
    for k, v in pairs(t) do
      if f(v, k) then count = count + 1 end
    end
    return count
  end
  --- Checks if all values in a collection are equal. Uses an optional `comp` function which is used
  -- to compare values and defaults to @{isEqual} when not given.
  -- <br/><em>Aliased as `alleq`</em>.
  -- @name allEqual
  -- @param t a table
  -- @param[opt] comp a comparison function. Defaults to `isEqual`
  -- @return `true` when all values in `t` are equal, `false` otherwise.
  -- @see isEqual
  function M.allEqual(t, comp)
    local k, pivot = next(t)
    for k, v in pairs(t) do
      if comp then 
        if not comp(pivot, v) then return false end
      else
        if not M.isEqual(pivot, v) then return false end
      end
    end
    return true
  end
  --- Loops `n` times through a table. In case `n` is omitted, it will loop forever.
  -- In case `n` is lower or equal to 0, it returns an empty function.
  -- <br/><em>Aliased as `loop`</em>.
  -- @name cycle
  -- @param t a table
  -- @param[opt] n the number of loops
  -- @return an iterator function yielding value-key pairs from the passed-in table.
  function M.cycle(t, n)
    n = n or 1
    if n<=0 then return M.noop end
    local k, fk
    local i = 0
    while true do
      return function()
        k = k and next(t,k) or next(t)
        fk = not fk and k or fk
        if n then
          i = (k==fk) and i+1 or i
          if i > n then
            return
          end
        end
        return t[k], k
      end
    end
  end
  --- Maps `f (v, k)` on value-key pairs, collects and returns the results.
  -- <br/><em>Aliased as `collect`</em>.
  -- @name map
  -- @param t a table
  -- @param f  an iterator function, prototyped as `f (v, k)`
  -- @return a table of results
  function M.map(t, f)
    local _t = {}
    for index,value in pairs(t) do
      local k, kv, v = index, f(value, index)
      _t[v and kv or k] = v or kv
    end
    return _t
  end
  --- Reduces a table, left-to-right. Folds the table from the first element to the last element
  -- to a single value, using a given iterator and an initial state.
  -- The iterator takes a state and a value and returns a new state.
  -- <br/><em>Aliased as `inject`, `foldl`</em>.
  -- @name reduce
  -- @param t a table
  -- @param f an iterator function, prototyped as `f (state, value)`
  -- @param[opt] state an initial state of reduction. Defaults to the first value in the table.
  -- @return the final state of reduction
  -- @see best
  -- @see reduceRight
  -- @see reduceBy
  function M.reduce(t, f, state)
    for k,value in pairs(t) do
      if state == nil then state = value
      else state = f(state,value)
      end
    end
    return state
  end
  --- Returns the best value passing a selector function. Acts as a special case of
  -- @{reduce}, using the first value in `t` as an initial state. It thens folds the given table,
  -- testing each of its values `v` and selecting the value passing the call `f(state,v)` every time.
  -- @name best
  -- @param t a table
  -- @param f an iterator function, prototyped as `f (state, value)`
  -- @return the final state of reduction
  -- @see reduce
  -- @see reduceRight
  -- @see reduceBy
  function M.best(t, f)
    local _, state = next(t)
    for k,value in pairs(t) do
      if state == nil then state = value
      else state = f(state,value) and state or value
      end
    end
    return state
  end
  --- Reduces values in a table passing a given predicate. Folds the table left-to-right, considering
  -- only values validating a given predicate.
  -- @name reduceBy
  -- @param t a table
  -- @param f an iterator function, prototyped as `f (state, value)`
  -- @param pred a predicate function `pred (v, k)` to select values to be considered for reduction
  -- @param[opt] state an initial state of reduction. Defaults to the first value in the table of selected values.
  -- @param[optchain] ... optional args to be passed to `pred`
  -- @return the final state of reduction
  -- @see reduce
  -- @see best
  -- @see reduceRight
  function M.reduceBy(t, f, pred, state)
  	return M.reduce(M.select(t, pred), f, state)
  end
  --- Reduces a table, right-to-left. Folds the table from the last element to the first element 
  -- to single value, using a given iterator and an initial state.
  -- The iterator takes a state and a value, and returns a new state.
  -- <br/><em>Aliased as `injectr`, `foldr`</em>.
  -- @name reduceRight
  -- @param t a table
  -- @param f an iterator function, prototyped as `f (state, value)`
  -- @param[opt] state an initial state of reduction. Defaults to the last value in the table.
  -- @return the final state of reduction
  -- @see reduce
  -- @see best
  -- @see reduceBy
  function M.reduceRight(t, f, state)
    return M.reduce(M.reverse(t),f,state)
  end
  --- Reduces a table while saving intermediate states. Folds the table left-to-right
  -- using a given iterator and an initial state. The iterator takes a state and a value, 
  -- and returns a new state. The result is an array of intermediate states.
  -- <br/><em>Aliased as `mapr`</em>
  -- @name mapReduce
  -- @param t a table
  -- @param f an iterator function, prototyped as `f (state, value)`
  -- @param[opt] state an initial state of reduction. Defaults to the first value in the table.
  -- @return an array of states
  -- @see mapReduceRight
  function M.mapReduce(t, f, state)
    local _t = {}
    for i,value in pairs(t) do
      _t[i] = not state and value or f(state,value)
      state = _t[i]
    end
    return _t
  end
  --- Reduces a table while saving intermediate states. Folds the table right-to-left
  -- using a given iterator and an initial state. The iterator takes a state and a value, 
  -- and returns a new state. The result is an array of intermediate states.
  -- <br/><em>Aliased as `maprr`</em>
  -- @name mapReduceRight
  -- @param t a table
  -- @param f an iterator function, prototyped as `f (state, value)`
  -- @param[opt] state an initial state of reduction. Defaults to the last value in the table.
  -- @return an array of states
  -- @see mapReduce
  function M.mapReduceRight(t, f, state)
    return M.mapReduce(M.reverse(t),f,state)
  end
  --- Performs a linear search for a value in a table. It does not work for nested tables.
  -- The given value can be a function prototyped as `f (v, value)` which should return true when
  -- any v in the table equals the value being searched. 
  -- <br/><em>Aliased as `any`, `some`, `contains`</em>
  -- @name include
  -- @param t a table
  -- @param value a value to search for
  -- @return a boolean : `true` when found, `false` otherwise
  -- @see detect
  function M.include(t, value)
    local _iter = (type(value) == 'function') and value or M.isEqual
    for k,v in pairs(t) do
      if _iter(v,value) then return true end
    end
    return false
  end
  --- Performs a linear search for a value in a table. Returns the key of the value if found.
  -- The given value can be a function prototyped as `f (v, value)` which should return true when
  -- any v in the table equals the value being searched. This function is similar to @{find}, 
  -- which is mostly meant to work with array.
  -- @name detect
  -- @param t a table
  -- @param value a value to search for
  -- @return the key of the value when found or __nil__
  -- @see include
  -- @see find
  function M.detect(t, value)
    local _iter = (type(value) == 'function') and value or M.isEqual
    for key,arg in pairs(t) do
      if _iter(arg,value) then return key end
    end
  end
  --- Returns all values having specified keys `props`.
  -- @name where
  -- @param t a table
  -- @param props a set of keys
  -- @return an array of values from the passed-in table
  -- @see findWhere
  function M.where(t, props)
  	local r = M.select(t, function(v)
  		for key in pairs(props) do
  			if v[key] ~= props[key] then return false end
  		end
  		return true
  	end)
  	return #r > 0 and r or nil
  end
  --- Returns the first value having specified keys `props`.
  -- @name findWhere
  -- @param t a table
  -- @param props a set of keys
  -- @return a value from the passed-in table
  -- @see where
  function M.findWhere(t, props)
    local index = M.detect(t, function(v)
      for key in pairs(props) do
        if props[key] ~= v[key] then return false end
      end
      return true
    end)
    return index and t[index]
  end
  --- Selects and returns values passing an iterator test.
  -- <br/><em>Aliased as `filter`</em>.
  -- @name select
  -- @param t a table
  -- @param f an iterator function, prototyped as `f (v, k)`
  -- @return the selected values
  -- @see reject
  function M.select(t, f)
    local _t = {}
    for index,value in pairs(t) do
      if f(value,index) then _t[#_t+1] = value end
    end
    return _t
  end
  --- Clones a table while dropping values passing an iterator test.
  -- <br/><em>Aliased as `discard`</em>
  -- @name reject
  -- @param t a table
  -- @param f an iterator function, prototyped as `f (v, k)`
  -- @return the remaining values
  -- @see select
  function M.reject(t, f)
    local _t = {}
    for index,value in pairs (t) do
      if not f(value,index) then _t[#_t+1] = value end
    end
    return _t
  end
  --- Checks if all values in a table are passing an iterator test.
  -- <br/><em>Aliased as `every`</em>
  -- @name all
  -- @param t a table
  -- @param f an iterator function, prototyped as `f (v, k)`
  -- @return `true` if all values passes the predicate, `false` otherwise
  function M.all(t, f)
    for index,value in pairs(t) do
      if not f(value,index) then return false end
    end
    return true
  end
  --- Invokes a method on each value in a table.
  -- @name invoke
  -- @param t a table
  -- @param method a function, prototyped as `f (v, k)`
  -- @return the result of the call `f (v, k)`
  -- @see pluck
  function M.invoke(t, method)
    return M.map(t, function(v, k)
      if (type(v) == 'table') then
        if v[method] then
          if M.isCallable(v[method]) then
            return v[method](v,k)
          else
            return v[method]
          end
        else
          if M.isCallable(method) then
            return method(v,k)
          end
        end
      elseif M.isCallable(method) then
        return method(v,k)
      end
    end)
  end
  --- Extracts values in a table having a given key.
  -- @name pluck
  -- @param t a table
  -- @param key a key, will be used to index in each value: `value[key]`
  -- @return an array of values having the given key
  function M.pluck(t, key)
    local _t = {}
    for k, v in pairs(t) do
      if v[key] then _t[#_t+1] = v[key] end
    end
    return _t
  end
  --- Returns the max value in a collection. If a `transform` function is passed, it will
  -- be used to evaluate values by which all objects will be sorted.
  -- @name max
  -- @param t a table
  -- @param[opt] transform a transformation function, prototyped as `transform (v, k)`, defaults to @{identity}
  -- @return the max value found
  -- @see min
  function M.max(t, transform)
    return extract(t, f_max, transform)
  end
  --- Returns the min value in a collection. If a `transform` function is passed, it will
  -- be used to evaluate values by which all objects will be sorted.
  -- @name min
  -- @param t a table
  -- @param[opt] transform a transformation function, prototyped as `transform (v, k)`, defaults to @{identity}
  -- @return the min value found
  -- @see max
  function M.min(t, transform)
    return extract(t, f_min, transform)
  end
  --- Checks if two tables are the same. It compares if both tables features the same values,
  -- but not necessarily at the same keys.
  -- @name same
  -- @param a a table
  -- @param b another table
  -- @return `true` or `false`
  function M.same(a, b)
    return M.all(a, function(v) return M.include(b,v) end) 
       and M.all(b, function(v) return M.include(a,v) end)
  end
  --- Sorts a table, in-place. If a comparison function is given, it will be used to sort values.
  -- @name sort
  -- @param t a table
  -- @param[opt] comp a comparison function prototyped as `comp (a, b)`, defaults to <tt><</tt> operator.
  -- @return the given table, sorted.
  -- @see sortBy
  function M.sort(t, comp)
    t_sort(t, comp)
    return t
  end
  --- Iterates on values with respect to key order. Keys are sorted using `comp` function
  -- which defaults to `math.min`. It returns upon each call a `key, value` pair.
  -- @name sortedk
  -- @param t a table 
  -- @param[opt] comp a comparison function. Defaults to `<` operator
  -- @return an iterator function 
  -- @see sortedv 
  function M.sortedk(t, comp)
    local keys = M.keys(t)
    t_sort(keys, comp)
    local i = 0
    return function ()
      i = i + 1
      return keys[i], t[keys[i]]
    end
  end
  --- Iterates on values with respect to values order. Values are sorted using `comp` function
  -- which defaults to `math.min`. It returns upon each call a `key, value` pair.
  -- @name sortedv
  -- @param t a table 
  -- @param[opt] comp a comparison function. Defaults to `<` operator
  -- @return an iterator function 
  -- @see sortedk
  function M.sortedv(t, comp)
    local keys = M.keys(t)
    comp = comp or f_min
    t_sort(keys, function(a,b) return comp(t[a],t[b]) end)
    local i = 0
    return function ()
      i = i + 1
      return keys[i], t[keys[i]]
    end
  end
  --- Sorts a table in-place using a transform. Values are ranked in a custom order of the results of
  -- running `transform (v)` on all values. `transform` may also be a string name property  sort by. 
  -- `comp` is a comparison function.
  -- @name sortBy
  -- @param t a table
  -- @param[opt] transform a `transform` function to sort elements prototyped as `transform (v)`. Defaults to @{identity}
  -- @param[optchain] comp a comparison function, defaults to the `<` operator
  -- @return a new array of sorted values
  -- @see sort
  function M.sortBy(t, transform, comp)
  	local f = transform or M.identity
  	if (type(transform) == 'string') then
  		f = function(t) return t[transform] end
  	end
  	comp = comp or f_min	
  	t_sort(t, function(a,b) return comp(f(a), f(b)) end)
  	return t
  end
  --- Splits a table into subsets groups.
  -- @name groupBy
  -- @param t a table
  -- @param iter an iterator function, prototyped as `iter (v, k)`
  -- @return a table of subsets groups
  function M.groupBy(t, iter)
    local _t = {}
    for k,v in pairs(t) do
      local _key = iter(v,k)
      if _t[_key] then _t[_key][#_t[_key]+1] = v
      else _t[_key] = {v}
      end
    end
    return _t
  end
  --- Groups values in a collection and counts them.
  -- @name countBy
  -- @param t a table
  -- @param iter an iterator function, prototyped as `iter (v, k)`
  -- @return a table of subsets groups names paired with their count
  function M.countBy(t, iter)
    local stats = {}
    for i,v in pairs(t) do
      local key = iter(v,i)
      stats[key] = (stats[key] or 0)+1
    end
    return stats
  end
  --- Counts the number of values in a collection. If being passed more than one argument
  -- it will return the count of all passed-in arguments.
  -- @name size
  -- @param[opt] ... Optional variable number of arguments
  -- @return a count
  -- @see count
  -- @see countf
  function M.size(...)
    local args = {...}
    local arg1 = args[1]
    return (type(arg1) == 'table') and count(args[1]) or count(args)
  end
  --- Checks if all the keys of `other` table exists in table `t`. It does not
  -- compares values. The test is not commutative, i.e table `t` may contains keys
  -- not existing in `other`.
  -- @name containsKeys
  -- @param t a table
  -- @param other another table
  -- @return `true` or `false`
  -- @see sameKeys
  function M.containsKeys(t, other)
    for key in pairs(other) do
      if not t[key] then return false end
    end
    return true
  end
  --- Checks if both given tables have the same keys. It does not compares values.
  -- @name sameKeys
  -- @param tA a table
  -- @param tB another table
  -- @return `true` or `false`
  -- @see containsKeys
  function M.sameKeys(tA, tB)
    for key in pairs(tA) do
      if not tB[key] then return false end
    end
    for key in pairs(tB) do
      if not tA[key] then return false end
    end
    return true
  end
  --- Array functions
  -- @section Array functions
  --- Samples `n` random values from an array. If `n` is not specified, returns a single element.
  -- It uses internally @{shuffle} to shuffle the array before sampling values. If `seed` is passed,
  -- it will be used for shuffling.
  -- @name sample
  -- @param array an array
  -- @param[opt] n a number of elements to be sampled. Defaults to 1.
  -- @param[optchain] seed an optional seed for shuffling 
  -- @return an array of selected values
  -- @see sampleProb
  function M.sample(array, n, seed)
    n = n or 1    
    if n == 0 then return {} end
  	if n == 1 then
  		if seed then randomseed(seed) end
  		return {array[random(1, #array)]}
  	end
  	return M.slice(M.shuffle(array, seed), 1, n)
  end
  --- Return elements from a sequence with a given probability. It considers each value independently. 
  -- Providing a seed will result in deterministic sampling. Given the same seed it will return the same sample
  -- every time.
  -- @name sampleProb
  -- @param array an array
  -- @param prob a probability for each element in array to be selected
  -- @param[opt] seed an optional seed for deterministic sampling
  -- @return an array of selected values
  -- @see sample
  function M.sampleProb(array, prob, seed)
  	if seed then randomseed(seed) end
    local t = {}
    for k, v in ipairs(array) do
      if random() < prob then t[#t+1] = v end
    end
  	return t
  end
  --- Returns the n-top values satisfying a predicate. It takes a comparison function
  -- `comp` used to sort array values, and then picks the top n-values. It leaves the original array untouched.
  -- @name nsorted
  -- @param array an array
  -- @param[opt] n a number of values to retrieve. Defaults to 1.
  -- @param[optchain] comp a comparison function. Defaults to `<` operator.
  -- @return an array of top n values
  function M.nsorted(array, n, comp)
    comp = comp or f_min
    n = n or 1
    local values, count = {}, 0
    for k, v in M.sortedv(array, comp) do
      if count < n then
        count = count + 1
        values[count] = v
      end
    end
    return values
  end
  --- Returns a shuffled copy of a given array. If a seed is provided, it will
  -- be used to init the built-in pseudo random number generator (using `math.randomseed`).
  -- @name shuffle
  -- @param array an array
  -- @param[opt] seed a seed
  -- @return a shuffled copy of the given array
  function M.shuffle(array, seed)
    if seed then randomseed(seed) end
    local _shuffled = {}
    for index, value in ipairs(array) do
      local randPos = floor(random()*index)+1
      _shuffled[index] = _shuffled[randPos]
      _shuffled[randPos] = value
    end
    return _shuffled
  end
  --- Converts a list of arguments to an array.
  -- @name pack
  -- @param ... a list of arguments
  -- @return an array of all passed-in args
  function M.pack(...) return {...} end
  --- Looks for the first occurrence of a given value in an array. Returns the value index if found.
  -- Uses @{isEqual} to compare values.
  -- @name find
  -- @param array an array of values
  -- @param value a value to lookup for
  -- @param[opt] from the index from where the search will start. Defaults to 1.
  -- @return the index of the value if found in the array, `nil` otherwise.
  -- @see detect
  function M.find(array, value, from)
    for i = from or 1, #array do
      if M.isEqual(array[i], value) then return i end
    end
  end
  --- Returns an array where values are in reverse order. The passed-in array should not be sparse.
  -- @name reverse
  -- @param array an array
  -- @return a reversed array
  function M.reverse(array)
    local _array = {}
    for i = #array,1,-1 do
      _array[#_array+1] = array[i]
    end
    return _array
  end
  --- Replaces elements in a given array with a given value. In case `i` and `j` are given
  -- it will only replaces values at indexes between `[i,j]`. In case `j` is greater than the array
  -- size, it will append new values, increasing the array size.
  -- @name fill
  -- @param array an array
  -- @param value a value
  -- @param[opt] i the index from which to start replacing values. Defaults to 1.
  -- @param[optchain] j the index where to stop replacing values. Defaults to the array size.
  -- @return the original array with values changed
  function M.fill(array, value, i, j)
  	j = j or M.size(array)
  	for i = i or 1, j do array[i] = value end
  	return array
  end
  --- Returns an array of `n` zeros.
  -- @name zeros
  -- @param n a number
  -- @return an array
  -- @see ones
  -- @see vector
  function M.zeros(n) return M.fill({}, 0, 1, n) end
  --- Returns an array of `n` 1's.
  -- @name ones
  -- @param n a number
  -- @return an array
  -- @see zeros
  -- @see vector
  function M.ones(n) return M.fill({}, 1, 1, n) end
  --- Returns an array of `n` times a given value.
  -- @name vector
  -- @param value a value
  -- @param n a number
  -- @return an array
  -- @see zeros
  -- @see ones
  function M.vector(value, n) return M.fill({}, value, 1, n) end
  --- Collects values from a given array. The passed-in array should not be sparse.
  -- This function collects values as long as they satisfy a given predicate and returns on the first falsy test.
  -- <br/><em>Aliased as `takeWhile`</em>
  -- @name selectWhile
  -- @param array an array
  -- @param f an iterator function prototyped as `f (v, k)`
  -- @return a new table containing all values collected
  -- @see dropWhile
  function M.selectWhile(array, f)
    local t = {}
    for i,v in ipairs(array) do
      if f(v,i) then t[i] = v else break end
    end
    return t
  end
  --- Collects values from a given array. The passed-in array should not be sparse.
  -- This function collects values as long as they do not satisfy a given predicate and returns on the first truthy test.
  -- <br/><em>Aliased as `rejectWhile`</em>
  -- @name dropWhile
  -- @param array an array
  -- @param f an iterator function prototyped as `f (v, k)`
  -- @return a new table containing all values collected
  -- @see selectWhile
  function M.dropWhile(array, f)
    local _i
    for i,v in ipairs(array) do
      if not f(v, i) then
        _i = i
        break
      end
    end
    if (_i == nil) then return {} end
    return M.rest(array,_i)
  end
  --- Returns the index at which a value should be inserted. This index is evaluated so 
  -- that it maintains the sort. If a comparison function is passed, it will be used to sort
  -- values.
  -- @name sortedIndex
  -- @param array an array
  -- @param the value to be inserted
  -- @param[opt] comp an comparison function prototyped as `f (a, b)`, defaults to <tt><</tt> operator.
  -- @param[optchain] sort whether or not the passed-in array should be sorted
  -- @return number the index at which the passed-in value should be inserted
  function M.sortedIndex(array, value, comp, sort)
    local _comp = comp or f_min
    if (sort == true) then t_sort(array,_comp) end
    for i = 1,#array do
      if not _comp(array[i],value) then return i end
    end
    return #array+1
  end
  --- Returns the index of the first occurrence of value in an array.
  -- @name indexOf
  -- @param array an array
  -- @param value the value to search for
  -- @return the index of the passed-in value
  -- @see lastIndexOf
  function M.indexOf(array, value)
    for k = 1,#array do
      if array[k] == value then return k end
    end
  end
  --- Returns the index of the last occurrence of value in an array.
  -- @name lastIndexOf
  -- @param array an array
  -- @param value the value to search for
  -- @return the index of the last occurrence of the passed-in value or __nil__
  -- @see indexOf
  function M.lastIndexOf(array, value)
    local key = M.indexOf(M.reverse(array),value)
    if key then return #array-key+1 end
  end
  --- Returns the first index at which a predicate returns true.
  -- @name findIndex
  -- @param array an array
  -- @param pred a predicate function prototyped as `pred (v, k)`
  -- @return the index found or __nil__
  -- @see findLastIndex
  function M.findIndex(array, pred)
  	for k = 1, #array do
  		if pred(array[k],k) then return k end
  	end
  end
  --- Returns the last index at which a predicate returns true.
  -- @name findLastIndex
  -- @param array an array
  -- @param pred a predicate function prototyped as `pred (k, v)`
  -- @return the index found or __nil__
  -- @see findIndex
  function M.findLastIndex(array, pred)
    local key = M.findIndex(M.reverse(array),pred)
    if key then return #array-key+1 end
  end
  --- Adds all passed-in values at the top of an array. The last elements will bubble to the
  -- top of the given array.
  -- @name addTop
  -- @param array an array
  -- @param ... a variable number of arguments
  -- @return the passed-in array with new values added
  -- @see prepend
  -- @see push
  function M.addTop(array, ...)
    for k,v in ipairs({...}) do
      t_insert(array,1,v)
    end
    return array
  end
  --- Adds all passed-in values at the top of an array. As opposed to @{addTop}, it preserves the order
  -- of the passed-in elements.
  -- @name prepend
  -- @param array an array
  -- @param ... a variable number of arguments
  -- @return the passed-in array with new values added
  -- @see addTop
  -- @see push
  function M.prepend(array, ...)
    return M.append({...}, array)
  end
  --- Pushes all passed-in values at the end of an array.
  -- @name push
  -- @param array an array
  -- @param ... a variable number of arguments
  -- @return the passed-in array with new added values
  -- @see addTop
  -- @see prepend
  function M.push(array, ...)
    local args = {...}
    for k,v in ipairs({...}) do
      array[#array+1] = v
    end
    return array
  end
  --- Removes and returns the values at the top of a given array.
  -- <br/><em>Aliased as `pop`</em>
  -- @name shift
  -- @param array an array
  -- @param[opt] n the number of values to be popped. Defaults to 1.
  -- @return the popped values
  -- @see unshift
  function M.shift(array, n)
    n = min(n or 1, #array)
    local ret = {}
    for i = 1, n do 
      local retValue = array[1]
      ret[#ret + 1] = retValue
      t_remove(array,1)
    end
    return unpack(ret)
  end
  --- Removes and returns the values at the end of a given array.
  -- @name unshift
  -- @param array an array
  -- @param[opt] n the number of values to be unshifted. Defaults to 1.
  -- @return the values
  -- @see shift
  function M.unshift(array, n)
    n = min(n or 1, #array)
    local ret = {}
    for i = 1, n do
      local retValue = array[#array]
      ret[#ret + 1] = retValue
      t_remove(array)
    end
    return unpack(ret)
  end
  --- Removes all provided values in a given array.
  -- <br/><em>Aliased as `remove`</em>
  -- @name pull
  -- @param array an array
  -- @param ... a variable number of values to be removed from the array
  -- @return the passed-in array with values removed
  function M.pull(array, ...)
    local values = {...}
    for i = #array, 1, -1 do
      local remval = false
      for k, rmValue in ipairs(values) do
        if (remval == false) then
          if M.isEqual(array[i], rmValue) then
            t_remove(array, i)
            remval = true
          end
        end
      end
    end
    return array
  end
  --- Removes values at an index within the range `[start, finish]`.
  -- <br/><em>Aliased as `rmRange`, `chop`</em>
  -- @name removeRange
  -- @param array an array
  -- @param[opt] start the lower bound index, defaults to the first index in the array.
  -- @param[optchain] finish the upper bound index, defaults to the array length.
  -- @return the passed-in array with values removed
  function M.removeRange(array, start, finish)
    start = start or 1
    finish = finish or #array
    if start > finish then 
      error("start cannot be greater than finish.")
    end  
    for i = finish, start, -1 do
      t_remove(array, i)
    end
    return array
  end
  --- Chunks together consecutive values. Values are chunked on the basis of the return
  -- value of a provided predicate `f (v, k)`. Consecutive elements which return 
  -- the same value are chunked together. Leaves the first argument untouched if it is not an array.
  -- @name chunk
  -- @param array an array
  -- @param f an iterator function prototyped as `f (v, k)`
  -- @return a table of chunks (arrays)
  -- @see zip
  function M.chunk(array, f)
    local ch, ck, prev, val = {}, 0
    for k,v in ipairs(array) do
      val = f(v, k)
      prev = (prev==nil) and val or prev
      ck = ((val~=prev) and (ck+1) or ck)
      if not ch[ck] then
        ch[ck] = {array[k]}
      else
        ch[ck][#ch[ck]+1] = array[k]
      end
      prev = val
    end
    return ch
  end
  --- Slices values indexed within `[start, finish]` range.
  -- <br/><em>Aliased as `M.sub`</em>
  -- @name slice
  -- @param array an array
  -- @param[opt] start the lower bound index, defaults to the first index in the array.
  -- @param[optchain] finish the upper bound index, defaults to the array length.
  -- @return a new array of sliced values
  function M.slice(array, start, finish)
    local t = {}
    for k = start or 1, finish or #array do
      t[#t+1] = array[k]
    end
    return t
  end
  --- Returns the first N values in an array.
  -- <br/><em>Aliased as `head`, `take` </em>
  -- @name first
  -- @param array an array
  -- @param[opt] n the number of values to be collected, defaults to 1.
  -- @return a new array
  -- @see initial
  -- @see last
  -- @see rest
  function M.first(array, n)
    n = n or 1
    local t = {}
    for k = 1, n do
      t[k] = array[k]
    end
    return t
  end
  --- Returns all values in an array excluding the last N values.
  -- @name initial
  -- @param array an array
  -- @param[opt] n the number of values to be left, defaults to the array length.
  -- @return a new array
  -- @see first
  -- @see last
  -- @see rest
  function M.initial(array, n)
    local l = #array
    n = n and l-(min(n,l)) or l-1
    local t = {}
    for k = 1, n do
      t[k] = array[k]
    end
    return t
  end
  --- Returns the last N values in an array.
  -- @name last
  -- @param array an array
  -- @param[opt] n the number of values to be collected, defaults to the array length.
  -- @return a new array
  -- @see first
  -- @see initial
  -- @see rest
  function M.last(array, n)
    local l = #array
    n = n and l-min(n-1,l-1) or 2 
    local t = {}
    for k = n, l do
      t[#t+1] = array[k]
    end
    return t
  end
  --- Returns all values after index.
  -- <br/><em>Aliased as `tail`</em>
  -- @name rest
  -- @param array an array
  -- @param[opt] index an index, defaults to 1
  -- @return a new array
  -- @see first
  -- @see initial
  -- @see last
  function M.rest(array, index)
    local t = {}
    for k = index or 1, #array do
      t[#t+1] = array[k]
    end
    return t
  end
  --- Returns the value at a given index.
  -- @name nth
  -- @param array an array
  -- @param index an index
  -- @return the value at the given index
  function M.nth(array, index)
    return array[index]
  end
  --- Returns all truthy values (removes `falses` and `nils`).
  -- @name compact
  -- @param array an array
  -- @return a new array
  function M.compact(array)
    local t = {}
    for k,v in pairs(array) do
      if v then t[#t+1] = v end
    end
    return t
  end
  --- Flattens a nested array. Passing `shallow` will only flatten at the first level.
  -- @name flatten
  -- @param array an array
  -- @param[opt] shallow specifies the flattening depth. Defaults to `false`.`
  -- @return a flattened array
  function M.flatten(array, shallow)
    shallow = shallow or false
    local new_flattened
    local _flat = {}
    for key,value in ipairs(array) do
      if type(value) == 'table' then
        new_flattened = shallow and value or M.flatten (value)
        for k,item in ipairs(new_flattened) do _flat[#_flat+1] = item end
      else _flat[#_flat+1] = value
      end
    end
    return _flat
  end
  --- Returns values from an array not present in all passed-in args.
  -- <br/><em>Aliased as `without` and `diff`</em>
  -- @name difference
  -- @param array an array
  -- @param another array
  -- @return a new array
  -- @see union
  -- @see intersection
  -- @see symmetricDifference
  function M.difference(array, array2)
    if not array2 then return M.clone(array) end
    return M.select(array,function(value)
      return not M.include(array2,value)
    end)
  end
  --- Returns the duplicate-free union of all passed in arrays.
  -- @name union
  -- @param ... a variable number of arrays arguments
  -- @return a new array
  -- @see difference
  -- @see intersection
  -- @see symmetricDifference
  function M.union(...)
    return M.unique(M.flatten({...}))
  end
  --- Returns the  intersection of all passed-in arrays.
  -- Each value in the result is present in each of the passed-in arrays.
  -- @name intersection
  -- @param ... a variable number of array arguments
  -- @return a new array
  -- @see difference
  -- @see union
  -- @see symmetricDifference
  function M.intersection(...)
    local arg = {...}
    local array = arg[1]
    t_remove(arg, 1)
    local _intersect = {}
    for i,value in ipairs(array) do
      if M.all(arg,function(v) return M.include(v,value) end) then
        _intersect[#_intersect+1] = value
      end
    end
    return _intersect
  end
  --- Checks if all passed in arrays are disjunct.
  -- @name disjoint
  -- @param ... a variable number of arrays
  -- @return `true` if the intersection of all arrays is not empty, `false` otherwise.
  -- @see intersection
  function M.disjoint(...)
    return (#M.intersection(...) == 0)
  end
  --- Performs a symmetric difference. Returns values from `array` not present in `array2` and also values
  -- from `array2` not present in `array`.
  -- <br/><em>Aliased as `symdiff`</em>
  -- @name symmetricDifference
  -- @param array an array
  -- @param array2 another array
  -- @return a new array
  -- @see difference
  -- @see union
  -- @see intersection
  function M.symmetricDifference(array, array2)
    return M.difference(
      M.union(array, array2),
      M.intersection(array,array2)
    )
  end
  --- Produces a duplicate-free version of a given array.
  -- <br/><em>Aliased as `uniq`</em>
  -- @name unique
  -- @param array an array
  -- @return a new array, duplicate-free
  -- @see isunique
  -- @see duplicates
  function M.unique(array)
    local ret = {}
    for i = 1, #array do
      if not M.find(ret, array[i]) then
        ret[#ret+1] = array[i]
      end
    end
    return ret
  end
  --- Checks if a given array contains distinct values. Such an array is made of distinct elements,
  -- which only occur once in this array.
  -- <br/><em>Aliased as `isuniq`</em>
  -- @name isunique
  -- @param array an array
  -- @return `true` if the given array is unique, `false` otherwise.
  -- @see unique
  -- @see duplicates
  function M.isunique(array)
    return #array == #(M.unique(array))
  end
  --- Returns an array list of all duplicates in array.
  -- @name duplicates
  -- @param array an array
  -- @return an array-list of duplicates
  -- @see unique
  function M.duplicates(array)
    local dict = M.invert(array)
    local dups = {}
    for k, v in ipairs(array) do
      if dict[v] ~= k and not M.find(dups, v) then
        dups[#dups+1] = v
      end
    end
    return dups
  end
  --- Merges values of each of the passed-in arrays in subsets.
  -- Only values indexed with the same key in the given arrays are merged in the same subset.
  -- <br/><em>Aliased as `transpose`</em>
  -- @name zip
  -- @param ... a variable number of array arguments
  -- @return a new array
  -- @see zipWith
  function M.zip(...)
    local args = {...}
    local n = M.max(args, function(array) return #array end)
    local _ans = {}
    for i = 1,n do
      if not _ans[i] then _ans[i] = {} end    
      for k, array in ipairs(args) do
        if (array[i]~= nil) then _ans[i][#_ans[i]+1] = array[i] end
      end
    end
    return _ans
  end
  --- Merges values using a given function.
  -- Only values indexed with the same key in the given arrays are merged in the same subset.
  -- Function `f` is used to combine values.
  -- <br/><em>Aliased as `transposeWith`</em>
  -- @name zipWith
  -- @param f a function
  -- @param ... a variable number of array arguments
  -- @return a flat array of results
  -- @see zip
  function M.zipWith(f, ...)
    local args = {...}
    local n = M.max(args, function(array) return #array end)
    local _ans = {}
    for i = 1,n do    
      _ans[i] = f(unpack(M.pluck(args,i)))
    end
    return _ans
  end
  --- Clones array and appends values from another array.
  -- @name append
  -- @param array an array
  -- @param other an array
  -- @return a new array
  function M.append(array, other)
    local t = {}
    for i,v in ipairs(array) do t[i] = v end
    for i,v in ipairs(other) do t[#t+1] = v end
    return t
  end
  --- Interleaves arrays. It returns a single array made of values from all
  -- passed in arrays in their given order, interleaved.
  -- @name interleave
  -- @param ... a variable list of arrays
  -- @return a new array
  -- @see interpose
  function M.interleave(...) 
    local args = {...}
    local n = M.max(args, M.size)
    local t = {}
    for i = 1, n do  
      for k, array in ipairs(args) do
        if array[i] then t[#t+1] = array[i] end
      end
    end
    return t
  end
  --- Interposes value in-between consecutive pair of values in array.
  -- <br/><em>Aliased as `intersperse`</em>
  -- @name interpose
  -- @param array an array
  -- @param value a value
  -- @return a new array
  -- @see interleave
  function M.interpose(array, value)
    for k = #array, 2,-1 do
      t_insert(array, k, value)
    end
    return array
  end
  --- Produces a flexible list of numbers. If one value is passed, will count from 1 to that value,
  -- with a default step of 1 (or -1). If two values are passed, will count from the first one to the second one,
  -- using a default step of 1 (or -1). A third value passed will be considered a step value.
  -- @name range
  -- @param[opt] from the initial value of the range
  -- @param[optchain] to the final value of the range
  -- @param[optchain] step the step of count. Defaults to 1 or -1.
  -- @return a new array of numbers
  function M.range(from, to, step)
    if (from == nil) and (to == nil) and (step ==nil) then
      return {}
    elseif (from ~= nil) and (to == nil) and (step == nil) then
      from, to, step = signum(from), from, signum(from)
    elseif (from ~= nil) and (to ~= nil) and (step == nil) then
      step = signum(to - from)
    end
    local _ranged = {from}
    local steps = max(floor((to-from)/step),0)
    for i=1,steps do _ranged[#_ranged+1] = from+step*i end
    return _ranged
  end
  --- Creates an array list of `n` values, repeated.
  -- @name rep
  -- @param value a value to be repeated
  -- @param n the number of repetitions of value.
  -- @return a new array of `n` values
  function M.rep(value, n)
    local ret = {}
    for i = 1, n do ret[i] = value end
    return ret
  end
  --- Returns the powerset of array values. For instance, when given the set {1,2,3},
  -- returns `{{1},{2},{3},{1,2},{2,3},{1,2,3}}`.
  -- @name powerset
  -- @param array an array
  -- @return an array
  function M.powerset(array)
    local n = #array
    if n == 0 then return {{}} end
    local t = {}
    for l = 1, n do  
      for s = 1, n-l+1 do
        t[#t+1] = M.slice(array,s,s+l-1)
      end
    end
    return t
  end
  --- Iterator returning partitions of an array. It returns arrays of length `n` 
  -- made of values from the given array. If the last partition has lower elements than `n` and 
  -- `pad` is supplied, it will be adjusted to `n` of elements with `pad` value.
  -- @name partition
  -- @param array an array
  -- @param[opt] n the size of partitions. Defaults to 1.
  -- @param[optchain] pads a value to adjust the last subsequence to the `n` elements
  -- @return an iterator function
  -- @see overlapping
  -- @see aperture
  function M.partition(array, n, pad)
  	if n<=0 then return end
    return wrap(function()
      partgen(array, n or 1, yield, pad)
    end)
  end
  --- Iterator returning overlapping partitions of an array. 
  -- If the last subsequence has lower elements than `n` and `pad` is 
  -- supplied, it will be adjusted to `n` elements with `pad` value.
  -- @name overlapping
  -- @param array an array
  -- @param[opt] n the size of partitions. Defaults to 2.
  -- @param[optchain] pads a value to adjust the last subsequence to the `n` elements
  -- @return an iterator function
  -- @see partition
  -- @see aperture
  function M.overlapping(array, n, pad)
  	if n<=1 then return end
    return wrap(function()
      partgen2(array, n or 2, yield, pad)
    end)
  end
  --- Iterator returning sliding partitions of an array.
  -- <br/><em>Aliased as `sliding`</em>
  -- @name aperture
  -- @param array an array
  -- @param[opt] n the size of partitions. Defaults to 2 (and then behaves like @{pairwise})
  -- @return an iterator function
  -- @see partition
  -- @see overlapping
  -- @see pairwise
  function M.aperture(array, n)
  	if n<=1 then return end
    return wrap(function()
      partgen3(array, n or 2, yield)
    end)
  end
  --- Iterator returning sliding pairs of an array.
  -- @name pairwise
  -- @param array an array
  -- @return an iterator function
  -- @see overlapping
  function M.pairwise(array) return M.aperture(array, 2) end
  --- Iterator returning the permutations of an array. It returns arrays made of all values
  -- from the passed-in array, with values permuted.
  -- @name permutation
  -- @param array an array
  -- @return an iterator function
  function M.permutation(array)
    return wrap(function() 
      permgen(array, #array, yield)
    end)
  end
  --- Concatenates values in a given array. Handles booleans as well. If `sep` string is
  -- passed, it will be used as a separator. Passing `i` and `j` will result in concatenating
  -- only values within `[i, j]` range.
  -- <br/><em>Aliased as `join`</em>
  -- @name concat
  -- @param array a given array
  -- @param[opt] sep a separator string, defaults to the empty string `''`.
  -- @param[optchain] i the starting index, defaults to 1.
  -- @param[optchain] j the final index, defaults to the array length.
  -- @return a string
  function M.concat(array, sep, i, j)
    return t_concat(M.map(array,tostring),sep,i,j)
  end
  --- Returns all possible pairs built from given arrays.
  -- @name xprod
  -- @param array a first array
  -- @param array2 a second array
  -- @return an array list of all pairs
  function M.xprod(array, array2)
    local p = {}
    for i, v1 in ipairs(array) do
      for j, v2 in ipairs(array2) do
        p[#p+1] = {v1, v2}
      end
    end
    return p
  end
  --- Creates pairs from value and array. Value is always prepended to the pair.
  -- @name xpairs
  -- @param valua a value
  -- @param array an array
  -- @return an array list of all pairs
  function M.xpairs(value, array)
    local xpairs = {}
    for k, v in ipairs(array) do
      xpairs[k] = {value, v}
    end
    return xpairs
  end
  --- Creates pairs from value and array. Value is always appended as the last item to the pair.
  -- @name xpairsRight
  -- @param valua a value
  -- @param array an array
  -- @return an array list of all pairs
  function M.xpairsRight(value, array)
    local xpairs = {}
    for k, v in ipairs(array) do
      xpairs[k] = {v, value}
    end
    return xpairs
  end
  --- Returns the sum of array values.
  -- @name sum
  -- @param array a given array
  -- @return the sum of array values
  function M.sum(array)
    local s = 0
    for k, v in ipairs(array) do s = s + v end
    return s
  end
  --- Returns the product of array values.
  -- @name product
  -- @param array a given array
  -- @return the product of array values
  function M.product(array)
    local p = 1
    for k, v in ipairs(array) do p = p * v end
    return p
  end
  --- Returns the mean of an array of numbers.
  -- <br/><em>Aliased as `average`</em>
  -- @name mean
  -- @param array an array of numbers
  -- @return a number
  -- @see sum
  -- @see product
  -- @see median
  function M.mean(array)
    return M.sum(array)/(#array)
  end
  --- Returns the median of an array of numbers.
  -- @name median
  -- @param array an array of numbers
  -- @return a number
  -- @see sum
  -- @see product
  -- @see mean
  function M.median(array)
    local t = M.sort(M.clone(array))
    local n = #t
    if n == 0 then 
      return 
    elseif n==1 then 
      return t[1]
    end
    local mid = ceil(n/2)
    return n%2==0 and (t[mid] + t[mid+1])/2 or t[mid]
  end
  --- Utility functions
  -- @section Utility functions
  --- The no operation function.
  -- @name noop
  -- @return nothing
  function M.noop() return end
  --- Returns the passed-in value. This function is used internally
  -- as a default iterator.
  -- @name identity
  -- @param value a value
  -- @return the passed-in value
  function M.identity(value) return value end
  --- Calls `f` with the supplied arguments. Returns the results of `f(...)`.
  -- @name call
  -- @param f a function
  -- @param[opt] ... a vararg list of args to `f`
  -- @return the result of `f(...)` call.
  function M.call(f, ...)
    return f(...)
  end
  --- Creates a constant function which returns the same output on every call.
  -- <br/><em>Aliased as `always`</em>
  -- @name constant
  -- @param value a constant value
  -- @return a constant function
  function M.constant(value) 
    return function() return value end 
  end
  --- Returns a function which applies `specs` on args. This function produces an object having
  -- the same structure than `specs` by mapping each property to the result of calling its 
  -- associated function with the supplied arguments
  -- @name applySpec
  -- @param specs a table
  -- @return a function
  function M.applySpec(specs)
    return function (...)
      local spec = {}
      for i, f in pairs(specs) do spec[i] = f(...) end
      return spec
    end
  end
  --- Threads `value` through a series of functions. If a function expects more than one args,
  -- it can be specified using an array list, where the first item is the function and the following
  -- are the remaining args neeeded. The value is used as the first input.
  -- @name thread
  -- @param value a value
  -- @param ... a vararg list of functions or arrays
  -- @return a value
  -- @see threadRight
  function M.thread(value, ...)
    local state = value
    local arg = {...}
    for k, t in ipairs(arg) do
      if type(t) == 'function' then
        state = t(state)
      elseif type(t) == 'table' then
        local f = t[1]
        t_remove(t, 1)
        state = M.reduce(t, f, state)
      end
    end
    return state
  end
  --- Threads `value` through a series of functions. If a function expects more than one args,
  -- it can be specified using an array list, where the first item is the function and the following
  -- are the remaining args neeeded. The value is used as the last input.
  -- @name threadRight
  -- @param value a value
  -- @param ... a vararg list of functions or arrays
  -- @return a value
  -- @see thread
  function M.threadRight(value, ...)
    local state = value
    local arg = {...}
    for k, t in ipairs(arg) do
      if type(t) == 'function' then
        state = t(state)
      elseif type(t) == 'table' then
        local f = t[1]
        t_remove(t, 1)
        t_insert(t, state)
        state = M.reduce(t, f)
      end
    end
    return state
  end
  --- Returns a dispatching function. When called with arguments, this function invokes each of its functions
  -- in the passed-in order and returns the results of the first non-nil evaluation.
  -- @name dispatch
  -- @param ... a vararg list of functions
  -- @return a dispatch function
  function M.dispatch(...)
    local funcs = {...}
    return function (...)
      for k, f in ipairs(funcs) do
        local r = {f(...)}
        if #r > 0 then return unpack(r) end
      end
    end
  end
  --- Memoizes a given function by caching the computed result.
  -- Useful for speeding-up slow-running functions.
  -- <br/><em>Aliased as `cache`</em>
  -- @name memoize
  -- @param f a function
  -- @return a new function
  function M.memoize(f)
    local _cache = setmetatable({},{__mode = 'kv'})
    return function (key)
        if (_cache[key] == nil) then
          _cache[key] = f(key)
        end
        return _cache[key]
      end
  end
  --- Builds a list from a seed value. Accepts an iterator function, which 
  -- returns either nil to stop iteration or two values : the value to add to the list
  -- of results and the seed to be used in the next call to the iterator function.
  -- @name unfold
  -- @param f an iterator function
  -- @param seed a seed value
  -- @return an array of values
  function M.unfold(f, seed)
    local t, result = {}
    while true do
      result, seed = f(seed)
      if result ~= nil then t[#t+1] = result
      else break
      end
    end 
    return t
  end
  --- Returns a version of `f` that runs only once. Successive calls to `f`
  -- will keep yielding the same output, no matter what the passed-in arguments are. 
  -- It can be used to initialize variables.
  -- @name once
  -- @param f a function
  -- @return a new function
  -- @see before
  -- @see after
  function M.once(f)
    local _internal = 0
    local _args = {}
    return function(...)
  		_internal = _internal+1
  		if _internal <= 1 then _args = {...} end
  		return f(unpack(_args))
    end
  end
  --- Returns a version of `f` that will run no more than <em>count</em> times. Next calls will
  -- keep yielding the results of the count-th call.
  -- @name before
  -- @param f a function
  -- @param count a count
  -- @return a new function
  -- @see once
  -- @see after
  function M.before(f, count)
    local _internal = 0
    local _args = {}
    return function(...)
  		_internal = _internal+1
  		if _internal <= count then _args = {...} end
  		return f(unpack(_args))
    end
  end
  --- Returns a version of `f` that runs on the `count-th` call.
  -- Useful when dealing with asynchronous tasks.
  -- @name after
  -- @param f a function
  -- @param count the number of calls before `f` will start running.
  -- @return a new function
  -- @see once
  -- @see before
  function M.after(f, count)
    local _limit,_internal = count, 0
    return function(...)
  		_internal = _internal+1
  		if _internal >= _limit then return f(...) end
    end
  end
  --- Composes functions. Each passed-in function consumes the return value of the function that follows.
  -- In math terms, composing the functions `f`, `g`, and `h` produces the function `f(g(h(...)))`.
  -- @name compose
  -- @param ... a variable number of functions
  -- @return a new function
  -- @see pipe
  function M.compose(...)
  	-- See: https://github.com/Yonaba/Moses/pull/15#issuecomment-139038895
    local f = M.reverse {...}
    return function (...)
  		local first, _temp = true
  		for i, func in ipairs(f) do
  			if first then
  				first = false
  				_temp = func(...)
  			else
  				_temp = func(_temp)
  			end
  		end
  		return _temp
  	end
  end
  --- Pipes a value through a series of functions. In math terms, 
  -- given some functions `f`, `g`, and `h` in that order, it returns `f(g(h(value)))`.
  -- @name pipe
  -- @param value a value
  -- @param ... a variable number of functions
  -- @return the result of the composition of function calls.
  -- @see compose
  function M.pipe(value, ...)
    return M.compose(...)(value)
  end
  --- Returns the logical complement of a given function. For a given input, the returned 
  -- function will output `false` if the original function would have returned `true`, 
  -- and vice-versa.
  -- @name complement
  -- @param f a function
  -- @return  the logical complement of the given function `f`.
  function M.complement(f)
    return function(...) return not f(...) end
  end
  --- Calls a sequence of passed-in functions with the same argument.
  -- Returns a sequence of results. 
  -- <br/><em>Aliased as `juxt`</em>
  -- @name juxtapose
  -- @param value a value
  -- @param ... a variable number of functions
  -- @return a list of results
  function M.juxtapose(value, ...)
    local res = {}
    for i, func in ipairs({...}) do
      res[i] = func(value) 
    end
    return unpack(res)
  end
  --- Wraps `f` inside of the `wrapper` function. It passes `f` as the first argument to `wrapper`.
  -- This allows the wrapper to execute code before and after `f` runs,
  -- adjust the arguments, and execute it conditionally.
  -- @name wrap
  -- @param f a function to be wrapped, prototyped as `f (...)`
  -- @param wrapper a wrapper function, prototyped as `wrapper (f, ...)`
  -- @return the results
  function M.wrap(f, wrapper)
    return function (...) return  wrapper(f,...) end
  end
  --- Runs `iter` function `n` times. Collects the results of each run and returns them in an array.
  -- @name times
  -- @param  iter an iterator function, prototyped as `iter (i)`
  -- @param[opt] n the number of times `iter` should be called. Defaults to 1.
  -- @return table an array of results
  function M.times(iter, n)
    local results = {}
    for i = 1, (n or 1) do
      results[i] = iter(i)
    end
    return results
  end
  --- Binds `v` to be the first argument to `f`. Calling `f (...)` will result to `f (v, ...)`.
  -- @name bind
  -- @param f a function
  -- @param v a value
  -- @return a function
  -- @see bind2
  -- @see bindn
  -- @see bindall
  function M.bind(f, v)
    return function (...)
      return f(v,...)
    end
  end
  --- Binds `v` to be the second argument to `f`. Calling `f (a, ...)` will result to `f (a, v, ...)`.
  -- @name bind2
  -- @param f a function
  -- @param v a value
  -- @return a function
  -- @see bind
  -- @see bindn
  -- @see bindall
  function M.bind2(f, v)
    return function (t, ...)
      return f(t, v, ...)
    end
  end
  --- Binds `...` to be the N-first arguments to function `f`. 
  -- Calling `f (a1, a2, ..., aN)` will result to `f (..., a1, a2, ...,aN)`.
  -- @name bindn
  -- @param f a function
  -- @param ... a variable number of arguments
  -- @return a function
  -- @see bind
  -- @see bind2
  -- @see bindall
  function M.bindn(f, ...)
    local args = {...}
    return function (...)
        return f(unpack(M.append(args,{...})))
      end
  end
  --- Binds methods to object. As such, whenever any of these methods is invoked, it 
  -- always receives the object as its first argument.
  -- @name bindall
  -- @param obj an abject
  -- @param ... a variable number of method names
  -- @return the passed-in object with all methods bound to the object itself.
  -- @see bind
  -- @see bind2
  -- @see bindn
  function M.bindall(obj, ...)
  	local methodNames = {...}
  	for i, methodName in ipairs(methodNames) do
  		local method = obj[methodName]
  		if method then obj[methodName] = M.bind(method, obj) end
  	end
  	return obj
  end
  --- Returns a function which iterate over a set of conditions. It invokes each predicate,
  -- passing it given values. It returns the value of the corresponding function of the first 
  -- predicate to return a non-nil value.
  -- @name cond
  -- @param conds an array list of predicate-function pairs
  -- @return the result of invoking `f(...)` of the first predicate to return a non-nil value
  function M.cond(conds)
    return function(...)
      for k, condset in ipairs(conds) do
        if condset[1](...) then 
          return condset[2](...) 
        end
      end
    end
  end
  --- Returns a validation function. Given a set of functions, the validation function evaluates
  -- to `true` only when all its funcs returns `true`.
  -- @name both
  -- @param ... an array list of functions
  -- @return `true` when all given funcs returns true with input, false otherwise
  function M.both(...)
    local funcs = {...}
    return function (...)
      for k, f in ipairs(funcs) do
        if not f(...) then return false end
      end
      return true
    end
  end
  --- Returns a validation function. Given a set of functions, the validation function evaluates
  -- to `true` when at least one of its funcs returns `true`.
  -- @name either
  -- @param ... an array list of functions
  -- @return `true` when one of the given funcs returns `true` with input, `false` otherwise
  function M.either(...)
    local funcs = {...}
    return function (...)
      for k, f in ipairs(funcs) do
        if f(...) then return true end
      end
      return false
    end
  end
  --- Returns a validation function. Given a set of functions, the validation function evaluates
  -- to `true` when neither of its func return `true`.
  -- @name neither
  -- @param ... an array list of functions
  -- @return `true` when neither of the given funcs returns `true` with input, `false` otherwise
  function M.neither(...)
    local funcs = {...}
    return function (...)
      for k, f in ipairs(funcs) do
        if f(...) then return false end
      end
      return true
    end
  end
  --- Generates an unique ID for the current session. If given a string `template`, it
  -- will use this template for output formatting. Otherwise, if `template` is a function, it
  -- will evaluate `template (id)`.
  -- <br/><em>Aliased as `uid`</em>.
  -- @name uniqueId
  -- @param[opt] template either a string or a function template to format the ID
  -- @return value an ID
  function M.uniqueId(template)
    unique_id_counter = unique_id_counter + 1
    if template then
      if type(template) == 'string' then
        return template:format(unique_id_counter)
      elseif type(template) == 'function' then
        return template(unique_id_counter)
      end
    end
    return unique_id_counter
  end
  --- Produces an iterator which repeatedly apply a function `f` onto an input. 
  -- Yields `value`, then `f(value)`, then `f(f(value))`, continuously.
  -- <br/><em>Aliased as `iter`</em>.
  -- @name iterator
  -- @param f a function 
  -- @param value an initial input to `f`
  -- @param[opt] n the number of times the iterator should run
  -- @return an iterator function
  function M.iterator(f, value, n)
    local cnt = 0
  	return function()
      cnt = cnt + 1
      if n and cnt > n then return end
  		value = f(value)
  		return value
  	end
  end
  --- Consumes the first `n` values of a iterator then returns it.
  -- @name skip
  -- @param iter an iterator function 
  -- @param[opt] n a number. Defaults to 1.
  -- @return the given iterator
  function M.skip(iter, n)
    for i = 1, (n or 1) do
      if iter() == nil then return end
    end
    return iter
  end
  --- Iterates over an iterator and returns its values in an array.
  -- @name tabulate
  -- @param ... an iterator function (returning a generator, a state and a value)
  -- @return an array of results
  function M.tabulate(...)
  	local r = {}
  	for v in ... do r[#r+1] = v end
  	return r
  end
  --- Returns the length of an iterator. It consumes the iterator itself.
  -- @name iterlen
  -- @param ... an iterator function (returning a generator, a state and a value)
  -- @return the iterator length
  function M.iterlen(...)
  	local l = 0
    for v in ... do l = l + 1 end
    return l
  end
  --- Casts value as an array if it is not one.
  -- @name castArray
  -- @param value a value
  -- @return an array containing the given value
  function M.castArray(value)
    return (type(value)~='table') and {value} or value
  end
  --- Creates a function of `f` with arguments flipped in reverse order.
  -- @name flip
  -- @param f a function 
  -- @return a function
  function M.flip(f)
  	return function(...)
  		return f(unpack(M.reverse({...})))
  	end
  end
  --- Returns a function that gets the nth argument. 
  -- If n is negative, the nth argument from the end is returned.
  -- @name nthArg
  -- @param n a number 
  -- @return a function
  function M.nthArg(n)
    return function (...)
      local args = {...}
      return args[(n < 0) and (#args + n + 1) or n]
    end
  end
  --- Returns a function which accepts up to one arg. It ignores any additional arguments.
  -- @name unary
  -- @param f a function
  -- @return a function
  -- @see ary
  function M.unary(f)
    return function (...)
      local args = {...}
      return f(args[1])
    end
  end
  --- Returns a function which accepts up to `n` args. It ignores any additional arguments.
  -- <br/><em>Aliased as `nAry`</em>.
  -- @name ary
  -- @param f a function
  -- @param[opt] n a number. Defaults to 1.
  -- @return a function
  -- @see unary
  function M.ary(f, n)
    n = n or 1
    return function (...)
      local args = {...}
      local fargs = {}
      for i = 1, n do fargs[i] = args[i] end
      return f(unpack(fargs))
    end
  end
  --- Returns a function with an arity of 0. The new function ignores any arguments passed to it.
  -- @name noarg
  -- @param f a function
  -- @return a new function
  function M.noarg(f)
    return function ()
      return f()
    end
  end
  --- Returns a function which runs with arguments rearranged. Arguments are passed to the 
  -- returned function in the order of supplied `indexes` at call-time.
  -- @name rearg
  -- @param f a function
  -- @param indexes an array list of indexes
  -- @return a function
  function M.rearg(f, indexes)
    return function(...)
      local args = {...}
      local reargs = {}
      for i, arg in ipairs(indexes) do reargs[i] = args[arg] end
      return f(unpack(reargs))
    end
  end
  --- Creates a function that runs transforms on all arguments it receives.
  -- @name over
  -- @param ... a set of functions which will receive all arguments to the returned function
  -- @return a function
  -- @see overEvery
  -- @see overSome
  -- @see overArgs
  function M.over(...)
  	local transforms = {...}
  	return function(...)
  		local r = {}
  		for i,transform in ipairs(transforms) do
  			r[#r+1] = transform(...)
  		end
  		return r
  	end
  end
  --- Creates a validation function. The returned function checks if *all* of the given predicates return 
  -- truthy when invoked with the arguments it receives.
  -- @name overEvery
  -- @param ... a list of predicate functions
  -- @return a new function
  -- @see over
  -- @see overSome
  -- @see overArgs
  function M.overEvery(...)
  	local f = M.over(...)
  	return function(...)
  		return M.reduce(f(...),function(state,v) return state and v end)
  	end
  end
  --- Creates a validation function. The return function checks if *any* of a given predicates return 
  -- truthy when invoked with the arguments it receives.
  -- @name overSome
  -- @param ... a list of predicate functions
  -- @return a new function
  -- @see over
  -- @see overEvery
  -- @see overArgs
  function M.overSome(...)
  	local f = M.over(...)
  	return function(...)
  		return M.reduce(f(...),function(state,v) return state or v end)
  	end
  end
  --- Creates a function that invokes `f` with its arguments transformed. 1rst arguments will be passed to 
  -- the 1rst transform, 2nd arg to the 2nd transform, etc. Remaining arguments will not be transformed.
  -- @name overArgs
  -- @param f a function
  -- @param ... a list of transforms funcs prototyped as `f (v)`
  -- @return the result of running `f` with its transformed arguments
  -- @see over
  -- @see overEvery
  -- @see overSome
  function M.overArgs(f,...)
  	local _argf = {...}
  	return function(...)
  		local _args = {...}
  		for i = 1,#_argf do
  			local func = _argf[i]
  			if _args[i] then _args[i] = func(_args[i]) end
  		end
  		return f(unpack(_args))
  	end
  end
  --- Converges two functions into one.
  -- @name converge
  -- @param f a function
  -- @param g a function
  -- @param h a function
  -- @return a new version of function f 
  function M.converge(f, g, h) return function(...) return f(g(...),h(...)) end end
  --- Partially apply a function by filling in any number of its arguments. 
  -- One may pass a string `'M'` as a placeholder in the list of arguments to specify an argument 
  -- that should not be pre-filled, but left open to be supplied at call-time. 
  -- @name partial
  -- @param f a function
  -- @param ... a list of partial arguments to `f`
  -- @return a new version of function f having some of it original arguments filled
  -- @see partialRight
  -- @see curry
  function M.partial(f,...)
  	local partial_args = {...}
  	return function (...)
  		local n_args = {...}	
  		local f_args = {}
  		for k,v in ipairs(partial_args) do
  			f_args[k] = (v == '_') and M.shift(n_args) or v
  		end
  		return f(unpack(M.append(f_args,n_args)))
  	end
  end
  --- Similar to @{partial}, but from the right.
  -- @name partialRight
  -- @param f a function
  -- @param ... a list of partial arguments to `f`
  -- @return a new version of function f having some of it original arguments filled
  -- @see partialRight
  -- @see curry
  function M.partialRight(f,...)
  	local partial_args = {...}
  	return function (...)
  		local n_args = {...}	
  		local f_args = {}
  		for k = 1,#partial_args do
  			f_args[k] = (partial_args[k] == '_') and M.shift(n_args) or partial_args[k]
  		end
  		return f(unpack(M.append(n_args, f_args)))
  	end
  end
  --- Curries a function. If the given function `f` takes multiple arguments, it returns another version of 
  -- `f` that takes a single argument (the first of the arguments to the original function) and returns a new 
  -- function that takes the remainder of the arguments and returns the result. 
  -- @name curry
  -- @param f a function
  -- @param[opt] n_args the number of arguments expected for `f`. Defaults to 2.
  -- @return a curried version of `f`
  -- @see partial
  -- @see partialRight
  function M.curry(f, n_args)
  	n_args = n_args or 2
  	local _args = {}
  	local function scurry(v)
  		if n_args == 1 then return f(v) end
  		if v ~= nil then _args[#_args+1] = v end
  		if #_args < n_args then
  			return scurry
  		else
  			local r = {f(unpack(_args))}
  			_args = {}
  			return unpack(r)
  		end
  	end
  	return scurry
  end
  --- Returns the execution time of `f (...)` and its returned values.
  -- @name time
  -- @param f a function
  -- @param[opt] ... optional args to `f`
  -- @return the execution time and the results of `f (...)`
  function M.time(f, ...)
  	local stime = clock()
  	local r = {f(...)}
  	return clock() - stime, unpack(r)
  end
  --- Object functions
  -- @section Object functions
  --- Returns the keys of the object properties.
  -- @name keys
  -- @param obj an object
  -- @return an array
  function M.keys(obj)
    local keys = {}
    for key in pairs(obj) do keys[#keys+1] = key end
    return keys
  end
  --- Returns the values of the object properties.
  -- @name values
  -- @param obj an object
  -- @return an array of values
  function M.values(obj)
    local values = {}
    for key, value in pairs(obj) do values[#values+1] = value end
    return values
  end
  --- Returns the value at a given path in an object. 
  -- Path is given as a vararg list of keys.
  -- @name path
  -- @param obj an object
  -- @param ... a vararg list of keys
  -- @return a value or nil
  function M.path(obj, ...)
    local value, path = obj, {...}
    for i, p in ipairs(path) do
      if (value[p] == nil) then return end
      value = value[p]
    end
    return value
  end
  --- Spreads object under property path onto provided object. 
  -- It is similar to @{flattenPath}, but removes object under the property path.
  -- @name spreadPath
  -- @param obj an object
  -- @param ... a property path given as a vararg list
  -- @return the passed-in object with changes
  -- @see flattenPath
  function M.spreadPath(obj, ...)
    local path = {...}
    for _, p in ipairs(path) do
      if obj[p] then
        for k, v in pairs(obj[p]) do 
          obj[k] = v
          obj[p][k] = nil
        end
      end
    end
    return obj
  end
  --- Flattens object under property path onto provided object. 
  -- It is similar to @{spreadPath}, but preserves object under the property path.
  -- @name flattenPath
  -- @param obj an object
  -- @param ... a property path given as a vararg list
  -- @return the passed-in object with changes
  -- @see spreadPath
  function M.flattenPath(obj, ...)
    local path = {...}
    for _, p in ipairs(path) do
      if obj[p] then
        for k, v in pairs(obj[p]) do obj[k] = v end
      end
    end
    return obj
  end
  --- Converts key-value pairs to an array-list of `[k, v]` pairs.
  -- @name kvpairs
  -- @param obj an object
  -- @return an array list of key-value pairs
  -- @see toObj
  function M.kvpairs(obj)
  	local t = {}
  	for k,v in pairs(obj) do t[#t+1] = {k,v} end
  	return t
  end
  --- Converts an array list of `[k,v]` pairs to an object. Keys are taken
  -- from the 1rst column in the `[k,v]` pairs sequence, associated with values in the 2nd
  -- column.
  -- @name toObj
  -- @param kvpairs an array-list of `[k,v]` pairs
  -- @return an object
  -- @see kvpairs
  function M.toObj(kvpairs)
  	local obj = {}
  	for k, v in ipairs(kvpairs) do
  		obj[v[1]] = v[2]
  	end
  	return obj
  end
  --- Swaps keys with values. Produces a new object where previous keys are now values, 
  -- while previous values are now keys.
  -- <br/><em>Aliased as `mirror`</em>
  -- @name invert
  -- @param obj a given object
  -- @return a new object
  function M.invert(obj)
    local _ret = {}
    for k, v in pairs(obj) do
      _ret[v] = k
    end
    return _ret
  end
  --- Returns a function that will return the key property of any passed-in object.
  -- @name property
  -- @param key a key property name
  -- @return a function which should accept an object as argument
  -- @see propertyOf
  function M.property(key)
  	return function(obj) return obj[key] end
  end
  --- Returns a function which will return the value of an object property. 
  -- @name propertyOf
  -- @param obj an object
  -- @return a function which should accept a key property argument
  -- @see property
  function M.propertyOf(obj)
  	return function(key) return obj[key] end
  end
  --- Converts any given value to a boolean
  -- @name toBoolean
  -- @param value a value. Can be of any type
  -- @return `true` if value is true, `false` otherwise (false or nil).
  function M.toBoolean(value)
    return not not value
  end
  --- Extends an object properties. It copies the properties of extra passed-in objects
  -- into the destination object, and returns the destination object. The last objects
  -- will override properties of the same name.
  -- @name extend
  -- @param destObj a destination object
  -- @param ... a list of objects
  -- @return the destination object extended
  function M.extend(destObj, ...)
    local sources = {...}
    for k, source in ipairs(sources) do
      if type(source) == 'table' then
        for key, value in pairs(source) do destObj[key] = value end
      end
    end
    return destObj
  end
  --- Returns a sorted list of all methods names found in an object. If the given object
  -- has a metatable implementing an `__index` field pointing to another table, will also recurse on this
  -- table if `recurseMt` is provided. If `obj` is omitted, it defaults to the library functions.
  -- <br/><em>Aliased as `methods`</em>.
  -- @name functions
  -- @param[opt] obj an object. Defaults to Moses library functions.
  -- @return an array-list of methods names
  function M.functions(obj, recurseMt)
    obj = obj or M
    local _methods = {}
    for key, value in pairs(obj) do
      if type(value) == 'function' then
        _methods[#_methods+1] = key
      end
    end
    if recurseMt then
      local mt = getmetatable(obj)
      if mt and mt.__index then
        local mt_methods = M.functions(mt.__index, recurseMt)
        for k, fn in ipairs(mt_methods) do
          _methods[#_methods+1] = fn
        end
      end
    end
    return _methods
  end
  --- Clones a given object properties. If `shallow` is passed will also clone nested array properties.
  -- @name clone
  -- @param obj an object
  -- @param[opt] shallow whether or not nested array-properties should be cloned, defaults to false.
  -- @return a copy of the passed-in object
  function M.clone(obj, shallow)
    if type(obj) ~= 'table' then return obj end
    local _obj = {}
    for i,v in pairs(obj) do
      if type(v) == 'table' then
        if not shallow then
          _obj[i] = M.clone(v,shallow)
        else _obj[i] = v
        end
      else
        _obj[i] = v
      end
    end
    return _obj
  end
  --- Invokes interceptor with the object, and then returns object.
  -- The primary purpose of this method is to "tap into" a method chain, in order to perform operations 
  -- on intermediate results within the chain.
  -- @name tap
  -- @param obj an object
  -- @param f an interceptor function, should be prototyped as `f (obj)`
  -- @return the passed-in object
  function M.tap(obj, f)
    f(obj)
    return obj
  end
  --- Checks if a given object implements a property.
  -- @name has
  -- @param obj an object
  -- @param key a key property to be checked
  -- @return `true` or `false`
  function M.has(obj, key)
    return obj[key]~=nil
  end
  --- Returns an object copy having white-listed properties.
  -- <br/><em>Aliased as `choose`</em>.
  -- @name pick
  -- @param obj an object
  -- @param ... a variable number of string keys
  -- @return the filtered object
  function M.pick(obj, ...)
    local whitelist = M.flatten {...}
    local _picked = {}
    for key, property in pairs(whitelist) do
      if (obj[property])~=nil then
        _picked[property] = obj[property]
      end
    end
    return _picked
  end
  --- Returns an object copy without black-listed properties.
  -- <br/><em>Aliased as `drop`</em>.
  -- @name omit
  -- @param obj an object
  -- @param ... a variable number of string keys
  -- @return the filtered object
  function M.omit(obj, ...)
    local blacklist = M.flatten {...}
    local _picked = {}
    for key, value in pairs(obj) do
      if not M.include(blacklist,key) then
        _picked[key] = value
      end
    end
    return _picked
  end
  --- Applies a template to an object, preserving non-nil properties.
  -- <br/><em>Aliased as `defaults`</em>.
  -- @name template
  -- @param obj an object
  -- @param[opt] template a template object. If `nil`, leaves `obj` untouched.
  -- @return the passed-in object filled
  function M.template(obj, template)
    if not template then return obj end
    for i, v in pairs(template) do
      if not obj[i] then obj[i] = v end
    end
    return obj
  end
  --- Performs a deep comparison test between two objects. Can compare strings, functions 
  -- (by reference), nil, booleans. Compares tables by reference or by values. If `useMt` 
  -- is passed, the equality operator `==` will be used if one of the given objects has a 
  -- metatable implementing `__eq`.
  -- <br/><em>Aliased as `M.compare`, `M.matches`</em>
  -- @name isEqual
  -- @param objA an object
  -- @param objB another object
  -- @param[opt] useMt whether or not `__eq` should be used, defaults to false.
  -- @return `true` or `false`
  -- @see allEqual
  function M.isEqual(objA, objB, useMt)
    local typeObjA = type(objA)
    local typeObjB = type(objB)
    if typeObjA~=typeObjB then return false end
    if typeObjA~='table' then return (objA==objB) end
    local mtA = getmetatable(objA)
    local mtB = getmetatable(objB)
    if useMt then
      if (mtA or mtB) and (mtA.__eq or mtB.__eq) then
        return mtA.__eq(objA, objB) or mtB.__eq(objB, objA) or (objA==objB)
      end
    end
    if M.size(objA)~=M.size(objB) then return false end
    
    local vB
    for i,vA in pairs(objA) do
      vB = objB[i]
      if vB == nil or not M.isEqual(vA, vB, useMt) then return false end
    end
    for i in pairs(objB) do
      if objA[i] == nil then return false end
    end
    return true
  end
  --- Invokes an object method. It passes the object itself as the first argument. if `method` is not
  -- callable, will return `obj[method]`.
  -- @name result
  -- @param obj an object
  -- @param method a string key to index in object `obj`.
  -- @return the returned value of `method (obj)` call
  function M.result(obj, method)
    if obj[method] then
      if M.isCallable(obj[method]) then
        return obj[method](obj)
      else return obj[method]
      end
    end
    if M.isCallable(method) then
      return method(obj)
    end
  end
  --- Checks if the given arg is a table.
  -- @name isTable
  -- @param t a value to be tested
  -- @return `true` or `false`
  function M.isTable(t)
    return type(t) == 'table'
  end
  --- Checks if the given argument is callable. Assumes `obj` is callable if
  -- it is either a function or a table having a metatable implementing `__call` metamethod.
  -- @name isCallable
  -- @param obj an object
  -- @return `true` or `false`
  function M.isCallable(obj)
    return 
      ((type(obj) == 'function') or
      ((type(obj) == 'table') and getmetatable(obj) and getmetatable(obj).__call~=nil) or
      false)
  end
  --- Checks if the given argument is an array. Assumes `obj` is an array
  -- if is a table with consecutive integer keys starting at 1.
  -- @name isArray
  -- @param obj an object
  -- @return `true` or `false`
  function M.isArray(obj)
    if not (type(obj) == 'table') then return false end
    -- Thanks @Wojak and @Enrique García Cota for suggesting this
    -- See : http://love2d.org/forums/viewtopic.php?f=3&t=77255&start=40#p163624
    local i = 0
    for k in pairs(obj) do
       i = i + 1
       if obj[i] == nil then return false end
    end
    return true
  end
  --- Checks if the given object is iterable with `pairs` (or `ipairs`).
  -- @name isIterable
  -- @param obj an object
  -- @return `true` if the object can be iterated with `pairs` (or `ipairs`), `false` otherwise
  function M.isIterable(obj)
    return M.toBoolean((pcall(pairs, obj)))
  end
  --- Extends Lua's `type` function. It returns the type of the given object and also recognises
  -- file userdata
  -- @name type
  -- @param obj an object
  -- @return the given object type
  function M.type(obj)
    local tp = type(obj)
    if tp == 'userdata' then
      local mt = getmetatable(obj)
      if mt == getmetatable(io.stdout) then 
        return 'file'
      end
    end
    return tp
  end
  --- Checks if the given pbject is empty. If `obj` is a string, will return `true`
  -- if `#obj == 0`. Otherwise, if `obj` is a table, will return whether or not this table
  -- is empty. If `obj` is `nil`, it will return true.
  -- @name isEmpty
  -- @param[opt] obj an object
  -- @return `true` or `false`
  function M.isEmpty(obj)
    if (obj == nil) then return true end
    if type(obj) == 'string' then return #obj==0 end
    if type(obj) == 'table' then return next(obj)==nil end
    return true
  end
  --- Checks if the given argument is a string.
  -- @name isString
  -- @param obj an object
  -- @return `true` or `false`
  function M.isString(obj)
    return type(obj) == 'string'
  end
  --- Checks if the given argument is a function.
  -- @name isFunction
  -- @param obj an object
  -- @return `true` or `false`
  function M.isFunction(obj)
     return type(obj) == 'function'
  end
  --- Checks if the given argument is nil.
  -- @name isNil
  -- @param obj an object
  -- @return `true` or `false`
  function M.isNil(obj)
    return obj==nil
  end
  --- Checks if the given argument is a number.
  -- @name isNumber
  -- @param obj an object
  -- @return `true` or `false`
  -- @see isNaN
  function M.isNumber(obj)
    return type(obj) == 'number'
  end
  --- Checks if the given argument is NaN (see [Not-A-Number](http://en.wikipedia.org/wiki/NaN)).
  -- @name isNaN
  -- @param obj an object
  -- @return `true` or `false`
  -- @see isNumber
  function M.isNaN(obj)
    return type(obj) == 'number' and obj~=obj
  end
  --- Checks if the given argument is a finite number.
  -- @name isFinite
  -- @param obj an object
  -- @return `true` or `false`
  function M.isFinite(obj)
    if type(obj) ~= 'number' then return false end
    return obj > -huge and obj < huge
  end
  --- Checks if the given argument is a boolean.
  -- @name isBoolean
  -- @param obj an object
  -- @return `true` or `false`
  function M.isBoolean(obj)
    return type(obj) == 'boolean'
  end
  --- Checks if the given argument is an integer.
  -- @name isInteger
  -- @param obj an object
  -- @return `true` or `false`
  function M.isInteger(obj)
    return type(obj) == 'number' and floor(obj)==obj
  end
  -- Aliases
  do
    -- Table functions aliases
    M.forEach       = M.each
    M.forEachi      = M.eachi
    M.update        = M.adjust
    M.alleq         = M.allEqual
    M.loop          = M.cycle
    M.collect       = M.map
    M.inject        = M.reduce
    M.foldl         = M.reduce
    M.injectr       = M.reduceRight
    M.foldr         = M.reduceRight
    M.mapr          = M.mapReduce
    M.maprr         = M.mapReduceRight
    M.any           = M.include
    M.some          = M.include
    M.contains      = M.include
    M.filter        = M.select
    M.discard       = M.reject
    M.every         = M.all
    
    -- Array functions aliases
    M.takeWhile     = M.selectWhile
    M.rejectWhile   = M.dropWhile
    M.pop           = M.shift
    M.remove        = M.pull
    M.rmRange       = M.removeRange
    M.chop          = M.removeRange
    M.sub           = M.slice
    M.head          = M.first
    M.take          = M.first
    M.tail          = M.rest
    M.without       = M.difference
    M.diff          = M.difference
    M.symdiff       = M.symmetricDifference
    M.xor           = M.symmetricDifference
    M.uniq          = M.unique
    M.isuniq        = M.isunique
  	M.transpose     = M.zip
    M.part          = M.partition
    M.perm          = M.permutation
    M.transposeWith = M.zipWith
    M.intersperse   = M.interpose
    M.sliding       = M.aperture
    M.mirror        = M.invert
    M.join          = M.concat
    M.average       = M.mean
    
    -- Utility functions aliases
    M.always        = M.constant
    M.cache         = M.memoize
    M.juxt          = M.juxtapose
    M.uid           = M.uniqueid
    M.iter          = M.iterator
    M.nAry          = M.ary
    
    -- Object functions aliases
    M.methods       = M.functions
    M.choose        = M.pick
    M.drop          = M.omit
    M.defaults      = M.template
    M.compare       = M.isEqual
    M.matches       = M.isEqual
  end
  -- Setting chaining and building interface
  do
    -- Wrapper to Moses
    local f = {}
    -- Will be returned upon requiring, indexes into the wrapper
    local Moses = {}
    Moses.__index = f
    -- Wraps a value into an instance, and returns the wrapped object
    local function new(value)
      return setmetatable({_value = value, _wrapped = true}, Moses)
    end
    setmetatable(Moses,{
      __call  = function(self,v) return new(v) end, -- Calls returns to instantiation
      __index = function(t,key,...) return f[key] end  -- Redirects to the wrapper
    })
    --- Returns a wrapped object. Calling library functions as methods on this object
    -- will continue to return wrapped objects until @{obj:value} is used. Can be aliased as `M(value)`.
    -- @class function
    -- @name chain
    -- @param value a value to be wrapped
    -- @return a wrapped object
    function Moses.chain(value)
      return new(value)
    end
    --- Extracts the value of a wrapped object. Must be called on an chained object (see @{chain}).
    -- @class function
    -- @name obj:value
    -- @return the value previously wrapped
    function Moses:value()
      return self._value
    end
    -- Register chaining methods into the wrapper
    f.chain, f.value = Moses.chain, Moses.value
    -- Register all functions into the wrapper
    for fname,fct in pairs(M) do
      if fname ~= 'operator' then -- Prevents from wrapping op functions
        f[fname] = function(v, ...)
          local wrapped = type(v) == 'table' and rawget(v,'_wrapped') or false
          if wrapped then
            local _arg = v._value
            local _rslt = fct(_arg,...)
            return new(_rslt)
          else
            return fct(v,...)
          end
        end
      end
    end
    
    -- Exports all op functions
    f.operator = M.operator
    f.op       = M.operator
    --- Imports all library functions into a context.
    -- @name import
    -- @param[opt] context a context. Defaults to `_ENV or `_G`` (current environment).
    -- @param[optchain] noConflict if supplied, will not import conflicting functions in the destination context.
    -- @return the passed-in context
    f.import = function(context, noConflict)
      context = context or _ENV or _G
      local funcs = M.functions()
      for k, fname in ipairs(funcs) do
        if rawget(context, fname)~= nil then
          if not noConflict then
            rawset(context, fname, M[fname])
          end
        else
          rawset(context, fname, M[fname])
        end
      end
      return context
    end
    -- Descriptive tags
    Moses._VERSION     = 'Moses v'.._MODULEVERSION
    Moses._URL         = 'http://github.com/Yonaba/Moses'
    Moses._LICENSE     = 'MIT <http://raw.githubusercontent.com/Yonaba/Moses/master/LICENSE>'
    Moses._DESCRIPTION = 'utility-belt library for functional programming in Lua'
    
    return Moses
  end
end

package.preload["stuart"] = function(...)
  local M = {}
  function M.class(super)
    local class = require 'stuart.class'
    return class.new(super)
  end
  function M.istype(obj, super)
    local class = require 'stuart.class'
    return class.istype(obj, super)
  end
  function M.NewContext(master, appName)
    local Context = require 'stuart.Context'
    return Context.new(master, appName)
  end
  function M.NewStreamingContext(arg1, arg2, arg3, arg4)
    local Context = require 'stuart.Context'
    local moses = require 'moses'
    local StreamingContext = require 'stuart.streaming.StreamingContext'
    if moses.isString(arg1) and (moses.isString(arg2) or arg2 == nil) and moses.isNumber(arg3) then
      local sc = Context.new(arg1, arg2, arg4)
      return StreamingContext.new(sc, arg3)
    end
    local SparkConf = require 'stuart.SparkConf'
    local istype = require 'stuart.class'.istype
    if (moses.isString(arg1) or istype(arg1, SparkConf)) and moses.isNumber(arg2) and arg3 == nil then
      local sc = Context.new(arg1)
      return StreamingContext.new(sc, arg2)
    end
    
    if moses.isTable(arg1) then
      if moses.isNumber(arg2) then
        return StreamingContext.new(arg1, arg2)
      end
      return StreamingContext.new(arg1)
    end
    
    error('Failed detecting NewStreamingContext parameters')
  end
  return M
end

package.preload["stuart-ml.clustering.KMeans"] = function(...)
  local class = require 'stuart.class'
  -- Moses find() and unique() don't use metatable __eq fns, so don't work for Spark Vector types
  local function find(array, value)
    local moses = require 'moses'
    for i = 1, #array do
      if moses.isEqual(array[i], value, true) then return i end
    end
  end
  local function unique(array)
    local ret = {}
    for i = 1, #array do
      if not find(ret, array[i]) then
        ret[#ret+1] = array[i]
      end
    end
    return ret
  end
  local KMeans = class.new()
  KMeans.RANDOM = 'RANDOM'
  KMeans.K_MEANS_PARALLEL = 'k-means||'
  function KMeans:_init(k, maxIterations, initializationMode, initializationSteps, epsilon, seed)
    self.k = k or 2
    self.maxIterations = maxIterations or 20
    self.initializationMode = initializationMode or KMeans.K_MEANS_PARALLEL
    self.initializationSteps = initializationSteps or 2
    self.epsilon = epsilon or 1e-4
    self.seed = seed or math.random(32000)
    self.initialModel = nil
  end
  -- Returns the squared Euclidean distance between two vectors
  function KMeans.fastSquaredDistance(vectorWithNorm1, vectorWithNorm2)
    local MLUtils = require 'stuart-ml.util.MLUtils'
    return MLUtils.fastSquaredDistance(vectorWithNorm1.vector, vectorWithNorm1.norm, vectorWithNorm2.vector, vectorWithNorm2.norm)
  end
  -- returns a Lua 1-based index
  function KMeans.findClosest(centers, point)
    local bestDistance = math.huge
    local bestIndex = 1
    for i,center in ipairs(centers) do
      local lowerBoundOfSqDist = center.norm - point.norm
      lowerBoundOfSqDist = lowerBoundOfSqDist * lowerBoundOfSqDist
      if lowerBoundOfSqDist < bestDistance then
        local distance = KMeans.fastSquaredDistance(center, point)
        if distance < bestDistance then
          bestDistance = distance
          bestIndex = i
        end
      end
    end
    return bestIndex, bestDistance
  end
  function KMeans:getInitializationMode()
    return self.initializationMode
  end
  function KMeans:getInitializationSteps()
    return self.initializationSteps
  end
  function KMeans:getK()
    return self.k
  end
  function KMeans:getMaxIterations()
    return self.maxIterations
  end
  function KMeans:getSeed()
    return self.seed
  end
  function KMeans:initKMeansParallel(data)
    local RDD = require 'stuart.RDD'
    assert(class.istype(data,RDD))
    
    -- Initialize empty centers and point costs.
    local costs = data:map(function() return math.huge end)
    -- Initialize the first center to a random point.
    math.randomseed(self.seed)
    local seed = math.random(32000)
    local sample = data:takeSample(false, 1, seed)
    
    -- Could be empty if data is empty; fail with a better message early:
    assert(#sample > 0, 'No samples available from data')
    local centers = {}
    local newCenters = {sample[1]:toDense()}
    centers[#centers+1] = newCenters[1]
    
    -- On each step, sample 2 * k points on average with probability proportional
    -- to their squared distance from the centers. Note that only distances between points
    -- and new centers are computed in each iteration.
    local bcNewCentersList = {}
    local moses = require 'moses'
    local tableIterator = require 'stuart-ml.util'.tableIterator
    local random = require 'stuart-ml.util.random'
    for step = 1, self.initializationSteps do
      local bcNewCenters = newCenters
      bcNewCentersList[#bcNewCentersList+1] = bcNewCenters
      local preCosts = costs
      costs = data:zip(preCosts):map(function(e)
        local point, cost = e[1], e[2]
        return math.min(KMeans.pointCost(bcNewCenters, point), cost)
      end)
      local sumCosts = costs:sum()
      local chosen = data:zip(costs):mapPartitionsWithIndex(function(_, pointCostsIter)
        local r = {}
        for pointCost in pointCostsIter do
          local point, cost = pointCost[1], pointCost[2]
          if random.nextDouble() < 2.0 * cost * self.k / sumCosts then
            r[#r+1] = point
          end
        end
        return tableIterator(r)
      end):collect()
      
      newCenters = moses.map(chosen, function(v) return v:toDense() end)
      centers = moses.append(centers, newCenters)
    end
    local distinctCenters = unique(moses.pluck(centers, 'vector'))
    local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
    distinctCenters = moses.map(distinctCenters, function(v) return VectorWithNorm.new(v) end)
    if #distinctCenters <= self.k then
      return distinctCenters
    else
      -- Finally, we might have a set of more than k distinct candidate centers; weight each
      -- candidate by the number of points in the dataset mapping to it and run a local k-means++
      -- on the weighted centers to pick k of them
      local countMap = data:map(function(vectorWithNorm)
        local bestIndex, _ = KMeans.findClosest(distinctCenters, vectorWithNorm)
        return bestIndex
      end):countByValue()
      local myWeights = moses.map(distinctCenters, function(_, i) return countMap[i] or 0.0 end)
      local localKMeans = require 'stuart-ml.clustering.localKMeans'
      return localKMeans.kMeansPlusPlus(0, distinctCenters, myWeights, self.k, 30)
    end
  end
  function KMeans:initRandom(vectorsWithNormsRDD)
    -- Select without replacement; may still produce duplicates if the data has < k distinct
    -- points, so deduplicate the centroids to match the behavior of k-means|| in the same situation
    local now = require 'stuart.interface'.now
    local has_now, seed = pcall(now)
    if not has_now then seed = math.random(32000) end
    local sample = vectorsWithNormsRDD:takeSample(false, self.k, seed)
    local moses = require 'moses'
    local distinctSample = unique(moses.pluck(sample, 'vector'))
    local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
    return moses.map(distinctSample, function(v) return VectorWithNorm.new(v) end)
  end
  function KMeans.pointCost(centers, point)
    local _, bestDistance = KMeans.findClosest(centers, point)
    return bestDistance
  end
  --[[
    Train a K-means model on the given set of points; `data` should be cached for high
    performance, because this is an iterative algorithm.
  --]]
  function KMeans:run(data)
    -- Compute squared norms and cache them.
    local Vectors = require 'stuart-ml.linalg.Vectors'
    local norms = data:map(function(v) return Vectors.norm(v, 2.0) end)
    local zippedData = data:zip(norms):map(function(e)
      local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
      return VectorWithNorm.new(e[1], e[2])
    end)
    local model = self:runAlgorithm(zippedData)
    return model
  end
  --[[
    Implementation of K-Means algorithm.
  --]]
  function KMeans:runAlgorithm(data)
    local moses = require 'moses'
    local centers
    if self.initialModel ~= nil then
      local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
      centers = moses.map(self.initialModel.clusterCenters, function(center) return VectorWithNorm.new(center) end)
    else
      if self.initializationMode == KMeans.RANDOM then
        centers = self:initRandom(data)
      else
        centers = self:initKMeansParallel(data)
      end
    end
    if self.initialModel == nil then
      if self.initializationMode == KMeans.RANDOM then
        self:initRandom(data)
      else
        self:initKMeansParallel(data)
      end
    end
    
    local converged, cost, iteration = false, 0.0, 1
    
    -- Execute iterations of Lloyd's algorithm until converged
    local now = require 'stuart.interface'.now
    local has_now, iterationStartTime = pcall(now)
    
    local BLAS = require 'stuart-ml.linalg.BLAS'
    local tableIterator = require 'stuart-ml.util'.tableIterator
    local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
    local Vectors = require 'stuart-ml.linalg.Vectors'
    
    while iteration <= self.maxIterations and not converged do
      
      -- Find the sum and count of points mapping to each center
      local totalContribs = data:mapPartitions(function(partitionIter)
        local dims = centers[1].vector:size()
        
        local sums = moses.fill({}, Vectors.zeros(dims), 1, #centers)
        local counts = moses.fill({}, 0, 1, #centers)
        
        for point in partitionIter do
          local bestCenter, cost_ = KMeans.findClosest(centers, point)
          cost = cost + cost_
          local sum = sums[bestCenter]
          BLAS.axpy(1.0, point.vector, sum)
          counts[bestCenter] = counts[bestCenter] + 1
        end
        
        local contribsKeys = moses.filter(moses.keys(counts), function(i) return counts[i] > 0 end)
        local contribs = moses.map(contribsKeys, function(j)
          return {j, {sums[j], counts[j]}}
        end)
        return tableIterator(contribs)
        
      end):reduceByKey(function(e)
        local sum1, count1, sum2, count2 = e[1][1], e[1][2], e[2][1], e[2][2]
        BLAS.axpy(1.0, sum2, sum1)
        return {sum1, count1 + count2}
      end):collectAsMap()
      
      -- Update the cluster centers and costs
      converged = true
      moses.each(totalContribs, function(e, j)
        local sum, count = e[1], e[2]
        BLAS.scal(1.0 / count, sum)
        local newCenter = VectorWithNorm.new(sum)
        if converged and KMeans.fastSquaredDistance(newCenter, centers[j]) > self.epsilon * self.epsilon then
          converged = false
        end
        centers[j] = newCenter
      end)
      
      iteration = iteration + 1
    end
    
    local logging = require 'stuart.internal.logging'
    if has_now then
      local iterationTimeInSeconds = now() - iterationStartTime
      logging.logInfo(string.format('Iterations took %f seconds.', iterationTimeInSeconds))
    end
    
    if iteration == self.maxIterations then
      logging.logInfo(string.format('KMeans reached the max number of iterations: %d.', self.maxIterations))
    else
      logging.logInfo(string.format('KMeans converged in %d iterations.', iteration))
    end
    
    logging.logInfo(string.format('The cost is %f', cost))
    
    local KMeansModel = require 'stuart-ml.clustering.KMeansModel'
    return KMeansModel.new(moses.pluck(centers, 'vector'))
  end
  function KMeans:setInitialModel(model)
    assert(model.k == self.k, 'mismatched cluster count')
    self.initialModel = model
    return self
  end
  function KMeans:setInitializationMode(initializationMode)
    assert(initializationMode == KMeans.RANDOM or initializationMode == KMeans.K_MEANS_PARALLEL)
    self.initializationMode = initializationMode
    return self
  end
  function KMeans:setInitializationSteps(initializationSteps)
    assert(initializationSteps > 0, 'Number of initialization steps must be positive but got ' .. initializationSteps)
    self.initializationSteps = initializationSteps
    return self
  end
  function KMeans:setK(k)
    assert(k > 0, 'Number of clusters must be positive but got ' .. k)
    self.k = k
    return self
  end
  function KMeans:setMaxIterations(maxIterations)
    assert(maxIterations >= 0, 'Maximum of iterations must be nonnegative but got ' .. maxIterations)
    self.maxIterations = maxIterations
    return self
  end
  function KMeans:setSeed(seed)
    self.seed = seed
    return self
  end
  function KMeans.train(rdd, k, maxIterations, initializationMode, seed)
    return KMeans.new(k, maxIterations, initializationMode, 2, 1e-4, seed):run(rdd)
  end
  return KMeans
end

package.preload["stuart-ml.clustering.KMeansModel"] = function(...)
  local class = require 'stuart.class'
  local KMeansModel = class.new()
  function KMeansModel:_init(clusterCenters)
    self.clusterCenters = clusterCenters
    if clusterCenters ~= nil then
      local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
      local moses = require 'moses'
      self.clusterCentersWithNorm = moses.map(clusterCenters, function(center) return VectorWithNorm.new(center) end)
      self.k = #clusterCenters
    end
  end
  function KMeansModel:__tostring()
    local moses = require 'moses'
    return string.format('KMeansModel(clusterCenters=%s)',
      table.concat(moses.map(self.clusterCenters, function(_,vector) return tostring(vector) end), ','))
  end
  --[[
    Return the K-means cost (sum of squared distances of points to their nearest center) for this
    model on the given data.
  --]]
  function KMeansModel:computeCost(rddOfVectors)
    local KMeans = require 'stuart-ml.clustering.KMeans'
    local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
    return rddOfVectors:map(function(vector)
      return KMeans.pointCost(self.clusterCentersWithNorm, VectorWithNorm.new(vector))
    end):sum()
  end
  function KMeansModel.load(sc, path)
    local hasSparkSession, SparkSession = pcall(require, 'stuart-sql.SparkSession')
    assert(hasSparkSession)
    local spark = SparkSession.builder():sparkContext(sc):getOrCreate()
    local Loader = require 'stuart-ml.util.Loader'
    local className, formatVersion, metadata = Loader.loadMetadata(sc, path)
    assert(className == 'org.apache.spark.mllib.clustering.KMeansModel')
    assert(formatVersion == '1.0')
    local centroids = spark.read:parquet(Loader.dataPath(path))
    --TODO Loader.checkSchema[Cluster](centroids.schema)
    local Vectors = require 'stuart-ml.linalg.Vectors'
    local localCentroids = centroids:rdd():map(function(e) return {e[1], Vectors.dense(e[2])} end)
    assert(metadata.k == localCentroids:count())
    return KMeansModel.new(localCentroids:sortByKey():map(function(e) return e[2] end):collect())
  end
  function KMeansModel:predict(arg)
    -- Returns the cluster index that a given point belongs to.
    local istype = require 'stuart.class'.istype
    local KMeans = require 'stuart-ml.clustering.KMeans'
    local Vector = require 'stuart-ml.linalg.Vector'
    local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
    if istype(arg, Vector) then
      local point = arg
      return KMeans.findClosest(self.clusterCentersWithNorm, VectorWithNorm.new(point))
    end
    
    -- Maps given RDD of points to their cluster indices.
    local RDD = require 'stuart.RDD'
    assert(istype(arg, RDD))
    local points = arg
    return points:map(function(p)
      local bestIndex, _ = KMeans.findClosest(self.clusterCentersWithNorm, VectorWithNorm.new(p))
      return bestIndex
    end)
  end
  return KMeansModel
end

package.preload["stuart-ml.clustering.VectorWithNorm"] = function(...)
  local class = require 'stuart.class'
  -- A vector with its norm for fast distance computation.
  --
  -- @see [[org.apache.spark.mllib.clustering.KMeans#fastSquaredDistance]]
  local VectorWithNorm = class.new()
  function VectorWithNorm:_init(arg1, norm)
    local Vector = require 'stuart-ml.linalg.Vector'
    local Vectors = require 'stuart-ml.linalg.Vectors'
    if class.istype(arg1, Vector) then
      self.vector = arg1
    else -- arg1 is a table
      self.vector = Vectors.dense(arg1)
    end
    self.norm = norm or Vectors.norm(self.vector, 2.0)
  end
  function VectorWithNorm.__eq(a, b)
    return a.vector == b.vector and a.norm == b.norm
  end
  function VectorWithNorm:__tostring()
    return '(' .. tostring(self.vector) .. ',' .. self.norm .. ')'
  end
  function VectorWithNorm:toDense()
    return VectorWithNorm.new(self.vector:toDense(), self.norm)
  end
  return VectorWithNorm
end

package.preload["stuart-ml.clustering.localKMeans"] = function(...)
  --[[
    An utility module to run K-means locally. It's used in the initialization of
    KMeans but not meant to be publicly exposed.
  --]]
  local M = {}
  --[[
    Run K-means++ on the weighted point set `points`. This first does the K-means++
    initialization procedure and then rounds of Lloyd's algorithm.
  --]]
  M.kMeansPlusPlus = function(_, points, weights, k, maxIterations)
    local dimensions = points[1].vector:size()
    local centers = {}
    -- Initialize centers by sampling using the k-means++ procedure.
    centers[1] = M.pickWeighted(points, weights):toDense()
    local KMeans = require 'stuart-ml.clustering.KMeans'
    local moses = require 'moses'
    local costArray = moses.map(points, function(vectorWithNorm)
      return KMeans.fastSquaredDistance(vectorWithNorm, centers[1])
    end)
    
    local random = require 'stuart-ml.util.random'
    local logging = require 'stuart.internal.logging'
    for i = 1, k do
      local sum = moses.sum(moses.map(moses.zip(costArray, weights), function(p) return p[1] * p[2] end))
      local r = random.nextDouble() * sum
      local cumulativeScore = 0.0
      local j = 1
      while j <= #points and cumulativeScore < r do
        cumulativeScore = cumulativeScore + weights[j] * costArray[j]
        j = j + 1
      end
      if j == 1 then
        logging.logWarning(string.format(
          'kMeansPlusPlus initialization ran out of distinct points for centers. Using duplicate point for center k = %d.', i))
        centers[i] = points[1]:toDense()
      else
        centers[i] = points[j-1]:toDense()
      end
    
      -- update costArray
      for p = 1, #points do
        costArray[p] = math.min(KMeans.fastSquaredDistance(points[p], centers[i], costArray[p]))
      end
    end
    
    -- Run up to maxIterations iterations of Lloyd's algorithm
    local oldClosest = moses.fill({}, -1, 1, #points)
    local iteration = 0
    local moved = true
    local BLAS = require 'stuart-ml.linalg.BLAS'
    local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'
    local Vectors = require 'stuart-ml.linalg.Vectors'
    while moved and iteration < maxIterations do
      moved = false
      local counts = moses.fill({}, 0.0, 1, k)
      local sums = moses.fill({}, Vectors.zeros(dimensions), 1, k)
      for i = 1, #points do
        local p = points[i]
        local index, _ = KMeans.findClosest(centers, p)
        BLAS.axpy(weights[i], p.vector, sums[index])
        counts[index] = counts[index] + weights[i]
        if index ~= oldClosest[i] then
          moved = true
          oldClosest[i] = index
        end
      end
      -- Update centers
      for j = 1, k do
        if counts[j] == 0.0 then
          -- Assign center to a random point
          centers[j] = points[1 + random.nextInt(#points-1)]:toDense()
        else
          BLAS.scal(1.0 / counts[j], sums[j])
          centers[j] = VectorWithNorm.new(sums[j])
        end
      end
      iteration = iteration + 1
    end
    
    if iteration == maxIterations then
      logging.logInfo(string.format('Local KMeans++ reached the max number of iterations: %d', maxIterations))
    else
      logging.logInfo(string.format("Local KMeans++ converged in %d iterations.", iteration))
    end
    
    return centers
  end
  M.pickWeighted = function(data, weights)
    local random = require 'stuart-ml.util.random'
    local moses = require 'moses'
    local r = random.nextDouble() * moses.sum(weights)
    local i, curWeight = 1, 0.0
    while i <= #data and curWeight < r do
      curWeight = curWeight + weights[i]
      i = i + 1
    end
    return data[i-1]
  end
  return M
end

package.preload["stuart-ml.linalg.BLAS"] = function(...)
  local M = {}
  --[[ y += a * x
  @param a number
  @param vectorX Vector
  @param vectorY Vector
  --]]
  M.axpy = function(a, vectorX, vectorY)
    local class = require 'stuart.class'
    local Vector = require 'stuart-ml.linalg.Vector'
    assert(class.istype(vectorX, Vector))
    assert(class.istype(vectorY, Vector))
    assert(vectorX:size() == vectorY:size())
    local DenseVector = require 'stuart-ml.linalg.DenseVector'
    if class.istype(vectorY,DenseVector) then
      local SparseVector = require 'stuart-ml.linalg.SparseVector'
      if class.istype(vectorX,SparseVector) then
        return M.axpy_sparse_dense(a,vectorX,vectorY)
      elseif class.istype(vectorX,DenseVector) then
        return M.axpy_sparse_dense(a,vectorX:toSparse(),vectorY)
      else
        error('axpy only supports DenseVector and SparseVector types for vectorX 2nd arg')
      end
    end
    error('axpy only supports adding to a DenseVector')
  end
  M.axpy_sparse_dense = function(a, x, y)
    local nnz = #x.indices
    if a == 1.0 then
      for k=1,nnz do
        y.values[x.indices[k]+1] = y.values[x.indices[k]+1] + x.values[k]
      end
    else
      for k=1,nnz do
        y.values[x.indices[k]+1] = y.values[x.indices[k]+1] + a * x.values[k]
      end
    end
  end
  M.dot = function(x, y)
    assert(x:size() == y:size())
    local class = require 'stuart.class'
    local istype = class.istype
    local DenseVector = require 'stuart-ml.linalg.DenseVector'
    if istype(x,DenseVector) and istype(y,DenseVector) then
      return M.dot_sparse_dense(x:toSparse(), y)
    end
    local SparseVector = require 'stuart-ml.linalg.SparseVector'
    if istype(x,SparseVector) and istype(y,DenseVector) then
        return M.dot_sparse_dense(x, y)
    elseif istype(x,DenseVector) and istype(y,SparseVector) then
        return M.dot_sparse_dense(y, x)
    elseif istype(x,SparseVector) and istype(y,SparseVector) then
        return M.dot_sparse_sparse(x, y)
    else
      error('dot only supports DenseVector and SparseVector types')
    end
  end
  M.dot_sparse_dense = function(x, y)
    local nnz = #x.indices
    local sum = 0.0
    for k=1,nnz do
      sum = sum + x.values[k] * y.values[x.indices[k]+1]
    end
    return sum
  end
  M.dot_sparse_sparse = function(x, y)
    local nnzx = #x.indices
    local nnzy = #y.indices
    local kx = 0
    local ky = 0
    local sum = 0.0
    while kx < nnzx and ky < nnzy do
      local ix = x.indices[kx+1]
      while ky < nnzy and y.indices[ky+1] < ix do
        ky = ky + 1
      end
      if ky < nnzy and y.indices[ky+1] == ix then
        sum = sum + x.values[kx+1] * y.values[ky+1]
        ky = ky + 1
      end
      kx = kx + 1
    end
    return sum
  end
  --[[ x = a * x
  --]]
  M.scal = function(a, x)
    for i=1,#x.values do
      x.values[i] = a * x.values[i]
    end
  end
  return M
end

package.preload["stuart-ml.linalg.DenseVector"] = function(...)
  local class = require 'stuart.class'
  local Vector = require 'stuart-ml.linalg.Vector'
  local DenseVector = class.new(Vector)
  function DenseVector:_init(values)
    Vector._init(self, values)
  end
  function DenseVector.__eq(a, b)
    if a:size() ~= b:size() then return false end
    local moses = require 'moses'
    return moses.same(a.values, b.values)
  end
  function DenseVector:__index(key)
    if type(key)~='number' then return rawget(getmetatable(self), key) end
    return self.values[key]
  end
  function DenseVector:__tostring()
    return '(' .. table.concat(self.values,',') .. ')'
  end
  function DenseVector:argmax()
    if self:size() == 0 then
      return -1
    else
      local maxIdx = -1
      local maxValue = self.values[1]
      for i, value in ipairs(self.values) do
        if value > maxValue then
          maxIdx = i
          maxValue = value
        end
      end
      return maxIdx
    end
  end
  function DenseVector:copy()
    local moses = require 'moses'
    return DenseVector.new(moses.clone(self.values))
  end
  function DenseVector:foreachActive(f)
    for i,value in ipairs(self.values) do
      f(i-1, value)
    end
  end
  function DenseVector:size()
    return #self.values
  end
  function DenseVector:toArray()
    return self.values
  end
  function DenseVector:toDense()
    return self
  end
  function DenseVector:toSparse()
    local ii = {}
    local vv = {}
    self:foreachActive(function(i,v)
      if v ~= 0 then
        ii[#ii+1] = i
        vv[#vv+1] = v
      end
    end)
    local SparseVector = require 'stuart-ml.linalg.SparseVector'
    return SparseVector.new(self:size(), ii, vv)
  end
  return DenseVector
end

package.preload["stuart-ml.linalg.SparseVector"] = function(...)
  local class = require 'stuart.class'
  local Vector = require 'stuart-ml.linalg.Vector'
  local SparseVector = class.new(Vector)
  -- @param indices 0-based indices
  function SparseVector:_init(size, indices, values)
    assert(#indices == #values, 'Sparse vectors require that the dimension of the '
      .. 'indices match the dimension of the values. You provided ' .. #indices .. ' indices and '
      .. #values .. ' values')
    assert(#indices <= size, 'You provided ' .. #indices .. ' indices and values, '
      .. 'which exceeds the specified vector size ' .. size)
    self._size = size
    self.indices = indices
    Vector._init(self, values)
  end
  function SparseVector.__eq(a, b)
    if a:size() ~= b:size() then return false end
    local moses = require 'moses'
    if class.istype(b,SparseVector) then
      if not moses.same(a.indices, b.indices) then return false end
      return moses.same(a.values, b.values)
    end
    
    -- This next section only runs in Lua 5.3+, and supports the equality test
    -- of a SparseVector against a DenseVector
    local DenseVector = require 'stuart-ml.linalg.DenseVector'
    if class.istype(b,DenseVector) then
      if not moses.same(a.values, b.values) then return false end
      local bIndices = moses.range(1, a:size())
      return moses.same(a.indices, bIndices)
    end
    
    return false
  end
  function SparseVector:__index(key)
    if type(key)~='number' then return rawget(getmetatable(self), key) end
    local moses = require 'moses'
    local i = moses.indexOf(self.indices, key)
    if i == nil then return 0 end
    return self.values[i]
  end
  function SparseVector:__tostring()
    return '(' .. self._size .. ',('
      .. table.concat(self.indices,',') .. '),('
      .. table.concat(self.values,',') .. '))'
  end
  function SparseVector:argmax()
    if self._size == 0 then return -1 end
    if self:numActives() == 0 then return 0 end
    -- Find the max active entry
    local maxIdx = self.indices[1]
    local maxValue = self.values[1]
    local maxJ = 0
    local na = self:numActives()
    for j=2,na do
      local v = self.values[j]
      if v > maxValue then
        maxValue = v
        maxIdx = self.indices[j]
        maxJ = j
      end
    end
    -- If the max active entry is nonpositive and there exists inactive ones, find the first zero.
    if maxValue <= 0.0 and na < self._size then
      if maxValue == 0.0 then
        -- If there exists an inactive entry before maxIdx, find it and return its index.
        if maxJ < maxIdx then
          local k = 0
          while k < maxJ and self.indices[k+1] == k do k = k + 1 end
          maxIdx = k
        end
      else
        local k = 0
        while k < na and self.indices[k+1] == k do k = k + 1 end
        maxIdx = k
      end
    end
    return maxIdx
  end
  function SparseVector:copy()
    local moses = require 'moses'
    return SparseVector.new(self._size, moses.clone(self.indices), moses.clone(self.values))
  end
  function SparseVector:foreachActive(f)
    for i,value in ipairs(self.values) do
      f(self.indices[i], value)
    end
  end
  function SparseVector:size()
    return self._size
  end
  function SparseVector:toArray()
    local moses = require 'moses'
    local data = moses.rep(0, self._size)
    for i,k in ipairs(self.indices) do
      data[k+1] = self.values[i]
    end
    return data
  end
  function SparseVector:toDense()
    local DenseVector = require 'stuart-ml.linalg.DenseVector'
    return DenseVector.new(self:toArray())
  end
  function SparseVector:toSparse()
    if self:numActives() == self:numNonzeros() then return self end
    local ii = {}
    local vv = {}
    self:foreachActive(function(i,v)
      if v ~= 0 then
        ii[#ii+1] = i
        vv[#vv+1] = v
      end
    end)
    return SparseVector.new(self:size(), ii, vv)
  end
  return SparseVector
end

package.preload["stuart-ml.linalg.Vector"] = function(...)
  local class = require 'stuart.class'
  local Vector = class.new()
  function Vector:_init(values)
    self.values = values or {}
  end
  function Vector:numActives()
    return #self.values
  end
  function Vector:numNonzeros()
    local moses = require 'moses'
    local nnz = moses.reduce(self.values, function(r,v)
      if v ~= 0 then r = r + 1 end
      return r
    end, 0)
    return nnz
  end
  return Vector
end

package.preload["stuart-ml.linalg.Vectors"] = function(...)
  local M = {}
  M.dense = function(...)
    local moses = require 'moses'
    local DenseVector = require 'stuart-ml.linalg.DenseVector'
    if moses.isTable(...) then
      return DenseVector.new(...)
    else
      return DenseVector.new({...})
    end
  end
  M.norm = function(vector, p)
    assert(p >= 1.0, 'To compute the p-norm of the vector, we require that you specify a p>=1. You specified ' .. p)
    local values = vector.values
    local size = #values
    if p == 1 then
      local sum = 0.0
      for i=1,size do
        sum = sum + math.abs(values[i])
      end
      return sum
    elseif p == 2 then
      local sum = 0.0
      for i=1,size do
        sum = sum + values[i] * values[i]
      end
      return math.sqrt(sum)
    elseif p == math.huge then
      local max = 0.0
      for i=1,size do
        local value = math.abs(values[i])
        if value > max then max = value end
      end
      return max
    else
      local sum = 0.0
      for i=1,size do
        sum = sum + math.pow(math.abs(values[i]), p)
      end
      return math.pow(sum, 1.0 / p)
    end
  end
  M.parseNumeric = function(values)
    local moses = require 'moses'
    assert(moses.isTable(values))
    if moses.all(values, function(x) return moses.isNumber(x) end) then
      return M.dense(values)
    elseif #values >= 3 and moses.isNumber(values[1]) and moses.isTable(values[2]) and moses.isTable(values[3]) then
      return M.sparse(values[1], values[2], values[3])
    else
      error('cannot parse Vector')
    end
  end
  M.sparse = function(size, arg2, arg3)
    local moses = require 'moses'
    local SparseVector = require 'stuart-ml.linalg.SparseVector'
    if arg3 == nil then -- arg2 is elements
      local elements = moses.sort(arg2, function(a,b)
        if moses.isTable(a) and moses.isTable(b) then return a[1] < b[1] end
      end)
      local unpack = table.unpack or unpack
      local unzip = require 'stuart-ml.util'.unzip
      local indices, values = unpack(unzip(elements))
  --    var prev = -1
  --    indices.foreach { i =>
  --      require(prev < i, s"Found duplicate indices: $i.")
  --      prev = i
  --    }
  --    require(prev < size, s"You may not write an element to index $prev because the declared " +
  --      s"size of your vector is $size")
      return SparseVector.new(size, indices, values)
    else -- arg2 is indices, arg3 is values
      return SparseVector.new(size, arg2, arg3)
    end
  end
  M.sqdist = function(v1, v2)
    assert(v1:size() == v2:size(), 'Vector dimensions do not match: Dim(v1)=' .. v1:size()
      .. ' and Dim(v2)=' .. v2:size())
    local class = require 'stuart.class'
    local SparseVector = require 'stuart-ml.linalg.SparseVector'
    if class.istype(v1,SparseVector) and class.istype(v2,SparseVector) then
      return M.sqdist_sparse_sparse(v1, v2)
    end
    local DenseVector = require 'stuart-ml.linalg.DenseVector'
    if class.istype(v1,SparseVector) and class.istype(v2,DenseVector) then
      return M.sqdist_sparse_dense(v1, v2)
    elseif class.istype(v1,DenseVector) and class.istype(v2,SparseVector) then
      return M.sqdist_sparse_dense(v2, v1)
    elseif class.istype(v1,DenseVector) and class.istype(v2,DenseVector) then
      local kv = 0
      local sz = #v1
      local squaredDistance = 0.0
      while kv < sz do
        local score = v1[kv+1] - v2[kv+1]
        squaredDistance = squaredDistance + score * score
        kv = kv + 1
      end
      return squaredDistance
    end
    error('sqdist only supports DenseVector and SparseVector types')
  end
  M.sqdist_sparse_sparse = function(v1, v2)
    local squaredDistance = 0.0
    local v1Values = v1.values
    local v1Indices = v1.indices
    local v2Values = v2.values
    local v2Indices = v2.indices
    local nnzv1 = #v1Indices
    local nnzv2 = #v2Indices
    local kv1 = 0
    local kv2 = 0
    while kv1 < nnzv1 or kv2 < nnzv2 do
      local score = 0.0
      if kv2 >= nnzv2 or (kv1 < nnzv1 and v1Indices[kv1+1] < v2Indices[kv2+1]) then
        score = v1Values[kv1+1]
        kv1 = kv1 + 1
      elseif kv1 >= nnzv1 or (kv2 < nnzv2 and v2Indices[kv2+1] < v1Indices[kv1+1]) then
        score = v2Values[kv2+1]
        kv2 = kv2 + 1
      else
        score = v1Values[kv1+1] - v2Values[kv2+1]
        kv1 = kv1 + 1
        kv2 = kv2 + 1
      end
      squaredDistance = squaredDistance + score * score
    end
    return squaredDistance
  end
  M.sqdist_sparse_dense = function(v1, v2)
    local kv1 = 0
    local kv2 = 0
    local indices = v1.indices
    local squaredDistance = 0.0
    local nnzv1 = #indices
    local nnzv2 = v2:size()
    local iv1 = -1; if nnzv1 > 0 then iv1 = indices[kv1+1] end
    while kv2 < nnzv2 do
      local score = 0.0
      if kv2 ~= iv1 then
        score = v2[kv2+1]
      else
        score = v1.values[kv1+1] - v2[kv2+1]
        if kv1 < nnzv1 - 1 then
          kv1 = kv1 + 1
          iv1 = indices[kv1+1]
        end
      end
      squaredDistance = squaredDistance + score * score
      kv2 = kv2 + 1
    end
    return squaredDistance
  end
  M.zeros = function(size)
    local moses = require 'moses'
    local data = moses.rep(0, size)
    local DenseVector = require 'stuart-ml.linalg.DenseVector'
    return DenseVector.new(data)
  end
  return M
end

package.preload["stuart-ml.util"] = function(...)
  local M = {}
  --- Produces a flexible list of numbers. If one positive value is passed, will count from 0 to that value,
  -- with a default step of 1. If two values are passed, will count from the first one to the second one, with the
  -- same default step of 1. A third value passed will be considered a step value.
  -- @name range
  -- @param[opt] from the initial value of the range
  -- @param[optchain] to the final value of the range
  -- @param[optchain] step the step of count
  -- @return a new array of numbers
  M.mosesPatchedRange = function(...)
    local arg = {...}
    local _start,_stop,_step
    if #arg==0 then return {}
    elseif #arg==1 then _stop,_start,_step = arg[1],0,1
    elseif #arg==2 then _start,_stop,_step = arg[1],arg[2],1
    elseif #arg == 3 then _start,_stop,_step = arg[1],arg[2],arg[3]
    end
    if (_step and _step==0) then return {} end
    
    -- BEGIN patch --------------------------------------------------------------
    if _start == 1 and _stop == 1 and _step == 1 then return {1} end
    -- END patch ----------------------------------------------------------------
    
    local _ranged = {}
    local _steps = math.max(math.floor((_stop-_start)/_step),0)
    for i=1,_steps do _ranged[#_ranged+1] = _start+_step*i end
    if #_ranged>0 then table.insert(_ranged,1,_start) end
    return _ranged
  end
  -- Moses 2.1.0-1 has a bug in zip(). This temporary fix is sourced from
  -- https://github.com/Yonaba/Moses/commit/14171d243b76c845c3a9001aee1a0e9d2056f95e
  M.mosesPatchedZip = function(...)
    local moses = require 'moses'
    local args = {...}
    local n = moses.max(args, function(array) return #array end) or 0
    local _ans = {}
    for i = 1,n do
      if not _ans[i] then _ans[i] = {} end
      for k, array in ipairs(args) do
        if (array[i]~=nil) then _ans[i][#_ans[i]+1] = array[i] end
      end
    end
    return _ans
  end
  M.tableIterator = function(table)
    local i = 0
    return function()
      i = i + 1
      if i <= #table then return table[i] end
    end
  end
  M.unzip = function(array)
    local zip = M.mosesPatchedZip
    local unpack = table.unpack or unpack
    return zip(unpack(array))
  end
  return M
end

package.preload["stuart-ml.util.MLUtils"] = function(...)
  local M = {}
  M.EPSILON = 2.2204460492503e-16
  --[[
   * Returns the squared Euclidean distance between two vectors. The following formula will be used
   * if it does not introduce too much numerical error:
   * <pre>
   *   \|a - b\|_2^2 = \|a\|_2^2 + \|b\|_2^2 - 2 a^T b.
   * </pre>
   * When both vector norms are given, this is faster than computing the squared distance directly,
   * especially when one of the vectors is a sparse vector.
   * @param v1 the first vector
   * @param norm1 the norm of the first vector, non-negative
   * @param v2 the second vector
   * @param norm2 the norm of the second vector, non-negative
   * @param precision desired relative precision for the squared distance
   * @return squared distance between v1 and v2 within the specified precision
  --]]
  M.fastSquaredDistance = function(v1, norm1, v2, norm2, precision)
    precision = precision or 1e-6
    local n = v1:size()
    assert(v2:size() == n)
    assert(norm1 >= 0.0 and norm2 >= 0.0)
    local sumSquaredNorm = norm1 * norm1 + norm2 * norm2
    local normDiff = norm1 - norm2
    local sqDist = 0.0
    local precisionBound1 = 2.0 * M.EPSILON * sumSquaredNorm / (normDiff * normDiff + M.EPSILON)
    local BLAS = require 'stuart-ml.linalg.BLAS'
    local class = require 'stuart.class'
    local Vectors = require 'stuart-ml.linalg.Vectors'
    local SparseVector = require 'stuart-ml.linalg.SparseVector'
    if precisionBound1 < precision then
      sqDist = sumSquaredNorm - 2.0 * BLAS.dot(v1, v2)
    elseif class.istype(v1,SparseVector) or class.istype(v2,SparseVector) then
      local dotValue = BLAS.dot(v1, v2)
      sqDist = math.max(sumSquaredNorm - 2.0 * dotValue, 0.0)
      local precisionBound2 = M.EPSILON * (sumSquaredNorm + 2.0 * math.abs(dotValue)) / (sqDist + M.EPSILON)
      if precisionBound2 > precision then
        sqDist = Vectors.sqdist(v1, v2)
      end
    else
      sqDist = Vectors.sqdist(v1, v2)
    end
    return sqDist
  end
  local function computeNumFeatures(rdd)
    local arrays = require 'stuart-ml.util.java.arrays'
    return rdd:map(function(e)
      local indices = e[2]
      return arrays.lastOption(indices) or 0
    end):reduce(function(r,e)
      return math.max(r,e)
    end) + 1
  end
  local function parseLibSVMRecord(line)
    local util = require 'stuart.util'
    local items = util.split(line, ' ')
    local arrays = require 'stuart-ml.util.java.arrays'
    local label = tonumber(arrays.head(items))
    local moses = require 'moses'
    local unzip = require 'stuart-ml.util'.unzip
    local y = moses.map(moses.filter(arrays.tail(items), function(s) return s:len() > 0 end), function(item)
      local indexAndValue = util.split(item, ':')
      local index = tonumber(indexAndValue[1]) - 1
      local value = tonumber(indexAndValue[2])
      return {index, value}
    end)
    local z = unzip(y)
    local indices, values = z[1] or {}, z[2] or {}
    -- check if indices are one-based and in ascending order
    local previous = -1
    for i = 1, #indices do
      local current = indices[i]
      assert(current > previous) -- indices should be one-based and in ascending order
      previous = current
    end
    return {label, indices, values}
  end
  local function parseLibSVMFile(sc, path, minPartitions)
    local function trim(s) return (s:gsub('^%s*(.-)%s*$', '%1')) end
    return sc:textFile(path, minPartitions)
      :map(function(s) return trim(s) end)
      :filter(function(line) return line:len() > 0 or line:sub(1,1) ~= '#' end)
      :map(parseLibSVMRecord)
  end
  --[[
    Loads labeled data in the LIBSVM format into an RDD[LabeledPoint].
    The LIBSVM format is a text-based format used by LIBSVM and LIBLINEAR.
    Each line represents a labeled sparse feature vector using the following format:
    {{{label index1:value1 index2:value2 ...}}}
    where the indices are one-based and in ascending order.
    @param sc Spark context
    @param path file or directory path in any Hadoop-supported file system URI
    @param numFeatures number of features, which will be determined from the input data if a
                       nonpositive value is given. This is useful when the dataset is already split
                       into multiple files and you want to load them separately, because some
                       features may not present in certain files, which leads to inconsistent
                       feature dimensions.
    @param minPartitions min number of partitions
    @return labeled data stored as an RDD[LabeledPoint]
  --]]
  M.loadLibSVMFile = function(sc, path, numFeatures, minPartitions)
    numFeatures = numFeatures or -1
    minPartitions = minPartitions or sc.defaultMinPartitions
    local parsed = parseLibSVMFile(sc, path, minPartitions)
    -- Determine number of features
    local d
    if numFeatures > 0 then
      d = numFeatures
    else
      d = computeNumFeatures(parsed)
    end
    local LabeledPoint = require 'stuart-ml.regression.LabeledPoint'
    local Vectors = require 'stuart-ml.linalg.Vectors'
    return parsed:map(function(e)
      local label, indices, values = e[1], e[2], e[3]
      return LabeledPoint.new(label, Vectors.sparse(d, indices, values))
    end)
  end
  return M
end

package.preload["stuart-ml.util.random"] = function(...)
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
end

package.preload["stuart.Context"] = function(...)
  local class = require 'stuart.class'
  local Context = class.new()
  function Context:_init(arg1, arg2, arg3, arg4)
    local SparkConf = require 'stuart.SparkConf'
    if arg1 == nil and arg2 == nil then
      self.conf = SparkConf.new()
    elseif class.istype(arg1, SparkConf) then
      self.conf = arg1
    else
      self.conf = Context._updatedConf(SparkConf.new(), arg1, arg2, arg3, arg4)
    end
    
    self.defaultParallelism = 1
    self.lastRddId = 0
    self.stopped = false
    local logging = require 'stuart.internal.logging'
    logging.logInfo('Running Stuart (Embedded Spark 2.2.0)')
  end
  function Context:appName()
    return self.conf:get('spark.app.name')
  end
  function Context:emptyRDD()
    local rdd = self:parallelize({}, 0)
    return rdd
  end
  function Context:getConf()
    return self.conf:clone()
  end
  function Context:getNextId()
    self.lastRddId = self.lastRddId + 1
    return self.lastRddId
  end
  function Context:hadoopFile(path, minPartitions)
    local fileSystemFactory = require 'stuart.fileSystemFactory'
    local fs, openPath = fileSystemFactory.createForOpenPath(path)
    if fs:isDirectory(openPath) then
      local fileStatuses = fs:listStatus(openPath)
      local lines = {}
      for _,fileStatus in ipairs(fileStatuses) do
        if fileStatus.type == 'FILE' and fileStatus.pathSuffix:sub(1,1) ~= '.' and fileStatus.pathSuffix:sub(1,1) ~= '_' then
          local uri = openPath .. '/' .. fileStatus.pathSuffix
          local content, status = fs:open(uri)
          if status and status >= 400 then error(content) end
          for line in content:gmatch('[^\r\n]+') do
            lines[#lines+1] = line
          end
        end
      end
      return self:parallelize(lines, minPartitions)
    else
      local content = fs:open(openPath)
      local lines = {}
      for line in content:gmatch('[^\r\n]+') do
        lines[#lines+1] = line
      end
      return self:parallelize(lines, minPartitions)
    end
  end
  function Context:isStopped()
    return self.stopped
  end
  function Context:makeRDD(x, numPartitions)
    return self:parallelize(x, numPartitions)
  end
  function Context:master()
    return self.conf:get('spark.master')
  end
  function Context:parallelize(x, numPartitions)
    assert(not self.stopped)
    local moses = require 'moses'
    if not moses.isNumber(numPartitions) then numPartitions = self.defaultParallelism end
    local Partition = require 'stuart.Partition'
    local RDD = require 'stuart.RDD'
    if numPartitions == 1 then
      local p = Partition.new(x, 0)
      return RDD.new(self, {p})
    end
    
    local chunks = {}
    local chunkSize = math.ceil(#x / numPartitions)
    if chunkSize > 0 then
      chunks = moses.tabulate(moses.partition(x, chunkSize))
    end
    while #chunks < numPartitions do chunks[#chunks+1] = {} end -- pad-right empty partitions
    local partitions = moses.map(chunks, function(chunk, i)
      return Partition.new(chunk, i)
    end)
    return RDD.new(self, partitions)
  end
  function Context:setLogLevel(level)
    local logging = require 'stuart.internal.logging'
    logging.log:setLevel(level)
  end
  function Context:stop()
    self.stopped = true
  end
  function Context:textFile(path, minPartitions)
    assert(not self.stopped)
    return self:hadoopFile(path, minPartitions)
  end
  function Context:union(rdds)
    local t = rdds[1]
    for i = 2, #rdds do t = t:union(rdds[i]) end
    return t
  end
  function Context._updatedConf(conf, master, appName, sparkHome)
    local res = conf:clone()
    res:setMaster(master)
    res:setAppName(appName)
    if sparkHome ~= nil then
      res:setSparkHome(sparkHome)
    end
    return res
  end
  return Context
end

package.preload["stuart.Partition"] = function(...)
  local class = require 'stuart.class'
  local Partition = class.new()
  function Partition:_init(data, index)
    self.data = data or {}
    self.index = index or 0
  end
  function Partition:_count()
    return #self.data
  end
  function Partition:_flatten()
    local moses = require 'moses'
    self.data = moses.flatten(self.data)
    return self
  end
  function Partition:_flattenValues()
    local moses = require 'moses'
    self.data = moses.reduce(self.data, function(r, e)
      local x = e[2]
      if moses.isString(x) then
        local t = {}
        x:gsub('.', function(c) t[#t+1] = c end)
        x = t
      end
      moses.map(x, function(v)
        table.insert(r, {e[1], v})
      end)
      return r
    end, {})
    return self
  end
  function Partition:_toLocalIterator()
    local i = 0
    return function()
      i = i + 1
      return self.data[i]
    end
  end
  return Partition
end

package.preload["stuart.RDD"] = function(...)
  local class = require 'stuart.class'
  local RDD = class.new()
  function RDD:_init(context, partitions)
    self.context = context
    self.id = context:getNextId()
    self.sparkContext = context
    self.partitions = partitions
  end
  function RDD:_dict()
    local moses = require 'moses'
    return moses.reduce(self:collect(), function(r, e)
      r[e[1]] = e[2]
      return r
    end, {})
  end
  function RDD:_flatten()
    for _, p in ipairs(self.partitions) do p:_flatten() end
    return self
  end
  function RDD:_flattenValues()
    for _, p in ipairs(self.partitions) do p:_flattenValues() end
    return self
  end
  function RDD:__tostring()
    return 'RDD[' .. self.id .. ']'
  end
  function RDD:aggregate(zeroValue, seqOp, combOp)
    local moses = require 'moses'
    local clone = require 'stuart.util'.clone
    return moses.reduce(self.partitions, function(r, p)
      local y = moses.reduce(p.data, seqOp, clone(zeroValue))
      return combOp(r, y)
    end, clone(zeroValue))
  end
  function RDD:aggregateByKey(zeroValue, seqOp, combOp)
    local moses = require 'moses'
    local y = moses.map(self.partitions, function(p)
      local keys = moses.uniq(moses.map(p.data, function(e) return e[1] end))
      local z = moses.reduce(keys, function(r,key)
        local valuesForKey = moses.reduce(p.data, function(r2,e)
          if e[1] == key then r2[#r2+1] = e[2] end
          return r2
        end, {})
        r[key] = moses.reduce(valuesForKey, seqOp, zeroValue)
        return r
      end, {})
      return z
    end, zeroValue)
    local keys = moses.uniq(moses.reduce(y, function(r,e) return moses.append(r, moses.keys(e)) end, {}))
    local t = moses.reduce(keys, function(r,key)
      local valuesForKey = moses.reduce(y, function(r2,e)
        for k,v in pairs(e) do
          if k == key then r2[#r2+1] = v end
        end
        return r2
      end, {})
      r[#r+1] = {key, moses.reduce(valuesForKey, combOp, 0)}
      return r
    end, {})
    return self.context:parallelize(t)
  end
  function RDD:cache()
    return self
  end
  function RDD:cartesian(other)
    local moses = require 'moses'
    local t = {}
    moses.forEach(self:collect(), function(x)
      moses.forEach(other:collect(), function(y)
        t[#t+1] = {x, y}
      end)
    end)
    return self.context:parallelize(t)
  end
  function RDD:coalesce(numPartitions, shuffle)
    local moses = require 'moses'
    if not moses.isBoolean(shuffle) then shuffle = false end
    return self.context:parallelize(self:collect(), numPartitions)
  end
  function RDD:collect(f)
    local moses = require 'moses'
    local t = moses.tabulate(self:toLocalIterator())
    if moses.isFunction(f) then
      -- reduce, not map, because Lua arrays cannot contain nil
      t = moses.reduce(t, function(r, v)
        local x = f(v)
        if x ~= nil then r[#r+1] = x end
        return r
      end, {})
    end
    return t
  end
  function RDD:collectAsMap()
    local moses = require 'moses'
    local t = moses.tabulate(self:toLocalIterator())
    -- now ensure keys are unique, since we are observing the Java Map (non-multimap) contract
    t = moses.reduce(t, function(r, v)
      r[v[1]] = v[2]
      return r
    end, {})
    return t
  end
  function RDD:combineByKey(createCombiner, mergeValue, mergeCombiners)
    local moses = require 'moses'
    assert(moses.isFunction(createCombiner))
    assert(moses.isFunction(mergeValue))
    assert(moses.isFunction(mergeCombiners))
    local y = moses.map(self.partitions, function(p)
      local keys = moses.uniq(moses.map(p.data, function(e) return e[1] end))
      local z = moses.reduce(keys, function(r,key)
        local valuesForKey = moses.reduce(p.data, function(r2,e)
          if e[1] == key then r2[#r2+1] = e[2] end
          return r2
        end, {})
        r[key] = moses.reduce(valuesForKey, mergeValue, {})
        return r
      end, {})
      return z
    end)
    local keys = moses.uniq(moses.reduce(y, function(r,e) return moses.append(r, moses.keys(e)) end, {}))
    local t = moses.reduce(keys, function(r,key)
      local valuesForKey = moses.reduce(y, function(r2,e)
        for k,v in pairs(e) do
          if k == key then r2[#r2+1] = v end
        end
        return r2
      end, {})
      r[#r+1] = {key, moses.reduce(valuesForKey, mergeCombiners, {})}
      return r
    end, {})
    return self.context:parallelize(t)
  end
  function RDD:count()
    local moses = require 'moses'
    return moses.reduce(self.partitions, function(r, p) return r + p:_count() end, 0)
  end
  function RDD:countApprox()
    return self:count()
  end
  function RDD:countByKey()
    local moses = require 'moses'
    return moses.reduce(self:collect(), function(r, e)
      local k = e[1]
      if r[k] == nil then
        r[k] = 1
      else
        r[k] = r[k] + 1
      end
      return r
    end, {})
  end
  function RDD:countByValue()
    local moses = require 'moses'
    return moses.reduce(self:collect(), function(r, n)
      if r[n] == nil then
        r[n] = 1
      else
        r[n] = r[n] + 1
      end
      return r
    end, {})
  end
  function RDD:distinct(numPartitions)
    local moses = require 'moses'
    local t = moses.uniq(self:collect())
    return self.context:parallelize(t, numPartitions)
  end
  function RDD:filter(f)
    local moses = require 'moses'
    local t = moses.filter(self:collect(), function(v) return f(v) end)
    return self.context:parallelize(t)
  end
  function RDD:filterByRange(lower, upper)
    local moses = require 'moses'
    local f = function(x)
      if moses.isTable(x) then return x[1] >= lower and x[1] <= upper end
      return false
    end
    return self:filter(f)
  end
  function RDD:first()
    return self.partitions[1].data[1]
  end
  function RDD:flatMap(f)
    return self:map(f):_flatten()
  end
  function RDD:flatMapValues(f)
    return self:mapValues(f):_flattenValues()
  end
  function RDD:fold(zeroValue, op)
    local moses = require 'moses'
    return moses.reduce(self:collect(), op, zeroValue)
  end
  function RDD:foldByKey(zeroValue, op)
    local moses = require 'moses'
    local keys = moses.unique(moses.map(self:collect(), function(e) return e[1] end))
    local t = moses.map(keys, function(k)
      local c = moses.map(self:collect(), function(e)
        if e[1] == k then return e[2] end
      end)
      return {k, moses.reduce(c, op, zeroValue)}
    end)
    return self.context:parallelize(t)
  end
  function RDD:foreach(f)
    for _, p in ipairs(self.partitions) do
      for i, _ in ipairs(p.data) do
        f(p.data[i])
      end
    end
  end
  function RDD:foreachPartition(f)
    for _, p in ipairs(self.partitions) do
      f(p.data)
    end
  end
  function RDD:glom()
    local moses = require 'moses'
    local t = moses.map(self.partitions, function(p) return p.data end)
    return self.context:parallelize(t)
  end
  function RDD:groupBy(f)
    local x = self:collect()
    local moses = require 'moses'
    local keys = moses.unique(moses.map(x, function(v) return f(v) end))
    local t = moses.map(keys, function(k)
      local v = moses.reduce(x, function(r, e)
        if f(e) == k then r[#r+1] = e end
        return r
      end, {})
      return {k, v}
    end)
    return self.context:parallelize(t)
  end
  function RDD:groupByKey(numPartitions)
    numPartitions = numPartitions or #self.partitions
    local moses = require 'moses'
    local keys = moses.keys(self:_dict())
    local t = moses.map(keys, function(k)
      local v = moses.reduce(self:collect(), function(r, e)
        if e[1] == k then r[#r+1] = e[2] end
        return r
      end, {})
      return {k, v}
    end)
    return self.context:parallelize(t, numPartitions)
  end
  function RDD:histogram(buckets)
    local moses = require 'moses'
    if moses.isNumber(buckets) then
      local num_buckets = buckets
      local min_v = self:min()
      local max_v = self:max()
      buckets = moses.map(moses.range(0, num_buckets), function(v)
        return min_v + v*(max_v-min_v)/num_buckets
      end)
      local h = self:_histogram(buckets)
      return buckets, h
    end
    local h = self:_histogram(buckets)
    return h
  end
  function RDD:_histogram(buckets)
    local num_buckets = #buckets - 1
    local moses = require 'moses'
    local h = {}; moses.fill(h, 0, 1, num_buckets)
    moses.forEach(self:collect(), function(x)
      for i = 1, num_buckets, 1 do
        local shouldAdd
        local lastBucket = i == num_buckets
        if lastBucket then -- last bucket is inclusive
          shouldAdd = x >= buckets[i] and x <= buckets[i+1]
        else
          shouldAdd = x >= buckets[i] and x < buckets[i+1]
        end
        if shouldAdd then h[i] = h[i] + 1 end
      end
    end)
    return h
  end
  function RDD:intersection(other)
    local moses = require 'moses'
    return self.context:parallelize(moses.intersection(moses.unique(self:collect()), moses.unique(other:collect())))
  end
  function RDD:isCheckpointed()
    return false
  end
  function RDD:isEmpty()
    return self:count() <= 0
  end
  function RDD:join(other)
    local moses = require 'moses'
    local keys = moses.intersection(moses.keys(self:_dict()), moses.keys(other:_dict()))
    local t = moses.reduce(keys, function(r, key)
      moses.forEach(self:collect(), function(x)
        if x[1] == key then
          moses.forEach(other:collect(), function(y)
            if y[1] == key then
              r[#r+1] = {key, {x[2], y[2]}}
            end
          end)
        end
      end)
      return r
    end, {})
    return self.context:parallelize(t, math.max(#self.partitions, #other.partitions))
  end
  function RDD:keyBy(f)
    local moses = require 'moses'
    local t = moses.map(self:collect(), function(e) return {f(e), e} end)
    return self.context:parallelize(t)
  end
  function RDD:keys()
    local moses = require 'moses'
    local t = moses.map(self:collect(), function(e) return e[1] end)
    return self.context:parallelize(t)
  end
  function RDD:leftOuterJoin(other)
    local moses = require 'moses'
    local t = moses.reduce(self:collect(), function(r, e)
        local right = {}
        moses.forEach(other:collect(), function(y)
          if y[1] == e[1] then right[#right+1] = y[2] end
        end)
        if #right == 0 then
          r[#r+1] = {e[1], {e[2], nil}}
        else
          moses.forEach(right, function(z)
            r[#r+1] = {e[1], {e[2], z}}
          end)
        end
      return r
    end, {})
    return self.context:parallelize(t)
  end
  function RDD:lookup(key)
    local moses = require 'moses'
    return moses.reduce(self:collect(), function(r, e)
      if e[1] == key then r[#r+1] = e[2] end
      return r
    end, {})
  end
  function RDD:map(f)
    local t = {}
    for e in self:toLocalIterator() do t[#t+1] = f(e) end
    return self.context:parallelize(t, #self.partitions)
  end
  function RDD:mapPartitions(iter)
    local moses = require 'moses'
    local t = moses.reduce(self.partitions, function(r,p)
      for e in iter(p:_toLocalIterator()) do
        r[#r+1] = e
      end
      return r
    end, {})
    return self.context:parallelize(t)
  end
  function RDD:mapPartitionsWithIndex(iter)
    local index = 0
    local moses = require 'moses'
    local t = moses.reduce(self.partitions, function(r,p)
      for e in iter(index, p:_toLocalIterator()) do
        r[#r+1] = e
      end
      index = index + 1
      return r
    end, {})
    return self.context:parallelize(t)
  end
  function RDD:mapValues(f)
    local moses = require 'moses'
    local t = moses.map(self:collect(), function(e) return {e[1], f(e[2])} end)
    return self.context:parallelize(t)
  end
  function RDD:max()
    local r = self:first()
    for n in self:toLocalIterator() do
      if n > r then r = n end
    end
    return r
  end
  function RDD:mean()
    return self:stats().mean
  end
  RDD.meanApprox = RDD.mean
  function RDD:min()
    local r = self:first()
    for n in self:toLocalIterator() do
      if n < r then r = n end
    end
    return r
  end
  function RDD:popStdev()
    return self:stats().popStdev
  end
  function RDD:popVariance()
    return self:stats().popVariance
  end
  function RDD:reduce(f)
    local moses = require 'moses'
    return moses.reduce(self:collect(), f)
  end
  function RDD:reduceByKey(f)
    local moses = require 'moses'
    return self:groupByKey():mapValues(function(e) return moses.reduce(e, f) end)
  end
  function RDD:repartition(numPartitions)
    return self:coalesce(numPartitions, true)
  end
  function RDD:rightOuterJoin(other)
    local moses = require 'moses'
    local t = moses.reduce(other:collect(), function(r, e)
        local left = {}
        moses.forEach(self:collect(), function(y)
          if y[1] == e[1] then left[#left+1] = y[2] end
        end)
        if #left == 0 then
          r[#r+1] = {e[1], {nil, e[2]}}
        else
          moses.forEach(left, function(z)
            r[#r+1] = {e[1], {z, e[2]}}
          end)
        end
      return r
    end, {})
    return self.context:parallelize(t)
  end
  function RDD:sample(_, fraction, seed)
    assert(fraction >= 0, 'Fraction must be nonnegative, but got ' .. fraction)
    local t = self:collect()
    local n = math.max(1, #t * fraction)
    if n > #t then return {} end
    local moses = require 'moses'
    local r = moses.sample(self:collect(), n, seed)
    return self.context:parallelize(r)
  end
  function RDD:sampleStdev()
    return self:stats().stdev
  end
  function RDD:sampleVariance()
    return self:stats().variance
  end
  function RDD:setName(name)
    self.name = name
  end
  function RDD:sortBy(f, ascending, numPartitions)
    local moses = require 'moses'
    if not moses.isBoolean(ascending) then ascending = true end
    local t = self:collect()
    local comp
    if ascending then
      comp = function(a,b) return a<b end
    else
      comp = function(a,b) return a>b end
    end
    t = moses.sortBy(t, f, comp)
    return self.context:parallelize(t, numPartitions)
  end
  function RDD:sortByKey(ascending, numPartitions)
    local moses = require 'moses'
    if not moses.isBoolean(ascending) then ascending = true end
    if not moses.isNumber(numPartitions) then numPartitions = #self.partitions end
    local f = function(a,b)
      if not moses.isTable(a) or not moses.isTable(b) then return 0 end
      if ascending then
        return a[1] < b[1]
      else
        return a[1] > b[1]
      end
    end
    local t = moses.sort(self:collect(), f)
    return self.context:parallelize(t, numPartitions)
  end
  function RDD:stats()
    local x = self:collect()
    -- calculate mean
    local moses = require 'moses'
    local r = moses.reduce(x, function(r, v)
      r.count = r.count + 1
      r.sum = r.sum + v
      return r
    end, {count=0, sum=0})
    r.mean = r.sum / r.count
    r.sum = nil
    -- calculate sum of distances from mean squared
    local sumDistances = moses.reduce(x, function(p, v)
      local distance = v - r.mean
      p = p + distance * distance
      return p
    end, 0)
    if r.count < 2 then
      -- avoid divide by zero and answer is zero for 1 item
      r.popStdev = 0
      r.popVariance = 0
      r.stdev = 0
      r.variance = 0
      return r
    end
    -- 'Sample' variance/stdev divide sum by N - 1 (Bessel's correction)
    r.variance = sumDistances/(r.count - 1)
    r.stdev = math.sqrt(r.variance)
    -- 'Population' variance/stdev divide sum by number of data points
    r.popVariance = sumDistances/r.count
    r.popStdev = math.sqrt(r.popVariance)
    return r
  end
  RDD.stdev = RDD.popStdev
  function RDD:subtract(other)
    local moses = require 'moses'
    local t = moses.without(self:collect(), other:collect())
    return self.context:parallelize(t, #self.partitions)
  end
  function RDD:subtractByKey(other)
    local selfKeys = self:keys():collect()
    local otherKeys = other:keys():collect()
    local moses = require 'moses'
    local keys = moses.without(selfKeys, otherKeys)
    local t = moses.reduce(self:collect(), function(r, e)
      if moses.detect(keys, e[1]) ~= nil then r[#r+1] = e end
      return r
    end, {})
    return self.context:parallelize(t, #self.partitions)
  end
  function RDD:sum()
    local moses = require 'moses'
    return moses.reduce(self:collect(), function(r, v) return r+v end, 0)
  end
  function RDD:sumApprox()
    return self:sum()
  end
  function RDD:take(n)
    local iter = self:toLocalIterator()
    local t = {}
    for i = 1, n, 1 do
      local x = iter()
      if x == nil then break end
      t[#t+1] = x
    end
    return t
  end
  function RDD:takeSample(withReplacement, num, seed)
    assert(num >= 0, 'Negative number of elements requested')
    if num == 0 then return {} end
    local initialCount = self:count()
    if initialCount == 0 then return {} end
    if seed ~= nil then math.randomseed(seed) end
    local randomizeInPlace = require 'stuart.util.spark'.randomizeInPlace
    if not withReplacement and num >= initialCount then
      return randomizeInPlace(self:collect())
    end
    local samplingUtils = require 'stuart.util.spark.samplingUtils'
    local fraction = samplingUtils.computeFractionForSampleSize(num, initialCount, withReplacement)
    local samples = self:sample(withReplacement, fraction, math.random(32000)):collect()
    -- If the first sample didn't turn out large enough, keep trying to take samples;
    -- this shouldn't happen often because we use a big multiplier for the initial size
    local numIters = 0
    while #samples < num do
      local log = require 'stuart.internal.logging'.log
      log:warn('Needed to re-sample due to insufficient sample size. Repeat #' .. numIters)
      samples = self:sample(withReplacement, fraction, math.random(32000)):collect()
      numIters = numIters + 1
    end
    local moses = require 'moses'
    return moses.first(randomizeInPlace(samples), num)
  end
  function RDD:toLocalIterator()
    local pIndex = 1
    local i = 0
    local moses = require 'moses'
    return function()
      if pIndex > #self.partitions then return nil end
      local partitionData = self.partitions[pIndex].data
      if not moses.isTable(partitionData) then return nil end
      i = i + 1
      if i > #partitionData then
        pIndex = pIndex + 1
        i = 1
        if pIndex > #self.partitions then return nil end
        partitionData = self.partitions[pIndex].data
      end
      if pIndex <= #self.partitions and i <= #partitionData then
        return partitionData[i]
      end
    end
  end
  function RDD:top(num)
    local moses = require 'moses'
    local t = moses.sort(self:collect(), function(a,b) return a>b end)
    return moses.slice(t, 1, num)
  end
  RDD.toString = RDD.__tostring
  function RDD:treeAggregate(zeroValue, seqOp, combOp)
    local clone = require 'stuart.util'.clone
    local moses = require 'moses'
    local partiallyAggregated = moses.map(self.partitions, function(p)
      return moses.reduce(p.data, seqOp, clone(zeroValue))
    end)
    return moses.reduce(partiallyAggregated, combOp)
  end
  RDD.treeReduce = RDD.reduce
  function RDD:union(other)
    local moses = require 'moses'
    local t = moses.append(self:collect(), other:collect())
    return self.context:parallelize(t)
  end
  function RDD:values()
    local moses = require 'moses'
    local t = moses.map(self:collect(), function(e) return e[2] end)
    return self.context:parallelize(t)
  end
  RDD.variance = RDD.popVariance
  function RDD:zip(other)
    local moses = require 'moses'
    local t = moses.zip(self:collect(), other:collect())
    return self.context:parallelize(t)
  end
  function RDD:zipWithIndex()
    local moses = require 'moses'
    local t = moses.map(self:collect(), function(x,i)
      return {x,i-1}
    end)
    return self.context:parallelize(t)
  end
  return RDD
end

package.preload["stuart.SparkConf"] = function(...)
  local class = require 'stuart.class'
  local SparkConf = class.new()
  function SparkConf:_init()
    self.settings = {}
  end
  function SparkConf:appName()
    return self:get('spark.app.name')
  end
  function SparkConf:clone()
    local cloned = SparkConf.new()
    local moses = require 'moses'
    cloned.settings = moses.clone(self.settings)
    return cloned
  end
  function SparkConf:contains(key)
    return self.settings[key] ~= nil
  end
  function SparkConf:get(key, defaultValue)
    return self.settings[key] or defaultValue
  end
  SparkConf.getOption = SparkConf.get
  function SparkConf:getAppId()
    return self:get('spark.app.id')
  end
  function SparkConf:getAll()
    local t = {}
    for k,v in pairs(self.settings) do
      t[#t+1] = {k, v}
    end
    return t
  end
  function SparkConf:getBoolean(key, defaultValue)
    local s = self.settings[key]
    if s == 'true' then return true end
    if s == 'false' then return false end
    return defaultValue
  end
  function SparkConf:master()
    return self:get('spark.master')
  end
  function SparkConf:remove(key)
    self.settings[key] = nil
    return self
  end
  function SparkConf:set(key, value)
    assert(key ~= nil)
    assert(value ~= nil)
    
    self.settings[key] = value
    return self
  end
  function SparkConf:setAll(settings)
    for _,setting in ipairs(settings) do
      local k,v = setting[1], setting[2]
      self:set(k,v)
    end
    return self
  end
  function SparkConf:setAppName(name)
    self:set('spark.app.name', name)
    return self
  end
  function SparkConf:setIfMissing(key, value)
    if self.settings[key] == nil then
      self.settings[key] = value
    end
    return self
  end
  function SparkConf:setMaster(master)
    self:set('spark.master', master)
    return self
  end
  function SparkConf:setSparkHome(home)
    self:set('spark.home', home)
    return self
  end
  function SparkConf:toDebugString()
    local s = ''
    for k,v in pairs(self.settings) do
      s = s .. k .. '=' .. v .. '\n'
    end
    return s
  end
  return SparkConf
end

package.preload["stuart.class"] = function(...)
  -- adapted from https://github.com/stevedonovan/Microlight#classes (MIT License)
  -- external API adapted roughly to https://github.com/torch/class
  local M = {}
  function M.istype(obj, super)
    return super.classof(obj)
  end
  function M.new(base)
    local klass, base_ctor = {}
    if base then
      for k,v in pairs(base) do klass[k]=v end
      klass._base = base
      base_ctor = rawget(base,'_init') or function() end
    end
    klass.__index = klass
    klass._class = klass
    klass.classof = function(obj)
      local m = getmetatable(obj) -- an object created by class() ?
      if not m or not m._class then return false end
      while m do -- follow the inheritance chain
        if m == klass then return true end
        m = rawget(m,'_base')
      end
      return false
    end
    klass.new = function(...)
      local obj = setmetatable({},klass)
      if rawget(klass,'_init') then
        klass.super = base_ctor
        local res = klass._init(obj,...) -- call our constructor
        if res then -- which can return a new self..
          obj = setmetatable(res,klass)
        end
      elseif base_ctor then -- call base ctor automatically
          base_ctor(obj,...)
      end
      return obj
    end
    --setmetatable(klass, {__call=klass.new})
    return klass
  end
  return M
end

package.preload["stuart.interface"] = function(...)
  local M = {}
  M.clockPrecision = function()
    local has_luasocket, _ = pcall(require, 'socket')
    if has_luasocket then
      return 4
    elseif os ~= nil then
      return 0 -- 0==whole seconds
    else
      error('No clock capability')
    end
  end
  M.now = function()
    local has_luasocket, socket = pcall(require, 'socket')
    if has_luasocket then
      return socket.gettime()
    elseif os ~= nil then
      return os.time(os.date('*t'))
    else
      error('No clock capability')
    end
  end
  M.sleep = function(duration)
    local has_luasocket, socket = pcall(require, 'socket')
    if has_luasocket then
      return socket.sleep(duration)
    end
    -- This environment is not capable of sleeping. Spark Streaming control loops
    -- will peg the CPU.
  end
  return M
end

package.preload["stuart.internal.Logger"] = function(...)
  local class = require 'stuart.class'
  -- log4j, roughly
  local FATAL = 50000
  local ERROR = 40000
  local WARN = 30000
  local INFO = 20000
  local DEBUG = 10000
  local TRACE = 0
  local levelName = {
    [FATAL] = 'FATAL',
    [ERROR] = 'ERROR',
    [WARN] = 'WARN',
    [INFO] = 'INFO',
    [DEBUG] = 'DEBUG',
    [TRACE] = 'TRACE'
  }
  local Logger = class.new()
  Logger.FATAL = FATAL
  Logger.ERROR = ERROR
  Logger.WARN = WARN
  Logger.INFO = INFO
  Logger.DEBUG = DEBUG
  Logger.TRACE = TRACE
  function Logger:_init()
    self.level = INFO
  end
  function Logger:debug(msg)
    if self.level <= DEBUG then
      self:log{level=DEBUG, message=msg}
    end
  end
  function Logger:error(msg)
    if self.level <= ERROR then
      self:log{level=ERROR, message=msg}
    end
  end
  function Logger:info(msg)
    if self.level <= INFO then
      self:log{level=INFO, message=msg}
    end
  end
  function Logger:log(event)
    local s = {levelName[event.level], event.message}
    if io ~= nil then
      io.stderr:write(table.concat(s,' ') .. '\n')
    else
      print(table.concat(s,' ') .. '\n')
    end
  end
  function Logger:setLevel(level)
    self.level = level
  end
  function Logger:trace(msg)
    if self.level <= TRACE then
      self:log{level=TRACE, message=msg}
    end
  end
  function Logger:warn(msg)
    if self.level <= WARN then
      self:log{level=WARN, message=msg}
    end
  end
  return Logger
end

package.preload["stuart.internal.logging"] = function(...)
  local Logger = require 'stuart.internal.Logger'
  local M = {log=Logger.new()}
  function M.logInfo(msg)
    M.log:info(msg)
  end
  function M.logDebug(msg)
    M.log:debug(msg)
  end
  function M.logTrace(msg)
    M.log:trace(msg)
  end
  function M.logWarning(msg)
    M.log:warn(msg)
  end
  function M.logError(msg)
    M.log:error(msg)
  end
  return M
end

package.preload["stuart.util.spark"] = function(...)
  local M = {}
  M.randomizeInPlace = function(arr)
    for i = #arr-1, 1, -1 do
      local j = math.random(i+1)
      local tmp = arr[j]
      arr[j] = arr[i]
      arr[i] = tmp
    end
    return arr
  end
    
  return M
end

package.preload["stuart.util.spark.samplingUtils"] = function(...)
  local M = {}
  local function binomialGetUpperBound(delta, n, fraction)
    local binomialMinSamplingRate = 1e-10
    local gamma = - math.log(delta) / n
    return math.min(1,
      math.max(binomialMinSamplingRate, fraction + gamma + math.sqrt(gamma * gamma + 2 * gamma * fraction)))
  end
  local function poissonNumStd(s)
    if s < 6.0 then return 12.0 end
    if s < 16.0 then return 9.0 end
    return 6.0
  end
  local function poissonGetUpperBound(s)
    return math.max(s + poissonNumStd(s) * math.sqrt(s), 1e-10)
  end
  M.computeFractionForSampleSize = function(sampleSizeLowerBound, total, withReplacement)
    if withReplacement then
      return poissonGetUpperBound(sampleSizeLowerBound) / total
    else
      local fraction = sampleSizeLowerBound / total
      return binomialGetUpperBound(1e-4, total, fraction)
    end
  end
  return M
end


local KMeans = require 'stuart-ml.clustering.KMeans'
local KMeansModel = require 'stuart-ml.clustering.KMeansModel'
local stuart = require 'stuart'
local Vectors = require 'stuart-ml.linalg.Vectors'
local VectorWithNorm = require 'stuart-ml.clustering.VectorWithNorm'

local sc = stuart.NewContext('local[1]', 'K-means')

local points = {
  Vectors.dense(0.0, 0.0),
  Vectors.dense(0.0, 0.1),
  Vectors.dense(0.1, 0.0),
  Vectors.dense(9.0, 0.0),
  Vectors.dense(9.0, 0.2),
  Vectors.dense(9.2, 0.0)
}
local rdd = sc:parallelize(points, 1)

local k = 2
local maxIterations = 5
local model = KMeans.train(rdd, k, maxIterations, KMeans.K_MEANS_PARALLEL)

print()
print('Model:', model)
for i, center in ipairs(model.clusterCenters) do
  print(string.format('  center %d %s', i, tostring(center)))
end

print()
print('Predicts:')
local predicts = model:predict(rdd):collect()
for i, predict in ipairs(predicts) do
  local msg = string.format(
    '  point %s\t==> center %d %s', tostring(points[i]), predict, tostring(model.clusterCenters[predict])
  )
  print(msg)
end
