local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local array = include("modules/array")
local util = include("modules/util")

-- if you know, you know
local SLF_dragon_lipulent = {
	onSpawnAbility = function ( self, sim, unit )
		self.abilityOwner = unit
		sim:addTrigger( simdefs.TRG_END_TURN, self )
	end,

	onTrigger = function ( self, sim, evType, evData )
		local anchor = self.abilityOwner:getTraits().acw_anchor
		if evType == simdefs.TRG_END_TURN and sim:getCurrentPlayer() == sim:getPC() then
			if self.abilityOwner:getTraits().acw_gc then
				-- pause for a bit
				sim:warpUnit(self.abilityOwner)
				-- apparently, setting player owner to nil doesn't play well with hudside
				self.abilityOwner:setPlayerOwner(sim:getNPC())
				if anchor then
					self.abilityOwner:getTraits().acw_genie_lamp.storedUnit = self.abilityOwner
		        	anchor:getTraits().acw_dependent = nil
		        	self.abilityOwner:getTraits().acw_gc = nil
		        end
			end
		end
	end,

	onDespawnAbility = function ( self, sim )
		sim:removeTrigger( simdefs.TRG_END_TURN, self )
	end,
}

local SLF_dragon_succulent = SLF_dragon_lipulent
return SLF_dragon_succulent