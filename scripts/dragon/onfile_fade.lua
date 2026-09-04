local util = include ( "modules/util" )
local sim = include ( "sim/engine" )
local simquery = include ( "sim/simquery" )
local simdefs = include ( "sim/simdefs" )

local guiex = include ("client/guiex")
local oldUpdate = guiex.updateButtonFromItem
local DEFAULT_AMMO_CLR = { 140/255, 255/255, 255/255 }
local ACTIVE_AMMO_CLR = { 1, 1, 0 }
function guiex.updateButtonFromItem( screen, game, widget, item, unit, encumbered, ... )
	oldUpdate( screen, game, widget, item, unit, encumbered, ... )

	local ammoTxt, ammoClr = "", DEFAULT_AMMO_CLR
	if item:getTraits().userFadeout then
		ammoTxt = util.sformat( STRINGS.UI.HUD_WEAPON_AMMO, item:getTraits().userFadeout, item:getTraits().maxUserFadeout )
		if item:getTraits().userFadeout <= 3 then
			ammoClr = ACTIVE_AMMO_CLR
		end
		widget.binder.ammoTxt:setText( ammoTxt )
		widget.binder.ammoTxt:setColor( 0, 0, 0 )
		widget.binder.ammoBG:setVisible( #ammoTxt > 0 )
		widget.binder.ammoBG:setColor( unpack(ammoClr) )
	end
end	

SLF_persist = {
	onSpawnAbility = function( self, sim, unit )
		self.abilityOwner = unit

		for i, item in pairs(unit:getChildren()) do
			if item:getUnitData().acw_resource then
				self.displayItemLink = item
			end
		end

		self:updateFadeTimer(sim)

		sim:addTrigger( simdefs.TRG_MAP_EVENT, self )
		sim:addTrigger( simdefs.TRG_END_TURN, self )
		sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
		sim:addTrigger( simdefs.TRG_UNIT_WARP_PRE, self )
		sim:addTrigger( simdefs.TRG_UNIT_KO, self )
		sim:addTrigger( simdefs.TRG_UNIT_KILLED, self )
		sim:addTrigger( simdefs.TRG_UNIT_RESCUED, self )
		sim:addTrigger( "dragon_burnout", self )
		sim:addTrigger( simdefs.TRG_ALARM_INCREASE, self )
	end,

	onDespawnAbility = function( self, sim, unit )
		sim:removeTrigger( simdefs.TRG_MAP_EVENT, self )
		sim:removeTrigger( simdefs.TRG_END_TURN, self )
		sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
		sim:removeTrigger( simdefs.TRG_UNIT_WARP_PRE, self )
		sim:removeTrigger( simdefs.TRG_UNIT_KO, self )
		sim:removeTrigger( simdefs.TRG_UNIT_KILLED, self )
		sim:removeTrigger( simdefs.TRG_UNIT_RESCUED, self )
		sim:removeTrigger( "dragon_burnout", self )
		sim:removeTrigger( simdefs.TRG_ALARM_INCREASE, self)
	end,

	onTrigger = function( self, sim, evType, evData )
		if evType == simdefs.TRG_MAP_EVENT and evData.event == simdefs.MAP_EVENTS.TELEPORT then
			-- check that dragon wasn't amongst teleported units
			local dragon = false
			for i, unit in pairs(evData.units) do
				--log:write(unit:getName().." is warping out.")
				if unit:getID() == self.abilityOwner:getID() then
					dragon = true
					break
				end
			end
			if dragon == false then
				-- check that there are no other units left in the field
				--log:write('MAP_EVENT_TELEPORT, not dragon, checking')
				self:checkCapableUnits( sim )
			end
		end

		if evType == simdefs.TRG_UNIT_KO then
			if evData.unit:getTraits().isAgent and evData.unit:hasAbility( "escape" ) and evData.unit:getID() ~= self.abilityOwner:getID() then
				self:checkCapableUnits( sim )
			end
		end

		-- if the unit is killed, it'll be despawned/invalid, and thus won't have an ID. Take it from the corpse instead.
		if evType == simdefs.TRG_UNIT_KILLED then
			if evData.unit:getTraits().isAgent and evData.unit:hasAbility( "escape" ) and evData.corpse:getTraits().unitID ~= self.abilityOwner:getID() then
				self:checkCapableUnits( sim )
			end
		end

		if evType == simdefs.TRG_END_TURN and sim:getCurrentPlayer() == sim:getPC() then
			-- check again, we might not need to do anything
			-- DANGER: this is minor overhead for end of turn
			self:checkCapableUnits( sim )

			if self.abilityOwner:getTraits().fadeTimer then
				-- if alarm isn't met yet, freeze the timer
				if self.abilityOwner:getTraits().fadeAlarm and self.abilityOwner:getTraits().fadeAlarm > sim:getTrackerStage() then
					self:assembleTab( sim, self.abilityOwner )
				else
					-- decrement the Fade Timer
					self:updateFadeTimer(sim, self.abilityOwner:getTraits().fadeTimer - 1)
					if self.abilityOwner:getTraits().fadeTimer <= 0 then
						self.abilityOwner:killUnit( sim )
					end
				end
			end
		end

		if evType == simdefs.TRG_UNIT_WARP and evData.unit == self.abilityOwner and not evData.to_cell then
			-- warping Dragon away; clear the danger
			self.abilityOwner:getTraits().fadeTimer = nil
			self.abilityOwner:getTraits().fadeAlarm = nil
			self.abilityOwner:destroyTab()
		end

		-- if rescued a unit, check again
		if evType == simdefs.TRG_UNIT_RESCUED and self.abilityOwner:getTraits().fadeTimer then
			self:checkCapableUnits( sim )
		end
		-- if revived a unit, check again
		if evType == "dragon_burnout" and self.abilityOwner:getTraits().fadeTimer then
			self:checkCapableUnits( sim )
		end

		if (evType == simdefs.TRG_UNIT_WARP or evType == simdefs.TRG_END_TURN) and evData.unit and evData.unit == self.abilityOwner and evData.unit:getTraits().fadeTimer then
			-- Dragon moved; update the tooltip
			self:assembleTab( sim, self.abilityOwner )
		end

		if evType == simdefs.TRG_ALARM_INCREASE then
			self:updateFadeTimer(sim)
		end
	end,

	checkCapableUnits = function( self, sim )
		local fieldUnits = {}
	    for _, unit in pairs( sim:getPC():getUnits() ) do
	        if unit:hasAbility( "escape" ) then
	            local cell = sim:getCell( unit:getLocation() )
	            if cell then
	            	-- log:write(unit:getName().." is still in the field.")
	            	if unit:getID() ~= self.abilityOwner:getID() and unit:canAct() and unit:getTraits().isAgent then
	                	table.insert( fieldUnits, unit )
	                end
	            end
	        end
	    end
	    if #fieldUnits == 0 then
	    	-- log:write("Confirmed that no other agents are left in the field.")
	    	self:addFadeTimer( sim )
	    elseif self.abilityOwner:getTraits().fadeTimer then
	    	-- there's a timer active and yet another capable unit exists who could support Dragon
	    	self.abilityOwner:getTraits().fadeTimer = nil
			self.abilityOwner:getTraits().fadeAlarm = nil
			self:updateFadeTimer( sim )
			self.abilityOwner:destroyTab()
		end
	end,

	addFadeTimer = function( self, sim )
		-- if already exists, just update the tab
		--log:write("Adding fade timer now. Current status: "..tostring(self.abilityOwner:getTraits().fadeTimer))

		if self.abilityOwner:getTraits().fadeTimer then
			self:assembleTab( sim, self.abilityOwner )
			return
		end

		local fadeTimer = nil

		for i, DLC in pairs(sim:getParams().difficultyOptions.enabledDLC) do
			if DLC.name == "Advanced Cyberwarfare" then
				fadeTimer = DLC.options.ac_dragon_extraction_timer.value
				fadeAlarm = DLC.options.ac_dragon_extraction_alarm.value
				if not fadeAlarm then
					fadeAlarm = DLC.options.ac_dragon_extraction_alarm_pe.value
				end
			end
		end

		--log:write("Current FADE TIMER setting: "..tostring(fadeTimer))

		if fadeTimer == -1 then --if set to INDEFINITE, don't set the timer
			return
		elseif fadeTimer == 0 then -- it was set to INSTANT DEATH. Murder!
			self.abilityOwner:killUnit( sim )
			return
		end

		if fadeAlarm == -1 then
			if not sim:isAlarmed() then -- clamp to max alarm
				fadeTimer = fadeTimer - sim:getTrackerStage()
			else
				fadeTimer = fadeTimer - simdefs.TRACKER_MAXCOUNT
			end
			if fadeTimer < 0 then
				fadeTimer = 0
			end
		end

		-- add the STABILITY skill value
		if self.abilityOwner:getTraits().fade_bonus then
			fadeTimer = fadeTimer + self.abilityOwner:getTraits().fade_bonus
		end

		if fadeTimer <= 0 then -- Check again. If it's still too low after the stability increase, murder!
			self.abilityOwner:killUnit( sim )
			return
		elseif fadeTimer < 2 then
			self.abilityOwner:getTraits().mainframeShaderOverride = self.abilityOwner:getTraits().shaderOverrides["crit"]
		else
			self.abilityOwner:getTraits().mainframeShaderOverride = self.abilityOwner:getTraits().shaderOverrides["fade"]
		end

		self.abilityOwner:getTraits().fadeTimer = fadeTimer
		self.abilityOwner:getTraits().fadeAlarm = fadeAlarm

		self:assembleTab( sim, self.abilityOwner )
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self.abilityOwner } )
	end,

	updateFadeTimer = function( self, sim, new_value )
		local base_timer, decaying = nil, nil

		for i, DLC in pairs(sim:getParams().difficultyOptions.enabledDLC) do
			if DLC.name == "Advanced Cyberwarfare" then
				base_timer = DLC.options.ac_dragon_extraction_timer.value
				decaying = DLC.options.ac_dragon_extraction_alarm.value
				if not decaying then
					decaying = DLC.options.ac_dragon_extraction_alarm_pe.value
				end
				if not decaying == -1 then
					decaying = nil
				end
			end
		end

		local fade_bonus = self.abilityOwner:getTraits().fade_bonus or 0
		local alarm_penalty = decaying and (-1*sim:getTrackerStage()) or 0
		if alarm_penalty*-1 >= simdefs.TRACKER_MAXCOUNT then alarm_penalty = simdefs.TRACKER_MAXCOUNT*-1 end
		self.displayItemLink:getTraits().maxUserFadeout = base_timer + fade_bonus + alarm_penalty

		--simlog("new_value detected: "..(tostring(new_value) or "N/A"))
		if not new_value then
			if self.abilityOwner:getTraits().fadeTimer then
				new_value = self.abilityOwner:getTraits().fadeTimer
			end
			if not new_value --[[or new_value < self.displayItemLink:getTraits().maxUserFadeout]] then
				new_value = self.displayItemLink:getTraits().maxUserFadeout
			end
		end
		self.displayItemLink:getTraits().userFadeout = new_value
		--simlog("Current fade timer: "..(tostring(self.abilityOwner:getTraits().fadeTimer) or "N/A").."; new_value: "..tostring(new_value))
		if self.abilityOwner:getTraits().fadeTimer then -- only modify actual timer if it is in fact present; don't create one
			self.abilityOwner:getTraits().fadeTimer = new_value
			self:assembleTab( sim, self.abilityOwner )
		end

		if self.abilityOwner:getTraits().fadeTimer and self.abilityOwner:getTraits().fadeTimer < 2 then
			self.abilityOwner:getTraits().mainframeShaderOverride = self.abilityOwner:getTraits().shaderOverrides["crit"]
		elseif self.abilityOwner:getTraits().fadeTimer then
			self.abilityOwner:getTraits().mainframeShaderOverride = self.abilityOwner:getTraits().shaderOverrides["fade"]
		else
			self.abilityOwner:getTraits().mainframeShaderOverride = self.abilityOwner:getTraits().shaderOverrides["live"]
		end

		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self.displayItemLink } )
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self.abilityOwner } )
	end,

	assembleTab = function( self, sim, unit )
		--simlog('Assembling tab - alarm level '..tostring(sim._trackerStage)..'; threshold '..unit:getTraits().fadeAlarm)
		if not unit:getLocation() then -- tabs only exist on the field
			return unit:destroyTab()
		end
		if unit:getTraits().fadeAlarm then
			if unit:getTraits().fadeAlarm <= sim._trackerStage then
				if unit:getTraits().fadeTimer <= 1 then
					unit:createTab(STRINGS.SLF.ABILITIES.PERSIST.TRACKER1, STRINGS.SLF.ABILITIES.PERSIST.TRACKER3)
				else
					unit:createTab(STRINGS.SLF.ABILITIES.PERSIST.TRACKER1, util.sformat(STRINGS.SLF.ABILITIES.PERSIST.TRACKER2, unit:getTraits().fadeTimer))
				end
			else
				unit:createTab(STRINGS.SLF.ABILITIES.PERSIST.TRACKER1, util.sformat(STRINGS.SLF.ABILITIES.PERSIST.FROZEN, unit:getTraits().fadeAlarm))
			end
		end
	end,
}

return SLF_persist