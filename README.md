# lua-defs
Snippet for implementing classes, enumeration and types in pure Lua language.

Version 1.0.2 (13th February 2019). Change notes at the end of this readme.

- Classes
- Classes inheritance
- Enum
- Custom Types
- For typed Dictionary implementation, see https://github.com/arj-mat/lua-dictionary/. It's also a good example of Lua Defs' usage.

## Usage
```lua
require "lua-defs" -- or copy the content of lua-defs.lua into your script

define "Animal" : Class {
  prototype = {
    name = "",
    sound = ""
  },
  constructor = function(self, name)
    self.name = name;
  end
}

define "Cat" : extends "Animal" {
  constructor = function(self)
    self:super("Thomas");
    self.sound = "meow";
  end
}

animal = Cat();
print(animal.name .. ' ' .. animal.sound .. '\'s!');
```

```Thomas meow's!```
___
## *Define* reference
**define** is the main method for declarating types of Def Lua.
It can be used on a pure-Lua styled syntax or in the normal way.
```lua
define "Animal" : Class { ... }
define "Cat" : extends "Animal" { ... }
--or
define("Animal"):Class({ ... })
define("Cat"):extends("Animal")({ ... })
```
The definition name allows for targeting specific tables for implementation. Example:
```lua
Geometry = {
  Forms = {}
}
define "Geometry.Forms.Square" : Class {...}
square1 = Geometry.Forms.Square();
```
If the specified path does not exists on the gloval envoriment, it will be created as a table.

## *Class* reference
**Class declarartion three**
```
{
  prototype = {
    propertyName = initialValue,
    methodName = function(self, args)
      --@param self Reference for the current instance
    end,
    super = nil -- constructor method of the parent class on extended classes,
    class = {} -- class reference
  },
  constructor = function(self, args)
    --@param self Reference for the current instance
    --@returns nil 
  end,
  chainedMethods = {
    chainedMethodName = function(self, args)
      --@param self Reference for the current instance
      --@returns self (always and automatically)
    end
  },
  metatable = {},
  extends = {} or nil, -- Reference for the parent class or nil
  className = "", -- Class' last name
  fullClassName = "", -- Class' full definition name
  indexOverload = nil,
  onlyExtendsFromItself = false,
  StaticProperty = value
}
```

**prototype** table is required for non-extended classes.

It's meant to be a set of **default methods and properties** when they were not declarated on the instance object. For setting your custom  properties you must initialize them inside of the **constructor** function  (eg.: `self.propertyName = "my new value"; self.myTable = {}`).

Classses' instances will have this prototype as their index meta table.

Prototype functions must be declarated with a *self* reference at the first argument and called using the **:** operator.
```lua
define "Person" : Class {
  prototype = {
    name = "Someone",
    age = 0,
    greeting = function(self)
      return 'Hi there ' .. self.name .. '!';
    end
  }
}
person = Person();
print(person:greeting());
--Hi there Someone!
```
___
**constructor** function is optional.

The first argument must always be *self*, a reference for the initializated instance. Arguments sent during the class initialization are available on this function. No return value is expected.
___
**chainedMethods** table is optional

Def-Lua supports the use of chained methods, those methods who always returns it's self instance and allow for sequencial calls. Despite of normal methods, wich are declarated on the *prototype* table, chained methods must be declarated on this specific table.
```lua
define 'Consumer' : Class {
  prototype = {
    credits = 0
  },
  chainedMethods = {
    addCredits = function(self, amount)
      self.credits = self.credits + amount;
    end,
    removeCredits = function(self, amount)
      self.credits = self.credits - amount;
    end
  }
}

consumer = Consumer();
consumer:
  addCredits(50):
  addCredits(80):
  removeCredits(50):
  addCredits(25):
  removeCredits(5);
```
___
**metatable** Optional table with Lua meta events and meta methods for setting on the class instance. Note that the \_\_index meta event is forbidden since it's for internal use of the class inheritance system. See the indexOverload field.
__

