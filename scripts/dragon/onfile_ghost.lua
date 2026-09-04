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
local items_panel = include("hud/items_panel")

--this shader code was referred to me by Hekateras, and the author is either herself or Qoala
--it is entirely awesome and ridiculously customizable
--no mortal should possess such power
--modders ye be warned

--shader for Dragon
--[[local dragon_shader_rgba = { 45/255, 100/255, 170/255, 0.75 }
local dragon_shader_alt_rgba = { 45/255, 170/255, 100/255, 0.75 }
local dragon_shader_timeout_rgba = { 170/255, 100/255, 45/255, 0.75 }
local SLF_dragon_shader = { shader = KLEIAnim.SHADER_FOW, r = dragon_shader_rgba[1], g = dragon_shader_rgba[2], b = dragon_shader_rgba[3], a = 0.3, lum = 1.3 }
local SLF_dragon_alt_shader = { shader = KLEIAnim.SHADER_FOW, r = dragon_shader_alt_rgba[1], g = dragon_shader_alt_rgba[2], b = dragon_shader_alt_rgba[3], a = 0.3, lum = 1.3 }
local SLF_dragon_timeout_shader = { shader = KLEIAnim.SHADER_FOW, r = dragon_shader_timeout_rgba[1], g = dragon_shader_timeout_rgba[2], b = dragon_shader_timeout_rgba[3], a = 0.3, lum = 1.3 }
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
            self._prop:setPlayMode( self._playMode )
            if unit:getTraits().isSLFDragon and not unit:getTraits().dynamicImpass then
            	local palette = nil
            	self._prop:setRenderFilter( nil )
            	if unit:getTraits().ACW_altpalette and 
            		(unit:getTraits().acw_gc or 
            			(unit:getTraits().fadeTimer and unit:getTraits().fadeTimer < 2)) then
            		-- about to time out
            		palette = dragon_shader_timeout_rgba
            		self._prop:setRenderFilter( SLF_dragon_timeout_shader )
            	elseif unit:getTraits().ACW_altpalette then
            		-- archive
            		palette = dragon_shader_rgba
            		self._prop:setRenderFilter( SLF_dragon_alt_shader )
            	else
            		-- on-file
            		palette = dragon_shader_alt_rgba
            		self._prop:setRenderFilter( SLF_dragon_shader )
            	end
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
						self._ghostFX.subFX.SelectionDisc:setSymbolModulate("shockwave",unpack(palette))
						self._ghostFX.subFX.SelectionDisc:setSymbolModulate("ring5",unpack(palette))
						-- add more effects here
						self._ghostFX.subFX.ConsoleFX = self:createHUDProp("kanim_null_fx", "effect", "idle", boardRig:getLayer("floor"), self._prop )
						self._ghostFX.subFX.ConsoleFX:setSymbolModulate("innercicrle",unpack(palette))
						self._ghostFX.subFX.ConsoleFX:setSymbolModulate("innerring",unpack(palette))
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
end]]

--bypass for the KO/wake-up function to keep (lack of) dynamicImpass intact
local setKO_old = simunit.setKO 

function simunit:setKO( ... )
	setKO_old(self, ...)
	if self:getTraits().isSLFDragon then
		self:getTraits().dynamicImpass = nil
	end
end

