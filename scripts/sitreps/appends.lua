local game = include( "modules/game" )
local util = include("client_util")
local array = include("modules/array")
local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )
local mui_tooltip = include( "mui/mui_tooltip" )
local mathutil = include( "modules/mathutil" )
local serverdefs = include( "modules/serverdefs" )
local version = include( "modules/version" )
local agentdefs = include("sim/unitdefs/agentdefs")
local skilldefs = include( "sim/skilldefs" )
local simdefs = include( "sim/simdefs" )
local simactions = include( "sim/simactions" )
local modalDialog = include( "states/state-modal-dialog" )
local rig_util = include( "gameplay/rig_util" )
local metrics = include( "metrics" )
local cdefs = include("client_defs")
local scroll_text = include("hud/scroll_text")
local guiex = include( "client/guiex" )
local SCRIPTS = include('client/story_scripts')
local simengine = include('sim/engine')

local sitreps = include(SCRIPT_PATHS.advanced_cyberwarfare.."/sitreps/sitreps" )

local function getEligibleSitreps()
	local sitrep_selection = util.tdupe(sitreps)

	local abilitydefs = include("sim/abilitydefs")
	for name, grid in pairs(sitrep_selection) do
		if grid.PE_AI_required and not abilitydefs.lookupAbility("W93_AI_assembly") then
	    	sitrep_selection[name] = nil
	    end
	end

	return sitrep_selection
end

local function fetchSitrep( name )
	for i, sitrep in pairs(sitreps) do
		if sitrep.name == name then
			return sitrep
		end
	end
end

-- actual mechanics of applying the grid
local oldinit = simengine.init
function simengine:init( params, levelData, ... )
	local grid = params.ACW_GRID
	self._acw_grid = grid

	if grid and grid.name then
		grid = fetchSitrep(grid.name)
		if not grid then return end
		if grid.pre_initialize then
			-- grid makes a fundamental change to the sim, before initial generation.
			-- very dangerous, as NOTHING can be relied upon at this point
			grid:pre_initialize( self )
		end
	end

	-- generate level, spawn units, ...
	oldinit(self, params, levelData, ...)

	if grid and grid.name then
		grid = fetchSitrep(grid.name)
		if not grid then return end
		if grid.initialize then
			-- grid makes a change to the sim once, and that change applies to the level
			grid:initialize( self )
			--log:write("[ACWLOG] Grid attached: "..grid.name)
		end
		if grid.trigger then
			for i, trg in pairs(grid.trigger) do
				-- grid adds a trigger and serves as the carrier of that trigger's effect
				--log:write("[ACWLOG] Attempting to add a trigger to "..util.stringize(grid, 2))
				self:addTrigger( trg, grid )
			end
			--log:write("[ACWLOG] Grid embedded: "..grid.name)
		end
	end
end

local function generateSitrep( mapScreen, situation, corpData, chance )
	local sitrep_none = {}

	-- do not make sitreps on the first mission, mid2, or ending1
	--log:write("Generating sitrep based on situation: "..util.stringize(situation, 2))
	if mapScreen._campaign.missionCount == 0 then
		log:write("[ACW-GRIDS] First mission - no grid")
		return sitrep_none
	end
	if situation.name == "ending_1" then
		log:write("[ACW-GRIDS] Final mission - no grid")
		return sitrep_none
	end

	if situation.name == "mid_1" then
		local allowed = true
		for i, DLC in pairs(mapScreen._campaign.difficultyOptions.enabledDLC) do
			if DLC.name == "Advanced Cyberwarfare" then
				allowed = DLC.options.ac_sitreps_mid1.enabled
			end
		end
		if not allowed then
			log:write("[ACW-GRIDS] Mid mission - no grid")
			return sitrep_none
		end
	end

	--log:write("[ACWLOG] Generating sitrep")
	local result = math.random(100)
	--log:write("[ACWLOG] Result: "..tostring(result).."/"..tostring(minimum))

	local sitreps = getEligibleSitreps() -- make sure we're not getting sitreps with prereqs

	if result > chance then
		-- each sitrep has a weight to appear at each corp (default is 10)
		local total_weight = 0
		for i, sitrep in pairs(sitreps) do
			total_weight = total_weight + sitrep.weights[corpData.shortname]
		end
		local choice = math.random(total_weight)
		local init_choice = choice
		for i, sitrep in pairs(sitreps) do
			choice = choice - sitrep.weights[corpData.shortname]
			if choice < 0 then
				log:write("[ACW-GRIDS] ".."Generated "..sitrep.name
					.." with rolls ["..result.." > ".. chance .."], ["..
					total_weight-init_choice.." / "..total_weight.."]")
				return sitrep
			end
		end
	else
		log:write("[ACW-GRIDS] ".."Failed to generate sitrep with a roll of ["..result.."<"..tostring(chance).."/100]")
		return sitrep_none
	end
end

-- map-screen grid label, along with actual mechanics of generating a grid
local stateMapScreen = include( "states/state-map-screen" )
local OnClickLocation_old = stateMapScreen.OnClickLocation