**indexOverload** Optional table or function declaration for extending the \_\_index metatable event. When setting indexOverload on a class, the inheritance control will look for the requested index on **self.class.prototype**, then on **self.class.extends.prototype** (if it exists and on it's prototypes aswell), then on **self.class.indexOverload**.

When indexOverload is declarated as a function, it will take the object instance and the requested key as arguments, eg.: `indexOverload = function(self, keyName) end`.
___

**onlyExtendsFromItself** Optional boolean value. If *true*, the class will not be allowed to be extended for any other rather than it's original declaration.

For example, if the class *Fruit* is declarated with *onlyExtendsFromItself = true*: `define "RedFruit" : extends "Fruit" { }` will be allowed, but `define "Strawberry" : extends "RedApple" { } ` will throw an error since the base class *Fruit* can only be extended from itself.

___
**Static properties** All fields set on the declaration will be available as static properties on the class table.
```lua
define 'Animal' : Class {
  prototype = {},
  LivesOn = "Earth"
}
print(Animal.LivesOn);
--Earth
```
___
**Instance object three** 
The table returned from a class constructor has the class prototype as it's index metatable.
```
{
  class = {}, -- Reference for the object's class declaration table
}
```
___
## *Class inheritance* reference
**Declaration**
```lua
define "Child" : extends "Parent" {
  
}
```
Declaration of a **prototype** table is not required on extended classes. Extended classes instances will have the parent's prototype as it's metatable index.

Prototype properties and chained methods with the same name as on the parent class will be overloaded.

**self:super(...)** can be called on the constructor of a extended class for invoking it's parent constructor method.

**self.class.extends** table will be available as a reference for the parent table declaration.
___
## *Enum* reference
```lua
define "LanguagesID" : Enum {
  pt = 1,
  en = 2,
  fr = 3,
  jp = 4
}

print(LanguaguesID.pt); -- 1
print(LanguagesID[1]); -- pt
```
**Enum methods**

**:getNames()** returns an array contaning all the names.

**:getValues()** returns an array containing all the values.

**:hasKey(index)** returns true or false according to the existence of the given argument as a key on the original declaration.
```lua
print(LanguagesID[1] ~= nil); -- true
print(LanguagesID:hasKey(1)); -- false
```

**:forEach(function(key, value))** performs an iteration over the original declaration table.

**:duplicateIndex(sourceIndex, ...newIndexes)** Clone the index key and it's value into the new index provided. Multiple new indexes can be provided.
```lua
LanguagesID:duplicateIndex("en", "en_us", "en_gb");
print(LanguagesID.en_us, LanguagesID.en_gb); -- 2  2
```
___
## *Type* reference
Lua-Defs allows you to declarate your own defintion types sou you can expand your possibilities of object oriented programming.
```lua
define "MyCustomType" : Type {
  declarationHandler = function(targetEnv, fullDefinitionName, definitionName)
    print("Define " .. definitionName .. " as MyCustomType with the following declaration arguments: " .. table.concat({...}, ', '));
    return {numbers = {...}}
  end
}

define "Something" : MyCustomType (1, 2, 3)
-- Define Something as MyCustomType with the following declaration arguments: 1, 2, 3

print(Something.numbers[2]); -- 2
```
**declarationHandler(targetEnv, fullDefinitionName, definitionName, ...)** is the required function for setting up future definitions. Returned value will be assigned for the new definition at target envoriment.

**targetEnv** envoriment where the definition name points for. Examples: for "Something" it will be the global envoriment (\_G); for "Aaa.Something", it will be the table "Aaa".

**fullDefinitionName** is the string passed after the define keyword.

**definitionName** is last name of the definition string.

**...** are the arguments passed after ": MyCustomType".

The custom type declaration will be available on the global envoriment only.

It can only contains alphanumeric characters and underlines on it's name.

## Change notes
**1.0.2**:
- \[NEW] Added the class "indexOverload" declaration. Documented above.
- \[NEW] Added the class flag "onlyExtendsFromItself" for disabling multiple class inheritance. Documented above.
- \[BUG FIX] Class constructor is now called after the definition of the instance's metatable. Problem: it was impossible to reach properties or methods on the prototype inside of the constructor function.
