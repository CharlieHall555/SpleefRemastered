local ListUtil = {}

function ListUtil.difference(listA, listB)
    local result = {}
    local setB = {}

    for _, v in ipairs(listB) do
        setB[v] = true
    end

    for _, v in ipairs(listA) do
        if not setB[v] then
            table.insert(result, v)
        end
    end

    return result
end

function ListUtil.union(list1, list2)
    local result = {}
    local seen = {}

    for _, v in ipairs(list1) do
        if not seen[v] then
            table.insert(result, v)
            seen[v] = true
        end
    end

    for _, v in ipairs(list2) do
        if not seen[v] then
            table.insert(result, v)
            seen[v] = true
        end
    end

    return result
end

function ListUtil.get_keys(list)
    local keys = {}
    for k, _ in pairs(list) do
        table.insert(keys, k)
    end
    return keys
end

function ListUtil.chunkList(list: {any}, chunkSize: number?): {{any}}
    local result = {}
    local size = chunkSize or 10 -- default to 10 if not given
    
    for i = 1, #list, size do
        local chunk = {}
        for j = i, math.min(i + size - 1, #list) do
            table.insert(chunk, list[j])
        end
        table.insert(result, chunk)
    end
    
    return result 
end

return ListUtil