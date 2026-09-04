local unitdefs = include( "sim/unitdefs" )
local simfactory = include( "sim/simfactory" )
local simdefs = include( "sim/simdefs" )
local util = include( "modules/util" )

SLF_dragon_ephemeral = {
	onSpawnAbility = function( self, sim, unit )
		self.dragon = unit:getUnitOwner()

		-- can we be summoned like some mongrel pup?
		if not self.dragon:getTraits().acw_genie_lamp then
			-- set a trigger for warp-in, which should follow
			local trigger = sim:addTrigger( simdefs.TRG_START_TURN, self )
			trigger.priority = -11
		end
	end,

	--[[onDespawnAbility = function(self, sim)
		--sim:removeTrigger( simdefs.TRG_MAP_EVENT, self )
	end,]]

	onTrigger = function( self, sim, evType, evData )
		if evType == simdefs.TRG_START_TURN then
			if not sim:getParams().ACW_dragonbound and not self.dragon:getTraits().acw_anchor then
				-- disappear into thin smoke...
				-- if we're not dragonbound, we leave behind the Anchorer.
				-- You know. The augment that creates an Anchor.
				sim:removeTrigger( simdefs.TRG_START_TURN, self )
				local unitTemplate = unitdefs.lookupTemplate( "SLF_augment_dragon_projector" )
				local augment = simfactory.createUnit( unitTemplate, sim )
				--log:write(util.stringize(augment, 2))
				sim:spawnUnit(augment)
				sim:warpUnit(augment, sim:getCell(self.dragon:getLocation()) )
				augment:setPlayerOwner( self.dragon:getPlayerOwner() )
				-- don't spawn the augment a second time even if it was never bound; this breaks rewind and so is nonfunctional
				-- ergo, KNOWN BUG: if you never install the augment, you can get a second one next mission, which lets you do Shenanigans:tm:
				--sim:getParams().ACW_dragonbind_setup = true
			end
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
			if not sim:getParams().ACW_dragonbound and not self.dragon:getTraits().acw_anchor then
				--log:write("Sending non-dragonbound Emma into limbo. Info follows ---")
				sim:warpUnit(self.dragon)
				--log:write(util.stringize(self.dragon, 2))
				sim:getPC()._dragon_in_limbo = self.dragon
			end
		end
	end,
}

return SLF_dragon_ephemeral