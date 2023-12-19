-- This LÖVE demo is used to run unit tests.

local offspring = require("init")
local utils = require("utils")

local ClassA = offspring.class("ClassA")

function ClassA.new()
  return setmetatable({}, ClassA)
end

function ClassA:sayHello()
  return string.format("Hello from %s", self:type())
end

local ClassB = offspring.class("ClassB", ClassA)

function ClassB.new()
  return setmetatable({}, ClassB)
end

local ClassC = offspring.class("ClassC", ClassA)

function ClassC.new()
  return setmetatable({}, ClassC)
end

local ClassD = offspring.class("ClassD", ClassB, ClassC)

function ClassD.new()
  return setmetatable({}, ClassD)
end

function ClassD:sayHello()
  return "Hello world"
end

local Color = offspring.enum("Color", {
  RED = "red",
  GREEN = "green",
  BLUE = "blue",
})

local tests = {
  utilsSplitFirst = {
    function ()
      local first, second = utils.splitFirst("foo|bar", "|")
      assert(first == "foo")
      assert(second == "bar")
    end,
    function ()
      local first, second = utils.splitFirst("|foo", "|")
      assert(first == "")
      assert(second == "foo")
    end,
    function ()
      local first, second = utils.splitFirst("foo|", "|")
      assert(first == "foo")
      assert(second == "")
    end,
    function ()
      local first, second = utils.splitFirst("foo", "|")
      assert(first == "foo")
      assert(second == "")
    end,
  },
  offspringType = {
    function ()
      assert(offspring.type(123) == "number")
      assert(offspring.type({123}) == "table")
      assert(offspring.type("abc") == "string")
      assert(offspring.type(nil) == "nil")
    end,
    function ()
      assert(offspring.type(love.graphics.newMesh(3)) == "Mesh")
    end,
    function ()
      assert(offspring.type(ClassA.new()) == "ClassA")
      assert(offspring.type(ClassD.new()) == "ClassD")
    end,
  },
  offspringTypeOf = {
    function ()
      assert(offspring.typeOf(123, "number") == true)
      assert(offspring.typeOf(123, "string") == false)
      assert(offspring.typeOf({}, "table") == true)
      assert(offspring.typeOf(false, "nil") == false)
    end,
    function ()
      -- Union types
      assert(offspring.typeOf(123, "number|string") == true)
      assert(offspring.typeOf("abc", "number|string") == true)
      assert(offspring.typeOf({}, "number|string") == false)
    end,
    function ()
      -- LÖVE types
      local mesh = love.graphics.newMesh(3)
      assert(offspring.typeOf(mesh, "Mesh") == true)
      assert(offspring.typeOf(mesh, "Object") == true)
      assert(offspring.typeOf(mesh, "Mesh|Object") == true)
      assert(offspring.typeOf(mesh, "Image") == false)
      assert(offspring.typeOf(mesh, "Image|Object") == true)
      assert(offspring.typeOf(mesh, "userdata") == true)
    end,
    function ()
      -- Offspring types
      assert(offspring.typeOf(ClassA.new(), "ClassA") == true)
      assert(offspring.typeOf(ClassB.new(), "ClassB") == true)
      assert(offspring.typeOf(ClassB.new(), "ClassA") == true)
      assert(offspring.typeOf(ClassB.new(), "ClassA|ClassB") == true)
      assert(offspring.typeOf(ClassB.new(), "ClassC") == false)
      assert(offspring.typeOf(ClassB.new(), "ClassC|ClassA") == true)
      assert(offspring.typeOf(ClassD.new(), "offspring.Object") == true)
      assert(offspring.typeOf(ClassA.new(), "table") == true)
    end,
    function ()
      -- Enums
      assert(offspring.typeOf("red", "Color") == true)
      assert(offspring.typeOf(Color.GREEN, "Color") == true)
      assert(offspring.typeOf("black", "Color") == false)
    end,
  },
  inheritance = {
    function ()
      assert(ClassA.new():sayHello() == "Hello from ClassA")
      assert(ClassC.new():sayHello() == "Hello from ClassC")
      assert(ClassD.new():sayHello() == "Hello world")
    end,
  },
}

local font

function love.load()
  font = love.graphics.newFont(36)
  for _, test in pairs(tests) do
    for index = 1, #test do
      test[index]()
    end
  end
  print("All tests run successfully!")
end

function love.draw()
  love.graphics.setFont(font)
  love.graphics.print("If you can see this text,\nall unit tests have passed!", 100, 100)
end