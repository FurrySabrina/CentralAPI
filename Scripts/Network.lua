Network = class()

--[[
local function includeMethods(target, source)
    if not source then return end
    for k, v in pairs(source) do
        if type(v) == "function" then
            target[k] = v
        end
    end
    return target
end

dofile("$CONTENT_DATA/Scripts/Graph.lua")
includeMethods(Network, Graph)
]]

--------------------------------------------------------------------------------
--================================== Globals ==================================--
--------------------------------------------------------------------------------

local plasticUuid = sm.uuid.new("628b2d61-5ceb-43e9-8334-a4135566df7a")
local pipeUuid = sm.uuid.new("0dba257b-b907-4919-baaf-2fefe19f4e24")
local pipeRotation = sm.vec3.new(0, 90, 0)
