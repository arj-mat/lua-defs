(function()
    --[[
        Lua Defs
        https://github.com/arj-mat/lua-defs
        This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree. 
        v1.0.3
    ]]

    local function showWarning(msg)
        print('[Lua-Defs] [Warning] ' .. msg);
    end

    local function DefinitionError(msg)
        error('[Lua-Defs] [Error] ' .. msg, 4);
    end

    local function defineScopeByName(name)
        local scope = _G;
        local lastPathName;
        local pathDepth = 0;
        for path in name:gmatch("(%a+)%.?") do
            pathDepth = pathDepth + 1;
        end
        local scopeDepth = 0;
        for path in name:gmatch("(%a+)%.?") do
            scopeDepth = scopeDepth + 1;
            lastPathName = path;
            if not scope[path] then
                scope[path] = {}
            end
            if not(scopeDepth == pathDepth) then
                scope = scope[path];
            end
        end
        return scope, lastPathName;
    end

    local function indexOverloadProcedure(selfInstance, keyName)
        if (type(selfInstance.class.indexOverload) == 'table') then
            return (selfInstance.class.prototype or (selfInstance.class.extends and selfInstance.class.extends.prototype or {}))[keyName] or selfInstance.class.indexOverload[keyName];
        elseif (type(selfInstance.class.indexOverload) == 'function') then
            return (selfInstance.class.prototype or (selfInstance.class.extends and selfInstance.class.extends.prototype or {}))[keyName] or selfInstance.class.indexOverload(selfInstance, keyName);
        end
    end

    local function createClass(fullClassName, declaration)
        local classEnv, className = defineScopeByName(fullClassName);
        if (classEnv[className].__isDefinition) then
            DefinitionError('"' .. fullClassName .. '" has already been defined.');
            return;
        end

        --- Classes without a parent must have a prototype table declarated
        if not(type(declaration.prototype) == 'table') and not(declaration.extends) then
            DefinitionError('Prototype declaration is missing on the definition of "' .. fullClassName .. '".');
            return;
        end

        if (declaration.prototype and declaration.prototype.class) then
            DefinitionError('Prototype declaration of "' .. fullClassName .. '" contains the reserved field "class".');
            return;
        end

        declaration.__isDefinition = true;
        declaration.__isClassDefinition = true;
        declaration.prototype = declaration.prototype or {};

        declaration.prototype.class = declaration; --- The class properties will be available by the field "class" of it's instance
        declaration.className =className .. "";
        declaration.fullClassName = fullClassName .. "";

        if (declaration.extends and declaration.extends.extends and declaration.extends.extends.onlyExtendsFromItself and declaration.extends.class ~= declaration.extends.extends) then
            DefinitionError("Attempt to extend \"" .. declaration.className .. "\" from " .. declaration.extends.className .. " but base class " .. declaration.extends.extends.className .. " can only extend from itself. \nUse define \"" .. declaration.className .. "\" : extends \"" .. declaration.extends.extends.className .. "\" instead.");
        end

        if (declaration.metatable and declaration.metatable.__index) then
            DefinitionError('Definition of "' .. fullClassName .. '"\'s metatable contains the __index field, which is reserved for the inheritance system. Use it on the class attribute "indexOverload" instead.');
        end

        classEnv[className] = declaration;

        --Resolve chained methods by putting them on the prototype as callable tables:
        if (classEnv[className].chainedMethods) then
            for name, value in next, classEnv[className].chainedMethods do
                if (type(value) == 'function') then
                    classEnv[className].chainedMethods[name] = {value};
                    setmetatable(classEnv[className].chainedMethods[name], {
                        __call = function(methodTable, self, ...)
                            methodTable[1](self, ...);
                            return self;
                        end
                    })
                    classEnv[className].prototype[name] = classEnv[className].chainedMethods[name];
                end
            end
        end

        --- If neither the class or it's parent has a constructor, then assign an empty function:
        if not(declaration.constructor or (declaration.extends and declaration.extends.constructor)) then
            declaration.constructor = function() end
        end

        --- Definition of inheritance methods
        if (classEnv[className].extends) then
            classEnv[className].prototype = classEnv[className].prototype or {};
            setmetatable(classEnv[className].prototype, {
                __index = classEnv[className].extends.prototype
            });
            classEnv[className].prototype.super = function(superInstance, ...)
                superInstance.class.extends.constructor(superInstance, ...);
            end;
        end

        --- Class initialization method:
        classEnv[className].Create = function(class, ...)
            local instance = {
                class = class
            };

            --- Classes' instances can have custom metaevents and metamethods declared on the "metatable" field...
            local metatable = class.metatable or (class.extends and class.extends.metatable or nil) or {};
            metatable.__index = class.prototype or (class.extends and class.extends.prototype or {});

            if (class.indexOverload) then
                metatable.__index = indexOverloadProcedure;
            end
            setmetatable(instance, metatable);

            (class.constructor and class.constructor or class.extends.constructor)(instance, ...); --- Calls for the available constructor method, with the new instance and the first received arguments.

            return instance;
        end

        --- Metamethod for allowing initializating the class by calling it as a function
        setmetatable(classEnv[className], {
            __call = function(refClass, ...)
                return refClass.Create(refClass, ...);
            end
        });
    end

    local function createEnum(fullEnumName, declaration)
        local enumEnv, enumName = defineScopeByName(fullEnumName);
        if (enumEnv[enumName].__isDefinition) then
            DefinitionError('"' .. fullEnumName .. '" has already been defined.');
            return;
        end

        local enum = {
            valuesByKey = {},
            keysByValue = {},
            getNames = function(self)
                --- Returns all the enumeration's name as an array
                local names = {};
                for key in next, self.valuesByKey do
                    table.insert(names, key);
                end
                return names;
            end,
            getValues = function(self)
                --Returns all the enumeration's values as an array
                local values = {};
                for value in next, self.keysByValue do
                    table.insert(values, value);
                end
                return values;
            end,
            forEach = function(self, func)
                --- Performs the given function on each element of the enumeration
                --@param func Iteration callback
                for key, value in next, self.valuesByKey do
                    func(key, value);
                end
            end,
            hasKey = function(self, index)
                --- Checks if the given index exists as a key only
                --@param index Enum declaration key
                return self.valuesByKey[index] ~= nil;
            end,
            duplicateIndex = function(self, sourceIndex, ...)
                --- Clone the index key and it's value into new indexes
                --@param sourceIndex The enumeration key to have it's value associated to the new indexes
                --@param ... Varag of new indexes to be included in the enumeration with the sourceIndex's value
                for _, newIndex in next, {...} do
                    self.valuesByKey[newIndex] = self.valuesByKey[sourceIndex];
                end
            end
        };

        if (#declaration > 0) then
            --- If the provided declaration is given as an array:
            for i = 1, #declaration do
                enum.valuesByKey[i] = declaration[i];
                enum.keysByValue[declaration[i]] = i;
            end
        else
            --- Or as an dictionary:
            for key, value in next, declaration do
                enum.valuesByKey[key] = value;
                enum.keysByValue[value] = key;
            end
        end

        --- Metaevent __index for allowing to get results from keys or values:
        setmetatable(enum, {
            __index = function(self, index)
                return enum.valuesByKey[index] or enum.keysByValue[index];
            end
        })

        enumEnv[enumName] = enum;
    end

    local customTypes = {};

    setmetatable(customTypes, {
        __call = function(_, typeName, fullDefName)
            return function(_, ...)
                local targetEnv, defName = defineScopeByName(fullDefName);
                targetEnv[defName] = customTypes[typeName](defName, ...);
            end
        end
    });

    local function defineType(name, declaration)
        if (name:find("[^%a%_]")) then
            DefinitionError('Invalid Type name "' .. name .. '". Only alphanumeric characters and underlines are accepted.');
            return;
        end
        if (customTypes[name]) then
            DefinitionError('Type "' .. name .. '" has already been defined.');
            return;
        end
        customTypes[name] = declaration.declarationHandler;
        _G[name] = declaration;
    end

    _G.define = function(name)
        local definitions = {
            Class = function(_, declaration)
                createClass(name, declaration);
            end,
            extends = function(_, parentName, ...)
                return function(declaration)
                    declaration.extends = defineScopeByName(parentName)[parentName]; --The class object will contain a referece to it's parent on the"extends" field.
                    if not(type(declaration.extends) == 'table') or not(declaration.extends.__isClassDefinition) then
                        DefinitionError('Definition of "' .. name .. '" extends from an unknown class named "' .. parentName .. '".');
                        return;
                    end
                    createClass(name, declaration);
                end
            end,
            Enum = function(_, declaration)
                createEnum(name, declaration);
            end,
            Type = function(_, declaration)
                defineType(name, declaration);
            end
        };

        setmetatable(definitions, {
            __index = function(_, unknownDefName)
                if (customTypes[unknownDefName]) then
                    return customTypes(unknownDefName, name);
                end
                DefinitionError('Unknown definition type "' .. unknownDefName .. '".');
            end
        });

        return definitions;
    end
end)();
