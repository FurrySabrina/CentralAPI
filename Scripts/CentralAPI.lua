--------------------------------------------------------------------------------
--================================= Initalize ================================--
--------------------------------------------------------------------------------

dofile("GUI.lua")
dofile("Status.lua")
dofile("Functions.lua")
dofile("Settings.lua")

local function includeMethods(target, source)
    if not source then return end
    for k, v in pairs(source) do
        if type(v) == "function" then
            target[k] = v
        end
    end
end

CentralAPI = CentralAPI or class()

includeMethods(CentralAPI, GUI)
includeMethods(CentralAPI, Status)
includeMethods(CentralAPI, Functions)
includeMethods(CentralAPI, Settings)

--------------------------------------------------------------------------------
--================================== Helpers =================================--
--------------------------------------------------------------------------------

local function splitPcallError(err)
    local data = {
        raw = tostring(err),
        path = nil,
        file = nil,
        line = nil,
        message = nil,
        variable = nil,
        reason = nil
    }

    local path, line, message = data.raw:match('%[string "([^"]+)"%]:(%d+): (.+)')

    if not path then
        path, line, message = data.raw:match("^([^:]+):(%d+): (.+)")
    end

    data.path = path
    data.line = tonumber(line)
    data.message = message

    if path then
        data.file = path:match("([^/\\]+)$")
    end

    if message then
        data.variable = message:match("'([^']+)'")
        data.reason = message:match("%((.-)%)")
    end

    return data
end

--------------------------------------------------------------------------------
--================================== Server ==================================--
--------------------------------------------------------------------------------

function CentralAPI:server_onCreate()
    local success, err = pcall(function()
        sm.log.info("CentralAPI:server_onCreate()")
        self.sv = {} -- create global server variables
        self:sv_onStatusCreate()
        self:sv_onSettingsCreate()
    end)
    if not success then
        sm.log.error("CentralAPI:server_onCreate() " .. err)
        self:sv_onStatusSet("ERROR", true, true)
    end
end

function CentralAPI:server_onRefresh()
    local success, err = pcall(function()
        sm.log.info("CentralAPI:server_onRefresh()")
        self:sv_onStatusRefresh()
        self:sv_onSettingsRefresh()
    end)
    if not success then
        sm.log.error("CentralAPI:server_onRefresh() " .. err)
        self:sv_onStatusSet("ERROR", true, true)
    end
end

function CentralAPI:checkScripts(dt)
    -- checks for if the scripts reloaded
    if sm.game.getCurrentTick() % 20 ~= 0 then return end -- check every 20 ticks
    dofile("$CONTENT_DATA/Scripts/GUI.lua")
    dofile("$CONTENT_DATA/Scripts/Status.lua")
    dofile("$CONTENT_DATA/Scripts/Functions.lua")
    dofile("$CONTENT_DATA/Scripts/Settings.lua")
    includeMethods(CentralAPI, GUI)
    includeMethods(CentralAPI, Status)
    includeMethods(CentralAPI, Functions)
    includeMethods(CentralAPI, Settings)
end

function CentralAPI:server_onFixedUpdate(dt)
    local success, err = pcall(function()
        self:checkScripts(dt)
    end)
    if not success then
        sm.log.error("CentralAPI:server_onFixedUpdate() " .. err)
        self:sv_onStatusSet("ERROR", true, true)
    end
end

--------------------------------------------------------------------------------
--================================== Client ==================================--
--------------------------------------------------------------------------------

function CentralAPI:client_onCreate()
    local success, err = pcall(function()
        sm.log.info("CentralAPI:client_onCreate()")
        self.cl = {} -- create global client variables
        self:cl_onCreateGUI()
        self:cl_onStatusCreate()
        self:cl_onRequestHostPlayer()
        self:cl_onCreateSettings()
    end)
    if not success then
        sm.log.error("CentralAPI:client_onCreate() " .. err)
        self:cl_onStatusSet("ERROR", true, true)
    end
end

function CentralAPI:client_onRefresh()
    local success, err = pcall(function()
        sm.log.info("CentralAPI:client_onRefresh()")
        self:cl_onRefreshGUI()
        self:cl_onStatusRefresh()
    end)
    if not success then
        sm.log.error("CentralAPI:client_onRefresh() " .. err)
        self:cl_onStatusSet("ERROR", true, true)
    end
end

function CentralAPI:client_onFixedUpdate(dt)
    self:cl_onStatusAnimate() -- animate regardless
    if self.cl.status.statuses.ERROR then return end
    local success, err = pcall(function()
        self:cl_onSettingsFixedUpdate(dt)
    end)
    if not success then
        sm.log.error("CentralAPI:client_onFixedUpdate() " .. err)
        self:cl_onStatusSet("ERROR", true, true)
    end
end

function CentralAPI:client_onUpdate(dt)
    local success, err = pcall(function()
        self:cl_onSettingsUpdate(dt)
    end)
    if not success then
        sm.log.error("CentralAPI:client_onUpdate() " .. err)
        self:cl_onStatusSet("ERROR", true, true)
    end
end

function CentralAPI:client_onInteract(character, state)
    if not state then return end
    local success, err = pcall(function()
        self:cl_onOpenGUI()
    end)
    if not success then
        sm.log.error("CentralAPI:client_onInteract() " .. err)
        self:cl_onStatusSet("ERROR", true, true)
    end
end
