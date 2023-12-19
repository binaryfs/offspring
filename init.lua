local BASE = (...):gsub("init$", ""):gsub("([^%.])$", "%1%.")

--- @type offspring.Object
local Object = require(BASE .. "Object")
--- @type offspring.utils
local utils = require(BASE .. "utils")

local enumRegistry = {}

--- Class and type checking library for LÖVE.
--- @class offspring
local offspring = {
  _NAME = "Offspring",
  _DESCRIPTION = "Class and type checking library for the LÖVE framework",
  _VERSION = "1.0.0",
  _URL = "https://github.com/binaryfs/offspring",
  _LICENSE = [[
    MIT License

    Copyright (c) 2023 Fabian Staacke

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
  ]],
}

--- The table keys listed here will not be inherited.
offspring.excludedFromInheritance = {
  __typename = true,
  __typemap = true,
  _init = true,
  new = true,
}

offspring.Object = Object

--- @param child table
--- @param parent table
--- @package
local function inheritClass(child, parent)
  offspring.assertArgument(1, child, "table")
  offspring.assertArgument(2, parent, "table")

  for key, value in pairs(parent) do
    if not offspring.excludedFromInheritance[key] then
      child[key] = value
    end
  end

  for key in pairs(parent.__typemap) do
    child.__typemap[key] = true
  end
end

--- @param t table
--- @param key string
--- @package
local function enumIndex(t, key)
  error(string.format("Key %s does not exist in enum %s", key, getmetatable(t).__typename))
end

--- @param t table
--- @param key string
--- @package
local function enumNewindex(t, key)
  error(string.format("Attempt to extend enum %s with key %s", getmetatable(t).__typename, key))
end

--- @param enumName string
--- @param value any
--- @return boolean
--- @nodiscard
--- @package
local function enumContainsValue(enumName, value)
  local enum = enumRegistry[enumName]

  if enum then
    for _, enumValue in pairs(enum) do
      if enumValue == value then
        return true
      end
    end
  end

  return false
end

--- Internal function to determine if a value is of a particular type.
--- @param value any
--- @param typename string
--- @return boolean
--- @nodiscard
--- @package
local function typeOf(value, typename)
  local valueType = type(value)

  if valueType == typename then
    return true
  end

  if (valueType == "table" or valueType == "userdata") and type(value.typeOf) == "function" then
    return value:typeOf(typename)
  end

  return enumContainsValue(typename, value)
end

--- Create a new class.
--- @param name string The name of the class
--- @param ... table Optional base classes to inherit from
--- @return table newClass
--- @nodiscard
function offspring.class(name, ...)
  offspring.assertArgument(1, name, "string")

  local newClass = {
    __typename = name,
    __typemap = {[name] = true},
  }

  local parents = {...}

  if #parents == 0 then
    table.insert(parents, Object)
  end

  for index = 1, #parents do
    inheritClass(newClass, parents[index])
  end

  if type(newClass.__index) ~= "function" then
    newClass.__index = newClass
  end

  offspring.classCreated(newClass, parents)

  return newClass
end

--- This function is called whenever a new class is created via `offspring.class`.
--- Override it to customize the class creation process.
--- @param newClass table
--- @param parentClasses table
function offspring.classCreated(newClass, parentClasses)
end

--- Make an enumeration from the specified table.
---
--- Raises an error if the enum is already defined.
--- @param name string Enumeration name
--- @param t table
--- @return table t
function offspring.enum(name, t)
  offspring.assertArgument(1, name, "string")
  offspring.assertArgument(2, t, "table")
  assert(not enumRegistry[name], string.format("Enum %s is already defined!", name))

  enumRegistry[name] = t

  return setmetatable(t, {
    __typename = name,
    __index = enumIndex,
    __newindex = enumNewindex,
  })
end

--- Get the type of the given value as a string.
---
--- In contrast to Lua's `type` function this function can also detect LÖVE objects and
--- objects created from Offspring classes.
--- @param value any
--- @return string typename
--- @nodiscard
function offspring.type(value)
  local typename = type(value)

  if (typename == "table" or typename == "userdata") and type(value.type) == "function" then
    return value:type()
  end

  return typename
end

--- Check if a value is of a particular type.
---
--- THe `typename` parameter can be a specific type or a union type, e.g. `string|number`.
--- @param value any
--- @param typename string
--- @return boolean
--- @nodiscard
function offspring.typeOf(value, typename)
  repeat
    local firstType, otherTypes = utils.splitFirst(typename, "|")
    if typeOf(value, firstType) then
      return true
    end
    typename = otherTypes
  until typename == ""

  return false
end


--- Raise an error if the value has not the specified type.
---
--- `expectedType` can be a specific type or a union type, e.g. `string|number`.
--- @param value any The value to check
--- @param expectedType string The expected type of the value
--- @param name? string How to name the value in the error message (default: no name)
--- @param level? integer The error level (default: 2)
--- @return any value The input value
function offspring.assertType(value, expectedType, name, level)
  -- Increase level by 1 to take this function into account.
  level = level and level + 1 or 2

  if not offspring.typeOf(value, expectedType) then
    error(
      string.format(
        "The type%s should be '%s' but was '%s'",
        name and " of " .. name or "",
        expectedType,
        offspring.type(value)
      ),
      level
    )
  end

  return value
end

--- Raise an error if a function argument has not the specified type.
---
--- The `expectedType` parameter can be a specific type or a union type, e.g. `string|number`.
--- @param index integer The index of the argument, starting with 1
--- @param value any The value of the argument
--- @param expectedType string The expected type of the argument
--- @return any value The input value
function offspring.assertArgument(index, value, expectedType)
  if not offspring.typeOf(value, expectedType) then
    error(
      string.format(
        "The type of argument #%d was expected to be '%s' but was '%s'",
        index,
        expectedType,
        offspring.type(value)
      ),
      3
    )
  end

  return value
end

return offspring