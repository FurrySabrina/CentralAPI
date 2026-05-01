Status = Status or class()

--------------------------------------------------------------------------------
--================================== Globals =================================--
--------------------------------------------------------------------------------

local STATUS_PROPERTIES = {
    ERROR = { blink = 30,  UVIndex = 5, priority = 10 },
    WARNING = { blink = 60, UVIndex = 4, priority = 9 },
    LOCKED = { blink = 0, UVIndex = 7, priority = 8 },
    QUESTION = { blink = 80, UVIndex = 2, priority = 7 },
    INFO = { blink = 80, UVIndex = 3, priority = 6 },
    SYNCING = { blink = 50, UVIndex = 8, priority = 5 },
    HOURGLASS = { blink = 80, UVIndex = 6, priority = 4 },
    DEBUG = { blink = 0, UVIndex = 9, priority = 3 },
    CHECK = { blink = 0, UVIndex = 1, priority = 2, default = true },
    OFF = { blink = 0, UVIndex = 0, priority = 1 }
}

--------------------------------------------------------------------------------
--================================== Server ==================================--
--------------------------------------------------------------------------------

function Status:sv_onStatusCreate(_, remote)
    if self:sv_detectClientCheat({ remote = remote, funcName = "sv_onStatusCreate" }) then return end
    sm.log.info("Status:sv_onStatusCreate()")
    self.sv.status = {}
    self.sv.status.statuses = {}
    for status, properties in pairs(STATUS_PROPERTIES) do
        self.sv.status.statuses[status] = properties.default or false
    end
end

function Status:sv_onStatusRefresh(_, remote)
    if self:sv_detectClientCheat({ remote = remote, funcName = "sv_onStatusRefresh" }) then return end
    sm.log.info("Status:sv_onStatusRefresh()")
    self.sv.status = {}
    self.sv.status.statuses = {}
    for status, properties in pairs(STATUS_PROPERTIES) do
        self.sv.status.statuses[status] = properties.default or false
    end
    self:sv_onStatusSet({ status = "DEBUG", active = true })
end

function Status:sv_onStatusSet(data, remote)
    if self:sv_detectClientCheat("sv_onStatusSet", remote) then return end
    local status = data.status or "OFF"
    local active = data.active or false
    sm.log.info("Status:sv_onStatusSet() " .. status .. " " .. tostring(active))
    if self.sv.status.statuses[status] == nil then
        sm.log.error("Status:sv_onStatusSet() " .. status .. " cant find status")
        assert(self.sv.status.statuses.ERROR ~= nil)
        self.sv.status.statuses.ERROR = true
        self.network:sendToClients("cl_onReceiveServerStatus", self.sv.status.statuses)
        return
    end
    self.sv.status.statuses[status] = active
    self.network:sendToClients("cl_onReceiveServerStatus", self.sv.status.statuses)
end

function Status:sv_onClientRequestStatus(args, remote)
    if not args then return end
    if type(args) ~= "table" then return end
    if not args.status then return end
    if not args.active then return end
    if type(args.status) ~= "string" then return end
    if type(args.active) ~= "boolean" then return end
    sm.log.info("Status:sv_onClientRequestStatus() " .. args.status .. " " .. tostring(args.active))
    self:sv_onStatusSet({ status = args.status, active = args.active })
end

function Status:sv_onRequestStatuses(_, remote)
    sm.log.info("Status:sv_onRequestStatuses()")
    self.network:sendToClient(remote, "cl_onReceiveServerStatus", self.sv.status.statuses)
end

function Status:sv_onResetStatus(_, remote)
    if self.sv.hostPlayer ~= remote then
        if self:sv_detectClientCheat("sv_onResetStatus", remote) then return end
    end
    sm.log.info("Status:sv_onResetStatus()")
    for status, properties in pairs(STATUS_PROPERTIES) do
        if status ~= "DEBUG" then
            self.sv.status.statuses[status] = properties.default or false
        end
    end
    self.network:sendToClients("cl_onReceiveServerStatus", self.sv.status.statuses)
end

function Status:sv_onRequestStatus(args, remote)
    if not args then return end
    if type(args) ~= "table" then return end
    if not args.status then return end
    if type(args.status) ~= "string" then return end
    sm.log.info("Status:sv_onRequestStatus() " .. args.status)
    self.network:sendToClient(remote, "cl_onRequestStatus", args.status)
end

--------------------------------------------------------------------------------
--================================== Client ==================================--
--------------------------------------------------------------------------------

function Status:cl_onStatusCreate()
    sm.log.info("Status:cl_onStatusCreate()")
    self.cl.status = {}
    self.cl.status.statuses = {}
    self:cl_onRequestStatuses()
    self.cl.status.blink = false
end

function Status:cl_onStatusRefresh()
    sm.log.info("Status:cl_onStatusRefresh()")
    self.cl.status = {}
    self.cl.status.statuses = {}
    for status, properties in pairs(STATUS_PROPERTIES) do
        self.cl.status.statuses[status] = properties.default or false
        if properties.default then
            self.interactable:setUvFrameIndex(properties.UVIndex)
        end
    end
    self.cl.status.blink = false
end

function Status:cl_onStatusAnimate()
    assert(self.cl.status)
    local statuses = self.cl.status.statuses
    local highestStatus = "OFF"
    local highestPriority = -1

    for status, active in pairs(statuses) do
        if active and STATUS_PROPERTIES[status] then
            local priority = STATUS_PROPERTIES[status].priority or 0
            if priority > highestPriority then
                highestPriority = priority
                highestStatus = status
            end
        end
    end

    local status = STATUS_PROPERTIES[highestStatus]
    if status and status.blink > 0 then
        local tick = sm.game.getCurrentTick()
        if tick % math.floor(status.blink/2) == 0 then
            self.cl.status.blink = not self.cl.status.blink 
        end
    end

    if status.blink ~= 0 and self.cl.status.blink then
        highestStatus = "OFF"
    end

    local UVFrame = self.interactable:getUvFrameIndex()
    local newUVFrame = STATUS_PROPERTIES[highestStatus].UVIndex
    if UVFrame ~= newUVFrame then
        --sm.log.info("Status:cl_onStatusAnimate() Face change to " .. highestStatus)
        self.interactable:setUvFrameIndex(newUVFrame)
    end
end

function Status:cl_onReceiveServerStatus(statuses)
    sm.log.info("Status:cl_onReceiveServerStatus()")
    self.cl.status.statuses = statuses
end

function Status:cl_onStatusSet(status, active, sendToServer)
    sm.log.info("Status:cl_onStatusSet() " .. status .. " " .. tostring(active))
    if self.cl.status.statuses[status] == nil then
        sm.log.error("Status:cl_onStatusSet() " .. status .. " cant find status")
        self.cl.status.statuses.ERROR = true
        if sendToServer then
            self.network:sendToServer("sv_onClientRequestStatus", { status = status, active = active })
        end
        return
    end
    self.cl.status.statuses[status] = active
    if sendToServer then
        self.network:sendToServer("sv_onClientRequestStatus", { status = status, active = active })
    end
end

function Status:cl_onResetStatus()
    sm.log.info("Status:sv_onResetStatus()")
    self.network:sendToServer("sv_onResetStatus")
end

function Status:cl_onRequestStatus(status)
    sm.log.info("Status:cl_onRequestStatus()")
    self.network:sendToServer("sv_onClientRequestStatus", { status = status, active = true })
end

function Status:cl_onRequestStatuses()
    sm.log.info("Status:cl_onRequestStatuses()")
    self.network:sendToServer("sv_onRequestStatuses")
end
