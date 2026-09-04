local sim = include("sim/engine")
local simdefs = include("sim/simdefs")
local util = include("modules/util")
local mathutil = include("modules/mathutil")
local simquery = include("sim/simquery")

------ console render filters
local consolerig = include("gameplay/consolerig").rig
local oldRefresh = consolerig.refresh

function consolerig:refresh()
	local result = oldRefresh(self) -- should be nil, but futureproofing
	local unit = self:getRawUnit()
	--log:write("CONSOLERIG #"..unit:getID().." - refreshed as per usual")
	--log:write(util.stringize(self,1))

	if unit:getTraits().mainframeShaderOverride then
		local renderFilter = {
			shader = KLEIAnim.SHADER_FOW,
			r = unit:getTraits().mainframeShaderOverride[1], 
			g = unit:getTraits().mainframeShaderOverride[2], 
			b = unit:getTraits().mainframeShaderOverride[3],
			a = unit:getTraits().mainframeShaderOverride[4],
			lum = 1.3
		}

		if unit then
			self._prop:setRenderFilter( renderFilter )
		end
	else
		local cdefs = include("client_defs")
		self._prop:setRenderFilter( cdefs.RENDER_FILTERS["default"] )
	end

	return result
end

local DEFAULT_BUFF =
{
    buffAbility = true, 

    getName = function( self, sim, unit )
        return self.name
    end,
        
    createToolTip = function( self,sim,unit,targetUnit)
        return formatToolTip( self.name, string.format("BUFF\n%s", self.desc ) )
    end,

    canUseAbility = function( self, sim, unit )
        return false -- Passives are never 'used'
    end,
    
    ghostable = true,

    executeAbility = nil, -- Passives by definition have no execute.
}

