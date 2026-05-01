GUI = class()

--------------------------------------------------------------------------------
--================================== Globals =================================--
--------------------------------------------------------------------------------

local GUI_FILE = "$CONTENT_DATA/Gui/Layouts/CentralAPI.layout"

local GUI_LAYOUT_PROPERTIES = {
    isHud = false,         --Whether the GUI is a HUD GUI or not.
    isInteractive = true,  --Whether the GUI can be interacted with or not.
    needsCursor = true,    --Whether the GUI frees player's cursor and makes it visible or not.
    hidesHotbar = false,   --Whether the GUI hides player's hotbar or not. NOTE: this hides only the hotbar, other parts of the hud like the health bar or the logbook icon have to be hidden manually!
    isOverlapped = true,   --Whether the GUI overlaps any non-hardcoded GUIs or not. NOTE: If multiple overlapping GUIs are created, the last one to be opened will be on top.
    backgroundAlpha = 0.5, --How much the GUI blurs player's screen, a fraction between 0 and 1. 0 - no blur, 1 - black background.
}

local GUI_BUTTONS = {
    "Main_Dashboard",
    "Main_Modules",
    "Main_Logs",
    "Main_Network",
    "Main_Settings",
    "Main_Credits",
    "Main_About",

    "Setting 1 Toggle",
    "Setting 2 Toggle",
    "Setting 3 Toggle",
    "Setting 4 Toggle",
    "Setting 5 Toggle",
    "Setting 6 Toggle",

    "Settings Last",
    "Settings Next",

    "Back",

    "Reset Status",
}

local GUI_EDITBOXES = {
    "Setting 1 String",
    "Setting 2 String",
    "Setting 3 String",
    "Setting 4 String",
    "Setting 5 String",
    "Setting 6 String",

    "Setting 1 Color",
    "Setting 2 Color",
    "Setting 3 Color",
    "Setting 4 Color",
    "Setting 5 Color",
    "Setting 6 Color",

    "Setting 1 Vector3 X",
    "Setting 1 Vector3 Y",
    "Setting 1 Vector3 Z",
    "Setting 2 Vector3 X",
    "Setting 2 Vector3 Y",
    "Setting 2 Vector3 Z",
    "Setting 3 Vector3 X",
    "Setting 3 Vector3 Y",
    "Setting 3 Vector3 Z",
    "Setting 4 Vector3 X",
    "Setting 4 Vector3 Y",
    "Setting 4 Vector3 Z",
    "Setting 5 Vector3 X",
    "Setting 5 Vector3 Y",
    "Setting 5 Vector3 Z",
    "Setting 6 Vector3 X",
    "Setting 6 Vector3 Y",
    "Setting 6 Vector3 Z",
}

local GUI_SLIDERS = {
    "Setting 1 Slider",
    "Setting 2 Slider",
    "Setting 3 Slider",
    "Setting 4 Slider",
    "Setting 5 Slider",
    "Setting 6 Slider",
}

local GUI_PAGES = {
    "MainMenu",
    "Dashboard",
    "Modules",
    "Logs",
    "Network",
    "Settings",
    "Info"
}

local GUI_VALID_MENUS = {
    Main = "MainMenu",
    Dashboard = "Dashboard",
    Modules = "Modules",
    Logs = "Logs",
    Network = "Network",
    Settings = "Settings",
    About = "Info",
    Credits = "Info"
}

