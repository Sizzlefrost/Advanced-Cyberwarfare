local sim = include("sim/engine")
local cdefs = include("client_defs")
local flagui = include("hud/flag_ui")
local boardrig = include("gameplay/boardrig")
local cellrig = include("gameplay/cellrig")
local wallrig = include("gameplay/wallrig2")
local postrig = include("gameplay/postrig")
local doorrig = include("gameplay/doorrig2")
local decorrig = include("gameplay/decorig")
local unitrig = include("gameplay/unitrig")
local selection = include("hud/selection")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local hudFile = include( "hud/hud" )
local util = include("modules/util")
local mathutil = include("modules/mathutil")
local mui_tooltip = include("mui/mui_tooltip")

local oldCreateHud = hudFile.createHud
local oldRefreshBoard = boardrig.refresh
local oldRefreshFlag = flagui.refreshFlag
local oldRefreshCell = cellrig.refresh
local oldInit = boardrig.init
local oldDestroy = boardrig.destroy
local oldRefreshDoor = doorrig.refreshProp
local oldRefreshPost = postrig.refreshProp
local oldRefreshDecor = decorrig.refreshCell
local oldRefreshWall = wallrig.refreshProp
local oldGetSelected = selection.getSelectedUnit
local oldRefresh = unitrig.rig.refresh

--[[cdefs.LEVELTILES_PARAMS =
{
	file = "data/images/leveltiles.png",
	21,			--width in tiles
	21,			--height in tiles
	48/1008,		--cellWidth
	48/1008,		--cellHeight
	0.5/1008,	--xOffset
	0.5/1008,	--yOffset
	47/1008,		--tileWidth
	47/1008,		--tileHeight
}]]
-----------------------------------------------------------

function hudFile.createHud(...)
	local hud = oldCreateHud(...)

	local oldOnSelectUnit = hud.onSelectUnit

	local boardrig = hud._game.boardRig

	function hud.onSelectUnit( self, prevUnit, selectedUnit, ... )
		if selectedUnit and selectedUnit:getTraits().isMainframeGhost then
			boardrig._SLF_pseudomainframe = true
		elseif prevUnit and prevUnit:getTraits().isMainframeGhost then
			boardrig._SLF_pseudomainframe = nil
			hud._game:getGfxOptions().bMainframeMode = false
		end
		boardrig:refresh()

	    return oldOnSelectUnit( self, prevUnit, selectedUnit, ... )
	end

	local oldShow = hud.showMainframe
	local oldHide = hud.hideMainframe
	local pseudomainframe = false

	function hud.showMainframe( self, ... )
		pseudomainframe = boardrig._SLF_pseudomainframe
		boardrig._SLF_pseudomainframe = false
		oldShow( self, ... )
	end

	function hud.hideMainframe( self, ... )
		oldHide( self, ... )
		boardrig._SLF_pseudomainframe = pseudomainframe
		boardrig:refresh()
	end

	local oldEvent = hud.onSimEvent

	function hud:onSimEvent( ev, ... )
		if ev.eventType == "ACW_null_refresh" then
			log:write("ev received: "..ev.eventType)
			boardrig:refresh()
		end

		return unpack({ oldEvent( self, ev, ... ) })
	end

	return hud
end

