local util = include("modules/util")
local simquery = include("sim/simquery")
local simplayer = include("sim/simplayer")
local simdefs = include("sim/simdefs")
local mainframe = include("sim/mainframe")
local mainframe_common = include("sim/abilities/mainframe_common")
local modifiers = include("sim/modifiers")
local cdefs = include("client_defs")
local mission_scoring = include("mission_scoring")
local dial_evs = include(SCRIPT_PATHS.advanced_cyberwarfare.."/frames/dialog_events")

local function assembleIncognitaFrame( strPath )
	return {
		name = strPath.NAME,
		special = strPath.SPECIAL or "",
		special_extended = strPath.SPECIAL_EXTENDED or "",
		flavor = strPath.FLAVOR,
		-- some frames require specific genoptions to be functional
		-- they will generally still work without them, but for safety
		-- set this to the option name to disable creation of corresponding item without the option
		required_option = nil,
		-- genoptions has this depend on difficulty, and it's appended post-sim-init
		-- the formula used is "existing max PWR - 20 + options max PWR"
		-- hardcoding it here should be okay, but it'll definitely be awkward to stringize
		max_pwr_mod = 0, --20
		-- simquery:getMaxPrograms is a Sim Constructor function that accounts for things including difficulty options
		-- ...turns out I do have to append it further, because it relies on sim:getTags and is therefore
		-- invalid when there's no sim
		max_programs_mod = 0, --4 (4! base game is 5)
		-- Specialized program slots, stretch goal
		spec_programs = {
			--{ slots = 3, type = "chip", color = util.color.MID_BLUE },
		},
		-- in Progextend, hash keys only appear when the AI does, which is after turn 1
		-- however, querying pcplayer:getTraits().aiToken / aiTokenMax seems legit
		-- PE falls back on a default of 8, or 14 with Decryptor
		max_hash_mod = 0, --8
		-- this is awkward, because pwrMod is only considered from all the programs 
		-- creating a dummy program is a no-go, too many things rely on a program being proper
		pwr_mod = 0,
		-- ditto
		cd_mod = 0,
		-- daemonReverse odds are hardcoded, but a pre-append is ok to meddle there
		algorithm_odds = 0, --0 (0! base game is 10)
		-- daemonDuration is fortunately simply a player trait
		daemon_duration_mod = 0,

		getTotalSpecSlots = function(self)
			local result = 0
			for i, spec in pairs(self.spec_programs) do
				result = result + spec.slots
			end

			return result
		end,

		onSpawnFrameBase = function(self, sim)
			sim:getTags().extraPrograms = (sim:getTags().extraPrograms or 0) + (self.max_programs_mod - 1)
			local PC = self:getPlayerOwner()
			PC._traits["PWRmaxBouns"] = (PC._traits["PWRmaxBouns"] or 0) + self.max_pwr_mod
			PC._traits["aiTokenMax"] = (PC._traits["aiTokenMax"] or 8) + self.max_hash_mod
			PC._traits["_incogReversalOverride"] = self.algorithm_odds
			PC._traits["daemonDurationModd"] = (PC._traits["daemonDurationModd"] or 0) + self.daemon_duration_mod
			PC._traits["program_cost_modifier"] = (PC._traits["program_cost_modifier"] or 0) + self.pwr_mod
			PC:sortSpecSlots()
		end,
		onSpawnFrame = function(self, sim)
		end,
		onDespawnFrameBase = function(self, sim)
			sim:getTags().extraPrograms = (sim:getTags().extraPrograms or 0) - (self.max_programs_mod - 1)
			local PC = self:getPlayerOwner()
			PC._traits["PWRmaxBouns"] = (PC._traits["PWRmaxBouns"] or 0) - self.max_pwr_mod
			PC._traits["aiTokenMax"] = (PC._traits["aiTokenMax"] or 8) - self.max_hash_mod
			PC._traits["_incogReversalOverride"] = 10
			PC._traits["daemonDurationModd"] = (PC._traits["daemonDurationModd"] or 0) - self.daemon_duration_mod
			PC._traits["program_cost_modifier"] = (PC._traits["program_cost_modifier"] or 0) - self.pwr_mod
		end,
		onDespawnFrame = function(self, sim)
		end,
		onTrigger = function(self, sim, evType, evData)
		end,
		getPlayerOwner = function(self)
			return self._playerOwner -- set on frame init
		end,
	}