-- brain-like behaviour: Navigate from device to device, each alarm level. Secure devices on the same tile.
local guard_abilities = {
	SLF_stonewall_patrols = util.extend( DEFAULT_BUFF )
	{
	    visited = {},

	    onSpawnAbility = function( self, sim, unit )
	    	sim:addTrigger( simdefs.TRG_UNIT_WARP, self, unit )
	        sim:addTrigger( simdefs.TRG_ALARM_STATE_CHANGE, self, unit )
	        self.abilityOwner = unit

			unit:getBrain():onSpawned(sim, unit)
			unit:getBrain():setSituation(unit:getPlayerOwner():getIdleSituation() )
	        unit:getPlayerOwner():getIdleSituation():generatePatrolPath( unit, unit:getLocation() )
	    end,

	    onDespawnAbility = function( self, sim, unit )
	    	sim:removeTrigger( simdefs.TRG_UNIT_WARP, self, unit )
	        sim:removeTrigger( simdefs.TRG_ALARM_STATE_CHANGE, self )
	    end,

	    onTrigger = function( self, sim, evType, evData, userUnit )
	        if evType == simdefs.TRG_ALARM_STATE_CHANGE or (evType == simdefs.TRG_UNIT_WARP and evData.unit == self.abilityOwner and evData.from_tile == nil) then
	        	if not userUnit then
	        		userUnit = evData.unit
	        	end
	            if userUnit:getBrain() and userUnit:getBrain():getSituation() == sim:getNPC():getIdleSituation() then

	            	--find devices around the place. Assign them weights.
	            	local target, value = nil, 0
	            	for _, device in pairs(sim:getNPC():getUnits()) do
	            		if device:getTraits().mainframe_status and not device:getTraits().isGuard then
	            			local weight = 20
	            			--√[(x₂ - x₁)² + (y₂ - y₁)²]
	            			--weight = LARGE (but not quite math.huge) - DISTANCE to device
	            			--try your best not to stand still
	            			--also prefer not to return to prior devices (penalty = 12 tiles' distance)
	            			local x1, y1 = userUnit:getLocation()
	            			local x2, y2 = device:getLocation()
	            			local dist = math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1))
	            			if dist == 0 then
	            				dist = 50
	            			end
	            			for _, v_device in pairs(self.visited) do
	            				if v_device == device then
	            					dist = dist + 12
	            				end
	            			end
	            			local weight = 100 - math.floor(dist)

	            			if weight > value then
	            				target = device
	            				value = weight
	            				table.insert(self.visited, device)
	            			end
	            		end
	            	end

	            	if target and target:getLocation() then
		            	local x,y = target:getLocation()
		                userUnit:getTraits().patrolPath = { { x = x, y = y } }
		                userUnit:getBrain():getSenses():addInterest(x, y, simdefs.SENSE_RADIO, simdefs.REASON_PATROLCHANGED, userUnit)
		            end
	        
	                sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit } )    
	            end
	        end 
	    end
	},

	SLF_noctis_curtain = {
		onSpawnAbility = function( self, sim, unit )
	    	sim:addTrigger( simdefs.TRG_UNIT_WARP, self, unit )
	        self.abilityOwner = unit

	        local oldMP = unit:getTraits().mpMax
			unit:getTraits().mpMax = 25
			unit:getBrain():onSpawned(sim, unit)
			unit:getBrain():setSituation(unit:getPlayerOwner():getIdleSituation() )
	        unit:getPlayerOwner():getIdleSituation():generatePatrolPath( unit, unit:getLocation() )
			unit:getTraits().mpMax = oldMP
	    end,

	    onDespawnAbility = function( self, sim, unit )
	    	sim:removeTrigger( simdefs.TRG_UNIT_WARP, self, unit )   
	    end,

	    onTrigger = function( self, sim, evType, evData, userUnit )
	    	if evData and evData.to_cell then
	    		local emitter, stc, enc = self.abilityOwner, evData.from_cell, evData.to_cell
	    		for _, unit in pairs(sim:getAllUnits()) do
	    			local x, y = nil, nil
	    			if evData.unit == emitter then -- if emitter is moving, update all units within range
	    				x, y = unit:getLocation()
	    			else -- if unit is moving, update only that unit
	    				x, y = emitter:getLocation()
	    			end
	    			if (simquery.isAgent(unit) or unit:getTraits().isGuard) and unit:canAct() and (unit == evData.unit or emitter == evData.unit) and unit ~= emitter then
	    				local distance_end = math.floor( mathutil.dist2d( enc.x, enc.y, x, y ) )
	    				local range = emitter:getTraits().voidFieldRange
	    				if unit:getTraits().voided and distance_end > range then
	    					unit:getTraits().hasHearing = unit:getTraits().hasHearing_temp
	    					unit:getTraits().hasHearing_temp = nil
	    					unit:getTraits().LOSrange = unit:getTraits().LOSrange_temp
	    					unit:getTraits().LOSrange_temp = nil
	    					unit:getTraits().voided = nil
	    				elseif not unit:getTraits().voided and distance_end < range then
	    					unit:getTraits().voided = true
	    					unit:getTraits().hasHearing_temp = unit:getTraits().hasHearing
	    					unit:getTraits().hasHearing = nil
	    					unit:getTraits().LOSrange_temp = unit:getTraits().LOSrange
	    					unit:getTraits().LOSrange = emitter:getTraits().voidFieldRange
	    				end
	    			end
	    		end
	    	end
	    end,
	},

	SLF_pandoras_box = {
		onSpawnAbility = function( self, sim, unit )
	    	sim:addTrigger( simdefs.TRG_UNIT_WARP, self, unit )
	    	sim:addTrigger( simdefs.TRG_UNIT_HIJACKED, self, unit )
	    	sim:addTrigger( 63200, self, unit ) -- dragonjacking consoles
	        self.abilityOwner = unit

			unit:getBrain():onSpawned(sim, unit)
			unit:getBrain():setSituation(unit:getPlayerOwner():getIdleSituation() )
	    end,

	    onDespawnAbility = function( self, sim, unit )
	    	sim:removeTrigger( simdefs.TRG_UNIT_HIJACKED, self, unit ) 
	    	sim:removeTrigger( 63200, self, unit )
	    end,

	    onTrigger = function( self, sim, evType, evData, userUnit )
	    	if evType == simdefs.TRG_UNIT_WARP and evData.unit == self.abilityOwner then
	    		self:dipInvis(sim)
	    		sim:removeTrigger( simdefs.TRG_UNIT_WARP, self, self.abilityOwner )
	    		return
	    	end

	    	if evType == simdefs.TRG_UNIT_HIJACKED and evData.unit and evData.unit == self.abilityOwner:getTraits().pandora_link then
				evData.unit:getTraits().mainframeShaderOverride = nil
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = evData.unit })
				self:performWail()
				self.abilityOwner:getTraits().pandora_link = nil
	    	end
		end,

		dipInvis = function( self, sim )
			local seers = {}
    		for i, unit in pairs(sim:getAllUnits()) do
    			if simquery.couldUnitSee( sim, unit, self.abilityOwner ) then
    				table.insert(seers, unit)
    			end
    		end
    		self.abilityOwner:getTraits().queryInvisible = true
    		for i, seer in pairs(seers) do
    			sim:refreshUnitLOS(seer)
    		end
		end,

		performWail = function( self )
			-- which corp are we at?
			local sim = self.abilityOwner:getSim()
			local corp = sim:getParams().world
			if corp == "ftm" then 
				-- do something
				local pandora = 0
			else
				--log:write(util.stringize(sim._params,1))
			end
		end
	},
}

return guard_abilities