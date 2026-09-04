-- mainframe_ghost.lua
-- details the limitations and alternate mechanics of mainframe ghosts
-- (units that exist only within the mainframe)

local array = include( "modules/array" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local abilityutil = include( "sim/abilities/abilityutil" )
local abilitydefs = include( "sim/abilitydefs" )
local inventory = include( "sim/inventory" )
local mission_util = include( "sim/missions/mission_util" )
local stateUpgradeScreen = include("states/state-upgrade-screen")
local itemdefs = include("sim/unitdefs/itemdefs")
local sim = include("sim/engine")
local simquery = include("sim/simquery")
local simunit = include("sim/simunit")
local simplayer = include("sim/simplayer")
local items_panel = include("hud/items_panel")

--this shader code was referred to me by Hekateras, and the author is either herself or Qoala
--it is entirely awesome and ridiculously customizable
--no mortal should possess such power
--modders ye be warned

--default mainframe shader (for non-Dragon)
local ghost_shader_rgba = { 128/255, 0/255, 255/255, 0.75 }
local function getGhostShader(ghost_shader_rgba)
	return {
		shader = KLEIAnim.SHADER_FOW,
		r = ghost_shader_rgba[1], 
		g = ghost_shader_rgba[2], 
		b = ghost_shader_rgba[3],
		a = ghost_shader_rgba[4],
		lum = 1.3
	}
end
--bypass for the function responsible for slotting in shaders
local agentrig = include( "gameplay/agentrig" ).rig
local refresh_old = agentrig.refreshRenderFilter

function agentrig.refreshRenderFilter(self)
    
    refresh_old(self)
    
    if self._renderFilterOverride then
        self._prop:setRenderFilter( self._renderFilterOverride )
    else
        local unit = self._boardRig:getLastKnownUnit( self._unitID )
        if unit then
            -- let units override mainframe colours via mainframeShaderOverride trait
        	if unit:getTraits().mainframeShaderOverride then
        		ghost_shader_rgba = unit:getTraits().mainframeShaderOverride
        		local ghost_shader = getGhostShader(ghost_shader_rgba)
            	self._prop:setRenderFilter( ghost_shader )
        	end
            if unit:getTraits().isMainframeGhost then
		        local boardRig = self._boardRig
                if boardRig._SLF_pseudomainframe then
                	if not self._ghostFX then
                		-- init the compound ghost FX
                		local owner = self
                		self._ghostFX = {
                			subFX = {},

                			setVisible = function( self, bool )
                				for i, fx in pairs(self.subFX) do
                					fx:setVisible( bool )
                				end
                			end
                		}
                		-- add effects here
			            self._ghostFX.subFX.SelectionDisc = self:createHUDProp("kanim_hud_agent_hud", "item", "loop", boardRig:getLayer("ceiling"), self._prop )
						self._ghostFX.subFX.SelectionDisc:setSymbolModulate("shockwave",unpack(ghost_shader_rgba))
						self._ghostFX.subFX.SelectionDisc:setSymbolModulate("ring5",unpack(ghost_shader_rgba))
						-- add more effects here
						self._ghostFX.subFX.ConsoleFX = self:createHUDProp("kanim_null_fx", "effect", "idle", boardRig:getLayer("floor"), self._prop )
						self._ghostFX.subFX.ConsoleFX:setSymbolModulate("innercicrle",unpack(ghost_shader_rgba))
						self._ghostFX.subFX.ConsoleFX:setSymbolModulate("innerring",unpack(ghost_shader_rgba))
					end
					-- toggle everything on while in Dragonspace
					self._ghostFX:setVisible(true)
				else
					if self._ghostFX then
						-- toggle everything off while out of Dragonspace
						self._ghostFX:setVisible(false)
					end
				end
            end
        end
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------
local modifyOld = sim.modifyExit
function sim:modifyExit( start_cell, dir, operation, unit, ... )
	--simlog(tostring(start_cell).."; "..tostring(dir).."; "..tostring(operation).."; "..tostring(unit)..".")
	if unit and unit:getTraits().isMainframeGhost == true then
		return
	end
	--simlog(tostring(start_cell).."; "..tostring(dir).."; "..tostring(operation).."; "..tostring(unit)..".")	
	return modifyOld( self, start_cell, dir, operation, unit, ... )
end

-- let ghosts glimpse one tile behind doors that they can move through
local warpOld = sim.warpUnit
function sim.warpUnit( self, unit, cell, facing, reverse )-- extra logic gate for Archive Dragon
	-- decline to spawn her when she's bound, if she's not been cleared to spawn

	-- side effect: because spawns can be declined, *de*spawning can fail
	-- (because she's already at nil), so block those attempts as well
	local oldcell = self:getCell( unit:getLocation() )
	if unit and unit:getTraits().acw_dependent then
		-- warping in, not cleared: fail
		if cell and not oldcell and not unit:getTraits().acw_cleared_to_spawn then
			return
		end
	end

	if unit and unit:getTraits().acw_dependent or unit:getTraits().acw_will_be_dependent then
		-- warping out, already at nil: fail
		if not cell and not oldcell then
			return
		end
	end

	warpOld( self, unit, cell, facing, reverse )

	--[[if unit and cell and unit.getTraits and unit:getTraits().isMainframeGhost == true then
		for i, exit in pairs(cell.exits) do
			if simquery.canPathBetween(sim, unit, cell, exit.cell) then
				-- if there are units on the tile, see them too
				for i, cellUnit in pairs(exit.cell.units) do
					unit:getPlayerOwner():glimpseUnit( self, cellUnit:getID() )
				end
			end
		end
	end]]
end

-- simquery pathing mechanics:
-- canPath: check dynamicImpass conflicts; assuming none, proceed
-- canStaticPath: check impass value of endcell, assert startcell, proceed
-- canPathBetween: check other required tiles, status of doors and walls in the way
-- RUNS FROM *INSIDE* canStaticPath; startcell guaranteed

local canStaticPathOld = simquery.canStaticPath
function simquery.canStaticPath( cellquery, unit, stc, enc )
	-- if ghost:
	if unit and unit:getTraits().isMainframeGhost == true then
		if enc.units then
			for i, cU in pairs(enc.units) do
				local t = cU:getTraits()
				if t.emitterID then
					-- this is a laser emitted by an emitter
					local sim = cU:getSim()
					local emitter = sim:getUnit(t.emitterID)

					-- fix canControl real quick, so simquery.findNearestEmptyCell can work from the cell
					-- this should probably be in vanilla but it's an edge case so understandable
					local oldCanControl = emitter.canControl
					function emitter:canControl( unit )
						if not unit then return false end
						return oldCanControl( self, unit )
					end

					local isLethal = emitter:getTraits().mainframe_spawnprop == "laser_beam"
					local isEnemyOwned = emitter:getPlayerOwner() ~= unit:getPlayerOwner()
					if isLethal and isEnemyOwned then
						-- can't move through enemy lethal lasers
						return false, simdefs.CANMOVE_NOEXIT
					end
				end
			end
		end
		if enc.impass > 0 then
			local mainframe_device = false

			-- check units at the endcell
			-- if tile has impass, and there is a mainframe device on it, we can path there
			-- assuming that pathing can actually be done

			for i, cellUnit in pairs(enc.units) do
				local t = cellUnit:getTraits()
				if t.mainframe_status and (
						not unit:getTraits().isSLFDragon or
						not t.magnetic_reinforcement or 
						t.mainframe_ice <= 2 or
						(unit:getTraits().bypassLevel and unit:getTraits().bypassLevel >= 2)
					) then
					-- a mainframe device exists on the tile, and it's one that can be accessed
					mainframe_device = true
				end
			end

			if mainframe_device == false then
				return false, simdefs.CANMOVE_STATIC_IMPASS
			else
				if stc and not simquery.canPathBetween( cellquery, unit, stc, enc ) then
					return false, simdefs.CANMOVE_NOEXIT
				end

				return true, simdefs.CANMOVE_OK
			end
		end
		-- Dragon entering a null zone unupgraded
		if unit:getTraits().isSLFDragon and (not unit:getTraits().bypassLevel or unit:getTraits().bypassLevel < 3) and unit:getSim()._ACW_null_cells[enc.id] then
			return false, simdefs.CANMOVE_NOEXIT
		end
	end

	-- if anyone else:
	local orig_canPath, orig_reason = canStaticPathOld( cellquery, unit, stc, enc )

	return orig_canPath, orig_reason
end

local canPathBetweenOld = simquery.canPathBetween
function simquery.canPathBetween( cellquery, unit, stc, enc )
	local result = canPathBetweenOld( cellquery, unit, stc, enc )

	if unit and unit:getTraits().isMainframeGhost == true then
		-- if a ghost attempts to move to a real cell, but conventional logic says they can't...
		if enc and not result then
			-- there might be a door in the way, which is pathable for ghosts
			-- first, ensure move is orthogonal (one coord is changing, but not *both*)
			if (stc.x ~= enc.x) ~= (stc.y ~= enc.y) then
				-- ensure endcell is really there (double check never hurts ¯\_(ツ)_/¯)
				local dir = simquery.getDirectionFromDelta( enc.x - stc.x, enc.y - stc.y )
				local exit = stc.exits[ dir ]
				local found = exit and exit.cell.x == enc.x and exit.cell.y == enc.y
				if found then
					-- high-security doors are still off limits
					if exit and exit.closed then
						--log:write("canPathBetween - CLOSED DOOR("..enc.x..", "..enc.y..")")
						if exit.keybits then
							--log:write("canPathBetween - LOCKED DOOR: "..exit.keybits..", LEVEL: "..tostring(unit:getTraits().bypassLevel))
							--[[ref
							OFFICE 			= 1,
							SECURITY 		= 2,
							ELEVATOR 		= 4,
							ELEVATOR_INUSE 	= 8,
							GUARD   		= 16,
							VAULT   		= 32,
							FINAL_LEVEL	    = 64, 
							FINAL_RED       = 128, 
						    SPECIAL_EXIT    = 256, 
						    BLAST_DOOR      = 512, ]]
						    if exit.keybits == simdefs.DOOR_KEYS.OFFICE then
						    	result = true
						    elseif exit.keybits == simdefs.DOOR_KEYS.SECURITY and unit:getTraits().bypassLevel and unit:getTraits().bypassLevel >= 1 then
						    	result = true
						    elseif exit.keybits == simdefs.DOOR_KEYS.VAULT and unit:getTraits().bypassLevel and unit:getTraits().bypassLevel >= 3 then
						    	result = true
						    end
						end
					end
				end
			end
		end
	end

	return result
end

local couldUnitSeeOld = simquery.couldUnitSee
function simquery.couldUnitSee( sim, unit, targetUnit, ignoreCover, targetCell, ... )
	-- Dragon can see in both worlds
	-- SuperUsers can see only digital and can be seen only in digital
	-- SuperUsers that can't be alerted, also can't see (hyperfocused AI)
	-- allied units see each other anyway
	local canSeeDimension = false

	if unit and targetUnit and unit:getPlayerOwner() ~= targetUnit:getPlayerOwner() then
		if unit:getTraits().isSLFDragon then
			canSeeDimension = true
		elseif targetUnit:getTraits().isSLFDragon and not unit:getTraits().isMainframeGhost then
			return false
		elseif unit:getTraits().isMainframeGhost == targetUnit:getTraits().isMainframeGhost then
			-- units are in the same dimension
			if unit:getTraits().innervate and unit:getPlayerOwner() ~= targetUnit:getPlayerOwner() then
				-- unit can't be alerted, so does not concern themselves with enemy units
				return false
			end
		end

		if targetUnit:getTraits().queryInvisible then
			-- invisible units are invisible to enemies
			return false
		end
	end
	
	return couldUnitSeeOld( sim, unit, targetUnit, ignoreCover, targetCell, ... )
end

local canModifyExitOld = simquery.canModifyExit
function simquery.canModifyExit( unit, exitOp, cell, dir, ... )
	if unit:getTraits().isMainframeGhost then
		return false
	end
	return canModifyExitOld( unit, exitOp, cell, dir, ... )
end
----------------------------------------------------------------------------------------------------------------------------------------------------
--make ghosts immune to encumbrance
--not a balance issue for Dragon, she drops everything anyway
local checkOlderload = simunit.checkOverload
--heh
function simunit.checkOverload(self, sim)
	if self:getTraits().isMainframeGhost then
		return
	else
		checkOlderload(self, sim)
	end
end
----------------------------------------------------------------------------------------------------------------------------------------------------
local oldTick = simunit.tickKO

function simunit.tickKO(self, sim)
	local cell = sim:getCell( self:getLocation() )
	if cell then
		-- jet ghosts cant pin steel ribs
		for i, cellUnit in ipairs( cell.units ) do
			if cellUnit:getTraits().isMainframeGhost then
				cellUnit:getTraits().fake_agent = cellUnit:getTraits().isAgent
				cellUnit:getTraits().isAgent = nil
			end
		end
		oldTick(self, sim)
		for i, cellUnit in ipairs( cell.units ) do
			if cellUnit:getTraits().isMainframeGhost then
				cellUnit:getTraits().isAgent = cellUnit:getTraits().fake_agent
				cellUnit:getTraits().fake_agent = nil
			end
		end
	end
end
----------------------------------------------------------------------------------------------------------------------------------------------------
--sync dependent's AP with anchor's (but don't let anchor gain AP from dependent)
--flagui also highlights the host AP instead; this is done in cyberspace_view
-- known bug: stims directly add to the units' AP instead of using simunit:addMP
-- I'm so outraged at that, that I'm not even gonna fix it. WHYYYYYYYYYYYY.
local useMpOld = simunit.useMP

function simunit:useMP( delta, sim, ... )
	local anchor = self:getTraits().acw_anchor
	local dependent = self:getTraits().acw_dependent

	if anchor then
		-- anchor exists, so I am dependent; use their MP
		anchor:useMP( delta, sim, ... )
		-- make extra sure that my MP is synced with theirs
		self:getTraits().mp = anchor:getTraits().mp
	else
		useMpOld( self, delta, sim, ... )
		if dependent then
			-- dependent exists, so I am anchor; my MP is used, update theirs
			dependent:getTraits().mp = self:getTraits().mp
		end
	end
end
----------------------------------------------------------------------------------------------------------------------------------------------------
-- mark and unmark dependent units for garbage collection when they LoSe or regain their connection
local oldAdd = simunit.addSeenUnit
local oldRemove = simunit.removeSeenUnit

function simunit.addSeenUnit(self, unit, ...)
	if not unit:getTraits().acw_anchor then
		return oldAdd( self, unit, ... )
	end
	local sim = self:getSim()
	local eyeballOwnerID = self:getTraits().peekID
	if self:getTraits().acw_dependent or (eyeballOwnerID and
	sim:getUnit(eyeballOwnerID):getTraits().acw_dependent) then
		-- we are the anchor or its eyeball

		-- remove the unit from GC if ANY of the eyeballs or the owner spots it

		--log:write("LOG_SPAM", "[ACW-LOSDETECTOR] NOW UNMARKING GC")
		unit:getTraits().acw_gc = nil
		unit:getTraits().mainframeShaderOverride = unit:getTraits().shaderOverrides["live"]
		unit:getSim():dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
	end
	return oldAdd( self, unit, ... )
end

function simunit.removeSeenUnit(self, unit, oldcell, newcell, ...)
	local anchor = unit:getTraits().acw_anchor
	if not anchor then
		return oldRemove( self, unit, ... )
	end
	local sim = self:getSim()
	local eyeballOwnerID = self:getTraits().peekID
	if self:getTraits().acw_dependent or (eyeballOwnerID and
	sim:getUnit(eyeballOwnerID):getTraits().acw_dependent) then
		-- we are the anchor or its eyeball

		-- add the unit to GC if ALL of the eyeballs and the owner fail to see it

		local capableOfSeeing, unobstructed = false, false

		for i, seer in pairs(sim:getPC():getUnits()) do
			capableOfSeeing, unobstructed = false, false
			if seer == anchor or seer:getTraits().peekID == anchor:getID() then
				-- a unit sees another when both Query and LOS return true
				--log:write("LOG_SPAM", "[ACW-LOSDETECTOR] LOSCHK <"..seer:getName()..">:")
				capableOfSeeing = false or simquery.couldUnitSee( self, seer, unit, true )
				--log:write("LOG_SPAM", "Simquery tested: "..tostring(capableOfSeeing and "can see" or "can't see"))
				local x, y = unit:getLocation()
				unobstructed = false or sim._los:hasSight( seer, x, y )
				--log:write("LOG_SPAM", "LoS tested: "..tostring(unobstructed and "exists" or "obstructed"))
				if capableOfSeeing and unobstructed then break end
			end
		end

		if not capableOfSeeing or not unobstructed then
			--log:write("LOG_SPAM", "[ACW-LOSDETECTOR] NOW MARKING GC")
			unit:getTraits().acw_gc = true
			unit:getTraits().mainframeShaderOverride = unit:getTraits().shaderOverrides["fade"]
			unit:getSim():dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
		end
	end

	return oldRemove( self, unit, oldcell, newcell, ... )
end
----------------------------------------------------------------------------------------------------------------------------------------------------
local oldDeploy = simplayer.deployUnit

function simplayer:deployUnit( sim, agentID, ... )
	local agentDef = self._deployed[ agentID ].agentDef
	if agentDef and agentDef.traits["isSLFDragon"] and agentDef.traits["acw_anchor"] and not self._dragon_in_limbo then
		-- unless it's the first time, don't warp Dragon into the level
		local unitData = unitdefs.createUnitData( agentDef )

		local unit = simfactory.createUnit( unitData, sim )
		unit:setPlayerOwner( self )
		sim:spawnUnit( unit )

		self._dragon_in_limbo = unit
		return
	end
	return oldDeploy( self, sim, agentID, ... )
end
----------------------------------------------------------------------------------------------------------------------------------------------------
--If a ghost loots a safe, lock the items! They must not move anything! (this is undone in an items_panel overrde below)
-- 3 types of items_panel exist
-- loot (safe), transfer (2 units) and pickup (off the ground)
local function improvedInit(self, hud, userUnit, unit, celly, ...)
	if userUnit:getTraits().isMainframeGhost then
		for i, child in pairs(unit:getChildren()) do
			if inventory.canCarry(userUnit, child) then
				child:getTraits().SLF_carryable = true
				child:removeAbility(self._hud._game.simCore, "carryable")
			end
		end
	end
	-- sometimes there's a cellx instead of a unit
	-- check if there's also a celly; if not, it's a real unit
	if not celly and unit:getTraits().isMainframeGhost then
		for i, child in pairs(unit:getChildren()) do
			if inventory.canCarry(userUnit, child) then
				child:getTraits().SLF_carryable = true
				child:removeAbility(self._hud._game.simCore, "carryable")
			end
		end 
	end
end

---

local initOld = items_panel.loot.init
function items_panel.loot:init(hud, userUnit, unit, ...)
	initOld(self, hud, userUnit, unit, ...)
	improvedInit(self, hud, userUnit, unit, ...)
end
local initOld = items_panel.transfer.init
function items_panel.transfer:init(hud, userUnit, unit, ...)
	initOld(self, hud, userUnit, unit, ...)
	improvedInit(self, hud, userUnit, unit, ...)
end
local initOld = items_panel.pickup.init
function items_panel.pickup:init(hud, userUnit, unit, ...)
	initOld(self, hud, userUnit, unit, ...)
	improvedInit(self, hud, userUnit, unit, ...)
end

---

-- Undo carryable changes on panel close
function improvedDestroy(self)
	local unit = self._targetUnit
	if unit then
		for i, child in pairs(unit:getChildren()) do
			if child:getTraits().SLF_carryable then
				child:giveAbility("carryable")
			end
		end
	end
	unit = self._unit
	if unit then
		for i, child in pairs(unit:getChildren()) do
			if child:getTraits().SLF_carryable then
				child:giveAbility("carryable")
			end
		end
	end
end

---

local destroyOld = items_panel.loot.destroy
function items_panel.loot:destroy(...)
	improvedDestroy(self)
	destroyOld(self, ...)
end
local destroyOld = items_panel.transfer.destroy
function items_panel.transfer:destroy(...)
	improvedDestroy(self)
	destroyOld(self, ...)
end
local destroyOld = items_panel.pickup.destroy
function items_panel.pickup:destroy(...)
	improvedDestroy(self)
	destroyOld(self, ...)
end

---

-- After visible items/credits are displayed (refreshItem returned false), display uncarryable items.
local function improvedRefreshItem(items_panel, widget, i, ...)
	self = items_panel
	if not self._unit or not self._unit:getTraits().isMainframeGhost then
		return false
	end

	local visibleItemsCount = 0
	local uncarryableItems = {}

	for i,childUnit in ipairs(self._targetUnit:getChildren()) do
		if not childUnit:getTraits().augment or not childUnit:getTraits().installed then
			if inventory.canCarry( self._unit, childUnit ) then
				visibleItemsCount = visibleItemsCount + 1
			elseif childUnit:getTraits().SLF_carryable then
				table.insert(uncarryableItems,childUnit)
			end
		end
	end

	if self._targetUnit and ((simquery.calculateCashOnHand( self._hud._game.simCore, self._targetUnit ) or 0) > 0 or (self._targetUnit:getTraits().credits or 0) > 0 or (simquery.calculatePWROnHand( self._hud._game.simCore, self._targetUnit ) or 0) > 0) then
		-- Credits/PWR are displayed as a fake item
		visibleItemsCount = visibleItemsCount + 1
	end
	i = i - visibleItemsCount
	if i <= 0 then
		return false
	end

	local item = uncarryableItems[i]

	if item == nil then
		return false
	else
		widget:setVisible( true )
		local guiex = include('guiex')
        guiex.updateButtonFromItem( self._screen, nil, widget, item, self._unit )
		widget.binder.itemName:setText( util.toupper(item:getName() ) )
		widget.binder.cost:setText( "" )
		widget.binder.img:setColor(0.5,0.5,0.5,1)
		widget.binder.btn:setColor(0.5,0.5,0.5,1)

		return true
	end
end

---

local refreshOld = items_panel.loot.refreshItem
function items_panel.loot:refreshItem( widget, i )
	local result = refreshOld(self, widget, i)
	return result or improvedRefreshItem(self, widget, i)
end
local refreshOld = items_panel.transfer.refreshItem
function items_panel.transfer:refreshItem( widget, i )
	local result = refreshOld(self, widget, i)
	return result or improvedRefreshItem(self, widget, i)
end
local refreshOld = items_panel.pickup.refreshItem
function items_panel.pickup:refreshItem( widget, i )
	local result = refreshOld(self, widget, i)
	return result or improvedRefreshItem(self, widget, i)
end

----------------------------------------------------------------------------------------------------------------------------------------------------

--If a ghost opens the store, lock the warez! They must not purchase anything! (this is undone in a trigger in the main code below)
local showItemStore = abilitydefs.lookupAbility("showItemStore")
local execOld = showItemStore.executeAbility
function showItemStore.executeAbility( self, sim, unit, userUnit )
	if userUnit:getTraits().isMainframeGhost and (unit:getTraits().storeType == "standard" or unit:getTraits().storeType == "large") then
    	for i, item in ipairs( unit.items ) do
    		if not item:getTraits().SLF_incogFrame then
    			item:removeAbility(sim, "carryable")
    		end
    	end
    	for i, item in ipairs( unit.weapons ) do
    		item:removeAbility(sim, "carryable")
    	end
    	for i, item in ipairs( unit.augments ) do
    		item:removeAbility(sim, "carryable")
    	end
	end

	return execOld( self, sim, unit, userUnit )
end
--------------------------------------------------------------------