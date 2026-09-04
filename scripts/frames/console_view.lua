-- in-mission grid label
local array = include("modules/array")
local util = include("modules/util")
local sim = include("sim/engine")
local simquery = include("sim/simquery")
local simdefs = include("sim/simdefs")
local mui_tooltip = include( "mui/mui_tooltip" )
local modalDialog = include( "states/state-modal-dialog" )
local abilitydefs = include("sim/abilitydefs")

local function colourCode( str )
	local eval = tonumber(str)
	if eval < 0 then
		str = "(<c:FF6000>"..str.."</c>)" -- there is already a - in the number, so we don't append it
	elseif eval > 0 then
		str = "(<c:00FF60>+"..str.."</c>)"
	else
		str = ""
	end
	return str
end

local function decToHex( int )
	local str = ""

	while int > 1 do
		local rem = int % 16
		int = math.floor(int / 16)

		if rem == 15 then
			str = "F"..str
		elseif rem == 14 then
			str = "E"..str
		elseif rem == 13 then
			str = "D"..str
		elseif rem == 12 then
			str = "C"..str
		elseif rem == 11 then
			str = "B"..str
		elseif rem == 10 then
			str = "A"..str
		elseif rem == 0 then
			str = "0"..str
		else
			str = rem..str
		end
	end

	while str:len() < 2 do
		str = "0"..str
	end

	return str
end

function util.color.clrToHex( utilcolor )
	if not utilcolor then return "<c:FFFFFF>" end
	local str = ""
	str = str .. decToHex(math.floor(utilcolor.r*255))
	str = str .. decToHex(math.floor(utilcolor.g*255))
	str = str .. decToHex(math.floor(utilcolor.b*255))

	return "<c:"..str..">"
end

local function getMaxPrograms( sim )
	-- an approximation of Sim Constructor's simquery:getMaxPrograms
	-- unfortunately, sim:getParams is accessible only once sim:init concludes
	return simdefs.MAX_PROGRAMS + (sim._params.agency.extraPrograms or 0) + (sim._params.difficultyOptions.programCount or 5) + sim._tags.extraPrograms - 5
end

local function makeFrameTooltip( frame )
	local name = frame.name .. STRINGS.SLF.FRAMES.FRAME
	local desc = ""
	local player = frame:getPlayerOwner()
	local sim = player._sim

	if frame.flavor then
		desc = desc .. "<c:61AAAA>"..frame.flavor.."</c>" .. "\n"
	end
	desc = desc .. "\n"

	if frame.unique_special and frame.special_extended and frame.special_extended ~= "" then
		desc = desc .. frame.special_extended .."\n\n"
	elseif frame.unique_special then
		desc = desc .. frame.special .."\n\n"
	end

	local PWR_max = player:getMaxCpus()
	local PWR_start = sim._params.difficultyOptions.startingPower + (sim:getPC():getTraits().extraStartingPWR or 0)
	local PWR_current = player:getCpus()

	local PROG_max = getMaxPrograms(sim)
	local PROG_current = 0 -- gets filled in later, slight optimization

	local PROGSPEC_max = 0 
	local PROGSPEC_type = ""
	for i, specialization in pairs(frame.spec_programs) do
		PROGSPEC_max = PROGSPEC_max + specialization.slots
	end
	if #frame.spec_programs == 1 then
		PROGSPEC_type = frame.spec_programs[1].type
	else
		PROGSPEC_type = "MIXED"
	end

	local HASH_max = player:getTraits().aiTokenMax
	local HASH_current = player:getTraits().aiToken

	local PWR_mod, CD_mod = 0, 0
	local programs = player:getAbilities()
	PROG_current = #programs
	local ALGO_chance_base = player:getTraits()._incogReversalOverride or 10 -- percent
	local ALGO_chance_real = 0
	for i, ability in pairs(programs) do
		if ability.pwrMod then
			PWR_mod = PWR_mod + ability.pwrMod
		end
		if ability.coolDownMod then
			CD_mod = CD_mod + ability.coolDownMod
		end
		if ability.daemonReversalAdd then
			ALGO_chance_real = ALGO_chance_real + ability.daemonReversalAdd
		end
	end
	PWR_mod = PWR_mod + frame.pwr_mod
	CD_mod = CD_mod + frame.cd_mod

	local DAEMON_dur = player:getTraits().daemonDurationModd

	desc = desc .. util.sformat(STRINGS.SLF.FRAMES.TOOLTIP.PWR, PWR_max, PWR_start, PWR_current) .. "\n"
	desc = desc .. util.sformat(STRINGS.SLF.FRAMES.TOOLTIP.PROGRAMS, PROG_max, PROG_current) .. "\n"
	if PROGSPEC_max ~= 0 then
		desc = desc .. STRINGS.SLF.FRAMES.TOOLTIP.SPEC_PROGRAMS .. "\n"
		for i, spec in pairs(frame.spec_programs) do
			desc = desc .. util.sformat(STRINGS.SLF.FRAMES.TOOLTIP.SPEC_TYPE,
			 util.color.clrToHex(spec.color)..spec.type.."</c>", 
			 spec.slots) .. "\n"
		end
	end
	if HASH_max and HASH_current then
		desc = desc .. util.sformat(STRINGS.SLF.FRAMES.TOOLTIP.HASH, HASH_max, HASH_current) .. "\n"
	end
	if PWR_mod ~= 0 then
		desc = desc .. util.sformat(STRINGS.SLF.FRAMES.TOOLTIP.PWRMOD, PWR_mod) .. "\n"
	end
	if CD_mod ~= 0 then
		desc = desc .. util.sformat(STRINGS.SLF.FRAMES.TOOLTIP.CDMOD, CD_mod) .. "\n"
	end
	desc = desc .. util.sformat(STRINGS.SLF.FRAMES.TOOLTIP.ALGO, ALGO_chance_base, ALGO_chance_base+ALGO_chance_real)
	if DAEMON_dur ~= 0 then
		desc = desc .. "\n" .. util.sformat(STRINGS.SLF.FRAMES.TOOLTIP.DAEMON_LENGTH, DAEMON_dur)
	end

	return mui_tooltip( name, desc )
