--- Internal utilities for the offspring library.
--- @class offspring.utils
local utils = {}

--- Convert the given value to a string, ignoring any __tostring metamethod.
--- @param value any
--- @return string
--- @nodiscard
function utils.rawtostring(value)
  if type(value) == "table" then
    local mt = getmetatable(value)
    local rawString = tostring(setmetatable(value, nil))
    setmetatable(value, mt)
    return rawString
  end
  return tostring(value)
end

--- Split a string at the first occurance of the given delimiter string.
--- @param str string
--- @param delimiter string
--- @return string # First part, or input string if delimiter is not found
--- @return string # Second part, or empty string if delimiter is not found
--- @nodiscard
function utils.splitFirst(str, delimiter)
  local start, stop = str:find(delimiter, 1, true)
  if start ~= nil then
    return str:sub(1, start - 1), str:sub(stop + 1)
  end
  return str, ""
end

return utils