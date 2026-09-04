local util = include("modules/util")
local simquery = include("sim/simquery")
local abilityutil = include("sim/abilities/abilityutil")
local simdefs = include("sim/simdefs")
local inventory = include("sim/inventory")

local SLF_install_framework = {
	name = STRINGS.SLF.ITEMS.FRAMEWORK.INSTALL,
	createToolTip = function( self,sim,unit,targetCell)
		return abilityutil.formatToolTip( STRINGS.SLF.ITEMS.FRAMEWORK.INSTALL, STRINGS.SLF.ITEMS.FRAMEWORK.INSTALL_DESC )
	end,
	profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_chargeweapon_small.png",

	alwaysShow = true,
	getName = function( self, sim, unit )
		return self.name
	end,

	onSpawnAbility = function(self, sim, unit)
		self.parentItem = unit
		self.parentItem._traits.SLF_install_ability = self

		-- frame is bound externally, from the item itself
		-- for some reason functions do not get ported when debug-spawning the item
		-- port them manually through this
		for i, element in pairs(unit._unitData) do
			if type(element) == "function" and not unit[i] then
				unit[i] = element
			end
		end

		--log:write("Spawning ability. Parent unit's onSpawn: "..util.stringize(unit.generateFrame))
	end,

	canUseAbility = function(self, sim, unit)
		local oldFrame = sim:getPC():getIncognitaFrame()

		-- cant install if:
		-- already using the same matrix
		if oldFrame.name == self.frame.name then
			return false, STRINGS.SLF.ITEMS.FRAMEWORK.CANT_INSTALL_REASON.SAME_FRAME
		end

		-- number of programs exceeds max capacity, after the frame would be installed
        local newMaxPrograms = simquery.getMaxPrograms(sim) - oldFrame.max_programs_mod + self.frame.max_programs_mod
		if #sim:getPC():getAbilities() > newMaxPrograms then
			return false, STRINGS.SLF.ITEMS.FRAMEWORK.CANT_INSTALL_REASON.PROGRAM_SLOTS
		end
		-- number of non-specialized programs exceeds max non-specialized capacity, after the frame would be installed
        local newMaxNormal = newMaxPrograms - self.frame:getTotalSpecSlots()
        local newCounts = sim:getPC():countSpecSlots(self.frame)
        if newCounts.EMPTY > newMaxNormal then -- couldn't fit everything into slots
			return false, STRINGS.SLF.ITEMS.FRAMEWORK.CANT_INSTALL_REASON.SPEC_PROGRAMS 
		end

		return true
	end,

	executeAbility = function(self, sim, unit, userUnit)
		local player = sim:getPC()
		-- replace the frame
		player:setIncognitaFrame( self.frame )
		-- reapply PWR cap, if needed
		if player:getCpus() > player:getMaxCpus() then
			player:addCPUs(player:getMaxCpus() - player:getCpus())
		end
		-- reapply Hash cap, if needed
		if player:getTraits().aiToken and player:getTraits().aiToken > player:getTraits().aiTokenMax then
			player:getTraits().aiToken = player:getTraits().aiTokenMax
		end
		-- the rest should be handled by the frames' onDespawn / onSpawn

		-- finally, show some fancy graphics, but only if we are not in replay
		sim:dispatchEvent( "ACW_frame_installed", { frame = self.frame, frameName = self.frame.name, icon = "gui/profile_icons/incognita_64.png" } )
		sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/VoiceOver/Incognita/Pickups/SynchronizationComplete" )	
		
		-- destroy the consumable item
		inventory.useItem( sim, userUnit, unit )
	end,
}

return SLF_install_framework