stateMapScreen.OnClickLocation = function( self, situation, ... )
	local results = {OnClickLocation_old( self, situation, ... )}

	local chance_threshold = 0

	-- where the hell are DLCs...
	for i, DLC in pairs(self._campaign.difficultyOptions.enabledDLC) do
		if DLC.name == "Advanced Cyberwarfare" then
			chance_threshold = DLC.options.ac_sitreps.value
		end
	end
	
	chance_threshold = 100 - (chance_threshold*100)

	if STRINGS.SLF then
		local mission_screen = nil
		for i, active_screen in pairs(mui.internals._activeScreens) do
			if active_screen:findWidget("SLF_Sitrep") then
				mission_screen = active_screen
				break
			end
		end

		if not mission_screen then return end

		local corpData = serverdefs.getCorpData( situation )

		if not situation.sitrep then
			situation.sitrep = generateSitrep( self, situation, corpData, chance_threshold )
			--log:write("Sitrep output: "..util.stringize(situation.sitrep, 1).."; length: "..#situation.sitrep)

			-- additionally, if generation was successful, run any immediate Sitrep Pre-Sim logic (once)
			if situation.sitrep.presim_init then
				situation.sitrep:presim_init(situation)
			end
		end
		if situation.sitrep.name then
			self._campaign.missionParams = self._campaign.missionParams or {}
			self._campaign.missionParams.ACW_GRID = situation.sitrep
			mission_screen:findWidget("SLF_Sitrep"):setVisible( true )
			mission_screen:findWidget("SLF_Sitrep.label"):setText("<font1_16_sb><c:F48134>Cybersec Grid detected</c>\n\n<font1_14_r><c:F5FF78>"..situation.sitrep.name..STRINGS.SLF.SITREPS.GRID_DEFAULT.."</c>\n<font1_12_r>"..situation.sitrep.desc)
		else
			mission_screen:findWidget("SLF_Sitrep"):setVisible( false )
			if self._campaign.missionParams then
				self._campaign.missionParams.ACW_GRID = nil
			end
		end
	end

	return unpack(results)
end

-- in-mission grid label
local hudFile = include("hud/hud")
local oldCreateHud = hudFile.createHud

function hudFile.createHud(...)
	local hud = oldCreateHud(...)

	local oldRefresh = hud.refreshHud

	function hud:refreshHud(...)
		local res = {oldRefresh(self, ...)}

		if not self._game.params.ACW_GRID then
			if self._screen.binder.statsPnl then
				local statsGridTxt = self._screen.binder.statsPnl.binder.statsGridTxt
				if statsGridTxt and not statsGridTxt.isnull then
					statsGridTxt:setVisible(false)
				end
			end
			return unpack(res)
		end

		local sim = self._game.simCore
		local showPanels = (sim:getCurrentPlayer() == self._game:getLocalPlayer())
		self._screen.binder.statsPnl:setVisible( showPanels and self:canShowElement( "statsPnl" ))

		local daysTxt = 0
		local turn = math.ceil( (sim:getTurnCount() + 1) / 2)
		if self._game.params.campaignHours then
			daysTxt = math.floor( self._game.params.campaignHours / 24 ) + 1
		end
		local gameModeStr = util.toupper( serverdefs.GAME_MODE_STRINGS[ self._game.params.campaignDifficulty ] )

	    local corpData = serverdefs.CORP_DATA[ self._game.params.world ]
	    local situationData = serverdefs.SITUATIONS[ self._game.params.situationName ]
	    if corpData and situationData then
	    	local locationName = situationData.ui.locationName
	    	if sim:getTags().newLocationName then
				locationName = sim:getTags().newLocationName
	    	end
	        local missionTxt = corpData.stringTable.SHORTNAME .." " .. locationName
		    self._screen.binder.statsPnl.binder.statsTxt:setText( string.format(STRINGS.UI.HUD_DAYS_TURN_ALARM, turn, daysTxt, gameModeStr, missionTxt ) )
		    local statsGridTxt = self._screen.binder.statsPnl.binder.statsGridTxt
		    if statsGridTxt and sim:getParams().ACW_GRID then
		    	local x, y = self._screen.binder.statsPnl.binder.statsTxt:getPosition()
		    	if y == 10 then
		    		y = 20
		    	end
				self._screen.binder.statsPnl.binder.statsTxt:setPosition(x, y)
				local grid = sim._acw_grid
				--log:write("[ACW] Grid follows:\n"..util.stringize(grid,1))

				-- fetch proper description of the grid.
				local desc_to_use = ""
				if grid.used then
					desc_to_use = "<c:616161>"..grid.desc.."</c>"..
					(grid.flavor_used and "\n<c:61AAAA>"..grid.flavor_used.."</c>" or "")..
					"\n"..STRINGS.SLF.SITREPS.EFFECT_APPLIED
				else
					desc_to_use = grid.desc..
					(grid.flavor and "\n<c:61AAAA>"..grid.flavor.."</c>" or "")
				end

				local tip =	mui_tooltip( 
					STRINGS.SLF.WORLD.GRID.NAME,
					STRINGS.SLF.WORLD.GRID.DESC .. "\n\n" .. 
					"<c:FF8411>" .. grid.name .. STRINGS.SLF.SITREPS.GRID_DEFAULT .. "</c>\n" .. desc_to_use
				)
				statsGridTxt:setText( "<font1_16_r><c:F4FF78>WARNING: SPECIAL MEASURE DETECTED</c>\n</font><font4_32_r><c:FF8411>"..grid.name.."</c>") --</font>\n"..grid.desc.."" )
				statsGridTxt:setTooltip(tip)
				statsGridTxt:setVisible(true)
			else
		    	local x, y = self._screen.binder.statsPnl.binder.statsTxt:getPosition()
		    	if y == 20 then
		    		y = 10
		    	end
				self._screen.binder.statsPnl.binder.statsTxt:setPosition(x, y)
				statsGridTxt:setVisible(false)
			end
	    end

	    return unpack(res)
	end

	return hud
end