end

-- properly despawn the frame when the player is despawned
local oldDespawnUnit = sim.despawnUnit
function sim:despawnUnit( player, ... )
	-- we are interested in cases when a player is despawned
	if player:isPC() and not player.getPlayerOwner and player.setIncognitaFrame then
		player:setIncognitaFrame()
	end
	return oldDespawnUnit(self, player, ...)
end

local mainframe_panel = include("hud/mainframe_panel").panel

-- there is a mainframe_panel:programWidgetSetColor, but, tragically, it doesn't work on empty slots
function mainframe_panel:specProgramSlotsSetColor()
	--log:write("[ACW-COLOR] Setting spec slot colour.")
	local sim = self._hud._game.simCore

	local maxPrograms = sim:getQuery().getMaxPrograms(sim)
	local specPrograms = {}
	if sim:getPC().getIncognitaFrame and sim:getPC():getIncognitaFrame() then
		specPrograms = sim:getPC():getIncognitaFrame().spec_programs
	end
	local currentPrograms = #sim:getPC():getAbilities()

	local array_slots = {
		EMPTY = maxPrograms
	}

	if #specPrograms > 0 then
		--log:write("[ACW-COLOR] Detected spec program slots.")
		for i, spec in pairs(specPrograms) do
			local specCountdown = spec.slots
			while specCountdown > 0 do
				-- count a slot. Remove it.
				array_slots.EMPTY = array_slots.EMPTY - 1
				array_slots[spec.type] = (array_slots[spec.type] or 0) + 1
				specCountdown = specCountdown - 1
			end
		end

		-- with 8 programs and 3 spec, we want slots 6, 7 and 8 to be painted
		-- unless, of course, they are filled already
		local minSlot = array_slots.EMPTY + 1
		-- adjust minSlot by program scroll offset
		minSlot = minSlot - self.programScrollHandler._scrollIndex

		for i, spec in pairs(specPrograms) do
			local colorOb = spec.color or util.color(140/255, 255/255, 140/255)
			colorOb.a = 0.8
			-- slots 6 and 7 are of one spec, slot 8 is of another
			local maxSlot = minSlot + spec.slots - 1
			--log:write("[ACW-COLOR] Applying spec program flairs.")

			for slot, widget in self._panel.binder.programsPanel.binder:forEach( "program" ) do
				--log:write("[ACW-COLOR] Iterating over slot "..widget._name)
				local btn = self._panel.binder.programsPanel.binder["empty"..slot]
				if slot >= minSlot and slot <= maxSlot then
					
					-- apply paint
					-- apparently, these don't have a setColor
					-- they have a setTooltip, but that appears nonfunctional
					btn:setTooltip(util.sformat(STRINGS.SLF.FRAMES.SPEC_PROGRAM_SLOT, util.color.clrToHex(spec.color)..spec.type.."</c>"))
					--log:write("[ACW-COLOR] Updated colours and tooltips for program "..slot)
					btn._cont:setColor(colorOb:unpack())
				else
					btn._cont:setColor(81/255, 140/255, 140/255, 0.8)
					--btn._cont:setImage("gui/hud3/MainframeIcons_agent_program_empty.png")
					btn:setTooltip(nil)
				end
			end
			minSlot = maxSlot + 1
		end
		--[[for i, child in pairs(self._panel.binder.programsPanel._children) do
			if child._cont._isVisible and child._cont._images then
				log:write("Detected "..child._name..", img "..util.stringize(child._cont._def, 3))
			end
		end]]
	else
		for slot, widget in self._panel.binder.programsPanel.binder:forEach( "program" ) do
			local btn = self._panel.binder.programsPanel.binder["empty"..slot]
			btn:setTooltip(nil)
			btn._cont:setColor(81/255, 140/255, 140/255, 0.8)
		end
	end
