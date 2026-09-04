local array = include( "modules/array" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local mainframe_abilities = include( "sim/abilities/mainframe_abilities" )

local ALARM_TO_WAKE = 1

--special thanks to wodzu for this little fix in my absence
local function findMainframeAbility(abilityID) 
    local testAbility = mainframe_abilities[abilityID]
    return testAbility
end

--special thanks to Mobbstar & Hekateras for this part
local abilitydefs = include( "sim/abilitydefs" ) --use this instead of the direct ability files, as mods may override some - Mobbstar
local use_medgel = abilitydefs._abilities.use_medgel
local use_medgel_canUseAbility_old = use_medgel.canUseAbility

use_medgel.canUseAbility = function( self, sim, abilityOwner, userUnit, targetUnitID , ... )
    local result, reason = use_medgel_canUseAbility_old( self, sim, abilityOwner, userUnit, targetUnitID , ... ) -- reason is important so tooltips stay intact in case it's not 
    local targetUnit = sim:getUnit(targetUnitID)

    if targetUnit and targetUnit:getTraits().cyberspace then
        return false, STRINGS.SLF.AUGMENTS.DRAGON2.MEDGEL_DENIAL
    end

    return result, reason
end

--If someone opens the store, hide the program! It's not to be purchased!
local showItemStore = abilitydefs.lookupAbility("showItemStore")
local execOld = showItemStore.executeAbility
function showItemStore.executeAbility( self, sim, unit, userUnit )
	if unit:getTraits().storeType == "server" or unit:getTraits().storeType == "miniserver" then
    	 if findMainframeAbility( "SLF_dragon_intellect" ) then --check: mod is loaded
    	 	for _, unit in pairs( sim:getPC():getUnits() ) do --check: dragon exists and is KO
    	 		--log:write("[AC][SCOUT] Checking unit "..unit:getName().." for scout trait.")
    	 		if unit:ownsAbility( "SLF_dragon_scout" ) and unit:isKO() == true then
    	 			sim:getPC():removeAbility( sim, "SLF_dragon_intellect" )
					if sim:getTags().extraPrograms then
						sim:getTags().extraPrograms = sim:getTags().extraPrograms - 1
		    		end
    	 		else
    	 			--log:write("[AC][SCOUT] Negative.")
    	 		end
    	 	end
    	end
	end

	return execOld( self, sim, unit, userUnit )
end

-- addMainframeAbility, but instead of looking up the def, just take it as an argument.
-- means that we can pass modified defs to this function (in case Dragon's Assistance gets modified smh)
-- defs are assumed to be prepared properly

-- p.s. also doesn't work on daemons, this is programs only! It's local anyway, idk why it'd be used for anything else.
local function returnMainframeAbility ( sim, abilityDef )
	-- How many instances of this ability do we already have?
	local count = 0
	for _, ability in ipairs( sim:getPC()._mainframeAbilities ) do
		if ability:getID() == abilityDef:getID() then
			count = count + 1
		end
	end

	if abilityDef and count < (abilityDef.max_count or math.huge) then	
		table.insert( sim:getPC()._mainframeAbilities, abilityDef )
		abilityDef:spawnAbility( sim, sim:getPC() )
	end
end

--SIMABILITY.CREATE() HELPERS, USED BELOW IN THE ABILITYDEF
local function getID( self )
	return self._abilityID
end
local function getDef( self )
	return self
end
local function spawnAbility( self, sim, owner, hostUnit )
    self._sim = sim
    if self.onSpawnAbility then
        self:onSpawnAbility( sim, owner, hostUnit )
    end
end
local function despawnAbility( self, sim, owner )
    self._sim = nil
    if self.onDespawnAbility then
        self:onDespawnAbility( sim, owner )
    end
end

--------------------------------------------------------------------
SLF_dragon_scout =
		{
			--THIS ABILITY IS ON AN AUGMENT. The augment is the abilityOwner. Dragon is the abilityOwner:getUnitOwner()

			name = "AI Core v1", --where the heck is this shown or referenced? It's the name of the ability, not the augment; but the ability is referenced via SLF_dragon_scout
			getName = function( self, sim, unit )
				return self.name --aka, where the heck is this called?
			end,				 --in short, do I even need this section? LOL

			programName = "SLF_dragon_intellect",

			setupProgramDef = function( self, programName, targetUnit )
				--log:write("target: "..tostring(targetUnit))
				if targetUnit:getTraits().programDef == nil then
					targetUnit:getTraits().programDef = findMainframeAbility(programName) --get the *base* ability from game's defs
					--now we must prepare it like simability:create() does
					targetUnit:getTraits().programDef._abilityID = programName
					targetUnit:getTraits().programDef.getID = getID --HELPER FUNCTIONS ARE ABOVE THIS ABILITYDEF
					targetUnit:getTraits().programDef.getDef = getDef -- just returns self (*current* def, not *base* def)
					targetUnit:getTraits().programDef.spawnAbility = spawnAbility
					targetUnit:getTraits().programDef.despawnAbility = despawnAbility
					targetUnit:getTraits().programDef.max_count = 1 -- prevents duplicates? Couldn't find this in base game, could be redundant
				end
			end,

			enterCyberspace = function( self, sim, targetUnit )
				targetUnit:getTraits().cyberspace = true
				--add temporary program slot
                sim:getTags().extraPrograms = (sim:getTags().extraPrograms or 0) + 1
                --when we first enter cyberspace, reset the cooldown of the program & add it
                targetUnit:getTraits().programDef.cooldown = 0
                returnMainframeAbility( sim, targetUnit:getTraits().programDef )
                --cloak up
               	targetUnit:getUnitOwner():setInvisible(true, math.huge)
				targetUnit:getUnitOwner():resetAllAiming()
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = targetUnit:getUnitOwner() } )
				sim:processReactions(targetUnit:getUnitOwner())	
			end,

			exitCyberspace = function( self, sim, targetUnit )
				targetUnit:getTraits().cyberspace = false
				--save program into trait & clean it up
				targetUnit:getTraits().programDef = sim:getPC():hasMainframeAbility(self.programName)
				sim:getPC():removeAbility( sim, self.programName )
				if sim:getTags().extraPrograms then
					sim:getTags().extraPrograms = sim:getTags().extraPrograms - 1
	    		end
				--decloak
				targetUnit:getUnitOwner():setInvisible(false)
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = targetUnit:getUnitOwner() } )
				sim:processReactions(targetUnit:getUnitOwner())	
				--wake up
				targetUnit:getUnitOwner():setKO(sim, nil)
				targetUnit:getUnitOwner():getTraits().dead = nil
			end,

			onSpawnAbility = function( self, sim, unit )
				self.abilityOwner = unit
				------------------------------------------------------
				-- FIRST TIME SETUP
				-- get def from Dragon's trait. If not present, get the base version from dragon_mainframe.
				self:setupProgramDef( self.programName, self.abilityOwner )
				------------------------------------------------------
				sim:addTrigger( simdefs.TRG_START_TURN, self )
				sim:addTrigger( simdefs.TRG_CLOSE_NANOFAB, self )
				sim:addTrigger( "activated_incogRoom", self ).priority = 1 --call this before normal behaviour
				sim:addTrigger( "cancelled_using_AI_terminal", self )
				sim:addTrigger( "finished_using_AI_terminal", self ).priority = 1
			end,

			onDespawnAbility = function( self, sim, unit )
				if self.abilityOwner:getTraits().cyberspace == true then --if the ability is removed and it's currently active, clean up
					self:exitCyberspace( sim, self.abilityOwner )
				end
				sim:removeTrigger( simdefs.TRG_START_TURN, self )
				sim:removeTrigger( simdefs.TRG_CLOSE_NANOFAB, self )
				sim:removeTrigger( "activated_incogRoom", self )
				sim:removeTrigger( "cancelled_using_AI_terminal", self )
				sim:removeTrigger( "finished_using_AI_terminal", self )
			end,

			onTrigger = function( self, sim, evType, evData)
				if evType == simdefs.TRG_START_TURN and sim:getCurrentPlayer() == sim:getPC() then
		            if sim._trackerStage < ALARM_TO_WAKE then
		            	if not self.abilityOwner:getTraits().cyberspace then
			                self:enterCyberspace( sim, self.abilityOwner )
						end
		            	local x1,y1 = self.abilityOwner:getUnitOwner():getLocation()
			            sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.SLF.AUGMENTS.DRAGON2.TRIGGER,x=x1,y=y1,color={r=1,g=1,b=1,a=1}} )
						self.abilityOwner:getUnitOwner():setKO(sim, 2)
						self.abilityOwner:getUnitOwner():getTraits().dead = true
					elseif self.abilityOwner:getTraits().cyberspace == true then
						self:exitCyberspace( sim, self.abilityOwner )
					end
				elseif evType == simdefs.TRG_CLOSE_NANOFAB and (evData.unit:getTraits().storeType == "server" or evData.unit:getTraits().storeType == "miniserver") then
					for i, unit in pairs(sim:getAllUnits()) do
						if (unit:getTraits().cyberspace or false) == true then
							sim:getTags().extraPrograms = (sim:getTags().extraPrograms or 0) + 1
							returnMainframeAbility( sim, self.abilityOwner:getTraits().programDef )
						end
					end
				elseif evType == "activated_incogRoom" and sim._trackerStage >= ALARM_TO_WAKE then
					-- before AI Terminal boots up, add dragon's program
					sim:getTags().extraPrograms = (sim:getTags().extraPrograms or 0) + 1
					returnMainframeAbility( sim, self.abilityOwner:getTraits().programDef )
				elseif (evType == "finished_using_AI_terminal" or evType == "cancelled_using_AI_terminal") and sim._trackerStage >= ALARM_TO_WAKE then
					-- upon closing, remove dragon's program
					self.abilityOwner:getTraits().programDef = sim:getPC():hasMainframeAbility(self.programName)
					sim:getPC():removeAbility( sim, self.programName )
					if sim:getTags().extraPrograms then
						sim:getTags().extraPrograms = sim:getTags().extraPrograms - 1
		    		end
				end
			end,
		}	
		
return SLF_dragon_scout