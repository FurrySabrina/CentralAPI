Graph = class()

--------------------------------------------------------------------------------
--================================== Globals ==================================--
--------------------------------------------------------------------------------

local lineUUID = sm.uuid.new("628b2d61-5ceb-43e9-8334-a4135566df7a") -- actally plastic block uuid
local CylinderUUID = sm.uuid.new("0dba257b-b907-4919-baaf-2fefe19f4e24") -- actual pipe small uuid
local CylinderRotation = sm.vec3.new(0, 90, 0)

--------------------------------------------------------------------------------
--================================== Client ==================================--
--------------------------------------------------------------------------------

--[[
function Epic2DEffectPositioning:client_onCreate()
	self.cl = {}
	self.cl.gui = sm.gui.createGuiFromLayout("$GAME_DATA/Gui/Layouts/Common/ToolTip.layout", nil, {
        isHud = false,
        isInteractive = true,
        needsCursor = true,
        hidesHotbar = true,
        isOverlapped = true,
        backgroundAlpha = 0.5,
    })
	self.cursor1 = sm.effect.createEffect2D( "Gui - LogbookIcon Flash" )
	self.cursor2 = sm.effect.createEffect2D( "Gui - LogbookIcon Flash" )
	self.cursor3 = sm.effect.createEffect2D( "Gui - LogbookIcon Flash" )
	self.cursor4 = sm.effect.createEffect2D( "Gui - LogbookIcon Flash" )
	self.cursor5 = sm.effect.createEffect2D( "Gui - LogbookIcon Flash" )
end

function findClosestResolution(targetWidth, targetHeight)
    local resolutionName = nil
    if targetWidth < 1920 and targetHeight < 1080 then
        return {width = 1280, height = 720}
    elseif targetWidth < 2560 and targetHeight < 1440 then
        return {width = 1920, height = 1080}
    elseif targetWidth < 3840 and targetHeight < 2160 then
        return {width = 2560, height = 1440}
    else
        return {width = 3840, height = 2160}
    end
end

function Epic2DEffectPositioning:client_onUpdate(dt)

	if self.cl.gui:isActive() then
		for i = 1, 5 do
			self["cursor"..i]:start()
		end
		
		local width, height = sm.gui.getScreenSize()
		local closestNormalRes = findClosestResolution(width, height)
		local closestX, closestY = closestNormalRes.width, closestNormalRes.height
		--print("closestNormalRes: ", closestNormalRes)
		local ratioMultiplierX = (width / closestX)
		local ratioMultiplierY = (height / closestY)
		
		self.cursor1:setPosition(sm.vec3.new(0,0,0))
		self.cursor2:setPosition(sm.vec3.new(16 * ratioMultiplierX,0,0))
		self.cursor3:setPosition(sm.vec3.new(0,0,9 * ratioMultiplierY))
		self.cursor4:setPosition(sm.vec3.new(16 * ratioMultiplierX,0,9 * ratioMultiplierY))
		self.cursor5:setPosition(sm.vec3.new(8 * ratioMultiplierX,0,4.5 * ratioMultiplierY))
	end
end

function Epic2DEffectPositioning:client_onInteract(_, state)
	if not state then return end
	self.cl.gui:open()
end
]]
