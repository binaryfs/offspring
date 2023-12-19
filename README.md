# Offspring

Offspring is a lightweight and flexible library for creating classes and doing type checking in the [LÖVE framework.](https://love2d.org/) It provides multiple inheritance, enumerations (enums) and a type checking system that supports Lua types, LÖVE types and union types. It also works very well wirh [Lua language server](https://github.com/LuaLS/lua-language-server) annotations. It doesn't do any magic, though.

## Requirements

Offspring requires LÖVE 11 or 12 and has no other external dependencies.

## Integration

This section describes how to integrate Offspring into your project.

### Manually

Create a new subdirectory in your project root, e.g. `libs/offspring`, and paste the content of this repository into it. Afterwards you can include Offspring like this:

```lua
local offspring = require("libs.offspring")
```

### Git Submodule

Run the following command in your project root to add Offspring as a submodule:

```
git submodule add https://github.com/binaryfs/offspring.git libs/offspring
```

Afterwards you can include offspring like this:

```lua
local offspring = require("libs.offspring")
```

## Usage

### Classes

All classes are abstract by default. This means that Offspring doesn't create constructors automatically, unless you want it to.

```lua
local offspring = require("libs.offspring")

-- Each class must be given a name, as this is used for type checking.
local Circle = offspring.class("Circle")

-- This is a class variable, which is shared by all instances of the class.
-- Uppercase variables are constant by convention, but not by design.
Circle.DEFAULT_RADIUS = 10

-- Constructors are defined explicitly for each class and are not inherited by subclasses.
function Circle.new(radius)
  local self = setmetatable({}, Circle)
  self.radius = radius or self.DEFAULT_RADIUS
  return self
end

function Circle:getArea()
  return math.pi * self.radius * self.radius
end

-- Create a Circle instance.
local circle = Circle.new(200)
```

This approach may seem cumbersome at first, but it was chosen for the following reasons:

- It clearly communicates how a class is to be used. If a class has no constructor, it is an abstract class and not meant to be used as a factory. If a class has a constructor but no initializer, it is not meant to be inherited by other classes (similar to a final class).
- You have full control over what happens in the constructor.
- Defining constructors explicitly also works best with auto-completion in most code editors and IDEs.

However, if you *want* Offspring to create constructors automatically, you can do this by overriding the `offspring.classCreated` function (see further below).

### Inheritance

A class can inherit from any number of parent classes:

```lua
local FooBar = offspring.class("FooBar", Foo, Bar)

function FooBar.new(a, b, c)
  local self = setmetatable({}, Sprite)
  Foo.init(self, a)
  Bar.init(self, b)
  self.c = c
  return self
end
```

If no parent class is specified, new classes automatically inherit from Offspring's `Object` class:

```lua
-- Inherits from Object implicitly.
local Rectangle = offspring.class("Rectangle")

-- Inherits from Object explicitly.
local Circle = offspring.class("Circle", offspring.Object)
```

In other words, `Object` is the base class for all Offspring classes. In order to add methods that should be available in all classes, you can monkey patch `Object`:

```lua
-- This adds the hasSameType method to all Offspring classes.
offspring.Object.hasSameType = function (self, other)
  return self:typeOf(offspring.type(other))
end
```


For optimization purposes, inheritance in Offspring is performed statically. This implies that when a class inherits from another, the fields are not dynamically sought in the parent class during runtime. Instead, they are directly copied from the parent class to the subclass. Consequently, if any changes are made to the parent class after a subclass has been derived from it, these modifications will not automatically propagate to the subclass.

### Class customization

Override the `offspring.classCreated` function to customize the classes created by Offspring. For example, if you want Offspring to add constructor functions automatically, you can simply do the following:

```lua
function offspring.classCreated(newClass, parentClasses)
  newclass.new = function (...)
    local self = setmetatable({}, newClass)
    self:init(...)
    return self
  end
end
```

Then you can define your classes like this:

```lua
local Rectangle = offspring.class("Rectangle")

function Rectangle:init(width, height)
  self.width = width
  self.height = height
end

-- Create a rectangle instance.
local rect = Rectangle.new(200, 100)
```

And if certain fields should *not* be inherited by subclasses, you can add them to the `offspring.excludedFromInheritance` table:

```lua
-- Do not inherit the __newindex metamethod.
offspring.excludedFromInheritance.__newindex = true
```

### Interfaces

There are no real interfaces in Offspring, but you can have interface classes, similar to C++.

```lua
local Drawable = offspring.class("Drawable")

function Drawable:draw(x, y)
  error("Drawable:draw is not implemented!")
end

local Sprite = offspring.class("Sprite", Drawable)

function Sprite:draw(x, y)
  love.graphics.draw(self.image, x, y)
end
```

### Enumerations (enums)

```lua
--- @alias Color "red" | "green" | "blue"
local Color = offspring.enum("Color", {
  RED = "red",
  GREEN = "green",
  BLUE = "blue",
})
```

The snippet from above uses the `@alias` annotation from the [Lua language server](https://github.com/LuaLS/lua-language-server) for better auto-completion. If you want to use the `@enum` annotation instead, you can slightly modify the code as follows:

```lua
--- @enum Color
local Color = {
  RED = "red",
  GREEN = "green",
  BLUE = "blue",
}
offspring.enum("Color", Color)
```

### Type checking

The type checking system is based on the two functions `offspring.type` and `offspring.typeOf` and supports Lua types, LÖVE types, union types and (of course) Offspring types.

Lua types:
```lua
offspring.type("abc") --> "string"
offspring.typeOf(123, "number") --> true
offspring.typeOf(123, "string") --> false
```

LÖVE types:
```lua
local mesh = love.graphics.newMesh(3)

offspring.type(mesh) --> "Mesh"
offspring.typeof(mesh, "Mesh") --> true
offspring.typeof(mesh, "Object")   --> true
offspring.typeof(mesh, "userdata") --> true
```

Offspring classes:
```lua
local Foo = offspring.class("Foo")

function Foo.new()
  return setmetatable({}, Foo)
end

local foo = Foo.new()

offspring.type(foo) --> "Foo"
offspring.typeof(foo, "Foo") --> true
offspring.typeof(foo, "offspring.Object") --> true
offspring.typeof(foo, "table") --> true
offspring.typeof(foo, "Bar")   --> false
```

Offspring enums:
```lua
local Color = offspring.enum("Color", {
  RED = "red",
  GREEN = "green",
  BLUE = "blue",
})

offspring.typeof(Color.RED, "Color") --> true
offspring.typeof("blue", "Color")    --> true
offspring.typeof("black", "Color")   --> false
```

Union types:
```lua
offspring.typeof("abc", "number|string") --> true
offspring.typeof(true, "number|string")  --> false
offspring.typeof(Foo.new(), "Foo|nil")   --> true
offspring.typeof(nil, "Foo|nil")         --> true
```

The type checking system is also compatible with foreign objects. The only requirement is that these objects must implement the two methods `type` and `typeOf`, just as the [Object superclass](https://love2d.org/wiki/Object) from LÖVE does (or the one from Offspring).

### Assertions

Use `offspring.assertArgument` to make sure that an argument has a certain type:

```lua
function Node:addChild(child)
  offspring.assertArgument(1, child, "Node")
  table.insert(self.children, child)
end
```

Or use `offspring.assertType` to check if any other kind of value has a certain type:

```lua
offspring.assertType(stack:pop(), "number|string|boolean")
```

## License

MIT License (see LICENSE file in project root)