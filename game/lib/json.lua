-- Minimal JSON decoder for Lua 5.1
-- Decode only — no encoder needed.
-- Handles: objects, arrays, strings, numbers, booleans, null.

local json = {}

-- Forward declaration
local decode

local function skip(s, i)
  -- Skip whitespace; return first non-whitespace position
  local j = s:find('[^ \t\r\n]', i)
  return j or i
end

local function decode_string(s, i)
  assert(s:sub(i, i) == '"', "Expected '\"' at pos " .. i)
  i = i + 1
  local buf = {}
  local escapes = {
    ['"']='"', ['\\']='\\', ['/']=   '/',
    b='\b', f='\f', n='\n', r='\r', t='\t',
  }
  while i <= #s do
    local c = s:sub(i, i)
    if c == '"' then
      return table.concat(buf), i + 1
    elseif c == '\\' then
      local e = s:sub(i + 1, i + 1)
      if escapes[e] then
        buf[#buf + 1] = escapes[e]
        i = i + 2
      elseif e == 'u' then
        buf[#buf + 1] = '?'   -- simplified: skip unicode escapes
        i = i + 6
      else
        error("Unknown escape \\" .. e .. " at pos " .. i)
      end
    else
      buf[#buf + 1] = c
      i = i + 1
    end
  end
  error("Unterminated string")
end

local function decode_number(s, i)
  local num = s:match('^-?%d+%.?%d*[eE]?[+-]?%d*', i)
  assert(num, "Expected number at pos " .. i)
  return tonumber(num), i + #num
end

local function decode_array(s, i)
  assert(s:sub(i, i) == '[')
  i = skip(s, i + 1)
  local t = {}
  if s:sub(i, i) == ']' then return t, i + 1 end
  while true do
    local v
    v, i = decode(s, i)
    t[#t + 1] = v
    i = skip(s, i)
    local c = s:sub(i, i)
    if c == ']' then return t, i + 1 end
    assert(c == ',', "Expected ',' or ']' at pos " .. i)
    i = skip(s, i + 1)
  end
end

local function decode_object(s, i)
  assert(s:sub(i, i) == '{')
  i = skip(s, i + 1)
  local t = {}
  if s:sub(i, i) == '}' then return t, i + 1 end
  while true do
    local k
    k, i = decode_string(s, i)
    i = skip(s, i)
    assert(s:sub(i, i) == ':', "Expected ':' at pos " .. i)
    i = skip(s, i + 1)
    local v
    v, i = decode(s, i)
    t[k] = v
    i = skip(s, i)
    local c = s:sub(i, i)
    if c == '}' then return t, i + 1 end
    assert(c == ',', "Expected ',' or '}' at pos " .. i)
    i = skip(s, i + 1)
  end
end

decode = function(s, i)
  i = skip(s, i)
  local c = s:sub(i, i)
  if     c == '"' then return decode_string(s, i)
  elseif c == '{' then return decode_object(s, i)
  elseif c == '[' then return decode_array(s, i)
  elseif c == 't' then
    assert(s:sub(i, i + 3) == 'true')
    return true, i + 4
  elseif c == 'f' then
    assert(s:sub(i, i + 4) == 'false')
    return false, i + 5
  elseif c == 'n' then
    assert(s:sub(i, i + 3) == 'null')
    return nil, i + 4
  else
    return decode_number(s, i)
  end
end

function json.decode(s)
  local value = decode(s, 1)
  return value
end

return json