local GUI_TEXTS = {
    ["About"] = [[#00C2FFCentralAPI#FFFFFF is a #3A86FFlightweight runtime system#FFFFFF for Scrap Mechanic mods that allows code to run continuously in the background.\n\nInstead of each mod handling its own #FFB020update loops#FFFFFF and timing systems, CentralAPI provides a #32C85Ashared execution layer#FFFFFF that ensures consistent, centralized processing across all compatible mods.\n\nIt is designed to support always-running logic such as #7B61FFautomation systems#FFFFFF, world updates, background tasks, and utility functions similar to an #FF8C00autotool-style framework#FFFFFF.\n\nCentralAPI also enables #00C2FFmod-to-mod connections#FFFFFF, allowing compatible mods to communicate, share data, and build on each other's systems for greater #32C85Amodularity#FFFFFF and extensibility.\n\nCentralAPI focuses on #3A86FFstability#FFFFFF, #32C85Asimplicity#FFFFFF, and #FFB020performance#FFFFFF, allowing multiple systems to run together without conflicts or duplicated logic.\n\nVersion: #32C85A1.0.0#FFFFFF\nCreated by: #7B61FFSabrina#FFFFFF]],
    ["Credits"] = [[#00C2FFCredits#FFFFFF\n\n#7B61FFSabrina#FFFFFF - Creator / Developer\n\n#FFB020Thanks#FFFFFF - Scrap Mechanic modding community]]
}

--------------------------------------------------------------------------------
--================================== Client ==================================--
--------------------------------------------------------------------------------

function GUI:cl_onCreateGUI()
    sm.log.info("GUI:cl_onCreateGUI()")
    self.cl.gui = {}
    self:cl_onInitGui()
end

function GUI:cl_onRefreshGUI()
    sm.log.info("GUI:cl_onRefreshGUI()")
    self:cl_onInitGui()
    self.cl.gui.layout:setVisible("DEBUG MODE", true)
    self.cl.gui.layout:setVisible("Reset Status", true)
end

function GUI:cl_onInitGui()
    sm.log.info("GUI:cl_onInitGui()")
    local reopen = false
    if self.cl.gui and self.cl.gui.layout and sm.exists(self.cl.gui.layout) then
        sm.log.info("GUI:cl_onInitGui() gui already exists, reloading it")
        reopen = self.cl.gui.layout:isActive()
        self.cl.gui.layout:close()
        self.cl.gui.layout:destroy()
        self.cl.gui.layout = nil
    end
    self.cl.gui.layout = sm.gui.createGuiFromLayout(GUI_FILE, false, GUI_LAYOUT_PROPERTIES)
    for _, button in pairs(GUI_BUTTONS) do
        self.cl.gui.layout:setButtonCallback(button, "cl_onButtonClick")
    end
    for _, editbox in pairs(GUI_EDITBOXES) do
        self.cl.gui.layout:setTextAcceptedCallback(editbox, "cl_onTextAccepted")
    end
    for _, slider in pairs(GUI_SLIDERS) do
        self.cl.gui.layout:setSliderCallback(slider, "cl_onSliderChanged")
    end
    if reopen then
        self:cl_openGuiPage(self.cl.gui.currentInfoPage)
        self.cl.gui.layout:open()
    end

    -- disable debug mode and reset status buttons
    self.cl.gui.layout:setVisible("DEBUG MODE", false)
    self.cl.gui.layout:setVisible("Reset Status", false)
end

function GUI:cl_onButtonClick(button)
    local success, err = pcall(function()
        sm.log.info("GUI:cl_onButtonClick() " .. button)
        if button == "Main_Settings" then
            self:cl_openGuiPage("Settings")
            return
        elseif button == "Main_About" then
            self:cl_openGuiPage("About")
            return
        elseif button == "Main_Credits" then
            self:cl_openGuiPage("Credits")
            return
        elseif button == "Back" then
            self:cl_openGuiPage("Main")
            return
        elseif button == "Reset Status" then
            self:cl_onResetStatus()
            return
        end
        if self:cl_onSettingButtonClick(button) then return end
        sm.log.info("GUI:cl_onButtonClick() unhandled button", button)
        self:cl_onStatusSet("QUESTION", true, true)
    end)
    if not success then
        sm.log.error("GUI:cl_onButtonClick() " .. err)
        self:cl_onStatusSet("ERROR", true, true)
    end
end

function GUI:cl_onTextAccepted(editbox, text)
    sm.log.info("GUI:cl_onTextAccepted() " .. editbox .. " " .. text)
    self:cl_onSettingTextAccepted(editbox, text)
end

function GUI:cl_onSliderChanged(slider, value)
    value = value / 10000 -- 0-1 range
    sm.log.info("GUI:cl_onSliderChanged() " .. slider .. " " .. value)
    self:cl_onSettingSliderCallback(slider, value)
end

function GUI:cl_onOpenGUI()
    sm.log.info("GUI:cl_onOpenGUI()")
    if not self.cl.gui or not self.cl.gui.layout then
        sm.log.error("GUI:cl_onOpenGUI() layout not found")
        self:cl_onStatusSet("ERROR", true, true)
        return
    end
    self:cl_openGuiPage("Main")
    self.cl.gui.layout:open()
end

function GUI:cl_openGuiPage(page)
    sm.log.info("GUI:cl_onOpenMenu() " .. page)

    local target = GUI_VALID_MENUS[page]

    if not target then
        sm.log.warning("GUI:cl_onOpenMenu() " .. tostring(page) .. " is not a valid menu")
        self:cl_onStatusSet("WARNING", true, true)
        return
    end

    for _, page in ipairs(GUI_PAGES) do
        self.cl.gui.layout:setVisible(page, page == target)
    end

    if page == "Main" then
        self.cl.gui.layout:setText("Title", "#00C2FFCentral API")
        self.cl.gui.layout:setVisible("Back", false)
    elseif page == "Settings" then
        self.cl.gui.layout:setText("Title", "#00C2FFSettings")
        self.cl.gui.layout:setVisible("Back", true)
        self:cl_onOpenSettings()
    elseif page == "About" then
        self.cl.gui.layout:setText("Title", "#00C2FFAbout Central API")
        self.cl.gui.layout:setText("Info Text", GUI_TEXTS["About"])
        self.cl.gui.layout:setVisible("Back", true)
    elseif page == "Credits" then
        self.cl.gui.layout:setText("Title", "#00C2FFCredits")
        self.cl.gui.layout:setText("Info Text", GUI_TEXTS["Credits"])
        self.cl.gui.layout:setVisible("Back", true)
    end

    self.cl.gui.currentInfoPage = page
end