end

local frames = {
	spymaster = util.extend(assembleIncognitaFrame(STRINGS.SLF.FRAMES.CUSTOM_SPYMASTER)){
		max_programs_mod = 1,
		algorithm_odds = 10,
		do_not_sell = true, -- not sold at terminals
		floor_weight = nil, -- does not turn up at dispatches
	},

	spymaster_sellable = util.extend(assembleIncognitaFrame(STRINGS.SLF.FRAMES.SPYMASTER)){
		max_programs_mod = 1,
		algorithm_odds = 10,

		value = 200,
	},

	desperado = util.extend(assembleIncognitaFrame(STRINGS.SLF.FRAMES.DESPERADO)){
		desperado_gain = 1,
		unique_special = true, -- requires a clarification tooltip
		value = 350,
		floor_weight = 2,

		onSpawnFrame = function(self, sim)
			sim:addTrigger(simdefs.TRG_ICE_BROKEN, self)
		end,
		onDespawnFrame = function(self, sim)
			sim:removeTrigger(simdefs.TRG_ICE_BROKEN, self)
		end,
		onTrigger = function(self, sim, evType, evData)
			if evType == simdefs.TRG_ICE_BROKEN and evData.unit and evData.unit:getTraits().mainframe_ice <= 0 then
				local x, y = nil, nil
				if evData.unit:getLocation() then
					x, y = evData.unit:getLocation()
				end

				sim:getPC():addCPUs( self.desperado_gain, sim, x, y )
			end
		end,
	},

	toolbox = util.extend(assembleIncognitaFrame(STRINGS.SLF.FRAMES.TOOLBOX)){
		max_programs_mod = 3,
		max_pwr_mod = -12,
		value = 450,
	},

	obelus = util.extend(assembleIncognitaFrame(STRINGS.SLF.FRAMES.OBELUS)){
		daemon_duration_mod = 3,
		algorithm_odds = 30,
		value = 300,
	},

	--[[supercorridor = util.extend(assembleIncognitaFrame(STRINGS.SLF.FRAMES.SUPERCORRIDOR)){
		max_programs_mod = 1,
		value = 400,

		-- Whenever you end the turn on the same PWR as the Counterintelligence AI, gain 4 PWR.
	},]]

	heartbeat = util.extend(assembleIncognitaFrame(STRINGS.SLF.FRAMES.HEARTBEAT)){
		max_programs_mod = 1,
		value = 100,

		-- Activate: destroy a program to revive an agent.
		active = true,
		unique_special = true,

		active_text_enabled = STRINGS.SLF.FRAMES.HEARTBEAT.BUTTON_ACTIVE,
		active_text_disabled = STRINGS.SLF.FRAMES.HEARTBEAT.BUTTON_INACTIVE,
		active_hover_disabled = STRINGS.SLF.FRAMES.HEARTBEAT.BUTTON_INACTIVE_HOVER,

		useActive = function( self, widget, sim )
			-- assemble a list of programs to sacrifice
			local options = {}

			for i, program in pairs(sim:getPC():getAbilities()) do
				table.insert(options, program.name)
			end

			table.insert(options, 1, STRINGS.UI.HUD_CANCEL)

			sim._choiceCount = sim._choiceCount + 1
			local option = dial_evs.showProgramBindDialog( 
				widget._hud, 
				STRINGS.SLF.FRAMES.HEARTBEAT.CHOICE_TITLE, 
				STRINGS.SLF.FRAMES.HEARTBEAT.CHOICE_DESC, 
				options 
			)

			if option == 0 then
				sim._choiceCount = sim._choiceCount - 1
				return
			else
				sim._choices[ sim._choiceCount ] = option
				for abilityID, program in pairs(sim:getPC():getAbilities()) do
					if program.name == options[option] then
						-- sacrifice the program
						sim:getPC():removeAbility(sim,program)
					end
				end

				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_turing_use" )
				-- revive agents
				for i, agent in pairs(sim:getPC():getUnits()) do
					if agent:getTraits().isAgent and agent:getTraits().canKO and 			-- isnt a drone, those are unfortunately also isAgent
						agent:isDown() and not simquery.isUnitPinned( sim, agent ) then 	-- is KO/dead, but not pinned
						
						if agent:isDead() then
							assert( agent:getWounds() >= agent:getTraits().woundsMax )
							agent:getTraits().dead = nil
							agent:addWounds( agent:getTraits().woundsMax - agent:getWounds() - 1 )			
						end
						agent:setKO( sim, nil )
				        agent:getTraits().mp = math.max( 0, agent:getMPMax() - (agent:getTraits().overloadCount or 0) )

				        local speechdefs = include( "sim/speechdefs" )
						sim:emitSpeech( agent, speechdefs.EVENT_REVIVED )
					end
				end
			end

			return widget._hud:refreshHud()
		end,

		canUseActive = function( self, sim )
			local downedAgents = {}

			for i, unit in pairs(sim:getPC():getUnits()) do
				if unit:getTraits().isAgent and unit:getTraits().canKO and 			-- isnt a drone, those are unfortunately also isAgent
					unit:isDown() and not simquery.isUnitPinned( sim, unit ) then 	-- is KO/dead, but not pinned
					table.insert(downedAgents, unit)
				end
			end

			if #downedAgents ~= 0 and #sim:getPC():getAbilities() ~= 0 then
				return true
			end

			return false
		end,
	},

	dinosaurus = util.extend(assembleIncognitaFrame(STRINGS.SLF.FRAMES.DINOSAURUS)){
		value = 550,
		max_programs_mod = -1,
		active = true, -- has an active ability
		unique_special = true,
		breakFirewallsBonus = 2,
		--do_not_sell = true, -- TODO: temporarily disabled

		active_text_enabled = STRINGS.SLF.FRAMES.DINOSAURUS.BUTTON_ACTIVE,
		active_text_disabled = STRINGS.SLF.FRAMES.DINOSAURUS.BUTTON_INACTIVE,
		active_hover_disabled = STRINGS.SLF.FRAMES.DINOSAURUS.BUTTON_INACTIVE_HOVER,

		useActive = function( self, widget, sim )
			local options = {}

			for i, program in pairs(sim:getPC():getAbilities()) do
				if program.break_firewalls and program.break_firewalls > 0 then
					table.insert(options, program.name)
				end
			end

			table.insert(options, 1, STRINGS.UI.HUD_CANCEL )

			--log:write("[ACW-DINO] Now displaying Binding Options: "..util.stringize(options,1))

			sim._choiceCount = sim._choiceCount + 1
			-- yucky hud-side code in sim, but apparently the sim way to do this is closed to us
			local option = dial_evs.showProgramBindDialog( 
				widget._hud, 
				STRINGS.SLF.FRAMES.DINOSAURUS.CHOICE_TITLE, 
				STRINGS.SLF.FRAMES.DINOSAURUS.CHOICE_DESC, 
				options 
			)
			--log:write("[ACW-DINO] Choice made: " .. tostring(options[option] or "CANCEL") .. " ["..tostring(option).."]")

			if option == 0 then
				sim._choiceCount = sim._choiceCount - 1
				return
			else
				sim._choices[ sim._choiceCount ] = option
				for abilityID, program in pairs(sim:getPC():getAbilities()) do
					if program.name == options[option] then
						self:doBindToProgram( sim, program )
						break
					end
				end
			end

			return widget._hud:refreshHud()
		end,

		doBindToProgram = function( self, sim, program )
			-- record the binding
			sim:getParams().agency.SLF_incogFrame_metadata = program.name

			--log:write("LOG_SPAM", "[ACW-DINO] Now bound to "..program.name)

			program.break_firewalls = program.break_firewalls + self.breakFirewallsBonus

			sim:addTrigger("SLF_DINO_TARGET_UNINSTALLED", self)

			program.undino_despawn = program.onDespawnAbility or function(self, sim) end
			program.onDespawnAbility = function( self, sim, ... )
				-- if despawning before the level is done, keep the binding..?
				if not sim:isGameOver() then
					sim:triggerEvent("SLF_DINO_TARGET_UNINSTALLED")
				end
				return program.undino_despawn( self, sim, ... )
			end

			program.undino_tooltip = program.onTooltip or mainframe_common.DEFAULT_ABILITY.onTooltip
			program.onTooltip = function( self, screen, sim, player, ... )
				local tooltip = program.undino_tooltip( self, screen, sim, player, ... )
				local section = tooltip:addSection()

				section:addAbility( 
					STRINGS.SLF.FRAMES.DINOSAURUS.TOOLTIP_TITLE, 
					STRINGS.SLF.FRAMES.DINOSAURUS.TOOLTIP_DESC, 
					"gui/icons/item_icons/items_icon_small/icon-incognitachip_small.png" )

				return tooltip
			end
		end,

		doUnbindFromProgram = function( self, sim )
			local progname = sim._params.agency.SLF_incogFrame_metadata
			local program = nil
			for i, ability in pairs(sim:getPC():getAbilities()) do
				if ability.name == progname then
					program = ability
					break
				end
			end
			sim._params.agency.SLF_incogFrame_metadata = nil
			
			if program then
				program.break_firewalls = program.break_firewalls - self.breakFirewallsBonus

				program.onDespawnAbility = program.undino_despawn
				program.onTooltip = program.undino_tooltip
			end

			sim:removeTrigger("SLF_DINO_TARGET_UNINSTALLED", self)
		end,

		canUseActive = function( self, sim )
			if sim._params.agency.SLF_incogFrame_metadata then
				-- possible PWR tax to switch target
				return false
			end

			return true
		end,

		onSpawnFrame = function(self, sim)
			local program 
			local progname = sim._params.agency.SLF_incogFrame_metadata
			--log:write("LOG_SPAM", "[ACW-DINO] Spawning now, seeking program: "..tostring(progname))

			for i, ability in pairs(sim:getPC():getAbilities()) do
				--log:write("LOG_SPAM", "[ACW-DINO] Checking "..tostring(ability.name))
				if ability.name == progname then
					program = ability
					break
				end
			end
			if program then
				self:doBindToProgram( sim, program )
			else
				sim._params.agency.SLF_incogFrame_metadata = nil
			end
		end,

		onDespawnFrame = function(self, sim)
			if not sim:isGameOver() then
				self:doUnbindFromProgram( sim )
			else
				-- re-record the name of the bound program, as it could have changed mid-mission
				for i, program in pairs(sim:getPC():getAbilities()) do
					if program.undino_tooltip then
						sim._params.agency.SLF_incogFrame_metadata = program.name
						break
					end
				end
			end
		end,
		onTrigger = function(self, sim, evType, evData)
			if evType == "SLF_DINO_TARGET_UNINSTALLED" then
				-- explicitly invalidate bond (that's right double-oh-seven, screw you in particular!)
				self:doUnbindFromProgram( sim )
			end
		end,
	},

	monolith = util.extend(assembleIncognitaFrame(STRINGS.SLF.FRAMES.MONOLITH)){
		max_programs_mod = 2,
		max_pwr_mod = 20,
		pwr_mod = 1,
		value = 750,
		floor_weight = 3,
	},

	--[[grimoire = util.extend(assembleIncognitaFrame(STRINGS.SLF.FRAMES.GRIMOIRE)){
		max_programs_mod = 3,
		required_option = "ac_chips",
		value = 400,
		floor_weight = 2,

		spec_programs = {
			{ slots = 3, type = "SCRIPT", color = util.color(140/255, 255/255, 140/255) },
		},
		special = util.sformat(STRINGS.SLF.FRAMES.GRIMOIRE.SPECIAL, 
			util.color.clrToHex(util.color(140/255, 255/255, 140/255))..
			STRINGS.SLF.PROGRAMS.SCRIPT.SPEC_TYPE.."</c>"),
	},

	deep_red = util.extend(assembleIncognitaFrame(STRINGS.SLF.FRAMES.RED_QUEEN)){ -- both a reference to Deep Red, and to Resident Evil
		max_programs_mod = 3,
		required_option = "ac_programs",
		floor_weight = 2,
		spec_programs = {
			{ slots = 3, type = "CAISSA", color = util.color(255/255, 0/255, 96/255) }
		},
		value = 400,
		special = util.sformat(STRINGS.SLF.FRAMES.RED_QUEEN.SPECIAL, 
			util.color.clrToHex(util.color(255/255, 0/255, 96/255))..
			STRINGS.SLF.PROGRAMS.CAISSA_COMMON.SPEC_TYPE.."</c>"),
	},]]

	blackguard = util.extend(assembleIncognitaFrame(STRINGS.SLF.FRAMES.BLACKGUARD)){
		max_pwr_mod = -15,
		firewalls_broken = 1,
		value = 300,
		unique_special = true,

		notSoldAfter = 48,

		onSpawnFrame = function(self, sim)
			sim:addTrigger( simdefs.TRG_UNIT_APPEARED, self )
			sim:addTrigger( simdefs.TRG_START_TURN, self )

			self:toggleSightable(sim, false)
			-- only on turn 0
			if sim:getTurnCount() == 0 then
				sim:forEachUnit(function(unit)
					if unit:getTraits().sightable and unit:getTraits().mainframe_item and sim:getPC():hasSeen( unit ) then
						self:executeAbility(sim, unit)
					end
				end)
			end
		end,

		onDespawnFrame = function(self, sim)
			sim:removeTrigger( simdefs.TRG_UNIT_APPEARED, self )
			sim:removeTrigger( simdefs.TRG_START_TURN, self )

			self:toggleSightable(sim, true)
		end,

		toggleSightable = function( self, sim, toggleOn )
			sim:forEachUnit( function (unit)
				if not toggleOn then
					-- turn off sightable for mainframe units under NPC control, that we havent spotted yet
					-- this still doesn't fuckin work! Drones that get controlled later, can still be spotted
					if unit:getTraits().mainframe_item and unit:getPlayerOwner() ~= sim:getPC() and not unit:getTraits().SLF_blackguard_seen then
						unit:getTraits().SLF_temp_sightable = unit:getTraits().sightable
						unit:getTraits().sightable = true
					end
				else
					if unit:getTraits().SLF_temp_sightable then
						unit:getTraits().sightable = unit:getTraits().SLF_temp_sightable
						unit:getTraits().SLF_temp_sightable = nil
					end
				end
			end)
		end,

		couldBreakIce = function( self, sim, target )
			-- mainframe.canBreakIce, but ignoring the equipped program properties
			-- temporarily unequip program
			local equipped_program = sim:getPC():getEquippedProgram()
			if equipped_program then
				equipped_program = equipped_program:getID()
			end
			sim:getPC():equipProgram()
			local result, reason = mainframe.canBreakIce(sim, target)
			if not result and reason == STRINGS.UI.REASON.NO_PROGRAM then
				result = true
			end
			sim:getPC():equipProgram(equipped_program)

			if not result then
				return result, reason
			end

			-- but respect null zones
			local x0, y0 = target:getLocation()
			for unitID, unit in pairs( sim:getAllUnits() ) do
				local range = unit:getTraits().mainframe_suppress_range
				if range and not unit:isKO() and unit:getLocation() and unit ~= target then
					local distSqr = mathutil.distSqr2d( x0, y0, unit:getLocation() )
					if distSqr <= range * range then
						return false, "nulldrone"
					end
				end
			end

			return result, reason
		end,

		onTrigger = function(self, sim, evType, evData)
			-- shameless adoption of frontier code
			-- sightable units are able to trigger TRG_UNIT_APPEARED
			if evType == simdefs.TRG_START_TURN and sim:getCurrentPlayer() == sim:getPC() then
				-- temp-sightable ON (true sightable OFF)
				self:toggleSightable(sim, false)

			end
			if evType == simdefs.TRG_START_TURN and sim:getCurrentPlayer() == sim:getNPC() then
				-- temp-sightable OFF
				self:toggleSightable(sim, true)
			end

			if evType == simdefs.TRG_UNIT_APPEARED and evData.unit 
			and evData.unit:getTraits().mainframe_item 
			and evData.seerID == sim:getPC():getID()
			and not evData.unit:getTraits().SLF_blackguard_seen then
				self:executeAbility(sim, evData.unit)				
			end
		end,

		executeAbility = function(self, sim, target)
			--log:write("LOG_SPAM", "[ACW-BLACKGUARD] Detected "..target:getName().." ("..target:getID()..")")
			-- on TRG_UNIT_APPEARED of a new unit, mark the unit as seen
			target:getTraits().SLF_blackguard_seen = true

			local canBreak, reason = self:couldBreakIce(sim, target)

			if canBreak then -- try to break!
				mainframe.breakIce( sim, target, self.firewalls_broken )
				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=self.name .. " | "..STRINGS.SLF.FRAMES.BLACKGUARD.ABILITY_SUCCESS.."\n" .. target:getName(), color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/HUD/gameplay/console_result_good" } )
				--log:write("Success!")
			else
				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=self.name .. " | "..STRINGS.SLF.FRAMES.BLACKGUARD.ABILITY_FAILURE.."\n" .. target:getName(), color=cdefs.COLOR_CORP_WARNING, sound = "SpySociety/HUD/gameplay/console_result_bad" } )
				--log:write("Failure: "..(reason or "no reason returned"))
			end
			target:getTraits().sightable = target:getTraits().SLF_temp_sightable
			target:getTraits().SLF_temp_sightable = nil
		end,
	},
}