function flagui.refreshFlag( self, unit, isSelected, ... )
	local mainframe = false
	if self._rig._boardRig._SLF_pseudomainframe then
		mainframe = self._rig._boardRig._game:getGfxOptions().bMainframeMode
		self._rig._boardRig._game:getGfxOptions().bMainframeMode = false
	end
	oldRefreshFlag( self, unit, isSelected, ... )
	if self._rig._boardRig._SLF_pseudomainframe then
		self._rig._boardRig._game:getGfxOptions().bMainframeMode = mainframe
	end

	-- addendum: flagui of dependents should not highlight their own flag
	-- instead, highlight their anchor's flag
	local hud = self._rig._boardRig._game.hud
	unit = unit or self._rig:getUnit()
	if hud and hud:getSelectedUnit() == unit and unit:getTraits().acw_anchor then
		-- unhilite self
		local color = {r=140/255,g=255/255,b=255/255,a=1}

		self._widget.binder.meters.binder.APnum:setText( "--" )
		if (self._moveCost or 0) == 0 then
			self._widget.binder.meters.binder.APnum:setColor(color.r,color.g,color.b,color.a)
			self._widget.binder.meters.binder.APtxt:setColor(color.r,color.g,color.b,color.a)
		end
		
		-- get a hold of anchor's flagUI module
		local anchor = unit:getTraits().acw_anchor
		local anchor_flag = self._rig._boardRig:getUnitRig( anchor:getID() )._flagUI
		if not anchor_flag then
			return
		else
			-- fire their flag update, if available...
			anchor_flag._moveCost = self._moveCost
			anchor_flag:refreshFlag( anchor )
		end
		return
	end

	if hud and unit:getTraits().acw_dependent then
		-- ...hilite anchor
		local color = {r=1,g=1,b=1,a=1}

		if (self._moveCost or 0) == 0 then
			self._widget.binder.meters.binder.APnum:setColor(color.r,color.g,color.b,color.a)
			self._widget.binder.meters.binder.APtxt:setColor(color.r,color.g,color.b,color.a)
		end
	end
end

function cellrig.refresh( self, ... )
	local function isUnknownCell( boardRig, rawcell )
	    if rawcell.tileIndex ~= cdefs.TILE_UNKNOWN then
	        for _, dir in ipairs( simdefs.DIR_SIDES ) do
	    	    local dx, dy = simquery.getDeltaFromDirection( dir )
			    local tocell = boardRig:getLastKnownCell( rawcell.x + dx, rawcell.y + dy )
			    if tocell and rawcell.exits[ dir ] then
	                return true
			    end
		    end
	    end
	    return false
	end

	local function isAnchorCell( boardRig, rawcell )
		if not boardRig._acw_anchor_cells then return end
		for i, cell in pairs(boardRig._acw_anchor_cells) do
			if rawcell == cell then
				return "direct"
			end
		end
		for i, cell in pairs(boardRig._acw_anchor_cells_indirect) do
			if rawcell == cell then
				return "indirect"
			end
		end
		return false
	end

	if self._boardRig._SLF_pseudomainframe then
		local scell = self._boardRig:getLastKnownCell( self._x, self._y )
	    local rawcell = self._game.simCore:getCell( self._x, self._y )
		if rawcell ~= nil then
			if isUnknownCell( self._boardRig, rawcell ) then
                --self._boardRig._grid:getGrid():setTile( self._x, self._y, cdefs.ACW.OVERLAY.CYBERSPACE_CELL )
                self._boardRig._grid:getGrid():setTile( self._x, self._y, cdefs.MAINFRAME_CELL )
                -- is this cell in a null zone?
                if self._game.simCore._ACW_null_cells and self._game.simCore._ACW_null_cells[rawcell.id] then
                	self._boardRig._grid:getGrid():setTile( self._x, self._y, cdefs.MAINFRAME_UNKNOWN_CELL )
                	-- if dragon can't path into null zones, this takes precedence over anchor highlights; TODO
                end

                if isAnchorCell( self._boardRig, rawcell ) == "direct" then
                	self._boardRig._grid:getGrid():setTile( self._x, self._y, 436 )
                elseif isAnchorCell( self._boardRig, rawcell ) == "indirect" then
                	self._boardRig._grid:getGrid():setTile( self._x, self._y, 434 )
                end
	        else
				self._boardRig._grid:getGrid():setTile( self._x, self._y, cdefs.BLACKOUT_CELL )
			end
			self._boardRig._grid:getGrid():setTileFlags( self._x, self._y, 0 )
		end
	else
		oldRefreshCell( self, ... )
	end
end

local function getPicturePlace(rowx, rowy)
	return {
		(rowx * 256 + 0.5) / 2048,
		((rowx + 1) * 256 - 1 + 0.5) / 2048,
		((rowy + 1) * 256 - 1 + 0.5) / 2048,
		(rowy * 256 + 0.5) / 2048 
	}
