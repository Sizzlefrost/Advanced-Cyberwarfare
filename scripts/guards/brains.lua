local Brain = include("sim/btree/brain")
local btree = include("sim/btree/btree")
local actions = include("sim/btree/actions")
local conditions = include("sim/btree/conditions")
local simfactory = include( "sim/simfactory" )
local simdefs = include( "sim/simdefs" )
local speechdefs = include( "sim/speechdefs" )
local mathutil = include( "modules/mathutil" )
local simquery = include( "sim/simquery" )
local util = include( "modules/util" )
local CommonBrain = include( "sim/btree/commonbrain" )
require("class")

function actions.PandoraGetInterest(sim, unit)
	-- find nearest unhacked console
	local x, y = unit:getLocation()
	local target, dist = nil, 10000 -- or math.huge
	for id, console in pairs(sim:getAllUnits()) do
		if (console:getTraits().cpus or 0) ~= 0 then
			local cx, cy = console:getLocation()
			local distance = mathutil.dist2d(x,y,cx,cy) -- this should probably use pathing distance, not geometric distance
			if distance < dist then
				dist = distance
				target = console
			end
		end
	end

	log:write("LOG_SPAM", "[ACW-PANDORA] Console target found, ID "..tostring(target:getID()))

	if target then
		local x, y = target:getLocation()
		unit:getBrain():spawnInterest(x, y, simdefs.SENSE_RADIO, simdefs.REASON_HUNTING)
		unit:getTraits().pandora_link = target
		unit:getTraits().mp = unit:getTraits().mp_max -- refresh, making sure he can still move
		return simdefs.BSTATE_COMPLETE
	end

	unit:getTraits().pandora_link = nil
	return simdefs.BSTATE_FAILED
end

actions.PandoraMoveToConsole = class(actions.MoveTo, function(self, name)
	btree.BaseAction.init(self, name or "PandoraMoveToConsole")
end)

function actions.PandoraMoveToConsole:getDestination(sim, unit)
	local interest = self.unit:getBrain():getSenses():getCurrentInterest()
	local path = self.unit:getPather():getPath(self.unit)
	if path and path.result == simdefs.CANMOVE_NOPATH and interest == self.unit:getBrain():getDestination() then
		local x, y = self.unit:getLocation()
		return {x=x, y=y, reason="Could not path"}
	end
	interest["facing"] = self.unit:getTraits().pandora_link:getFacing()
	return interest
end

function actions.PandoraMoveToConsole:executePath(unit)
	-- decloak
	unit:getTraits().queryInvisible = false

	local result = actions.MoveTo.executePath(self, unit)

	if result == simdefs.BSTATE_COMPLETE then
		local sim = unit:getSim()

		simlog(actions.MarkInterestInvestigated(sim, unit))
		simlog(actions.RemoveInterest(sim, unit))
		simlog(actions.FinishSearch(sim, unit))

		unit:getBrain():getSenses().knownInterests = 0
		unit:getBrain():getSenses().currentInterest = nil
		unit:getBrain():getSenses().currentTarget = nil

		unit:getTraits().queryInvisible = true
		unit:getTraits().pandora_link:getTraits().mainframeShaderOverride = { 0/255, 0/255, 255/255, 0.75 }

		local console = unit:getTraits().pandora_link
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = console })
		unit:hasAbility("SLF_pandoras_box"):dipInvis(sim) -- hide thyself
	end

	log:write("LOG_SPAM", "[ACW-PANDORA] Path toward console: "..util.stringize(result,1))
	return result
end

function actions.PandoraExitLevel(sim, unit)
	local cell = sim:getCell(unit:getLocation())
	if not cell then
		return simdefs.BSTATE_FAILED
	end

	local units = {unit}
	sim:dispatchEvent( simdefs.EV_TELEPORT, { units=units, warpOut =true } )

	sim:warpUnit( unit, nil )
	sim:despawnUnit( unit )
	return simdefs.BSTATE_COMPLETE
end

conditions.PandoraBound = function(sim, unit) -- Pandora sitting in her console?
	local console = unit:getTraits().pandora_link
	if not console then
		log:write("LOG_SPAM", "[ACW-PANDORA] State: console not marked.")
		return false
	end
	local x1, y1 = unit:getLocation()
	local x2, y2 = console:getLocation()
	if x1 == x2 and y1 == y2 then
		log:write("LOG_SPAM", "[ACW-PANDORA] State: cyberguard inside console.")
		return true
	else
		log:write("LOG_SPAM", "[ACW-PANDORA] State: cyberguard en route to console.")
		return false
	end
end

local GuardBrainPandora = class(Brain, function(self)
	Brain.init(self, "PandoraBrain",
		btree.Selector( -- this selector is pretty much optional, but it's a compatibility layer with Leverage
		{
			btree.Sequence(											-- main loop; try until failure
			{
				btree.Not(btree.Condition(conditions.PandoraBound)),	-- succeeds when not bound to console

				btree.Selector("PandoraMarkConsole", 					-- always succeeds unless unit is off the board
				{
					btree.Condition(conditions.HasInterest),				-- succeeds when a console has been marked before
					btree.Action(actions.PandoraGetInterest),				-- succeeds when able to find a console
					btree.Action(actions.PandoraExitLevel),					-- despawns the unit
				}),

				btree.Not(actions.PandoraMoveToConsole()) 				-- succeeds when move is incomplete				
			}),
			CommonBrain.Patrol()
		})
	)
end)
    
local function createBrain()
	return GuardBrainPandora()
end

simfactory.register(createBrain)

return
{
	createBrain = createBrain,	
}
