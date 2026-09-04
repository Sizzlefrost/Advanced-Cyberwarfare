local array = include( "modules/array" )
local util = include( "modules/util" )
local mainframe_common = include("sim/abilities/mainframe_common")

local DEFAULT_CAISSA = util.extend( mainframe_common.DEFAULT_ABILITY )
{
	desc_caissa = nil,

    PROGRAM_LIST = 15,

	isCaissaKingsbound = function(self, sim, pc)
		if not sim then return false end

		if not pc then pc = sim:getPC() end

		for i, program in pairs(pc:getAbilities()) do
			if program.name == STRINGS.SLF.PROGRAMS.KING.NAME then
				return true
			end
		end

		return false
	end,

	updateDescription = function(self, sim, pc)
		local kingsbound = self:isCaissaKingsbound(sim, pc)
		if not kingsbound then
			self.desc = self.desc_normal .. self.desc_caissa
		elseif self.desc_normal then
			self.desc = self.desc_normal
		end
		self.desc_made = true
	end,

	onSpawnAbility = function(self, sim, abilityOwner)
		mainframe_common.DEFAULT_ABILITY.onSpawnAbility(self, sim)

		self:updateDescription(sim, abilityOwner)
	end,

	onTooltip = function( self, screen, sim, player )
		local tooltip = mainframe_common.DEFAULT_ABILITY.onTooltip( self, screen, sim, player )

		self:updateDescription(sim)

		if not self:isCaissaKingsbound(sim) and not SCRIPT_PATHS.alternate_costs_framework then 
			-- with Prettier Programs, don't bother showing this bit, PP does that anyway
			local section = tooltip:addSection()
			section:addAbility(STRINGS.SLF.PROGRAMS.CAISSA_COMMON.CAISSA_TITLE, STRINGS.SLF.PROGRAMS.CAISSA_COMMON.CAISSA_DESC)
		end

		return tooltip
	end,

	onUnitdataTooltip = function( hud, tooltip, item, unit )
		-- we receive completely wrong args here -_- time to reconstruct a workable tooltip
		local sim = hud._game.simCore
		-- im genuinely not sure what to do if sim is undefined at this point...
		local abilityName = item:getUnitData().traits.mainframe_program
		local programdef = sim:getAbilities().lookupAbility( abilityName )

		-- base game doesn't delegate to ability, so I won't either :(
	    local section = tooltip:addSection()
	    -- name on one side, X PWR on the other
	    section:addLine( "<ttheader>"..programdef.name.."</>", util.sformat( STRINGS.PROPS.STORE_PROGRAM_TOOLTIP, programdef:getCpuCost() ))
		if programdef.maxCooldown and programdef.maxCooldown > 0  then
			section:addLine( util.sformat( STRINGS.PROGRAMS.COOLDOWN, programdef.maxCooldown )  )
		end
		section:addAbility( programdef.shortdesc, programdef.desc, "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png" )

		if programdef.dlcFooter then
            section:addFooter(programdef.dlcFooter[1], programdef.dlcFooter[2])
        end

        if programdef.desc_caissa then
	        programdef:updateDescription(sim)
			if not programdef:isCaissaKingsbound(sim) and not SCRIPT_PATHS.alternate_costs_framework then 
				-- with Prettier Programs, don't bother showing this bit, PP does that anyway
				local section_2 = tooltip:addSection()
				section_2:addAbility(STRINGS.SLF.PROGRAMS.CAISSA_COMMON.CAISSA_TITLE, STRINGS.SLF.PROGRAMS.CAISSA_COMMON.CAISSA_DESC)
			end
		end

		return tooltip
	end,
}
mainframe_common.DEFAULT_CAISSA = DEFAULT_CAISSA

return {
	DEFAULT_CAISSA = DEFAULT_CAISSA,
} 