end

function wallrig:setUVTransform( prop, uvInfo )
	local u,v,U,V = unpack( uvInfo )
	local uvTransform = MOAITransform.new()
	if self._boardRig._SLF_pseudomainframe then
		uvTransform:setScl( 1,1 )
		uvTransform:addLoc( 0,0 )
	else
		uvTransform:setScl( 1,1 )
		uvTransform:addLoc( 0,0 )
	end

	prop:setUVTransform( uvTransform )
end

function postrig.refreshProp(self, ...)
	if self._boardRig._SLF_pseudomainframe then
		 self._prop:setVisible( false )
	else
		oldRefreshPost(self, ...)
	end
end

function doorrig.refreshProp(self, ...)
	local frameView = self._game._gfxOptions.bMainFrameMode	
	if self._boardRig._SLF_pseudomainframe then
		self._game._gfxOptions.bMainFrameMode = true

		local x1,y1 = self:getLocation1()
		local x2,y2 = self:getLocation2()
		local ccell_1 = self._boardRig:getLastKnownCell( x1,y1 )
		local ccell_2 = self._boardRig:getLastKnownCell( x2,y2 )
		local offset, count = 0, 0

		if ccell_1 or ccell_2 then
			local exit1 = ccell_1 and ccell_1.exits[ self._simdir1 ]
			local exit2 = ccell_2 and ccell_2.exits[ self._simdir2 ]

			local showClosed, showLocked
			if ccell_1 and not ccell_1.ghostID then
				showClosed, showLocked = exit1.closed, exit1.locked
			elseif ccell_2 and not ccell_2.ghostID then
				showClosed, showLocked = exit2.closed, exit2.locked
			elseif not ccell_1 then
				showClosed, showLocked = exit2.closed, exit2.locked
			elseif not ccell_2 then
				showClosed, showLocked = exit1.closed, exit1.locked
			elseif ccell_1.ghostID > ccell_2.ghostID then
				showClosed, showLocked = exit1.closed, exit1.locked
			else
				showClosed, showLocked = exit2.closed, exit2.locked
			end

	        -- Show guard elevators and elevators in use as always locked.
	        if exit1 and (exit1.keybits == simdefs.DOOR_KEYS.GUARD or exit1.keybits == simdefs.DOOR_KEYS.ELEVATOR_INUSE) then
	            showLocked = true
	        elseif exit2 and (exit2.keybits == simdefs.DOOR_KEYS.GUARD or exit2.keybits == simdefs.DOOR_KEYS.ELEVATOR_INUSE) then
	            showLocked = true
		    end

			if showLocked then
			    assert( self._offsets and self._offsets['mainframe_locked'] )
			    offset, count = unpack( self._offsets['mainframe_locked'] )
			elseif showClosed then
			    assert( self._offsets and self._offsets['mainframe_unlocked'] )
			    offset, count = unpack( self._offsets['mainframe_unlocked'] )
			else
			    assert( self._offsets and self._offsets['mainframe_open'] )
			    offset, count = unpack( self._offsets['mainframe_open'] )
			end
			self:setUVTransform( cdefs.WALL_MAINFRAME )

			if self.lock1 then
				local orientation = self._boardRig._game:getCamera():getOrientation()

				self.lock1:setCurrentFacingMask( 2^((self.lock1._facing - orientation*2) % simdefs.DIR_MAX) )
				self.lock2:setCurrentFacingMask( 2^((self.lock2._facing - orientation*2) % simdefs.DIR_MAX) )

				self.lock1:setVisible(false)
				self.lock2:setVisible(false)

				if showLocked then
					self.lock1:setCurrentAnim( "idle" )
					self.lock2:setCurrentAnim( "idle" )
				else
					self.lock1:setCurrentAnim( "idle_unlocked" )
					self.lock2:setCurrentAnim( "idle_unlocked" )
				end	
			end
		end

		local prop, mesh = self._prop, self._mesh
		mesh:setElementOffset( offset )
		mesh:setElementCount( count )
		prop:setVisible( count > 0 )
	else
		oldRefreshDoor(self, ...)
	end
	self._game._gfxOptions.bMainFrameMode = frameView