end

local oldRefresh = mainframe_panel.refresh
function mainframe_panel:refresh( ... )
	local results = { oldRefresh( self, ... ) }

	local frame_panel = self._screen.binder.mainframePnl.binder.frame_panel
		
	-- update frame info
	local sim = self._hud._game.simCore

	if not frame_panel or frame_panel.isnull then 
		return unpack(results) 
	else
		if not sim:getPC().getIncognitaFrame then
			frame_panel:setVisible( false )
			return unpack(results)
		end
	end
	local frame = sim:getPC():getIncognitaFrame()
	if not frame then return unpack(results) end

	if self._mode == 0 then -- 0 = MODE_HIDDEN, per mainframe_panel
		frame_panel:setVisible( false )
	else
		frame_panel:setVisible( true )

		self:specProgramSlotsSetColor()

		local info_2 = STRINGS.SLF.FRAMES.INFO_2
		if #frame.special < 25 then -- for short special descs, insert another newline
			info_2 = "\n"..info_2
		end

		frame_panel.binder.label:setText(util.sformat(STRINGS.SLF.FRAMES.INFORMATION, 
			frame.name,
			sim:getPC():getMaxCpus(),
			colourCode(frame.max_pwr_mod),
			getMaxPrograms( sim ),
			colourCode(frame.max_programs_mod),
			frame.special,
			info_2))

		local tip =	makeFrameTooltip( frame )
		frame_panel.binder.label:setTooltip(tip)

		if frame.active then
			local button = frame_panel.binder.frame_active
			button.onClick = util.makeDelegate( nil, frame.useActive, frame, self, sim )
			button:setVisible( true )
			if not frame.canUseActive or frame:canUseActive( sim ) then
				-- if not defined canUse, assume canUse == true
				button:setText(frame.active_text_enabled)
				button:setTooltip(nil)
				button:setDisabled( false )
			else
				button:setText(frame.active_text_disabled)
				button:setTooltip(frame.active_hover_disabled)
				button:setDisabled( true )
			end
		else
			local button = frame_panel.binder.frame_active
			button:setDisabled( true )
			button:setVisible( false )
		end
	end

	return unpack(results)
end

-- enforce being unable to buy programs when only specialized capacity is available
local shop_panel = include("hud/shop_panel")

local function onClickWrapper( self, fn, panel, item, itemType, ... )
	local sim = panel._hud._game.simCore	
	local player = panel._unit
	if not panel._unit._isPlayer then	
	 	player = panel._unit:getPlayerOwner()
	end
	if player ~= sim:getCurrentPlayer() then
		modalDialog.show( STRINGS.UI.TOOLTIP_CANT_PURCHASE )
		return
	end

	local pc = sim:getPC()
	local pcFrame = pc and pc.getIncognitaFrame and pc:getIncognitaFrame()
	if item:getTraits().mainframe_program and pcFrame and #pcFrame.spec_programs > 0 then
		-- Vanilla checks
		local maxPrograms = sim:getQuery().getMaxPrograms(sim) 
		if #player:getAbilities() >= maxPrograms then
			modalDialog.show( STRINGS.UI.TOOLTIP_PROGRAMS_FULL )
			return
		end
		if player:hasMainframeAbility( item:getTraits().mainframe_program ) then
			modalDialog.show( STRINGS.UI.TOOLTIP_ALREADY_OWN )
			return
		end

		-- Program slot usage if this programe were added
		local maxNormal = maxPrograms - pcFrame:getTotalSpecSlots()
		local newCounts = pc:countSpecSlots(nil, abilitydefs.lookupAbility(item:getTraits().mainframe_program))
        if newCounts.EMPTY > maxNormal then
            -- Couldn't fit everything into slots
            modalDialog.show( STRINGS.SLF.FRAMES.REASON_SPEC_SLOTS )
            return
		end
	end

	return fn(panel, item, itemType, ...)
end

-- onClickBuyItem, unfortunately, is local. But we can cheat a bit and find it anyway
-- change server terminals
local oldRefreshItem = shop_panel.server.refreshItem
function shop_panel.server:refreshItem( widget, i, itemType, ... )
	local results = { oldRefreshItem(self, widget, i, itemType, ...) }

	local oldOnClickTbl = widget.binder.btn.onClick
	if not oldOnClickTbl then return unpack(results) end
	local onClick = oldOnClickTbl._fn
	oldOnClickTbl._fn = nil

	widget.binder.btn.onClick = util.makeDelegate( nil, onClickWrapper, self, onClick, unpack(oldOnClickTbl) )

	local mainframe_common = include("sim/abilities/mainframe_common")
	local caissa_tooltip = mainframe_common.DEFAULT_CAISSA.onUnitdataTooltip

	-- todo refactor
	widget.binder.btn:setTooltip(
		function()
			local tooltip = util.tooltip( self._screen, nil )
			caissa_tooltip( self._hud, tooltip, self._targetUnit.items[i], self._unit, nil )
			return tooltip
		end
	)

	return unpack(results)
