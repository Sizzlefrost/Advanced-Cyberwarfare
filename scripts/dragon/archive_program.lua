local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "client_util" )
local simdefs = include("sim/simdefs")
local cdefs = include( "client_defs" )
local mainframe = include( "sim/mainframe" )
local modifiers = include( "sim/modifiers" )
local mission_util = include( "sim/missions/mission_util" )
local serverdefs = include("modules/serverdefs")
local mainframe_common = include("sim/abilities/mainframe_common")
local mainframe_abilities_base = include("sim/abilities/mainframe_abilities")
local nonbreakIceTooltip = include( "hud/tooltip_nonbreakice" )
local booster_tooltip = class(nonbreakIceTooltip)


local DEFAULT_ABILITY = mainframe_common.DEFAULT_ABILITY

function booster_tooltip:init( mainframePanel, targetWidget, unit, reason )
	util.tooltip.init( self, mainframePanel._hud._screen )
	self._targetWidget = targetWidget
	self.mainframePanel = mainframePanel

	local localPlayer = mainframePanel._hud._game:getLocalPlayer()
	local equippedProgram = nil
	if localPlayer then 
		equippedProgram = localPlayer:getEquippedProgram()
		if equippedProgram then
			local programWidget = mainframePanel._panel.binder.programsPanel:findWidget( equippedProgram:getID() )		
			if programWidget and programWidget:isVisible() then            	
				self._ux0, self._uy0 = programWidget.binder.btn:getAbsolutePosition()
				if equippedProgram:canUseAbility( mainframePanel._hud._game.simCore, localPlayer ) then
					self.programWidget = programWidget
					self.equippedProgram = equippedProgram
				end
			end
		end
	end

	local section = self:addSection()
	section:addLine( "<ttheader>"..util.sformat( "TARGET {1}", unit:getName() ).."</>" )

	if equippedProgram then
		if equippedProgram:getDef().credit_cost then
			section:addAbility( string.format(STRINGS.UI.TOOLTIPS.CURRENTLY_EQUIPPED, equippedProgram:getDef().name), util.sformat(equippedProgram:getDef().tipdesc, equippedProgram:getCpuCost(), equippedProgram:getDef().credit_cost),  "gui/icons/arrow_small.png" )
		else
			section:addAbility( string.format(STRINGS.UI.TOOLTIPS.CURRENTLY_EQUIPPED, equippedProgram:getDef().name), util.sformat(equippedProgram:getDef().tipdesc, equippedProgram:getCpuCost()),  "gui/icons/arrow_small.png" )
		end
	end 

	if reason then
		section:addRequirement( reason )
	end
end

local mainframe_abilities =
{	---------------------------------------------------------------------------
	--THIS IS ALICE IN WONDERLAND (aka dragon in cyberspace)
	---------------------------------------------------------------------------
	SLF_dragon_intellect = util.extend( DEFAULT_ABILITY )
	{     
		name = STRINGS.SLF.PROGRAMS.DRAGON2.NAME,   
		desc = STRINGS.SLF.PROGRAMS.DRAGON2.DESC,
		huddesc = STRINGS.SLF.PROGRAMS.DRAGON2.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.DRAGON2.SHORT_DESC,
		tipdesc = STRINGS.SLF.PROGRAMS.DRAGON2.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_DragonWise.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_DragonWise.png",
		--value = 0,	
		cpu_cost = 2,
		cooldown = 0,
		maxCooldown = 1,
		equip_program = true, 
		equipped = false,
		targetingIcon = "gui/icons/item_icons/items_icon_small/icon-item_chargeweapon_small.png",
		targetingDisabledColor = util.color(0.45,0.45,0.5,0.6),
		targetingColor = util.color( 120/255, 244/255, 255/255 ),
		targetingHoverColor = util.color( 188/255, 250/255, 255/255 ),
		targetRawUnit = true,
		target = {},

		customTargetTooltip = function( mainframePanel, widget, unit, reason )
			return booster_tooltip( mainframePanel, widget, unit, reason )
		end,

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			local player = sim:getCurrentPlayer()

			if targetUnit then
				if not targetUnit:getTraits().isAgent then 				
					return false
				end
				
				if targetUnit:getTraits().isGuard then 				
					return false
				end

				if targetUnit:isGhost() then
					return false
				end

				if targetUnit:getPlayerOwner() ~= sim:getPC() then
					return false
				end

				if targetUnit:ownsAbility("SLF_dragon_scout") then
					return false, STRINGS.SLF.PROGRAMS.DRAGON2.FAILDRAGON
				end

				if targetUnit:getTraits().dashSoundRangeNormal and targetUnit:getTraits().dashSoundRangeNormal > targetUnit:getTraits().dashSoundRange then
					return false, STRINGS.SLF.PROGRAMS.DRAGON2.FAIL
				end

				if not sim:canPlayerSeeUnit( sim:getPC(), targetUnit ) then
					return false
				end
			end

			if player == nil or player ~= abilityOwner then
				return false
			end

			if player:getCpus() < self:getCpuCost() then
				return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
			end

			if self.cooldown > 0 then
				return false, STRINGS.UI.REASON.EQUIPPED_ON_COOLDOWN
			end

			return true	
		end,

		executeAbility = function ( self, sim, unit )
			self:useCPUs( sim )
			self:setCooldown( sim )
			unit:getTraits().mp = unit:getTraits().mp + 3
			unit:getTraits().dashSoundRangeDragon = unit:getTraits().dashSoundRange
			unit:getTraits().dashSoundRange = unit:getTraits().dashSoundRange - 3
			--log:write("[AC][DRAGASSIST] Added marker trait to unit ID "..unit:getID()..", designation '"..unit:getName().."'")
			--log:write("[AC][DRAGASSIST] Marked unit's saved dash sound range: "..unit:getTraits().dashSoundRangeDragon)
		end,

		onSpawnAbility = function( self, sim )
			DEFAULT_ABILITY.onSpawnAbility( self, sim )
			sim:addTrigger( simdefs.TRG_END_TURN, self )
		end,

		onDespawnAbility = function( self, sim )
			DEFAULT_ABILITY.onDespawnAbility( self, sim )
	        sim:removeTrigger( simdefs.TRG_END_TURN, self )
	    end,

	    onTrigger = function( self, sim, evType, evData )
	    	DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )
	    	if evType ~= simdefs.TRG_END_TURN or sim:getCurrentPlayer() ~= sim:getPC() then
	    		return
	    	end

	    	--log:write("[AC][DRAGASSIST] Searching for marked units")
	    	local target = nil
	    	for _, unit in pairs(sim:getPC():getUnits()) do
	    		if unit:hasTrait("isAgent") then
		    		if unit:getTraits().dashSoundRangeDragon ~= nil then
		    			target = unit
		    		end
		    	end
	    	end
	    	if target then
	    		--log:write("[AC][DRAGASSIST] Found marked unit, designation "..target:getName())
	    		--log:write("[AC][DRAGASSIST] Marked unit's general dash range: "..target:getTraits().dashSoundRangeDragon..", modified to "..target:getTraits().dashSoundRange)
	    		--log:write("[AC][DRAGASSIST] Resetting the dash range now")
		    	target:getTraits().dashSoundRange = target:getTraits().dashSoundRangeDragon
		    	target:getTraits().dashSoundRangeDragon = nil
		    end
		end,
	},
}

return mainframe_abilities