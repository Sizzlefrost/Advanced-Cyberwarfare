local simdefs = include("sim/simdefs")
local util = include("modules/util")
local cdefs = include("client_defs")
local modifiers = include("sim/modifiers")
local array = include("modules/array")
local unitdefs = include("sim/unitdefs")
local simfactory = include("sim/simfactory")
local simquery = include("sim/simquery")
local mathutil = include("modules/mathutil")
local simguard = include("modules/simguard")
local abilitydefs = include("sim/abilitydefs")
local simactions = include("sim/simactions")

function simactions.niseiRewindAction( sim )
	sim:triggerEvent("TRG_NISEI_REWIND_COMPLETE")
end

local viz_manager = include("gameplay/viz_manager")

local oldInit = viz_manager.init
function viz_manager:init(game, ...)
	local results = {oldInit(self, game, ...)}

	self.eventMap[ "EV_ACW_NISEI" ] = {function (viz, eventData)
		--log:write("[ACW-VIZ] Rewinding.")
		local game = viz.game
		local numTurns = 1 -- 1 is sufficient as it takes us to start of agency turn

		-- Safeguard for when objective completes at the start of the turn.
		-- If this occurs, go back one more turn.
		local historyLength = #game.simHistory
		while #game.simHistory > 1 and numTurns > 0 do
	        local action = table.remove( game.simHistory )
	        if action.name == "endTurnAction" then
	        	if #game.simHistory + 1 ~= historyLength then
	            	numTurns = numTurns - 1
	            end
	            if numTurns <= 0 then
	                table.insert( game.simHistory, action )
	            end
	        end
		end
		game:goto( #game.simHistory )
		game:doAction( "rewindAction", viz.game.simCore:getTags().rewindsLeft )
		game:doAction( "niseiRewindAction" )
		--log:write("[ACW-VIZ] Done rewinding.")
	end}

	local rewoundPastNisei = true
	for i, action in pairs(game.simHistory) do
		if action.name == "niseiRewindAction" then
			rewoundPastNisei = false
		end
	end
	if rewoundPastNisei and self.game.hud then 
		game.simCore._acw_grid.used = false
		self.game.hud:refreshHud()
	end

	return unpack(results)
end

-- WEIGHTS

-- KO: 3. Satellite (close elevator), Skorpios (limit weapons), GRNDL (turrets are buffed).
-- make it hard to do combat
-- FTM: 3. SanSan (accel alarm), Argus (alarm on objective), Harmony (scientists present).
-- make it hard to delay combat
-- SANKAKU: 3. Oaktown (sprint noise), Hokusai (KO and alert drones), Nisei (rewind and predict).
-- make it hard to contain the threats
-- PLASTECH: 3. Crisium (no reversals), Heinlein (limit hacking), A Teia (double firewall buffs).
-- make it hard to hack
-- NEPTUNE: 3. Djupstad (AP drain on objective), Manegarm (end turn after shopping), GameNET (shops replaced with databases).
-- make it hard to move
-- NEUTRAL: 1. Mahkota Langit (CAI deletion boost).
-- OMNI: 1. Terminus (supersight on max alarm).

------
-- ALTERATIONS
-- initialize (sufficient for most cases): grid takes effect on level start, directly after sim:init()
-- pre_initialize: grid takes effect before sim:init() - use when init behaviour is to be changed
-- pre_generate (DANGEROUS): grid applies when the mission is locked in. Use to amend level-related behaviour

local function createSitrep( stringTbl, region )
	-- stringTbl: STRINGS.SLF.SITREPS.<> - location of string for the sitrep
	-- region: optional; primary region. A Grid is 3x more likely to show up in a "home region"
	local home_factor = 3
	local neutral_factor = 1.5
	local default_weight = 10

	local weights = {
		KO = default_weight,
		FTM = default_weight,
		SANKAKU = default_weight,
		PLASTECH = default_weight,
		NEPTUNE = default_weight,
		OMNI = default_weight,
	}

	if region then
		if region == "DEBUG" then
			-- "force-spawn" the grid by having huge weights in every corp
			for r, w in pairs(weights) do
				weights[r] = 100000
			end
		elseif region == "NEUTRAL" then
			-- all weights remain on default, multiplied by neutral_factor
			for r, w in pairs(weights) do
				weights[r] = neutral_factor * weights[r]
			end
		else
			weights[region] = home_factor * weights[region]
		end
	end

	return
		{
			name = stringTbl.NAME,
			desc = stringTbl.DESC,
			flavor = stringTbl.FLAVOR,	
			flavor_used = stringTbl.FLAVOR_USED or nil,	
			used = false,
			weights = weights,
		}
end

local sitreps = {
	-- Nisei Grid: When the objective is complete, rewind, then pinpoint 2 agents.
	nisei = util.extend(createSitrep(STRINGS.SLF.SITREPS.NISEI, "SANKAKU")){
		flavor_used = STRINGS.SLF.SITREPS.NISEI.FLAVOR_USED,
		targets = 2,
		trigger = { simdefs.TRG_OBJ_COMPLETE, "TRG_NISEI_REWIND_COMPLETE" },
		onTrigger = function( self, sim, evType, evData )
			--log:write("[ACW] Nisei trigger entered, with "..evType)
			if evType == simdefs.TRG_OBJ_COMPLETE then
		    	sim:dispatchEvent("EV_ACW_NISEI")
				--sim:getTags().rewindsLeft = sim:getTags().rewindsLeft + 1
		    	return
		    end
		    if evType ~= "TRG_NISEI_REWIND_COMPLETE" then
		    	return
		    end
		    --log:write("[ACW] Nisei rewind successful. Continuing...")
		    self.used = true
		    --self.desc = util.sformat(self.flavor_used, self.desc)

		    -- get any objective room cell that is surrounded by other objective room cells
		    -- look for agents close to that and have guards hunt those

		    local loX, loY, hiX, hiY = nil, nil, nil, nil
		    sim:forEachCell( function(cell)
		    	if cell.procgenRoom and cell.procgenRoom.tags and cell.procgenRoom.tags.objective then
		    		if not loX or cell.x < loX then
		    			loX = cell.x
		    		end
		    		if not hiX or cell.x > hiX then
		    			hiX = cell.x
		    		end
		    		if not loY or cell.x < loY then
		    			loY = cell.x
		    		end
		    		if not hiY or cell.x > hiY then
		    			hiY = cell.x
		    		end
		    	end
			end)

			assert(loX, "Failed to find the objective room")
		    --log:write("[ACW] Nisei objective found. Continuing...")

			local agents = util.tdupe(sim:getPC():getAgents())

			table.sort(agents, function (agent1, agent2) 
				local x0, y0 = agent1:getLocation()
				local x1, y1 = agent2:getLocation()
				return mathutil.dist2d(x0, y0, (hiX+loX)/2, (hiY+loY)/2) < mathutil.dist2d(x1, y1, (hiX+loX)/2, (hiY+loY)/2)
			end)

		    --log:write("[ACW] Nisei agents sorted. Continuing...")
		    --log:write("[...] "..util.stringize(agents, 1))

			local targets = {}
    		while #targets < self.targets do
    			local target = table.remove(agents, 1)
    			local x2,y2 = target:getLocation()
    			log:write("LOG_SPAM", "[ACW-NISEI] Spawning interest on "..target:getName().." at "..x2..", "..y2)
    			sim:getNPC():spawnInterest(x2,y2, simdefs.SENSE_RADIO,  simdefs.REASON_CAMERA, target)
    			table.insert(targets, target)
    		end

    		for i, target in pairs(targets) do
    			--sim:dispatchEvent( simdefs.EV_SHOW_DIALOG, { speech="SpySociety/HUD/gameplay/scan_line", dialog = "programDialog", dialogParams = dialogParams } )
    			sim:dispatchEvent( simdefs.EV_SHOW_DIALOG, { dialog = "locationDetectedDialog", dialogParams = { target }} )
    		end

		    sim:removeTrigger(simdefs.TRG_OBJ_COMPLETE, self)
		    sim:removeTrigger("TRG_NISEI_REWIND_COMPLETE", self)

			--log:write("[ACW] Nisei done. New description:\n"..self.desc)
		    sim._acw_grid = self -- update the description for reloads' sake
		end,
	},

	-- Mahkota Langit Grid: CAI subroutine deletion requirement increased by 2.
	mahkota = util.extend(createSitrep(STRINGS.SLF.SITREPS.MAHKOTA_LANGIT, "NEUTRAL")){
		PE_AI_required = true,
		addedRequirement = 2,
		initialize = function( self, sim )
			-- find CAI, increase its deletion req for the mission via a modifier
			local CAI = abilitydefs.lookupAbility( "W93_AI_assembly" )

			local addedReq = self.addedRequirement -- we're about to redefine the self
			if CAI then
				local baseOnSpawn = CAI.onSpawnAbility
				local baseOnDespawn = CAI.onDespawnAbility

				function CAI:onSpawnAbility( sim, ... )
					-- onSpawn doesn't typically return anything, but *just in case*
					local results = { baseOnSpawn( self, sim, ... ) }
					-- abilities are not units, and dont support SC's modifiers system :(
					self.deletionRequirement = self.deletionRequirement + addedReq
					return unpack(results)
				end
				function CAI:onDespawnAbility( sim, ... )
					local results = { baseOnDespawn( self, sim, ... ) }
					self.deletionRequirement = self.deletionRequirement - addedReq
					return unpack(results)
				end
			end
		end,
	},

	-- GameNET Grid: Stores (except large ones) and server terminals are replaced with Databases.
	gamenet = util.extend(createSitrep(STRINGS.SLF.SITREPS.GAMENET, "NEPTUNE")){
		initialize = function( self, sim )
			-- we'll be changing the unit list, so make a copy
			local units = util.tdupe(sim:getAllUnits())
			local database_templates, databases = {"camera_core", "map_core", "console_core", "daemon_core"}, {}
			for i, template in pairs(database_templates) do
				local unit = simfactory.createUnit(unitdefs.lookupTemplate( template ), sim)
				table.insert(databases, unit)
			end

			for i, unit in pairs(units) do
				if unit:getTraits().storeType == "standard" or unit:getTraits().storeType == "miniserver" then
					local x, y = unit:getLocation()

					local dbase = table.remove(databases, sim:nextRand(1, #databases)) or nil
					if dbase then
						sim:warpUnit(unit)
						sim:despawnUnit(unit)
						sim:spawnUnit(dbase)
						sim:warpUnit(dbase, sim:getCell(x, y))
					end
				end
			end
		end,
	},

	-- GRNDL Grid: Turrets have +2 firewalls, HP and ammo.
	grndl = util.extend(createSitrep(STRINGS.SLF.SITREPS.GRNDL, "KO")){
		initialize = function( self, sim )
			for i, unit in pairs(sim:getAllUnits()) do
				if unit:getTraits().isMainframeTurret then
					unit:getTraits().mainframe_ice = unit:getTraits().mainframe_ice + 2
					unit:getTraits().mainframe_iceMax = unit:getTraits().mainframe_iceMax + 2
					unit:getTraits().woundsMax = unit:getTraits().woundsMax + 2
					for i, child in pairs(unit:getChildren()) do
						child:getTraits().ammo = (child:getTraits().ammo or 0) + 1
						child:getTraits().maxAmmo = (child:getTraits().maxAmmo or 0) + 1
					end
				end
			end
		end,
	},


	-- A Teia Grid: Firewall boosts are twice as effective.
	a_teia = util.extend(createSitrep(STRINGS.SLF.SITREPS.ATEIA, "PLASTECH")){
		pre_initialize = function( self, sim )
			local simunit = include("sim/simunit")
			local oldIncrease = simunit.increaseIce
			function simunit:increaseIce( sim, iceInc, ... )
				return oldIncrease( self, sim, 2*iceInc, ... )
			end
		end,
	},

	-- Harmony Grid: Extra scientists are spawned in the level.
	harmony = util.extend(createSitrep(STRINGS.SLF.SITREPS.HARMONY, "FTM")){
		presim_init = function( self, situation )
			-- reminder: current state is state-map-screen, mission select widget!

			-- get corp, get worldgen.worlds[corp], add guards to simdefs.[CORP]_SPAWN_TABLE[ self.params.difficultyOptions.spawnTable ]
		end,

		initialize = function( self, sim )
			-- check # of existing guards; for every 3 guards, a scientist is spawned
			local scientistsToSpawn = 0

			for i, unit in pairs(sim:getNPC():getUnits()) do
				if unit:getTraits().isGuard then
					scientistsToSpawn = scientistsToSpawn + 1
				end
			end

			local scientistsToSpawn = math.floor(scientistsToSpawn/3)
			local scientists = {}

			--log:write(util.sformat("[ACWLOG] Harmony: spawning {1} scientists.", scientistsToSpawn))
			while #scientists < scientistsToSpawn do
				-- spawn the scientist
				local template = unitdefs.lookupTemplate( "npc_scientist" )

				-- adjust loot tables: medgel instead of stim, twice as common
				-- anarchy gets you paralyzers
				template.dropTable = {
					{ "item_adrenaline", 5 },
					{nil, 35}
				}
				template.anarchyDropTable = {
					{ "item_paralyzer_2",5},
				    { "item_defiblance",5},
					{ "item_paralyzer" ,35},
					{nil,150}
				}

				local unit = simfactory.createUnit( template, sim )
				for i, child in pairs(unit:getChildren()) do
					unit:removeChild(child)
					sim:despawnUnit(child)
				end
				unit.getName = function(self) return STRINGS.SLF.SITREPS.HARMONY.SCIENTIST_TITLE end
				unit:getTraits().vip = nil
				unit:getTraits().lockScientistDoor = nil
				unit:changeKanim("kanim_scientist")
				unit:setPlayerOwner( sim:getNPC() )
				sim:spawnUnit( unit )
				-- get a random tile to warp the unit to before making up pathing
				-- path generation does not strictly require the unit to be in the level *in vanilla*;
				-- however, apparently FuncLib resolves an odd pathfinding interaction where the guards wouldn't know of a blockage
				-- and yet be affected by it. This requires knowing where the guard is.
				local function canGuardSpawn( sim, unit, x, y )
					local cell = sim:getCell( x, y )
					if cell.tileIndex == nil or cell.tileIndex == cdefs.TILE_SOLID or cell.exitID or cell.cell ~= nil or cell.impass > 0 then
						return false
					end

					if simquery.cellHasTag(sim, cell, "noguard") then        
						return false
					end

				    if not simquery.canPath( sim, unit, nil, cell ) then
						return false
					end

					return true
				end

				if sim._rooms then
					local cellResult = nil
					while not cellResult do
						local room = sim._rooms[sim:nextRand( 1, #sim._rooms )]
						local cells = {}
						for _, rect in pairs(room.rects) do
							for x = rect.x0, rect.x1 do
								for y = rect.y0, rect.y1 do
									if canGuardSpawn( sim, unit, x, y ) then
					                    table.insert( cells, x )
					                    table.insert( cells, y )
					                end
								end
							end
						end
						if #cells > 0 then
					        local i = sim:nextRand( 1, #cells / 2 )
					        cellResult = sim:getCell(cells[2 * i - 1], cells[2 * i])
					    end
					end
					sim:warpUnit( unit, cellResult )
				else return end
				unit:setPather(sim:getNPC().pather)
				unit:getBrain():setSituation(sim:getNPC():getIdleSituation() )
				sim:getNPC():getIdleSituation():generatePatrolPath( unit )
				local patrolPath = unit:getTraits().patrolPath
				--log:write(util.sformat("[ACWLOG] Patrol \n{1}", util.stringize(patrolPath,2)))
                if patrolPath and #patrolPath > 0 then
                	--sim:warpUnit( unit, sim:getCell(x, y) )
                	if patrolPath[1].facing then
                    	unit:updateFacing( patrolPath[1].facing )
                    end
                end
				table.insert(scientists, unit)
			end
		end,
	},

	-- SanSan City Grid: Whenever Alarm Level increases, add 1 tick to it.
	sansan = util.extend(createSitrep(STRINGS.SLF.SITREPS.SANSAN, "FTM")){
		trigger = { simdefs.TRG_ALARM_STATE_CHANGE },
		onTrigger = function( self, sim, evType, evData )
			if not sim._SLF_tracker_advancing then
				sim._SLF_tracker_advancing = true
				sim:trackerAdvance(1, STRINGS.SLF.SITREPS.SANSAN.TRIGGER)
				sim._SLF_tracker_advancing = nil
			end
		end,
	},

	-- Crisium Grid: Daemons cannot be reversed.
	crisium = util.extend(createSitrep(STRINGS.SLF.SITREPS.CRISIUM, "PLASTECH")){
		initialize = function( self, sim )
			local aiplayer = sim:getNPC()
			local reversible = aiplayer.addMainframeAbility
			function aiplayer.addMainframeAbility( self, sim, abilityID, hostUnit, reversalOdds, ... )
				-- Progextend Reflect coverage
				local PE_reverse = sim:getPC():getTraits().reverseAll
				sim:getPC():getTraits().reverseAll = nil

				-- determine whether the daemon would be reversed in order to display the pop-up
				-- this relies on the next sim:getRand call to be part of the base addMainframeAbility;
				-- so if another mod appends addMainframeAbility and calls a rand in there, this might well cease to be accurate
				local monst3rReverseOdds = reversalOdds or 10
				for _, ability in ipairs( sim:getPC():getAbilities() ) do 
					if ability.daemonReversalAdd and monst3rReverseOdds > 0 then 
						monst3rReverseOdds = monst3rReverseOdds + ability.daemonReversalAdd
					end 
				end 

				local seed = sim._seed
				local monst3rReverse = sim:nextRand(1, 100) < monst3rReverseOdds
				if monst3rReverse then
					--log:write("[ACWLOG] Should display warning here.")
					sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.SLF.SITREPS.CRISIUM.TRIGGER, color=cdefs.COLOR_CORP_WARNING, sound = "SpySociety/Actions/mainframe_deterrent_action" } )
				end
				-- undo the rand call to avoid messing with simhistory
				sim._seed = seed

				local results = {reversible( self, sim, abilityID, hostUnit, 0, ... )} -- setting reversalOdds to 0 makes daemons irreversible

				sim:getPC():getTraits().reverseAll = PE_reverse

				return unpack(results)
			end
		end,
	},

	-- Djupstad Grid: When the objective is completed, your units get -1 max AP for the rest of the mission.
	djupstad = util.extend(createSitrep(STRINGS.SLF.SITREPS.DJUPSTAD, "NEPTUNE")){
		flavor_used = STRINGS.SLF.SITREPS.DJUPSTAD.FLAVOR_USED,
		trigger = { simdefs.TRG_OBJ_COMPLETE },
		onTrigger = function( self, sim, evType, evData )
			for i, unit in pairs(sim:getPC():getUnits()) do
				unit:getModifiers():add("mpMax", "ACW_djupstad", modifiers.ADD, -2)
			end	
			sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.SLF.SITREPS.DJUPSTAD.TRIGGER, color=cdefs.COLOR_CORP_WARNING, sound = "SpySociety/Actions/mainframe_deterrent_action" } )
			self.used = true
			sim:removeTrigger(simdefs.TRG_OBJ_COMPLETE, self)
			sim._acw_grid = self -- update the description for reloads' sake
		end,
	},

	-- Mirrormorph Grid: After a device is captured, drain 1 PWR.
	mirrormorph = util.extend(createSitrep(STRINGS.SLF.SITREPS.MIRRORMORPH, "PLASTECH")){
		trigger = { simdefs.TRG_ICE_BROKEN },
		onTrigger = function( self, sim, evType, evData )
			if evType == simdefs.TRG_ICE_BROKEN and sim._mainframeLockout == 0 and evData.unit and evData.unit:getTraits().mainframe_ice < 1 then
				sim:getPC():addCPUs(-1, sim)
				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.SLF.SITREPS.MIRRORMORPH.TRIGGER, color=cdefs.COLOR_CORP_WARNING, sound = "SpySociety/Actions/mainframe_deterrent_action" } )
			end
		end,
	},

	-- Hokusai Grid: All drones are shut down. Each turn, one wakes up, pre-alerted.
	hokusai = util.extend(createSitrep(STRINGS.SLF.SITREPS.HOKUSAI, "SANKAKU")){
		initialize = function( self, sim )
			local KO_timer = 1
			for i, unit in pairs(sim:getNPC():getUnits()) do
				if unit:getTraits().isDrone then
					unit:getTraits().magreintemp = unit:getTraits().magnetic_reinforcement
					unit:getTraits().magnetic_reinforcement = nil
					unit:getTraits().tempEmpDeath = unit:getTraits().empDeath
					unit:getTraits().empDeath = nil
					unit:processEMP(KO_timer)
					if unit._sim and unit._sim._resultTable then
						unit:setAlerted(true)
					else
						log:write("[ACW-HOKUSAI] WARNING: no sim reference on "..unit:getName().." ("..unit:getID()..")")
					end
					unit:getTraits().empDeath = unit:getTraits().tempEmpDeath
					unit:getTraits().tempEmpDeath = nil
					unit:getTraits().magnetic_reinforcement = unit:getTraits().magreintemp
					unit:getTraits().magreintemp = nil
					KO_timer = KO_timer + 1
				end
			end
		end,
	},

	-- Satellite Grid: when the objective is completed, lock the exit elevator for 5 turns.
	satellite = util.extend(createSitrep(STRINGS.SLF.SITREPS.SATELLITE, "KO")){
		flavor_used = STRINGS.SLF.SITREPS.SATELLITE.FLAVOR_USED,
		trigger = { simdefs.TRG_OBJ_COMPLETE },
		onTrigger = function( self, sim, evType, evData )
			sim:closeElevator()
			sim._elevator_inuse = 5
			sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.SLF.SITREPS.SATELLITE.TRIGGER, color=cdefs.COLOR_CORP_WARNING, sound = "SpySociety/Actions/mainframe_deterrent_action" } )
			self.used = true
			sim:removeTrigger(simdefs.TRG_OBJ_COMPLETE, self)
			sim._acw_grid = self -- update the description for reloads' sake
		end,
	},

	-- Oaktown Grid: ALL units have +3 sprint noise.
	oaktown = util.extend(createSitrep(STRINGS.SLF.SITREPS.OAKTOWN, "SANKAKU")){
		pre_initialize = function( self, sim )
			local oldSpawn = sim.spawnUnit
			function sim:spawnUnit( unit, ... )
				local results = {oldSpawn( self, unit, ... )}

				if unit and unit:getTraits().mp and unit:getTraits().dashSoundRange then
					unit:getModifiers():add("dashSoundRange", "ACW_oaktown", modifiers.ADD, 3)
				end

				return unpack(results)
			end
		end,
	},

	-- Skorpios Grid: Weapons are limited to 3 charges.
	skorpios = util.extend(createSitrep(STRINGS.SLF.SITREPS.SKORPIOS, "KO")){
		pre_initialize = function( self, sim )
			local oldSpawn = sim.spawnUnit
			function sim:spawnUnit( unit, ... )
				local results = {oldSpawn( self, unit, ... )}

				--log:write("Spawning a "..unit:getName().." ("..unit:getID()..")")

				-- do not limit the charges of NPC weaponry - only carryable, agency-usable weapons
				if unit and unit:getTraits().slot and unit:hasAbility("carryable") then
					if not unit:getTraits().usesCharges then
						unit:getModifiers():add("usesCharges", "ACW_skorpios", modifiers.SET, true)
					end
					local chargesPrev = unit:getTraits().charges
					unit:getModifiers():add("chargesMax", "ACW_skorpios", modifiers.SET, 3)
					unit:getModifiers():add("charges", "ACW_skorpios", modifiers.SET, chargesPrev or 3)
				end

				return unpack(results)
			end
		end,
	},

	-- Argus Grid: when the objective is completed, install a Blowfish.
	argus = util.extend(createSitrep(STRINGS.SLF.SITREPS.ARGUS, "FTM")){
		flavor_used = STRINGS.SLF.SITREPS.ARGUS.FLAVOR_USED,
		trigger = { simdefs.TRG_OBJ_COMPLETE },
		onTrigger = function( self, sim, evType, evData )
			sim:getNPC():addMainframeAbility(sim, "bruteForce")
			-- sim:endTurn() -- KNOW MY MERCY >:(

			self.used = true
			sim:removeTrigger(simdefs.TRG_OBJ_COMPLETE, self)
			sim._acw_grid = self -- update the description for reloads' sake
		end,
	},

	-- Manegarm Grid: whenever a nanofab/terminal window is closed, end the turn.
	manegarm = util.extend(createSitrep(STRINGS.SLF.SITREPS.MANEGARM, "NEPTUNE")){
		initialize = function( self, sim )
			local level = include("sim/level")			

			local recursive_shop_hook = function( script, sim )
				while true do 	-- it works, trust :>
					local _ = script:waitFor( {
						uiEvent = level.EV_CLOSE_SHOP_UI,
						fn = function( sim, evData )
							return true
						end
					} )

					sim:endTurn()
				end
			end

			self.hook = sim:getLevelScript():addHook("ACW_SHOP_CLOSED", recursive_shop_hook, true)
		end,
	},

	-- Terminus Grid: When alarm hits the max level, guards can see through cover.
	terminus = util.extend(createSitrep(STRINGS.SLF.SITREPS.TERMINUS)){
		flavor_used = STRINGS.SLF.SITREPS.TERMINUS.FLAVOR_USED,
		weights = {
			KO = 5,
			FTM = 0,
			SANKAKU = 0,
			PLASTECH = 0,
			NEPTUNE = 0,
			OMNI = 15,
		},
		trigger = { simdefs.TRG_ALARM_STATE_CHANGE },
		onTrigger = function( self, sim, evType, evData )
			if evData >= simdefs.TRACKER_MAXSTAGE then
				-- grant superman vision to existing guards
				for i, unit in pairs(sim:getNPC():getUnits()) do
					if unit:getTraits().isGuard then
						unit:getTraits().seesHidden = true
					end
				end
				-- ...and to newly spawned guards
				local oldSpawn = sim.spawnUnit
				function sim:spawnUnit( unit, ... )
					local results = {oldSpawn( self, unit, ... )}

					if unit:getTraits().isGuard then
						unit:getTraits().seesHidden = true
					end

					return unpack(results)
				end

				self.used = true
			end
		end,
	},
}

return sitreps