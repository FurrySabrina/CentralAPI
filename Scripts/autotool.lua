autotool = class()

print("Loading CentralAPI Autotool")

--------------------------------------------------------------------------------
--================================== Globals ==================================--
--------------------------------------------------------------------------------

local CELLING_CHECK_HEIGHT = 16384
local CELLING_HEIGHT = nil
CENTRAL_API = CENTRAL_API or nil
local CENTRAL_API_UUID = sm.uuid.new("02189350-abdc-482e-9e5a-f10e5b72e6f6")
local raycastMasks = {
    all = -1,
    dynamicBody = 1,
    staticBody = 2,
    character = 4,
    areaTrigger = 8,
    terrainSurface = 128,
    terrainAsset = 256,
    harvestable = 512,
    joints = 4096,
    static = 34690,
    default = 38791,
    voxelTerrain = 32768,
}

--------------------------------------------------------------------------------
--================================== Helpers ==================================--
--------------------------------------------------------------------------------

local function raycastMask(strings)
    if type(strings) ~= "table" then return raycastMasks.all end
    local mask = 0
    for _, str in ipairs(strings) do
        if not raycastMasks[str] then
            sm.log.error("raycastMask() failed to find mask for "..str)
            return raycastMasks.all
        end
        mask = mask + raycastMasks[str]
    end
    return mask
end

local function getWorldRay(pos)
    if not pos then
        pos = {x=0, y=0}
    end
    pos = {x=math.floor(pos.x+0.5)/4, y=math.floor(pos.y+0.5)/4}
    if not CELLING_HEIGHT then
        local hit, result = sm.physics.raycast(sm.vec3.new(0, 0, 0), sm.vec3.new(0, 0, CELLING_CHECK_HEIGHT), nil, raycastMask{"voxelTerrain"})
        if hit and result.type == "limiter"then
            CELLING_HEIGHT = result.pointWorld.z
        end
    end
    local hit, result = sm.physics.raycast(sm.vec3.new(pos.x, pos.y, CELLING_HEIGHT-1), sm.vec3.new(pos.x, pos.y, -CELLING_HEIGHT), nil, raycastMask{"terrainSurface", "terrainAsset", "voxelTerrain"})

    if hit then
        local pointWorld = result.pointWorld
        local modifiedResult = sm.vec3.new(pointWorld.x, pointWorld.y, math.ceil( (pointWorld.z) * 4 ) / 4)
        return modifiedResult
    else
        return nil
    end
end

--------------------------------------------------------------------------------
--================================== Server ==================================--
--------------------------------------------------------------------------------

function autotool:server_onCreate(refreshData)
    print("autotool:server_onCreate()")
    self.sv = refreshData or {
        cache = {
            position = nil,
            rotation = nil
        }
    }
end

function autotool:server_onRefresh()
    print("autotool:server_onRefresh()")
    self:server_onCreate(self.sv)

    for _,body in pairs(sm.body.getAllBodies()) do
        for _,shape in pairs(body:getShapes()) do
            if shape.uuid == CENTRAL_API_UUID then
                shape:destroyShape()
            end
        end
    end
end

function autotool:server_onFixedUpdate(dt)
    if not sm.isHost then return end
    local CentralAPI = nil
    local search = {}
    if #sm.body.getAllBodies() == 0 then
        CentralAPI = nil
        goto skipSearch
    end
    for _,body in pairs(sm.body.getAllBodies()) do
        for _,shape in pairs(body:getShapes()) do
            if shape.uuid == CENTRAL_API_UUID then
                table.insert(search, shape)
            end
        end
    end
    if #search > 1 then
        sm.log.warning("autotool:server_onFixedUpdate() found more than one CentralAPI, Attempting to clean up duplicates")
        local lowestID = math.huge
        local lowestShape = nil
        local duplicateShapes = {}
        
        for _, shape in pairs(search) do
            if shape.id < lowestID then
                if lowestShape then
                    table.insert(duplicateShapes, lowestShape)
                end
            
                lowestID = shape.id
                lowestShape = shape
            else
                table.insert(duplicateShapes, shape)
            end
        end

        for _,shape in pairs(duplicateShapes) do
            if not sm.exists(shape) then goto continue end
            sm.log.info("autotool:server_onFixedUpdate() removing duplicate shape with id "..shape.id)
            shape:destroyShape()
            ::continue::
        end

        CentralAPI = lowestShape
        self.sv.cache.position = CentralAPI:getWorldPosition()
        self.sv.cache.rotation = sm.quat.getAt(CentralAPI:getWorldRotation())
    elseif #search == 1 then
        for _,shape in pairs(search) do
            CentralAPI = shape
            break
        end
    elseif #search == 0 then
        CentralAPI = nil
    end

    ::skipSearch::

    if not CentralAPI then
        sm.log.info("autotool:server_onFixedUpdate() creating new CentralAPI")
        local position = getWorldRay({x=0, y=0})
        local rotation = sm.quat.fromEuler(sm.vec3.new(90, 90, 0))
        CentralAPI = sm.shape.createPart(
            CENTRAL_API_UUID,
            position, 
            rotation,
            false,
            false
        )
        self.sv.cache.position = position+sm.vec3.new(0.125, 0.125, 0.125)
        self.sv.cache.rotation = sm.quat.getAt( rotation )
    end

    if sm.game.getCurrentTick() % 2 == 0 then
        local newestID = 0
        local newestShape = nil
        for _,shape in pairs(CentralAPI:getBody():getShapes()) do
            if shape.uuid == CENTRAL_API_UUID then goto continue end
            if shape.id > newestID then
                newestID = shape.id
                newestShape = shape
            end
            ::continue::
        end

        if newestShape and sm.exists(newestShape) then
            newestShape:destroyShape()
        end
    end

    local shapePos = CentralAPI:getWorldPosition()
    local shapeRot = sm.quat.getAt( CentralAPI:getWorldRotation() )
    local cachePos = self.sv.cache.position
    local cacheRot = self.sv.cache.rotation
    if not cachePos or not cacheRot then
        self.sv.cache.position = shapePos
        self.sv.cache.rotation = shapeRot
        return
    end
    local diffPos = shapePos-cachePos
    local diffRot = shapeRot-cacheRot

    if sm.vec3.length(diffPos) > 0.01 or sm.vec3.length(diffRot) > 0.01 then
        CentralAPI:destroyShape()
        sm.log.warning("autotool:server_onFixedUpdate() replacing CentralAPI due to position or rotation mismatch")
        local position = getWorldRay({x=0, y=0})
        local rotation = sm.quat.fromEuler(sm.vec3.new(90, 90, 0))
        CentralAPI = sm.shape.createPart(
            CENTRAL_API_UUID,
            position, 
            rotation,
            false,
            false
        )
        self.sv.cache.position = position+sm.vec3.new(0.125, 0.125, 0.125)
        self.sv.cache.rotation = sm.quat.getAt( rotation )
    end

    CENTRAL_API = CentralAPI
end

print("Finished loading CentralAPI Autotool")