SLF_ghostForm =
{
	dropItems = function( self, sim, specificItem )
		-- drop items to the nearest empty cell
		local x, y = self.abilityOwner:getLocation()
		local dropCell = sim:getCell(x,y)
		-- items might need to be moved
		if not dropCell or not simquery.canReach(sim, x, y, dropCell.x, dropCell.y) or not simquery.canPath( sim, nil, nil, dropCell ) then
			dropCell = simquery.findNearestEmptyReachableCell( sim, x, y, self.abilityOwner )
			for i=#self.abilityOwner:getChildren(),1,-1 do
				local item = self.abilityOwner:getChildren()[i]
				if not specificItem or specificItem == item then
					item:getTraits().SLF_dropToCell = dropCell
				end
			end
		end
		if specificItem then
			if not specificItem:getTraits().augment and not specificItem:getTraits().installed then
				inventory.dropItem(sim, self.abilityOwner, specificItem)
			end
		else
			for i=#self.abilityOwner:getChildren(),1,-1 do
				local item = self.abilityOwner:getChildren()[i]
				if not item:getTraits().augment and not item:getTraits().installed then
					inventory.dropItem(sim, self.abilityOwner, item)
				end
			end
		end
		for i, unit in pairs(sim:getAllUnits()) do
			if unit:getTraits().SLF_dropToCell then
				-- break dropped items out of objects if necessary
				if sim:getCell(unit:getLocation()) ~= unit:getTraits().SLF_dropToCell and not unit:getUnitOwner() then
					sim:warpUnit( unit, unit:getTraits().SLF_dropToCell )
				end
				unit:getTraits().SLF_dropToCell = nil
			end
		end
	end,

	setupGhost = function( self, sim )
		if self.abilityOwner:getTraits().isMainframeGhost then
			return
		end

		self.abilityOwner:getTraits().dynamicImpass = nil
		self.abilityOwner:getTraits().hidesInCover = false
        self.abilityOwner:getTraits().isMainframeGhost = true
		self.abilityOwner:getTraits().inventoryMaxSize = 0
		self.abilityOwner:resetAllAiming()
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self.abilityOwner } )
		sim:processReactions(self.abilityOwner)
		self:dropItems(sim)

		-- disable jackin on Dragon, but let her have the ability; this highlights console gains
		local jackin = self.abilityOwner:hasAbility("jackin")
		local oldCanUseJack = jackin.canUseAbility

		function jackin.canUseAbility( self, sim, abilityOwner, unit, targetUnitID )
			if abilityOwner and abilityOwner:getTraits().isMainframeGhost then
				return false
			end

			return oldCanUseJack( self, sim, abilityOwner, unit, targetUnitID )
		end
	end,

	onSpawnAbility = function( self, sim, unit )
		self.abilityOwner = unit
		sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
		sim:addTrigger( simdefs.TRG_UNIT_RESCUED, self )
		sim:addTrigger( simdefs.TRG_CLOSE_NANOFAB, self )
		sim:addTrigger( simdefs.TRG_UNIT_PICKEDUP, self )
		-- what if I told you this is a vanilla trigger? O.O
		sim:addTrigger( "agentGotItem", self )
	end,

	onDespawnAbility = function( self, sim, unit )
		sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
		sim:removeTrigger( simdefs.TRG_UNIT_RESCUED, self )
		sim:removeTrigger( simdefs.TRG_CLOSE_NANOFAB, self )
		sim:removeTrigger( simdefs.TRG_UNIT_PICKEDUP, self )
		sim:removeTrigger( "agentGotItem", self )	
	end,

	onTrigger = function( self, sim, evType, evData )
		--IF WARPING IN, SET UP MAINFRAME_GHOST
        if evType == simdefs.TRG_UNIT_WARP and not evData.from_cell and evData.unit == self.abilityOwner then
        	self:setupGhost(sim)
		end
		--IF RESCUED, SET UP MAINFRAME_GHOST
		if evType == simdefs.TRG_UNIT_RESCUED and evData.unit == self.abilityOwner then
			self:setupGhost(sim)
		end

		--BREAK DATA LOGS OUT OF IMPASS TILES IF NEEDED
		if evType == simdefs.TRG_UNIT_WARP and evData.to_cell and evData.unit:getTraits().lostData then
			local x,y = evData.unit:getLocation()
			if sim:getCell(x,y).impass > 0 then
				local newcell = simquery.findNearestEmptyReachableCell( sim, x, y, evData.unit )
				sim:warpUnit(evData.unit, newcell)
			end
		end

		--REDUNDANCY: drop items on warp
		if evType == simdefs.TRG_UNIT_WARP and evData.to_cell and evData.unit == self.abilityOwner then
			self:dropItems(sim)

			--also, glimpse all the cells behind doors
			local sourceCell = evData.to_cell
			for i, cell in pairs(sim:getLOS():calculateUnitLOS(evData.to_cell, evData.unit)) do
				for i, exit in pairs(cell.exits) do
					if simquery.isClosedDoor( exit ) then
						local x0, y0 = evData.to_cell.x, evData.to_cell.y
						local x1, y1 = cell.x, cell.y
						local x2, y2 = exit.cell.x, exit.cell.y
						if mathutil.distSqr2d( x0, y0, x1, y1 ) < mathutil.distSqr2d( x0, y0, x2, y2 ) then
							-- exit.cell is behind a closed door and is further away from Dragon than the cell in front of the door
							-- glimpse it
							evData.unit:getPlayerOwner():glimpseCell(sim, exit.cell)
						end
					end
				end
			end
		end

		-- undo nanofab carryable-locks after browsing
		if evType == simdefs.TRG_CLOSE_NANOFAB and evData.sourceUnit:getTraits().isMainframeGhost then
			local unit = evData.unit
	    	for i, item in ipairs( unit.items ) do
	    		item:giveAbility("carryable")
	    	end
	    	for i, item in ipairs( unit.weapons ) do
	    		item:giveAbility("carryable")
	    	end
	    	for i, item in ipairs( unit.augments ) do
	    		item:giveAbility("carryable")
	    	end
		end

		-- DROP ITEMS THAT ARE PICKED UP
		if evType == simdefs.TRG_UNIT_PICKEDUP and evData.unit == self.abilityOwner then
			-- this trigger fires *before* parenting, so we mark the item first
			evData.item:getTraits().SLF_dropThis = true
		end

		if evType == "agentGotItem" and evData.item:getTraits().SLF_dropThis then
			-- this trigger *does* fire after parenting, so we can drop the item here
			-- quirk: this particular trigger doesn't have an evData.unit
			evData.item:getTraits().SLF_dropThis = nil
			self:dropItems(sim, evData.item)
		end

	end,
}	
		
return SLF_ghostForm
