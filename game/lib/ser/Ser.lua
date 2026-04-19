-- Ser.lua — Lua table serializer
-- Serializes a Lua value to a loadable string.
-- Ser(value) returns a string; load(Ser(value))() returns the original value.
-- Supports: nil, boolean, number, string, table (non-circular, string/integer keys)

local Ser

local function serialize(val, seen)
  local t = type(val)
  if t == "nil" then
    return "nil"
  elseif t == "boolean" then
    return tostring(val)
  elseif t == "number" then
    if val ~= val then return "0/0"
    elseif val ==  math.huge then return "math.huge"
    elseif val == -math.huge then return "-math.huge"
    else return string.format("%.17g", val)
    end
  elseif t == "string" then
    return string.format("%q", val)
  elseif t == "table" then
    assert(not seen[val], "Ser: circular reference detected")
    seen[val] = true
    local parts = {}
    local next_index = 1
    for i, v in ipairs(val) do
      parts[#parts + 1] = serialize(v, seen)
      next_index = i + 1
    end
    for k, v in pairs(val) do
      local skip = type(k) == "number" and k >= 1 and k < next_index and k == math.floor(k)
      if not skip then
        local key
        if type(k) == "string" and k:match("^[%a_][%w_]*$") then
          key = k
        else
          key = "[" .. serialize(k, seen) .. "]"
        end
        parts[#parts + 1] = key .. " = " .. serialize(v, seen)
      end
    end
    seen[val] = nil
    return "{" .. table.concat(parts, ", ") .. "}"
  else
    error("Ser: cannot serialize type '" .. t .. "'")
  end
end

Ser = function(val)
  return "return " .. serialize(val, {})
end

return Ser
