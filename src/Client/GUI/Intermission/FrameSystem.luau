local FrameSystem = {}

local currentFrame : Frame

function FrameSystem.closeCurrent()
    if currentFrame then
        currentFrame.Visible = false
        currentFrame = nil
    end
end

function FrameSystem.setCurrent(new : Frame)
    FrameSystem.closeCurrent()
    currentFrame = new
end


return FrameSystem