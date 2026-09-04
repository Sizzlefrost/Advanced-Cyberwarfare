local util = include( "client_util" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local mui_defs = include( "mui/mui_defs")
local world_hud = include( "hud/hud-inworld" )
local simquery = include( "sim/simquery" )
local mathutil = include( "modules/mathutil" )
local geo_util = include( "geo_util" )
local targeting_base = include( "hud/targeting" )


---------------------------------------------------------------------
-- Unit-based cell targeting.

local flickerTarget = class( targeting_base.areaTargetBase )

function flickerTarget:init( game, range, sim, ability, anchor )
	self._game = game
	self.sim = sim 
	self._hiliteClr = { 0, 1, 1, 0.33 }
	self.mx = nil
	self.my = nil
	self.range = range
    self.unitTargets = { self.anchor }
    self.ability = ability
    self.anchor = anchor
end

function flickerTarget:setUnitPredicate( unitTargetFn )
    self.unitTargetFn = unitTargetFn
end

function flickerTarget:setHiliteColor( clr )
    self._hiliteClr = clr
end

function flickerTarget:hasTargets()
	return true
end

function flickerTarget:setTargetCell( cellx, celly )
    self.mx, self.my = cellx, celly

	if self:isValidTargetLoc( cellx, celly ) then
		self.cells = simquery.rasterCircle( self.sim, cellx, celly, self.range )
    else
        self.cells = nil
    end

     if self.unitTargetFn then
        local count = #self.unitTargets
        if self.cells then
		    for i = 1, #self.cells, 2 do
                local cell = self.sim:getCell( self.cells[i], self.cells[i+1] )
                if cell then
                    for j, cellUnit in ipairs(cell.units) do
                        if self.unitTargetFn( cellUnit ) then
                            -- Hey: does this already exist in the list?
                            local idx = array.find( self.unitTargets, cellUnit:getID() )
                            if idx then
                                table.insert( self.unitTargets, table.remove( self.unitTargets, idx ))
                                count = count - 1
                            else
                                table.insert( self.unitTargets, cellUnit:getID() )
                                self._game.boardRig:getUnitRig( cellUnit:getID() ):getProp():setRenderFilter( cdefs.RENDER_FILTERS["mainframe_pc"] )
                            end
                        end
                    end
                end
            end
		end

        while count > 0 do
            local unitRig = self._game.boardRig:getUnitRig( table.remove( self.unitTargets, 1 ))
            unitRig:refreshRenderFilter()
            count = count - 1
        end
    end
end

function flickerTarget:startTargeting()
   	--[[local rig = self._game.boardRig:getUnitRig( self.anchor:getID() )
    if self._hiliteClr[3] ~= 1 then
		local render_filter = cdefs.RENDER_FILTERS["mainframe_pc"] 
			-- { shader=KLEIAnim.SHADER_HILITE,		r=255/255,	g= 0/255,	b= 0/255,	a=0.5, lum = 1.0 }
		rig:getProp():setRenderFilter( render_filter )
	end]]
end

function flickerTarget:endTargeting()
    self:setTargetCell( nil, nil )
    local rig = self._game.boardRig:getUnitRig( self.anchor:getID() )
	rig:refreshRenderFilter()
end


function flickerTarget:onInputEvent( event )
	if event.eventType == mui_defs.EVENT_MouseDown and event.button == mui_defs.MB_Left then
        self.ux, self.uy = event.wx, event.wy

	elseif event.eventType == mui_defs.EVENT_MouseUp and event.button == mui_defs.MB_Left then
        if mathutil.dist2d( self.ux or event.wx, self.uy or event.wy, event.wx, event.wy ) >= 16 then
            return nil
        else
		    local x, y = self._game:wndToSubCell( event.wx, event.wy )	
		    local cellx, celly = math.floor(x), math.floor(y)
		    if self:isValidTargetLoc(cellx, celly) then
				local unitID = (self._hiliteClr[3] == 1) and self.anchor:getID() or self.ability.selectedAgent:getID()
		    	self.ability.selectedAgent = self.sim:getUnit(unitID)
			    return {cellx, celly, unitID}
		    else
			    return nil
		    end
        end
	elseif event.eventType == mui_defs.EVENT_MouseMove then
		local x, y = self._game:wndToSubCell( event.wx, event.wy )
        x, y = math.floor(x), math.floor(y)
        if x ~= self.mx or y ~= self.my then
            self.tooltip = self:generateTooltip( x, y )
            self:setTargetCell( x, y )
        end
    end
end

function flickerTarget:onDraw()
	MOAIGfxDevice.setPenColor(unpack(self._hiliteClr))
	--log.write("DRAWING: "..(util.stringize(self, 1) or tostring(nil)))
	if self.cells then
		for i = 1, #self.cells, 2 do
            local x, y = self.cells[i], self.cells[i+1]
			local x0, y0 = self._game:cellToWorld( x + 0.4, y + 0.4 )
			local x1, y1 = self._game:cellToWorld( x - 0.4, y - 0.4 )
			MOAIDraw.fillRect( x0, y0, x1, y1 )
		end

		if self._hiliteClr[3] == 1 then
			local x, y = self.anchor:getLocation()
			local x0, y0 = self._game:cellToWorld( x + 0.4, y + 0.4 )
			local x1, y1 = self._game:cellToWorld( x - 0.4, y - 0.4 )
			MOAIDraw.fillRect( x0, y0, x1, y1 )
		end

		--[[local rig = self._game.boardRig:getUnitRig( self.anchor:getID() )
		if self._hiliteClr[3] ~= 1 then
			local render_filter = cdefs.RENDER_FILTERS["mainframe_pc"] 
				-- { shader=KLEIAnim.SHADER_HILITE,		r=255/255,	g= 0/255,	b= 0/255,	a=0.5, lum = 1.0 }
			rig:getProp():setRenderFilter( render_filter )
		end]]

        return true
	end
	--[[local rig = self._game.boardRig:getUnitRig( self.anchor:getID() )
	rig:refreshRenderFilter()]]

    return false
end

function flickerTarget:generateTooltip( x, y )
    return nil
end

function flickerTarget:getTooltip( x, y )
    return self.tooltip
end

function flickerTarget:getDefaultTarget()
	return nil
end

function flickerTarget:isValidTargetLoc(x, y)
	local valid = x and y and self.sim:getPC():getLastKnownCell( self.sim, x, y ) ~= nil

	if not valid then return end

	local cell = self.sim:getCell(x,y)
	if not cell then return end
	if cell.impass ~= 0 then
		return
	end

	-- cell is at [0;2EFFECT]* of anchor: potentially valid
	local relCoords = { 
		{x=0, y=-self.ability.range*self.ability.effectMod}, 
		{x=0, y=self.ability.range*self.ability.effectMod}, 
		{x=self.ability.range*self.ability.effectMod, y=0}, 
		{x=-self.ability.range*self.ability.effectMod, y=0} }
	local guessed = false
	for i, coordSet in pairs(relCoords) do
		local anchorGuess = self.sim:getCell(coordSet.x+cell.x, coordSet.y+cell.y)
		if anchorGuess and anchorGuess == self.sim:getCell(self.anchor:getLocation()) then
			guessed = anchorGuess
		end
	end

	-- potentially valid cell is blocked from the original: invalid
	if guessed then
		local cells, i = {}, 0
		while i <= self.ability.range*self.ability.effectMod do
			local xd, yd = self.sim:getCell(self.anchor:getLocation()).x - cell.x, self.sim:getCell(self.anchor:getLocation()).y - cell.y
			xd, yd = simquery.getDeltaFromDirection(simquery.getDirectionFromDelta(xd, yd))
			table.insert(cells, self.sim:getCell(cell.x+i*xd, cell.y+i*yd))
			i = i+1
		end
		local prevCell = nil
		for i, cell in pairs(cells) do
			if prevCell and not simquery.isConnected(self.sim, cell, prevCell) then
				--[[log:write("Cell {"..tostring(cell.x)..", "..tostring(cell.y).."} is not connected to "..
					"cell {"..tostring(prevCell.x)..", "..tostring(prevCell.y).."}")]]
				return false
			end
			prevCell = cell
		end
	end

	-- cell contains an agent that is not selected: valid
	-- cell contains any other impassable unit: invalid
	for i, unit in pairs(cell.units) do
		if unit:getID() ~= self.anchor:getID() and unit:getTraits().isAgent then
			self.ability.selectedAgent = unit
			self:setHiliteColor( { 1, 1, 0, 0.33 } )
			self.ability.no_costs = true
			return true
		elseif unit:getTraits().dynamicImpass then
			return false
		end
	end

	--[[log:write("Valid: "..tostring(valid))
	log:write("Guessed: "..tostring(guessed).." (anchor @ "..
		"{"..tostring(anchorCell.x)..", "..tostring(anchorCell.y).."}, tested cell "..
		"{"..tostring(cell.x)..", "..tostring(cell.y).."}")
	log:write("Switch "..tostring(switch))
	log:write("---")]]

	self:setHiliteColor( { 0, 1, 1, 0.33 } )
	
	self.ability.no_costs = false
	return valid and guessed
end

---------------------------------------------------------------------
-- Throwing that can target the inside of impass mainframe units.

local throwMainframeTarget = class( targeting_base.throwTarget )

function throwMainframeTarget:isValidTargetLoc(x, y)
	if not x or not y then
		return false
	end

	if not self.sim:getQuery().is360viewClear( self.sim, self.unit, self.unitRange,x,y) then
		return false
	end

	if not self.unit:getTraits().explodes then
		local cell = self.sim:getCell(x, y)
		if cell and cell.impass > 0 then
			local mainframe_cell = false

			for i, cellUnit in pairs(cell.units) do
				local t = cellUnit:getTraits()
				if t.mainframe_status and not self.unit:getTraits().isSLFDragon then
					-- a mainframe device exists on the tile, and it's one that can be accessed
					-- note; we do not check for magnetic reinforcements since this is archive dragon
					-- but otherwise we WOULD need a Stability skill upgrade check here
					mainframe_cell = true
				end
			end

			if not mainframe_cell then return false end
		end
	end

	local targetCell = self.sim:getCell(x,y)
	if self.sim:isVersion("0.17.9") and targetCell and self.sim:getQuery().cellHasTag( self.sim, targetCell, "interruptNonCentral" ) then		
		return false
	end

	return true
end

---------------------------------------------------------------------
--

local targeters = {
    flickerTarget = flickerTarget,
    throwMainframeTarget = throwMainframeTarget,
}

for i, targeter in pairs(targeters) do
	targeting_base[i] = targeter
end

return targeting_base