-- these will go into simplayer on init (apparently, it doesn't work to just append them from here)
local function setIncognitaFrame( self, framedef )
	local sim = self._sim
	-- remove the previous frame, if necessary
	if self._incogFrame then
		--log:write("LOG_SPAM", "[ACW-FRAME] Now dismantling: "..self._incogFrame.name)
		self._incogFrame:onDespawnFrame(sim)
		self._incogFrame:onDespawnFrameBase(sim)
		sim:getParams().SLF_incogFrame = nil
	end
	-- create the new frame, if supplied
	if framedef then
		--log:write("LOG_SPAM", "[ACW-FRAME] Now installing: "..framedef.name)
		self._incogFrame = framedef
		framedef._playerOwner = self
		framedef:onSpawnFrame(sim)
		framedef:onSpawnFrameBase(sim)
		sim:getParams().SLF_incogFrame = framedef.name
	else
		self._incogFrame = framedef
	end
end
local function getIncognitaFrame( self )
	local sim = self._sim
	if self:isNPC() then
		assert(false, "Attempting to get the Corp's frame. Only the Agency may have a frame.")
		-- figure better to throw this explicit error
		-- than to have it be a nil value elsewhere to debug
	elseif self._incogFrame then
		-- if a frame exists, that's fine, just return at the end
	elseif sim._params.SLF_incogFrame then
		-- otherwise, try to fetch it from campaign
		self._incogFrame = self:getIncognitaFramedef(sim._params.SLF_incogFrame)
	else
		-- ...or at least make one up, all else failing.
		-- This should not happen, because this would happen in init before
		--self._incogFrame = setIncognitaFrame( self, frames.spymaster )
	end

	return self._incogFrame
end

local function getIncognitaFramedefs( self )
	return frames
end

local function getIncognitaFramedef( self, name )
	for k, frame in pairs(frames) do
		if k == name or frame.name == name then
			return frame
		end
	end
end

local function _firstMatchingSpec(frameSpecs, programTypes)
	if not programTypes then
		return nil
	end
	for _, spec in ipairs(frameSpecs) do
		for _, pt in ipairs(programTypes) do
			if pt == spec.type then
				return spec
			end
		end
	end
	return nil
end
local function countSpecSlots( self, frameOverride, additionalProgram )
	-- outputs a table with occupied spec slots of each type
	-- unlike the game itself, prefers to occupy spec slots first
	-- useful to determine if such an arrangement is even possible
	local tbl = {
		EMPTY = 0,
	}

	local frame = frameOverride or self:getIncognitaFrame()
	local specs = frame.spec_programs

	for _, spec in ipairs(specs) do
		tbl[spec.type] = 0
	end

	for i, program in ipairs(self:getAbilities()) do
		local spec = _firstMatchingSpec(specs, program.specialized_type)
		if spec and (tbl[spec.type] or 0) < spec.slots then
			tbl[spec.type] = (tbl[spec.type] or 0) + 1
		else
			tbl.EMPTY = tbl.EMPTY + 1
		end
	end

	if additionalProgram then
		local spec = _firstMatchingSpec(specs, additionalProgram.specialized_type)
		if spec and (tbl[spec.type] or 0) < spec.slots then
			tbl[spec.type] = (tbl[spec.type] or 0) + 1
		else
			tbl.EMPTY = tbl.EMPTY + 1
		end
	end

	return tbl
end

local function sortSpecSlots( self )
	-- Sort programs in specialized slots to the end.
	-- The UI always draws specialized slots at the end, so position them that way.
	-- This sort is stable and correctly limits special slots if multiple
	-- slot types are specified.
	local frame = self:getIncognitaFrame()
	local specs = frame and frame.spec_programs
	if not specs or #specs == 0 then
		return
	end

	local programs = self._mainframeAbilities
	-- Programs in special slots (reverse order).
	local programsByType = {}
	-- Programs not matching any slot (reverse order).
	local emptyPrograms = {}
	-- Programs matching a slot, but not in that slot due to overflow (reverse order).
	local overflowPrograms = {}
	for _, spec in ipairs(specs) do
		programsByType[spec.type] = {}
	end
	for i = #programs, 1, -1 do
		local program = programs[i]
		local spec = _firstMatchingSpec(specs, program.specialized_type)
		if spec and #(programsByType[spec.type]) < spec.slots then
			table.insert(programsByType[spec.type], program)
		elseif spec then
			table.insert(overflowPrograms, program)
		else
			table.insert(emptyPrograms, program)
		end
	end

	local i = #programs
	for j = #specs, 1, -1 do
		local spec = specs[j]
		for _, program in ipairs(programsByType[spec.type]) do
			programs[i] = program
			i = i - 1
		end
	end
	for _, program in ipairs(overflowPrograms) do
		programs[i] = program
		i = i - 1
	end
	for _, program in ipairs(emptyPrograms) do
		programs[i] = program
		i = i - 1
	end
	assert(i == 0)
end

local function patchNpcAddMainframeAbility(oldAddAbility)
	local function addMainframeAbility( self, sim, abilityID, hostUnit, reversalOdds, ... )
		-- allow for daemon reversal odds override
		local results = nil
		local pcFrame = sim:getPC() and sim:getPC()._incogFrame
		if not reversalOdds and self:isNPC() and pcFrame then
			return oldAddAbility( self, sim, abilityID, hostUnit, pcFrame.algorithm_odds, ... )
		else
			return oldAddAbility( self, sim, abilityID, hostUnit, reversalOdds, ... )
		end
	end
	return addMainframeAbility
end

local function patchPcAddMainframeAbility(oldAddAbility)
	local function addMainframeAbility( self, sim, abilityID, hostUnit, reversalOdds, ... )
		local results = { oldAddAbility( self, sim, abilityID, hostUnit, reversalOdds, ... ) }
		self:sortSpecSlots()
		return results
	end
	return addMainframeAbility
end

local engine = include("sim/engine")
local oldInit = engine.init

-- move the frame install from simplayer:init to sim:init, so that pc is ready and we can use things like pc:getAbilities()
function engine:init( params, ... )
	local results = { oldInit(self, params, ...) }

	local pcplayer, npcplayer
	for i, player in pairs(self._players) do
		if player:isPC() then
			pcplayer = player
		elseif player:isNPC() then
			npcplayer = player
		end
	end

	local diff = params.difficultyOptions

	if diff and diff.ACW_frames_enabled then
		-- append daemon reversal override enabler
		npcplayer.addMainframeAbility = patchNpcAddMainframeAbility(npcplayer.addMainframeAbility)
	
		-- append frame handler funcs
		pcplayer.getIncognitaFrame = getIncognitaFrame
		pcplayer.setIncognitaFrame = setIncognitaFrame
		pcplayer.getIncognitaFramedef = getIncognitaFramedef
		pcplayer.getIncognitaFramedefs = getIncognitaFramedefs
		-- hotswap fix
		pcplayer.addMainframeAbility = patchPcAddMainframeAbility(pcplayer.addMainframeAbility)
		-- append spec slots support
		pcplayer.countSpecSlots = countSpecSlots
		pcplayer.sortSpecSlots = sortSpecSlots
		-- attempt to get a frame
		local frame = nil
		if params.agency.SLF_incogFrame then
			frame = pcplayer:getIncognitaFramedef(params.agency.SLF_incogFrame)
		else
			frame = pcplayer:getIncognitaFramedef("spymaster") -- default is spymaster, but apparently this doesn't work
		end

		-- initialize the frame
		pcplayer:setIncognitaFrame(frame)

		--log:write("LOG_SPAM", "[ACW-FRAME] Sim:init - Frame set up: "..tostring(frame.name))
	end

	return unpack(results)
end

-- copy sim's installed frame to the campaign at mission end
local OldDoFinishMission = mission_scoring.DoFinishMission
function mission_scoring.DoFinishMission(sim, campaign, ...)
	campaign.agency.SLF_incogFrame = sim._params.SLF_incogFrame
	campaign.agency.SLF_incogFrame_metadata = sim._params.SLF_incogFrame_metadata
	--log:write("LOG_SPAM", util.stringize(campaign),1)
	return OldDoFinishMission( sim, campaign, ... )
end

return frames
