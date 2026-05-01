Settings = Settings or class()

---------------------------------------------------------------------------------
---================================== Helpers =================================--
---------------------------------------------------------------------------------

local function capitalize(str)
    return str:sub(1, 1):upper() .. str:sub(2)
end

local chances = {
    nameParts = {low = 2, high = 4},
    typeChances = {
        toggle = 0.5,
        integer = 0.5,
        float = 0.5,
        string = 0.5,
        color = 0.5,
        vector3 = 0.5
    },
    limit = 0.5,
    limitValues = {
        minValue = {low = -1000, high = 0},
        maxValue = {low = 0, high = 1000},
        step = {low = 0.1, high = 1},
        floatDevision = {low = 1, high = 1000}
    },
    slider = 0.3,
    clientViewable = 0.2
}

local function generateSettings(count)
    local settings = {}

    local syllables = {
        "zor", "tek", "ban", "qua", "flo", "rix", "mon", "vel",
        "dra", "pik", "lum", "gar", "shi", "tor", "zen", "plu",
        "vox", "kri", "nop", "yel", "fim", "wak", "jor", "sni"
    }

    local function randomName()
        local parts = math.random(chances.nameParts.low, chances.nameParts.high)
        local name = ""

        for i = 1, parts do
            name = name .. syllables[math.random(1, #syllables)]
        end

        name = capitalize(name)
        return name
    end

    local function randFloat(min, max)
        return min + math.random() * (max - min)
    end

    local function randVec3(min, max)
        return sm.vec3.new(
            math.random(min, max),
            math.random(min, max),
            math.random(min, max)
        )
    end

    local function randColor()
        return sm.color.new(
            math.random(),
            math.random(),
            math.random()
        )
    end

    for i = 1, count do
        local setting = {
            name = randomName(),
            clientViewable = math.random() > chances.clientViewable
        }

        local t = math.random(1, 6)

        if t == 1 then
            setting.type = "toggle"
            setting.value = math.random() > chances.typeChances.toggle
        elseif t == 2 then
            local minVal = math.random(chances.limitValues.minValue.low, chances.limitValues.minValue.high)
            local maxVal = math.random(chances.limitValues.maxValue.low, chances.limitValues.maxValue.high)

            setting.type = "integer"
            setting.value = math.random(minVal, maxVal)
            setting.limit = math.random() > chances.limit and {
                minValue = minVal,
                maxValue = maxVal,
                step = math.random(chances.limitValues.step.low, chances.limitValues.step.high)
            } or nil
            setting.isSlider = math.random() > chances.slider

        elseif t == 3 then
            local minVal = math.random(chances.limitValues.minValue.low, chances.limitValues.minValue.high)
            local maxVal = math.random(chances.limitValues.maxValue.low, chances.limitValues.maxValue.high)

            setting.type = "float"
            setting.value = randFloat(minVal, maxVal)
            local floatDevision = math.random(chances.limitValues.floatDevision.low, chances.limitValues.floatDevision.high)
            setting.limit = math.random() > chances.limit and {
                minValue = minVal,
                maxValue = maxVal,
                step = math.random(chances.limitValues.step.low * floatDevision, chances.limitValues.step.high * floatDevision) / floatDevision
            } or nil
            setting.isSlider = math.random() > chances.slider
        elseif t == 4 then
            setting.type = "string"
            setting.value = randomName() .. "_" .. math.random(100, 999)
        elseif t == 5 then
            setting.type = "color"
            setting.value = randColor()
        elseif t == 6 then
            setting.type = "vector3"
            local min = math.random(chances.limitValues.minValue.low, chances.limitValues.minValue.high)
            local max = math.random(chances.limitValues.maxValue.low, chances.limitValues.maxValue.high)
            setting.value = randVec3(min, max)
            setting.limit = math.random() > chances.limit and {
                minValue = randVec3(min, max),
                maxValue = randVec3(min, max),
                step = randVec3(chances.limitValues.step.low, chances.limitValues.step.high)
            }
        end

        table.insert(settings, setting)
    end

    return settings
end

--------------------------------------------------------------------------------
--================================== Globals =================================--
--------------------------------------------------------------------------------

local SETTINGS_DATA = {
    settingsPerPage = 6,
    types = {
        "toggle",
        "integer",
        "float",
        "string",
        "color",
        "vector3"
    },
    defaultSliderValues = {
        minValue = 0,
        maxValue = 100,
        step = 1
    },
    orginalColor = sm.color.new("#FFD449"),
    appliedColor = sm.color.new("#32C85A"),
    fadeTime = 1,
    nonViewableColor = sm.color.new("#3A86FF")
}

--------------------------------------------------------------------------------
--================================== Server ==================================--
--------------------------------------------------------------------------------

function Settings:sv_onSettingsCreate(_, remote)
    if self:sv_detectClientCheat({ remote = remote, funcName = "sv_onSettingsCreate" }) then return end
    sm.log.info("Settings:sv_onCreate()")
    self.sv.settingsData = {
        settings = {
            --[[ { name = "Toggle",
            type = "toggle",
            value = true,
            defaultValue = true,
            clientEditable = true,
            clientViewable = true }
            } ]]
        }
    }
end

function Settings:sv_onSettingsRefresh(_, remote)
    if self:sv_detectClientCheat({ remote = remote, funcName = "sv_onSettingsRefresh" }) then return end
    sm.log.info("Settings:sv_onRefresh()")
    self.sv.settingsData = {}
    self.sv.settingsData.settings = generateSettings(50)
    self:sv_sendClientsSettings()
end

function Settings:sv_onResetSettings(player, remote)
    if remote ~= self.sv.hostPlayer then return end
    sm.log.info("Settings:sv_onResetSettings()")
    if self.sv.hostPlayer ~= player then return end
    for _, setting in pairs(self.sv.settingsData.settings) do
        setting.value = setting.defaultValue
    end
    self:sv_sendClientsSettings()
end

function Settings:sv_sendClientsSettings(except, remote)
    if self:sv_detectClientCheat({ remote = remote, funcName = "sv_sendClientsSettings" }) then return end
    sm.log.info("Settings:sv_sendClientsSettings()")
    for _, player in pairs(sm.player.getAllPlayers()) do
        if self:ifInTable(except, player) then goto continue end
        if player == self.sv.hostPlayer then
            self.network:sendToClient(player, "cl_onReceiveServerSettings", self.sv.settingsData.settings)
        else
            local filtered = {}
            for _, setting in pairs(self.sv.settingsData.settings) do
                if setting.clientViewable then
                    table.insert(filtered, setting)
                end
            end
            self.network:sendToClient(player, "cl_onReceiveServerSettings", filtered)
        end
        ::continue::
    end
end

function Settings:sv_onGetSetting(name, remote)
    if self:sv_detectClientCheat({ remote = remote, funcName = "sv_onGetSetting" }) then return end
    sm.log.info("Settings:sv_onGetSetting()")
    if not name then return end
    for i, setting in pairs(self.sv.settingsData.settings) do
        if setting.name == name then
            return setting
        end
    end
    return nil
end

function Settings:sv_onGetSettingIndex(name, remote)
    if self:sv_detectClientCheat({ remote = remote, funcName = "sv_onGetSettingIndex" }) then return end
    sm.log.info("Settings:sv_onGetSettingIndex()")
    if not name then return end
    for i, setting in pairs(self.sv.settingsData.settings) do
        if setting.name == name then
            return i
        end
    end
end

function Settings:sv_onSettingChangedByClient(args, remote)
    sm.log.info("Settings:sv_onSettingChanged()")
    if not args then return end
    if type(args) ~= "table" then return end
    if not args.setting then return end
    if type(args.setting) ~= "table" then return end
    if not args.setting.name then return end
    if args.setting.value == nil then return end

    local serverSetting = self:sv_onGetSetting(args.setting.name)

    if not serverSetting or type(serverSetting) ~= "table" then return end

    if serverSetting.clientViewable == false and self.sv.hostPlayer ~= remote then
        sm.log.warning("Settings:sv_onSettingChanged() "..remote.name.." sent setting that is not viewable")
        self:sv_onStatusSet({ status = "WARNING", active = true })
        return
    end
    serverSetting.value = args.setting.value
    self:sv_sendClientsSettings({remote})
end



--------------------------------------------------------------------------------
--================================== Client ==================================--
--------------------------------------------------------------------------------

function Settings:cl_onCreateSettings()
    sm.log.info("Settings:cl_onCreateSettings()")
    self.cl.settingsData = {
        page = 1,
        settings = {},
        fade = {}
    }
    for i = 1, SETTINGS_DATA.settingsPerPage do
        self.cl.settingsData.fade[i] = {
            time = 0,
            textCache = "",
            type = nil,
            color = nil
        }
    end
end

function Settings:cl_onSettingsUpdate(dt)
    local layout = self.cl.gui.layout
    for i, fade in pairs(self.cl.settingsData.fade) do
        if fade.time > 0 and fade.type ~= nil then
            fade.time = fade.time - dt
            if fade.time < 0 then
                fade.time = 0
                fade.textCache = ""
                fade.type = nil
                fade.color = nil
            end
            if not fade.type then return end
            local lerped = fade.time/SETTINGS_DATA.fadeTime
            local color = self:lerpColor(SETTINGS_DATA.orginalColor, SETTINGS_DATA.appliedColor, lerped)
            local text = "#"..self:colorToHex(color)..tostring(fade.textCache)
            layout:setText("Setting " .. i .. " "..fade.type, text)
        end
    end
end

function Settings:cl_onReceiveServerSettings(settings)
    sm.log.info("Settings:cl_onReceiveServerSettings()")
    self.cl.settingsData.settings = settings
    self:cl_onOpenSettings()
end

function Settings:cl_onSettingSliderCallback(widget, value)
    sm.log.info("Settings:cl_onSliderCallback() " .. widget .. " " .. value)
    local layout = self.cl.gui.layout
    local base = (self.cl.settingsData.page - 1) * SETTINGS_DATA.settingsPerPage

    local round3 = function(v)
        return math.floor(v * 1000 + 0.5) / 1000
    end

    local toStep = function(v, step)
        return math.floor(v / step + 0.5) * step
    end

    for i = 1, SETTINGS_DATA.settingsPerPage do
        if "Setting " .. i .. " Slider" == widget then
            local settingIndex = i + base
            local setting = self.cl.settingsData.settings[settingIndex]
            if not setting then return end

            local newValue = round3(toStep(sm.util.lerp(setting.limit.minValue, setting.limit.maxValue, value), setting.limit.step))
            if setting.value ~= newValue then
                self.cl.settingsData.fade[i] = {
                    time = SETTINGS_DATA.fadeTime,
                    textCache = tostring(setting.value),
                    type = "Slider Value",
                    color = SETTINGS_DATA.appliedColor
                }
                self:cl_onSettingChanged(setting)
            end
            setting.value = round3(toStep(sm.util.lerp(setting.limit.minValue, setting.limit.maxValue, value), setting.limit.step))
            layout:setText("Setting " .. i .. " Slider Value", tostring(setting.value))
            return
        end
    end
end

function Settings:cl_onSettingTextAccepted(widget, text)
    sm.log.info("Settings:cl_onTextAcceptedCallback() " .. widget .. " " .. text)

    local layout = self.cl.gui.layout
    local data = self.cl.settingsData
    local page = data.page
    local perPage = SETTINGS_DATA.settingsPerPage
    local base = (page - 1) * perPage
    local fadeTime = SETTINGS_DATA.fadeTime

    local function round3(v)
        return math.floor(v * 1000 + 0.5) / 1000
    end

    local function num(str)
        str = tostring(str):gsub("[^%d%.%-%+eE]", "")
        return tonumber(str)
    end

    local function fade(i, cache, t)
        data.fade[i] = {
            time = fadeTime,
            textCache = tostring(cache),
            type = t
        }
    end

    local function clampStep(v, min, max, step)
        if min and v < min then v = min end
        if max and v > max then v = max end
        if step and step ~= 0 then
            v = math.floor(v / step) * step
        end
        return v
    end

    for i = 1, perPage do
        local prefix = "Setting " .. i .. " "
        local index = i + base
        local setting = data.settings[index]

        if not setting then return end

        if widget == prefix .. "String" then
            local t = setting.type

            if t == "integer" or t == "float" then
                local value = num(text)
                if not value then
                    layout:setText(widget, tostring(setting.value))
                    return
                end

                if t == "integer" then
                    value = math.floor(value)
                end

                if setting.limit then
                    value = clampStep(
                        value,
                        setting.limit.minValue,
                        setting.limit.maxValue,
                        setting.limit.step
                    )
                end

                if t == "integer" then
                    value = math.floor(value)
                else
                    value = round3(value)
                end

                setting.value = value
                fade(i, value, "String")
                layout:setText(widget, tostring(value))
                self:cl_onSettingChanged(setting)
                return

            elseif t == "string" then
                setting.value = text
                fade(i, text, "String")
                layout:setText(widget, text)
                self:cl_onSettingChanged(setting)
                return
            end

        elseif widget == prefix .. "Color" then
            text = tostring(text):gsub("^#", "")

            local color, ok = self:hexToColor(text)
            if not ok then
                layout:setText(widget, self:colorToHex(setting.value))
                return
            end

            setting.value = color
            fade(i, text, "Color")
            layout:setText(widget, self:colorToHex(color))
            layout:setColor(prefix .. "Color Icon", color)
            self:cl_onSettingChanged(setting)
            return

        else
            local axis = widget:match("^" .. prefix .. "Vector3 ([XYZ])$")
            if axis and setting.type == "vector3" then
                local value = num(text)
                if not value then
                    layout:setText(widget, tostring(setting.value[axis:lower()]))
                    return
                end

                local a = axis:lower()
                local lim = setting.limit

                if lim then
                    value = clampStep(
                        value,
                        lim.minValue and lim.minValue[a],
                        lim.maxValue and lim.maxValue[a],
                        lim.step and lim.step[a]
                    )
                end

                value = round3(value)

                local v = setting.value
                setting.value = sm.vec3.new(
                    axis == "X" and value or v.x,
                    axis == "Y" and value or v.y,
                    axis == "Z" and value or v.z
                )

                fade(i, value, "Vector3 " .. axis)
                layout:setText(widget, tostring(value))
                self:cl_onSettingChanged(setting)
                return
            end
        end
    end
end

function Settings:cl_onSettingButtonClick(button)
    sm.log.info("Settings:cl_onButtonClick() " .. button)
    if button == "Settings Last" then
        self.cl.settingsData.page = self.cl.settingsData.page - 1
        self:cl_onOpenSettings()
        return true
    elseif button == "Settings Next" then
        self.cl.settingsData.page = self.cl.settingsData.page + 1
        self:cl_onOpenSettings()
        return true
    end

    for i = 1, SETTINGS_DATA.settingsPerPage do
        if button == "Setting " .. i .. " Toggle" then
            sm.log.info("Settings:cl_onButtonClick() " .. button)
            local settingIndex = i + ((self.cl.settingsData.page-1) * SETTINGS_DATA.settingsPerPage)
            local setting = self.cl.settingsData.settings[settingIndex]

            self.cl.settingsData.fade[i] = {
                time = SETTINGS_DATA.fadeTime,
                textCache = capitalize(tostring(setting.value)),
                type = "Toggle",
                color = SETTINGS_DATA.appliedColor
            }
            setting.value = not setting.value
            self:cl_onSettingChanged(setting)
            self.cl.gui.layout:setText("Setting " .. i .. " Toggle", capitalize(tostring(setting.value)))
            return true
        end
    end
    return false
end

function Settings:cl_onOpenSettings()
    local layout = self.cl.gui.layout
    local base = (self.cl.settingsData.page - 1) * SETTINGS_DATA.settingsPerPage

    for i,_ in ipairs(self.cl.settingsData.fade) do
        self.cl.settingsData.fade[i] = {
            time = 0,
            textCache = "",
            type = nil,
            color = nil
        }
    end

    local hideList = {
        "Name","Toggle","String BG","Color BG","Color Icon BG",
        "Vector3 X BG","Vector3 Y BG","Vector3 Z BG",
        "Vector3 X Static","Vector3 Y Static","Vector3 Z Static",
        "Slider","Slider Value"
    }

    local function validateSlider(setting)
        local lim = setting.limit
        return setting.isSlider and lim ~= nil and lim.minValue ~= nil and lim.maxValue ~= nil and lim.step ~= nil
    end

    local function round3(v)
        return math.floor(v * 1000 + 0.5) / 1000
    end

    self.cl.gui.layout:setVisible("Settings Last", self.cl.settingsData.page > 1)
    self.cl.gui.layout:setVisible("Settings Next", self.cl.settingsData.settings[(self.cl.settingsData.page - 1) * SETTINGS_DATA.settingsPerPage + SETTINGS_DATA.settingsPerPage] ~= nil)
    self.cl.gui.layout:setText("Settings Page", tostring(self.cl.settingsData.page))

    for i = 1, SETTINGS_DATA.settingsPerPage do
        local setting = self.cl.settingsData.settings[i + base]
        local prefix = "Setting " .. i .. " "

        for _, v in ipairs(hideList) do
            layout:setVisible(prefix .. v, false)
        end

        if not setting then goto continue end

        local isSlider = false
        if setting.type == "integer" or setting.type == "float" then
            isSlider = validateSlider(setting)
        end

        if setting.name then
            layout:setVisible(prefix .. "Name", true)

            local colorHex = ""

            if not setting.clientViewable then
                colorHex = self:colorToHex(SETTINGS_DATA.nonViewableColor)      -- server only / hidden from client
            end

            layout:setText(prefix .. "Name", colorHex .. setting.name)
        end

        if setting.type == "toggle" then
            local btn = prefix .. "Toggle"
            layout:setText(btn, capitalize(tostring(setting.value)))
            layout:setVisible(btn, true)

        elseif setting.type == "integer" then
            local edit = prefix .. "String"
            local slider = prefix .. "Slider"

            if isSlider then
                layout:setText(slider .. " Value", tostring(setting.value))
                layout:setVisible(slider, true)
                layout:setVisible(slider .. " Value", true)
            else
                layout:setText(edit, tostring(setting.value))
                layout:setVisible(edit, true)
                layout:setVisible(edit .. " BG", true)
            end

        elseif setting.type == "float" then
            local edit = prefix .. "String"
            local slider = prefix .. "Slider"
            local v = round3(setting.value)

            if isSlider then
                layout:setText(slider .. " Value", tostring(v))
                layout:setVisible(slider, true)
                layout:setVisible(slider .. " Value", true)
            else
                layout:setText(edit, tostring(v))
                layout:setVisible(edit, true)
                layout:setVisible(edit .. " BG", true)
            end

        elseif setting.type == "string" then
            local edit = prefix .. "String"
            layout:setText(edit, setting.value)
            layout:setVisible(edit, true)
            layout:setVisible(edit .. " BG", true)

        elseif setting.type == "color" then
            layout:setText(prefix .. "Color", self:colorToHex(setting.value))
            layout:setColor(prefix .. "Color Icon", setting.value)
            layout:setVisible(prefix .. "Color BG", true)
            layout:setVisible(prefix .. "Color Icon BG", true)

        elseif setting.type == "vector3" then
            local vx = prefix .. "Vector3 X"
            local vy = prefix .. "Vector3 Y"
            local vz = prefix .. "Vector3 Z"

            local Vx = round3(setting.value.x)
            local Vy = round3(setting.value.y)
            local Vz = round3(setting.value.z)

            layout:setText(vx, tostring(Vx))
            layout:setText(vy, tostring(Vy))
            layout:setText(vz, tostring(Vz))

            layout:setVisible(vx .. " BG", true)
            layout:setVisible(vy .. " BG", true)
            layout:setVisible(vz .. " BG", true)

            layout:setVisible(vx .. " Static", true)
            layout:setVisible(vy .. " Static", true)
            layout:setVisible(vz .. " Static", true)

            layout:setVisible(vx, true)
            layout:setVisible(vy, true)
            layout:setVisible(vz, true)
        end

        ::continue::
    end
end

function Settings:cl_onSettingChanged(setting)
    sm.log.info("Settings:cl_onSettingChanged()")
    if not setting then
        sm.log.info("Settings:cl_onSettingChanged() setting is nil")
        self:cl_onStatusSet("INFO", true)
        return
    end
    self.network:sendToServer("sv_onSettingChangedByClient", {
        player = sm.localPlayer.getPlayer(),
        setting = setting
    })
end
