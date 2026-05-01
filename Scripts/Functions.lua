Functions = Functions or class()

function Functions:getTableCount(table)
    local count = 0
    for _ in pairs(table) do count = count + 1 end
    return count
end

function Functions:ifInTable(table, value)
    if not table then return false end
    if type(table) ~= "table" then return false end
    if not value then return false end
    for i, v in pairs(table) do
        if i == value then return true end
        if v == value then return true end
    end
    return false
end

function Functions:sv_onGetHostPlayer()
    sm.log.info("Functions:sv_onGetHostPlayer()")
    if self.sv.hostPlayer then return self.sv.hostPlayer end
    if #sm.player.getAllPlayers() == 1 then return sm.player.getAllPlayers()[1]
    elseif #sm.player.getAllPlayers() > 1 then
        sm.log.warning("Functions:sv_onGetHostPlayer() more than one player detected, returning first player")
        return sm.player.getAllPlayers()[1]
    end
    return nil
end

function Functions:sv_sendHostPlayerRequest(player)
    sm.log.info("Functions:sv_sendHostPlayerRequest()")
    if not player then return end
    if not self.sv.hostPlayer then
        self.sv.hostPlayer = self:sv_onGetHostPlayer()
    end
    self.network:sendToClient(player, "cl_onReceiveHostPlayer", self.sv.hostPlayer)
end

function Functions:cl_onRequestHostPlayer()
    sm.log.info("Functions:cl_onRequestHostPlayer()")
    if not self.cl.hostPlayer then
        self.network:sendToServer("sv_sendHostPlayerRequest", sm.localPlayer.getPlayer())
    end
end

function Functions:cl_onReceiveHostPlayer(player)
    sm.log.info("Functions:cl_onReceiveHostPlayer()")
    if not player then return end
    self.cl.hostPlayer = player
end

function Functions:colorToHex(color)
    local r = math.floor(color.r * 255)
    local g = math.floor(color.g * 255)
    local b = math.floor(color.b * 255)
    return string.format("%02X%02X%02X", r, g, b)
end

function Functions:hexToColor(hex)
    if type(hex) ~= "string" then
        return nil, false
    end

    hex = hex:gsub("%s+", ""):upper()

    -- support shorthand RGB -> RRGGBB
    if #hex == 3 then
        hex = hex:gsub(".", "%1%1")
    end

    -- must be exactly 6 valid hex chars
    if not hex:match("^[0-9A-F]+$") or #hex ~= 6 then
        return nil, false
    end

    local r = tonumber(hex:sub(1,2), 16)
    local g = tonumber(hex:sub(3,4), 16)
    local b = tonumber(hex:sub(5,6), 16)

    return sm.color.new(r / 255, g / 255, b / 255), true
end

function Functions:lerpColor(start, end_, t)
    local R = sm.util.lerp(start.r, end_.r, t)
    local G = sm.util.lerp(start.g, end_.g, t)
    local B = sm.util.lerp(start.b, end_.b, t)
    return sm.color.new(R, G, B)
end