end
-- ...and the code compile side mission
local oldRefreshItem = shop_panel.research.refreshItem
function shop_panel.research:refreshItem( widget, i, itemType, ... )
	local results = { oldRefreshItem(self, widget, i, itemType, ...) }
	local oldOnClickTbl = widget.binder.btn.onClick
	if not oldOnClickTbl then return unpack(results) end
	local onClick = oldOnClickTbl._fn
	oldOnClickTbl._fn = nil
	widget.binder.btn.onClick = util.makeDelegate( nil, onClickWrapper, self, onClick, unpack(oldOnClickTbl) )
	return unpack(results)
end

-- also, copy the colours/tooltip over to shop_panel
local oldRefreshPrograms = shop_panel.server.refreshUserPrograms

function shop_panel.server:refreshUserPrograms( player, ability, widget, i, ... )
	local results = { oldRefreshPrograms( self, player, ability, widget, i, ... )}
	local sim = self._hud._game.simCore

	-- false means empty slot
	if not results[1] then
		local maxPrograms = sim:getQuery().getMaxPrograms(sim)
		local specPrograms = {}
		if sim:getPC().getIncognitaFrame and sim:getPC():getIncognitaFrame() then
			specPrograms = sim:getPC():getIncognitaFrame().spec_programs
		end

		local array_slots = {}

		while #array_slots < maxPrograms do
			table.insert(array_slots, {})
		end

		if #specPrograms > 0 then
			--log:write("[ACW-COLOR] Detected spec program slots.")
			for j, spec in pairs(specPrograms) do
				local specCountdown = spec.slots
				while specCountdown > 0 do
					-- count a slot. Remove it.
					table.remove(array_slots, 1)
					table.insert(array_slots, spec)
					specCountdown = specCountdown - 1
				end
			end
		end
		if not array_slots[i] then return unpack(results) end
		local colorOb = array_slots[i].color

		-- check out specialized slots
		local tip = util.sformat(STRINGS.UI.TOOLTIPS.EMPTY_SLOT,1)
		if colorOb then
			colorOb.a = 0.8
			widget.binder.img:setColor(colorOb:unpack())
			tip = tip .. "\n".. util.sformat(STRINGS.SLF.FRAMES.SPEC_PROGRAM_SLOT, util.color.clrToHex(array_slots[i].color)..array_slots[i].type.."</c>")
		else
			widget.binder.img:setColor(util.color.GRAY:unpack())
		end
		--log:write("[ACW-COLOR] "..util.stringize(widget.binder.btn._image._images))
		widget.binder.btn:setTooltip( tip )
	end

	return unpack(results)
end

-- here follows the documentation of relevant parts of mainframe_panel obtained via logging.
--[[
mainframe_panel:
 - _iceBreaks: empty table, presumably temp-storage for icebreak events
 - _panel: proper contents, listed below
 - _base: constructor
 - _hud: pointer to hud
 - _hiddenProgram: -1, ???
 - programScrollHandler: 99% likely SimConst code
 - _screen: pointer to screen
 - _installing: presumably temp-storage similar to _iceBreaks?
 - _mode: 1, corresponds to SHOW_MAINFRAME. 0 is HIDE_MAINFRAME

panel: (proper contents)
 - _name: mainframePnl
 - _children: 2 entries: daemonPanel and programsPanel
 - _base: constructor
 - _cont: contents. Important to note: no ctor field present in the panel contents. Full cont table pasted below
 - _parent: pointer to mainframe_panel, most likely. Perhaps to hud.
 - binder: the typical binder.

_cont: (panel raw contents)
{
    _widget = table: 6D990198,
    _sx = 1,
    _prop = 6D9A1BC0 <MOAIProp2D>,
    _h = 0,
    _screen = table: 6D8223E8,
    _xpx = true,
    _y = -47,
    _x = 1,
    _sy = 1,
    _w = 0,
    _children = table: 6D98FF90,
    _base = function: 6D9354C0,
    _isVisible = true,
    _def = table: 6D81F9B8,
    _anchor = 1,
    _ypx = true,
},
]]

-- item: Construct Adjustment Framework
-- can adjust Incognita on the fly, consumable.
-- contains a framework to adjust to
-- at the regular nanofab, in addition to the 4 items, you will have 2 framework options
-- at a security dispatch, the CAF is a possible item
