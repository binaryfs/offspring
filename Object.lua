local BASE = (...):gsub("[^%.]*$", "")

--- @type offspring.utils
local utils = require(BASE .. "utils")

--- This is the abstract base class for all Offspring classes.
--- @class offspring.Object
--- @field protected __typename string
--- @field protected __typemap table
local Object = {
  __typename = "offspring.Object",
  __typemap = {["offspring.Object"] = true},
}

--- Get the class table that was used to create the object.
--- @return table
--- @nodiscard
function Object:class()
  return getmetatable(self)
end

--- Get the type of the object as a string.
--- @return string typename
--- @nodiscard
function Object:type()
  return self.__typename
end

--- Determine if the object is of a certain type.
--- @param typename string
--- @return boolean
--- @nodiscard
function Object:typeOf(typename)
  return self.__typemap[typename] == true
end

--- @return string
function Object:__tostring()
  return string.format("%s instance (%s)", self.__typename, utils.rawtostring(self))
end

return Object