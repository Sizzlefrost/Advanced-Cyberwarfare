local simdefs = include("sim/simdefs")
local sim = include("sim/engine")
local simquery = include("sim/simquery")
local util = include("modules/util")

-- unoptimized repeating code alert

SLF_nullblock = 
{
	null_cells = {},
	onSpawnAbility = function( self, sim, unit )
		self.abilityOwner = unit
		sim._ACW_null_cells = {}
		sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
		sim:addTrigger( simdefs.TRG_ICE_BROKEN, self )
		sim:addTrigger( simdefs.TRG_UNIT_KO, self )
		sim:addTrigger( simdefs.TRG_UNIT_EMP, self )
	end,

	onDespawnAbility = function( self, sim, unit )
		sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
		sim:removeTrigger( simdefs.TRG_ICE_BROKEN, self )
		sim:removeTrigger( simdefs.TRG_UNIT_KO, self )
		sim:removeTrigger( simdefs.TRG_UNIT_EMP, self )
	end,

	refreshNull = function( self, sim )
		local new_null_cells = {}
		-- silly monstrosity.
		-- first, loop over units, pick out the ones that project null zones
		-- for each null zone, add cells to the list, UNLESS they're already there
		-- then, with the list ready, unmark all null cells, then mark list null cells
		for i, unit in pairs(sim:getAllUnits()) do
			local range = unit:getTraits().mainframe_suppress_range
			local origin = sim:getCell(unit:getLocation())
			if range and not unit:isKO() and origin and not (unit:getPlayerOwner() == sim:getPC()) then -- copied hacking logic from mainframe
				local null_zone = simquery.fillCircle(sim, origin.x, origin.y, unit:getTraits().mainframe_suppress_range, 0)
				for _, cell in pairs(null_zone) do
					local already_exists = false
					for _, existingCell in pairs(new_null_cells) do
						if cell == existingCell then
							already_exists = true
						end
					end
					if cell == origin and not unit:isAlerted() then
						already_exists = true
					end
					if not already_exists then
						new_null_cells[cell.id] = cell
					end
				end
			end
		end
		-- we cannot use actual cell tags, or any cell data for that matter. That's non-sim, non-rewindproof data.
		-- just store it in the sim
		sim._ACW_null_cells = new_null_cells

		-- refresh the null cells
		sim:dispatchEvent( "ACW_null_refresh" )
		--log:write("ev sent: ACW_null_refresh")
	end,

	onTrigger = function( self, sim, evType, evData )
		--null drone is captured
		if evType == simdefs.TRG_ICE_BROKEN and evData.unit:getTraits().mainframe_suppress_range and evData.unit:getTraits().mainframe_ice <= 0 then
			self:refreshNull(sim)
		end

		--null drone KO and wakeup
		if (evType == simdefs.TRG_UNIT_KO or evType == simdefs.TRG_UNIT_EMP) and evData.unit and evData.unit:getTraits().mainframe_suppress_range then
			
			self:refreshNull(sim)
		end

		--null drone moves
		if evData.unit and not evData.unit:isKO() and evData.unit:getTraits().mainframe_suppress_range and evData.unit:getPlayerOwner() == sim:getNPC() then
			
			self:refreshNull(sim)
		end
	end,
}

return SLF_nullblock