end

function decorrig.refreshCell(self, x, y, ...)
	if self._boardRig._SLF_pseudomainframe then
		local cellid = simquery.toCellID( x, y )
		local decors = self._cells[ cellid ]
		if decors then
			local gfxOptions = self._boardRig._game:getGfxOptions()
			local orientation = self._boardRig._game:getCamera():getOrientation()
			local cell = self._boardRig:getLastKnownCell( x, y )
			local visStatus = 0

			if cell and not cell.ghostID then
				visStatus = 2
			elseif cell then
				visStatus = 1
			end

			local cellSim = self._boardRig._game.simCore:getCell(x,y)
			if cellSim and (not cellSim.impass or cellSim.impass < 1 ) then
				visStatus = 0
			end

			for i,decor in ipairs( decors ) do
				if decor:refreshVisibility( x, y, visStatus ) then
					decor:refresh( orientation, gfxOptions )
				end
			end
		end
	else
		oldRefreshDecor(self, x, y, ...)
	end
end

function wallrig:refreshProp(...)
	--[[if self._boardRig._SLF_pseudomainframe then
		--simlog("Updating wallrigs.")

		for _,piece in pairs(self._pieces) do
			local prop, mesh = piece.prop, piece.mesh
			mesh:setElementOffset( 0 )
			mesh:setElementCount( 0 )
			picturePlace = getPicturePlace(1,4)
			self:setUVTransform( prop, picturePlace )
			prop:setScl(1,1,1)
			prop:setVisible( true )
			prop:scheduleUpdate()
		end
		--self:refreshRenderFilter()
	else]]
		oldRefreshWall( self, ... )

	if self._boardRig._SLF_pseudomainframe then
		for _,piece in pairs(self._pieces) do
			local prop = piece.prop
			self:setShader(prop, KLEIAnim.SHADER_FOW, 0.3, 1, 1, 1, 0.8)
			prop:setScl(1,1,-0.07)
			prop:scheduleUpdate()
		end
	end
end

function boardrig.init( self, layers, levelData, game )
	oldInit( self, layers, levelData, game )

	local overlayGrid, _, overlayAnim = createPseudomainframeGridProp(game, game.simCore, cdefs.LEVELTILES_PARAMS)
	layers["floor"]:insertProp(overlayGrid)

	self._SLFpseudomainframe_overlayGrid = overlayGrid
	self._SLFpseudomainframe_overlayAnim = overlayAnim
end

function boardrig.destroy( self, ... )
	if self._SLFpseudomainframe_overlayGrid then
		if self._SLFpseudomainframe_overlayAnim then
			self._SLFpseudomainframe_overlayAnim:stop()
		end
		self._layers["floor"]:removeProp(self._SLFpseudomainframe_overlayGrid)

		self._SLFpseudomainframe_overlayGrid = nil
		self._SLFpseudomainframe_overlayAnim = nil
	end

	oldDestroy( self, ... )
end

function unitrig.rig.refresh( self, ... )
	local sim = self._boardRig:getSim()
	local dep = sim:getUnit(self._unitID)
	if not dep then return end
	local rawUnit = dep:getTraits().acw_anchor
	if rawUnit and rawUnit == self._boardRig:getSelectedUnit() then
		local x0, y0 = rawUnit:getLocation()
		local cells = sim._los:calculateUnitLOS( sim:getCell( x0, y0 ), rawUnit )
		local eyeball_cells = {}
		-- add eyeball vision to this
		--log:write("CELLS: \n"..util.stringize(cells, 1))
		for i, eyeball in pairs(sim:getPC():getUnits()) do
			if eyeball:getTraits().peekID == rawUnit:getID() then
				-- TODO: append eyeball vision, without cell overlap
				local x1, y1 = eyeball:getLocation()
				local newCells = sim._los:calculateUnitLOS( sim:getCell( x1, y1 ), eyeball )
				for cellID, cellData in pairs(newCells) do
					if not cells[cellID] and not eyeball_cells[cellID] then
						eyeball_cells[cellID] = cellData
					end
				end
			end
		end
		self._boardRig._acw_anchor_cells = cells
		self._boardRig._acw_anchor_cells_indirect = eyeball_cells
	end

	return oldRefresh( self, ... )
