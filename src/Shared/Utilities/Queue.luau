local Queue = {}
Queue.__index = Queue

function Queue.new()
    local newQueue = {}
    setmetatable(newQueue , Queue)
    newQueue.items = {}
    newQueue.front = 1
    newQueue.back = 0
    return newQueue
end

function Queue:enqueue(value)
    self.back += 1
    self.items[self.back] = value
end

function Queue:dequeue()
    if self:isEmpty() then
        error("Queue is empty")
    end

    local value = self.items[self.front]
    self.items[self.front] = nil
    self.front += 1

    if self.front > self.back then
        self.front = 1
        self.back = 0
    end

    return value
end

function Queue:peek()
    if self:isEmpty() then
        error("Queue is empty")
    end
    return self.items[self.front]
end

function Queue:isEmpty()
    return self.front > self.back
end

function Queue:size()
    return self.back - self.front + 1
end

return Queue
