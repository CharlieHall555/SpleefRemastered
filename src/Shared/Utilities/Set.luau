-- Set module for Roblox utilities
-- Implements a Set data structure with common operations

local Set = {}
Set.__index = Set

-- Export type definition for the Set
export type Set = {
    elements: { [any]: boolean }, -- Internal storage of set elements
    add: (self: Set, element: any) -> Set,
    remove: (self: Set, element: any) -> Set,
    contains: (self: Set, element: any) -> boolean,
    size: (self: Set) -> number,
    clear: (self: Set) -> Set,
    toArray: (self: Set) -> { any },
    union: (self: Set, otherSet: Set) -> Set,
    intersection: (self: Set, otherSet: Set) -> Set,
    difference: (self: Set, otherSet: Set) -> Set,
    isSubset: (self: Set, otherSet: Set) -> boolean
}

-- Constructor
function Set.new(initialElements: { any }?): Set
    local self = setmetatable({}, Set)
    self.elements = {}

    if initialElements then
        for _, element in ipairs(initialElements) do
            self.elements[element] = true
        end
    end

    return self
end

-- Add an element to the set
function Set:add(element: any): Set
    self.elements[element] = true
    return self
end

-- Remove an element from the set
function Set:remove(element: any): Set
    self.elements[element] = nil
    return self
end

-- Check if set contains an element
function Set:contains(element: any): boolean
    return self.elements[element] == true
end

-- Get the size of the set
function Set:size(): number
    local count = 0
    for _ in pairs(self.elements) do
        count = count + 1
    end
    return count
end

-- Clear all elements from the set
function Set:clear(): Set
    self.elements = {}
    return self
end

-- Convert set to array
function Set:toArray(): { any }
    local array = {}
    for element in pairs(self.elements) do
        table.insert(array, element)
    end
    return array
end

-- Union with another set
function Set:union(otherSet: Set): Set
    local result = Set.new()
    for element in pairs(self.elements) do
        result:add(element)
    end
    for element in pairs(otherSet.elements) do
        result:add(element)
    end
    return result
end

-- Intersection with another set
function Set:intersection(otherSet: Set): Set
    local result = Set.new()
    for element in pairs(self.elements) do
        if otherSet:contains(element) then
            result:add(element)
        end
    end
    return result
end

-- Difference with another set
function Set:difference(otherSet: Set): Set
    local result = Set.new()
    for element in pairs(self.elements) do
        if not otherSet:contains(element) then
            result:add(element)
        end
    end
    return result
end

-- Check if this set is a subset of another
function Set:isSubset(otherSet: Set): boolean
    for element in pairs(self.elements) do
        if not otherSet:contains(element) then
            return false
        end
    end
    return true
end

return Set