end


function boardrig.refresh( self, ... )
	local mainframe = self._game._gfxOptions.bMainframeMode
	local tacView = self._game._gfxOptions.bTacticalView

	-- disable mainframe mode so most things render as normal
	if self._SLF_pseudomainframe then
		self._game._gfxOptions.bMainframeMode = false
	end

	oldRefreshBoard( self, ... )

	-- with most things rendered, run the walls again, but with tactical mode (outline-only)
	--[[if self._SLF_pseudomainframe then
		self._game._gfxOptions.bTacticalView = true
		self:refreshWalls()
	end

	self._game._gfxOptions.bMainframeMode = mainframe
	self._game._gfxOptions.bTacticalView = tacView]]
end

function createPseudomainframeGridProp( game, simCore, params )
	local boardWidth, boardHeight = simCore:getBoardSize()

	local grid = MOAIGrid.new ()
	grid:initRectGrid ( boardWidth, boardHeight, cdefs.BOARD_TILE_SIZE, cdefs.BOARD_TILE_SIZE )

	local tileDeck = MOAITileDeck2D.new ()
	local prop = MOAIProp2D.new ()

	if params.file then
		local mt = MOAIMultiTexture.new()
		mt:reserve( 6 )
		mt:setTexture( 1, params.file )
		mt:setTexture( 2, game.shadow_map )
		mt:setTexture( 3, "data/images/los_full.png" )
		mt:setTexture( 4, "data/images/los_partial.png" )
        mt:setTexture( 5, "data/images/los_full_cover.png" )
		mt:setTexture( 6, "data/images/los_partial_cover.png" )

		tileDeck:setShader( MOAIShaderMgr.getShader( MOAIShaderMgr.FLOOR_SHADER ) )
		tileDeck:setTexture ( mt )

	end
	tileDeck:setSize ( unpack(params) )
	tileDeck:setRect( -0.5, -0.5, 0.5, 0.5 )
	tileDeck:setUVRect( -0.5, -0.5, 0.5, 0.5 )

	
	prop:setDeck ( tileDeck )
	prop:setGrid ( grid )
	prop:setLoc( -boardWidth * cdefs.BOARD_TILE_SIZE / 2, -boardHeight * cdefs.BOARD_TILE_SIZE / 2)
	prop:setPriority( cdefs.BOARD_PRIORITY - 10 )
	prop:setDepthTest( false )

	prop:forceUpdate ()
	return prop, tileDeck
end

-- fix a strange multi-mod bug where a tab is attempted to be created despite the unit not being warped in yet (so no coordinates, and tab doesn't have checks for it?!)
local hud_tabs = include("hud/hud_tabs")
local oldCreateTab = hud_tabs.createTab

function hud_tabs:createTab( tabID, cellx, celly, tab, ... )
	if not cellx then
		local sim = self._game.simCore
		log:write('[ACW Bugfix] Unit '..tostring(tabID)..' ('..sim:getUnit(tabID):getName()..') is getting a tab despite being off the board!')
		log:write('Tab prevented, looked like this:')
		log:write('>>> '..tab[1])
		log:write('>>> '..tab[2])
		return
	end
	return oldCreateTab(self, tabID, cellx, celly, tab, ... )
end

-- fix archive dragon still being selected on the turn after the one she disappears

function selection.getSelectedUnit( self, ... )
	if self and self.selectedUnit and self.canSelect(self, self.selectedUnit) then
		return oldGetSelected( self, ... )
	else
		return nil
	end
end