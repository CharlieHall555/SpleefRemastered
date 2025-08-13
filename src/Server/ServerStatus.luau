

local ServerStatus = {}

export type Status = "LOADING" | "OK" | "SHUTTING_DOWN"

local status = "OK"

function ServerStatus.init()
    
    game:BindToClose(function()
        status = "SHUTTING_DOWN"
    end)

end

function ServerStatus.set(newStatus : string)

    status = newStatus
    
end

function ServerStatus.get()
    return status
end



return ServerStatus