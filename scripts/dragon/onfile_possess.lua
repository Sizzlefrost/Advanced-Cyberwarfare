local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )
local unitdefs = include( "sim/unitdefs" )
local mainframe = include( "sim/mainframe" )
local mathutil = include( "modules/mathutil" )
-------------------------------------------------------------------
--

local peek_tooltip = class( abilityutil.hotkey_tooltip )

function peek_tooltip:init( hud, unit, ... )
	abilityutil.hotkey_tooltip.init( self, ... )
	self._game = hud._game
	self._unit = unit
end

function peek_tooltip:activate( screen )
	abilityutil.hotkey_tooltip.activate( self, screen )
	self._game.hud:previewAbilityAP( self._unit, 1 )
end

function peek_tooltip:deactivate()
	abilityutil.hotkey_tooltip.deactivate( self )
	self._game.hud:previewAbilityAP( self._unit, 0 )
end
-- you know what? Screw you.
local function unglimpseUnit( sim, unitID )
-- *unglimpses your unit*
	local unit = sim:getUnit( unitID )
    --simlog('Unglimpsing '..unit:getName())
	local x, y = unit:getLocation()
	if y and not sim:canPlayerSee( sim:getPC(), x, y ) then
		sim:getPC():removeSeenUnit( unit )
		sim:getPC():markSeen(sim,x,y) -- contrary to the name, this is effectively removeSeenCell

		--ghostbusters.exe: old logic
		--[[local ghost = sim:getPC()._ghost_units[ unitID ]
		if ghost then
			local cellghost = sim:getPC()._ghost_cells[ simquery.toCellID( x, y ) ]
			array.removeElement( cellghost.units, ghost )
			sim:getPC()._ghost_units[ unitID ] = nil
			sim:getPC()._ghost_cells[ simquery.toCellID( x, y ) ] = nil

			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = ghost } )	
		end]]
	end
end

local function storeCurrentDeviceInformation( abilityref, sim, unit )
	--STORE: # of firewalls, daemon and whether there was a parasite hosted
	local previousIce = unit:getTraits().mainframe_ice
	local previousDaemon, previousParasite = {}, nil

    if unit:getTraits().mainframe_program then
    	-- if daemon host, punt it elsewhere
    	if unit:getTraits().daemonHost then
    		sim:moveDaemon(unit:getTraits().daemonHost)
    	else
		    previousDaemon = { unit:getTraits().mainframe_program, unit:getTraits().daemon_sniffed }
		    unit:getTraits().mainframe_program = nil
		    unit:getTraits().daemon_sniffed = false
		end
	end

	if unit:getTraits().parasite or unit:getTraits().plague then
		if unit:getTraits().parasite and not unit:getTraits().parasiteV2 then
			previousParasite = 1
		elseif unit:getTraits().parasiteV2 then
			previousParasite = 2
		end
		if unit:getTraits().plague then
			previousParasite = (previousParasite or 0) + 10
		end

		for i,ability in ipairs(sim:getPC():getAbilities()) do
			if ability.parasite_hosts then
	            array.removeElement( ability.parasite_hosts, unit:getID() )
			end
			if ability.plague_hosts then
	            array.removeElement( ability.plague_hosts, unit:getID() )
			end
		end
		unit:getTraits().parasite = nil
		unit:getTraits().plague = nil
	end

	--[[log:write( "Stored firewalls: " .. tostring(previousIce) )
	log:write( "Stored daemon: " .. previousDaemon )
	log:write( "Stored parasite: " .. previousParasite )]]

	unit:getTraits().SLF_chkdsk = {
		ice = previousIce,
		daemon = previousDaemon,
		parasite = previousParasite,
		recapture = unit:getTraits().mainframe_no_recapture,
		abilityref = abilityref,
	}
end

local function destroyIceSneakily( sim, unit )
    local currentPlayer = sim:getPC()

	if unit:getTraits().isDrone then
		unit:setPlayerOwner( currentPlayer )

		sim:dispatchEvent( simdefs.EV_UNIT_CAPTURE, { unit = unit } )
		if unit:getBrain() then
			unit:getBrain():onDespawned()
			unit._brain = nil
		end
		local modifiers = include( "sim/modifiers" )
		unit:getModifiers():add( "LOSrange", "control", modifiers.SET, nil )
	    unit:getModifiers():add( "LOSarc", "control", modifiers.SET, math.pi * 2 )
	    unit:getModifiers():add( "LOSperipheralRange", "control", modifiers.SET, nil )
	    unit:getModifiers():add( "LOSperipheralArc", "control", modifiers.SET, nil )
	    unit:getTraits().takenDrone = true
	    sim:refreshUnitLOS( unit )
	    if unit:getTraits().mainframe_suppress_rangeMax then
			unit:getTraits().mainframe_suppress_range = 0
		end
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
	end

	unit:getTraits().mainframe_ice = 0 --will get reversed

	if sim._resultTable.devices[unit:getID()] then --will get reversed
		sim._resultTable.devices[unit:getID()].hacked = true
	end

	if unit:getTraits().revealUnits then --will get reversed (new)
		local database_type = unit:getTraits().revealUnits
		--renew known units
		unit:getTraits().SLF_known_units = {}
		sim:forEachUnit(
			function ( u )
				if u:getTraits()[ database_type ] ~= nil then
					local x, y = u:getLocation()
					if currentPlayer._ghost_units[ u:getID() ] or sim:canPlayerSee( sim:getPC(), x, y ) then
						-- remember the units that are known before possession
						table.insert(unit:getTraits().SLF_known_units, currentPlayer._ghost_units[ u:getID() ])
					end
					u:getTraits().SLF_sightable = u:getTraits().sightable
					u:getTraits().sightable = true -- always trigger TRG_UNIT_APPEARED
					currentPlayer:glimpseUnit( sim, u:getID() )				
				end
			end
		)

		-- track if new knowledge of units happens
		-- add a listener to the database
		unit.oldTrigger = unit.onTrigger
		unit.onTrigger = function( self, sim, evType, evData )
			if evType == simdefs.TRG_UNIT_APPEARED then
				simlog('Unit '..evData.unit:getID()..' appeared')
				if evData.unit:getTraits()[ database_type ] ~= nil then
					-- if not already in known units, add
					local found = false
					for i, u2 in pairs(unit:getTraits().SLF_known_units) do
						if u2:getID() == evData.unit:getID() then
							found = true -- unit was known already
						end
					end
					if found == false then -- add
						simlog('Adding '..evData.unit:getID()..' to known units')
						table.insert(self:getTraits().SLF_known_units, evData.unit)
					end
				end
			end
			if self.SLF_oldTrigger then
				return self.SLF_oldTrigger( self, sim, evType, evData )
			end
		end
		sim:addTrigger( simdefs.TRG_UNIT_APPEARED, unit )
	end
	
	if unit:getTraits().showOutline then --will get reversed; facility is revealed silently
		sim._showOutline = true
		sim:dispatchEvent( simdefs.EV_WALL_REFRESH )
	end
	
	if unit:getTraits().revealDaemons then  --will get reversed
		sim:forEachUnit(
		function ( u )
			if u:getTraits().mainframe_program ~= nil then
				u:getTraits().daemon_sniffed = true 
			end
		end )
	end

	if not unit:getTraits().noTakeover then --will get reversed; the contents of this are a lite version of simunit.takeControl( player )
		unit:setPlayerOwner( currentPlayer )	
    	currentPlayer:glimpseUnit( sim, unit:getID() )

    	if unit:getTraits().partnerID then
			local partner = sim:getUnit( unit:getTraits().partnerID )

			partner:setPlayerOwner( currentPlayer )
    		currentPlayer:glimpseUnit( sim, partner:getID() )

    		if partner:getTraits().mainframe_autodeactivate then
				partner:deactivate( sim )
			end

			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = partner } )
		end

		if unit:getTraits().mainframe_autodeactivate then
			if unit:getTraits().powerGrid then
				--skip power propagation animations, just deactivate the units
				unit:getTraits().mainframe_status = "inactive"
				for i, gridUnit in pairs(sim:getAllUnits()) do
					if gridUnit:getID() ~= unit and gridUnit:getTraits().powerGrid == unit:getTraits().powerGrid and gridUnit:getLocation() then
						unit:powerUnit( sim, gridUnit, false )
					end
				end
			else
				unit:deactivate( sim )
			end
		end

		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
	end

	if unit:getTraits().parasite or unit:getTraits().parasiteV2 or unit:getTraits().plague then	--will get reversed
		for i,ability in ipairs(currentPlayer:getAbilities()) do
			if ability.parasite_hosts then
	            array.removeElement( ability.parasite_hosts, unit:getID() )
			end
			if ability.plague_hosts then
				array.removeElement( ability.plague_hosts, unit:getID() )
			end
		end
		unit:getTraits().parasite = nil
		unit:getTraits().plague = nil
	end
end

local function restoreDeviceSneakily( sim, unit ) --in order to succeed, this function needs to affect a device that was affected by storeCurrentDeviceInformation
    local currentPlayer = sim:getPC()

	if unit:getTraits().isDrone then
		local player = sim:getNPC()
		unit:setPlayerOwner( player )

		if not unit:getBrain() then
			local simfactory = include( "sim/simfactory" )
			unit._brain = simfactory.createBrain(unit:getUnitData().brain, sim, unit)
			unit:getBrain():onSpawned(sim, unit)
		end
		player:returnToIdleSituation(unit)
		unit:getModifiers():remove( "control" )
		unit:getTraits().takenDrone = nil
	    sim:refreshUnitLOS( unit )
	    if unit:getTraits().mainframe_suppress_rangeMax then
			unit:getTraits().mainframe_suppress_range = unit:getTraits().mainframe_suppress_rangeMax
		end
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
	end

	unit:getTraits().mainframe_ice = unit:getTraits().SLF_chkdsk.ice --restore firewalls

	if sim._resultTable.devices[unit:getID()] then --unhack the device
		sim._resultTable.devices[unit:getID()].hacked = false
	end

	if unit:getTraits().revealUnits then --rehide the units
		sim:forEachUnit(
			function ( u )
				if u:getTraits()[ unit:getTraits().revealUnits ] ~= nil then
					local found = false
					for i, u2 in pairs(unit:getTraits().SLF_known_units) do
						if u2:getID() == u:getID() then
							found = true -- unit was known before possession
						end
					end
					if found == false then -- unit was newly discovered via database possession
						unglimpseUnit( sim, u:getID() ) -- rehide it, unless it's seen *right now*
					end
					u:getTraits().sightable = u:getTraits().SLF_sightable
					u:getTraits().SLF_sightable = nil
				end
			end
		)
		--renew known units
		unit:getTraits().SLF_known_units = {}
		if unit.SLF_oldTrigger then
			unit.onTrigger = unit.SLF_oldTrigger
		else
			sim:removeTrigger( simdefs.TRG_UNIT_APPEARED, unit )
		end
		unit.SLF_oldTrigger = nil
	end
	
	if unit:getTraits().showOutline then --rehide the facility outline
		sim._showOutline = false
		sim:dispatchEvent( simdefs.EV_WALL_REFRESH )
	end
	
	if unit:getTraits().revealDaemons then  --rehide the daemons
			sim:forEachUnit(
			function ( u )
				if u:getTraits().mainframe_program ~= nil then
					u:getTraits().daemon_sniffed = false 
				end
			end )
	end

	if not unit:getTraits().noTakeover then --will get reversed 
		--log:write("Attempting to restore grid. Supply detected ["..unit:getID().."], grid ID "..tostring(unit:getTraits().powerGridName))
		unit:setPlayerOwner( sim:getNPC() )	
    	currentPlayer:glimpseUnit( sim, unit:getID() )

    	if unit:getTraits().partnerID then
			local partner = sim:getUnit( unit:getTraits().partnerID )

			partner:setPlayerOwner( sim:getNPC() )
    		currentPlayer:glimpseUnit( sim, partner:getID() )

    		if partner:getTraits().mainframe_autodeactivate then
				partner:activate( sim )
			end

			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = partner } )
		end

		if unit:getTraits().mainframe_autodeactivate then
			if unit:getTraits().powerGrid then
				--skip power propagation animations, just reactivate the units
				unit:getTraits().mainframe_status = "active"
				for i, gridUnit in pairs(sim:getAllUnits()) do
					if gridUnit:getID() ~= unit and gridUnit:getTraits().powerGrid == unit:getTraits().powerGrid and gridUnit:getLocation() then
						--log:write("Now putting "..gridUnit:getName().." ("..gridUnit:getID()..") under corp control.")
						gridUnit:setPlayerOwner( sim:getNPC() )
						unit:powerUnit( sim, gridUnit, true )
					end
				end
			else
				unit:activate( sim )
			end
		end

		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
	end

	if unit:getTraits().SLF_chkdsk.parasite then	--rehost the parasite
		local ptype = unit:getTraits().SLF_chkdsk.parasite
		--log:write("PARASITE CHECK - "..ptype)
		if ptype >= 10 then
			unit:getTraits().plague = true
			for i,ability in ipairs(currentPlayer:getAbilities()) do
				if ability.plague_hosts then
					table.insert( ability.plague_hosts, unit:getID() )
				end
			end

			ptype = ptype - 10
		end

		if ptype ~= 0 then
			unit:getTraits().parasite = true 
			if ptype == 2 then
				unit:getTraits().parasiteV2 = true
			end

			for i,ability in ipairs(currentPlayer:getAbilities()) do
				if ability.parasite_hosts and ptype == ability.parasite_strength then
		            table.insert( ability.parasite_hosts, unit:getID() )
				end
			end
		end
	end

	if unit:getTraits().SLF_chkdsk.daemon then		--rehost the daemon
		local daemon, sniffed = unpack(unit:getTraits().SLF_chkdsk.daemon)
		unit:getTraits().mainframe_program = daemon
		unit:getTraits().daemon_sniffed = sniffed
	end

	unit:getTraits().SLF_chkdsk = nil
end

----------------------------------------------------------------------------------------------------------------------------------------------------
local SLF_possess =
{
    prepHackSecure = function( self, sim, device )
    	--PREP THE DEVICE
		storeCurrentDeviceInformation( self, sim, device) -- firewalls / daemons / parasites
		--HACK THE DEVICE WITHOUT ALERTING ANYTHING
		destroyIceSneakily(sim,device)
		--SECURE THE DEVICE
		device:getTraits().mainframe_no_recapture = true
    end,

    unsecureReturnClean = function( self, sim, device )
    	--UNSECURE THE DEVICE
		device:getTraits().mainframe_no_recapture = device:getTraits().SLF_chkdsk.recapture
    	--RETURN IT, CLEANING UP THE TRACES
		restoreDeviceSneakily(sim, device)
    end,

    alertUnit = function( self, sim, unit, reason )
    	--simlog('alerting '..unit:getName()..' aka '..unit:getID())
    	unit:setAlerted(true)
    	--[[for i, guard in pairs(sim._resultTable.guards) do
    		if i == unit:getID() then
    			guard.alerted = true
    		end
    	end
    	sim:triggerEvent(simdefs.TRG_UNIT_ALERTED, {unit=unit})]]
    	sim:trackerAdvance(1, reason)
		local x,y = unit:getLocation()
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
		if unit:getBrain() and unit:getBrain():getSenses() then
			unit:getBrain():getSenses():addInterest( x, y, simdefs.SENSE_RADIO, simdefs.REASON_SENSEDTARGET, self.abilityOwner )
		else
			sim:triggerEvent( simdefs.TRG_NEW_INTEREST, { x = x, y = y, range = simdefs.SOUND_RANGE_3, interest = { x= x, y = y, reason=reason} })
		end
    end,

    doPossession = function( self, sim, device )
    	if device:getPlayerOwner() == sim:getPC() or (device:getTraits().isGuard and not device:getTraits().isDrone) or ((device:getTraits().mainframe_iceMax or 0) == 0 and (device:getTraits().cpus or 0) == 0) or device:getTraits().mainframe_status == "inactive" or device:getTraits().mainframe_status == "off" then
    		-- fail conditions:
    		-- > device already under agency control
    		-- > device is a mainframe-attuned guard
    		-- > device does not have firewalls nor stored PWR (console)
    		-- > device is rebooting
    		log:write("LOG_SPAM", "[ACW-POSSESS] Subvert failed (device ineligible).")
    		return
    	end

    	--IF SUBVERSION FAILS, DON'T ADD DEVICE TO LIST
    	local success = false

    	-- OPTION A:
    	-- device is a normal mainframe device
    	if not device:getTraits().isGuard and not device:getTraits().isDrone and (device:getTraits().mainframe_iceMax or 0) > 0 then
			self:prepHackSecure(sim, device)
			success = true
		end

		-- OPTION B:
		-- device is a drone; has to be unalerted and not KO
		--simlog(util.stringize(device._traits, 1))
		if device:getTraits().isDrone and not device:getTraits().alerted and not device:isKO() then
			if device:getTraits().failsafeAi then
				-- BZZT!
				self:alertUnit( sim, device, STRINGS.SLF.REASON.DESTROYER )
			else
				self:prepHackSecure(sim, device)
				success = true
				--DRONE SPECIAL CODE
				device:getTraits().apOld = device:getTraits().ap
				device:getTraits().ap = 0
				device:getTraits().sneaking = true -- technically, drones sprint
				local user = self.abilityOwner
				device:getTraits().controllingAgent = user
			end

			-- explicitly update null zones cause normal updates are all skipped
			if self.abilityOwner:hasAbility("SLF_nullblock") then
				self.abilityOwner:hasAbility("SLF_nullblock"):refreshNull(sim)
			end
		end

		-- OPTION C:
		-- device is a console with PWR; wasn't hijacked before
		if (device:getTraits().cpus or 0) > 0 and not device:getTraits().hijacked then
			local x1, y1 = device:getLocation()
			local user = self.abilityOwner
			user:getPlayerOwner():addCPUs( device:getTraits().cpus, sim, x1,y1 )				
			device:getTraits().hijacked = true
			device:getTraits().cpus = 0				
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = device } )
			sim:triggerEvent(63200, {unit=device})
            device:getTraits().mainframe_suppress_range = nil
			device:setPlayerOwner(user:getPlayerOwner())
			-- also trigger the MM AI console mission script
			if device:getTraits().MM_AIconsole and device:hasTag("W93_INCOG_LOCK") then
				sim:triggerEvent( simdefs.TRG_UNIT_HIJACKED, { unit = device } )
			end
			-- also grant the player PE's Hash Keys
			if sim:getPC():getTraits().aiTokenMax and sim:getPC():getTraits().aiToken then
				sim:getPC():getTraits().aiToken = math.min(sim:getPC():getTraits().aiToken + 1, sim:getPC():getTraits().aiTokenMax)
				sim:dispatchEvent( "PE_UPDATE_AI_INFO" )
			end
		end

		--IF SUBVERSION FAILS, DON'T ADD DEVICE TO LIST
		if success == false then
			return
		end

		-- Make Dragon disappear! Now with fancy daemon FX! (always wanted to add this but never found out how, until I spotted it in NIAA, cheers wodzu!)
		local fx_params = {color ={{symbol="inner_line",r=0,g=1,b=1,a=0.75},{symbol="wall_digital",r=0,g=1,b=1,a=0.75},{symbol="boxy_tail",r=0,g=1,b=1,a=0.75},{symbol="boxy",r=0,g=1,b=1,a=0.75}} }		
		sim:dispatchEvent( simdefs.EV_UNIT_ADD_FX, { unit = self.abilityOwner, kanim = "fx/deamon_ko", symbol = "effect", anim="break", above=true, params=fx_params} )
		self.abilityOwner:getTraits().tempKanim = "kanim_empty"
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self.abilityOwner } )

		--ADD TO LIST OF POSSESSED DEVICES
		local user = self.abilityOwner
		user:getTraits().controlledDevices = user:getTraits().controlledDevices or {}
		table.insert(user:getTraits().controlledDevices, device)
    end,

    getPossessed = function( self )
    	if not self.abilityOwner:getTraits().controlledDevices then
    		self.abilityOwner:getTraits().controlledDevices = {}
    	end
    	return self.abilityOwner:getTraits().controlledDevices
    end,

    undoPossession = function( self, sim, device, deviceListIndex )
    	user = self.abilityOwner

    	if not device or device:hasAbility("SLF_possess") or device:getTraits().cpus == 0 then
    		-- fail conditions:
    		-- > device no longer exists
    		-- > device is Dragon (?)
    		-- > device is a console that's been (possibly possess-)hacked

    		return
    	end

		self:unsecureReturnClean(sim, device)

		if device:getTraits().isDrone then
			device:getTraits().mainframe_no_recapture = true --drones actually have this by default, we need to restore it
			device:getTraits().ap = device:getTraits().apOld
			device:getTraits().apOld = nil
			device:getTraits().sneaking = true -- technically, drones sprint

			if device:getTraits().movedByAgent then --if the drone was moved, it'll be alerted
				self:alertUnit(sim, device, STRINGS.SLF.REASON.DRONE_ALERTED)
				device:getTraits().movedByAgent = nil
			end

			device:getTraits().controllingAgent = nil
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = device  } )

			-- explicitly update null zones cause normal updates are all skipped
			if self.abilityOwner:hasAbility("SLF_nullblock") then
				self.abilityOwner:hasAbility("SLF_nullblock"):refreshNull(sim)
			end
		end


		self.abilityOwner:getTraits().tempKanim = nil --make agent reappear
		local fx_params = {color ={{symbol="inner_line",r=0,g=1,b=1,a=0.75},{symbol="wall_digital",r=0,g=1,b=1,a=0.75},{symbol="boxy_tail",r=0,g=1,b=1,a=0.75},{symbol="boxy",r=0,g=1,b=1,a=0.75}} }
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self.abilityOwner  } )
		self.abilityOwner:getTraits().SLF_tempfxparams = fx_params

		table.remove(self:getPossessed(), deviceListIndex)
    end,

	onSpawnAbility = function( self, sim, unit )
		self.abilityOwner = unit
        sim:addTrigger( simdefs.TRG_UNIT_WARP_PRE, self )
        sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
        sim:addTrigger( simdefs.TRG_START_TURN, self )
        sim:addTrigger( simdefs.TRG_END_TURN, self )
    end,

    onDespawnAbility = function( self, sim )
        sim:removeTrigger( simdefs.TRG_UNIT_WARP_PRE, self )
        sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
        sim:removeTrigger( simdefs.TRG_START_TURN, self )
        sim:removeTrigger( simdefs.TRG_END_TURN, self )
    end,

	onTrigger = function( self, sim, evType, evData )

		if evType == simdefs.TRG_END_TURN then 	--drones get de-possessed at end of turn
			for i, unit in pairs(self:getPossessed()) do
				if unit:getTraits().isDrone and unit:getTraits().controllingAgent then	
					self:undoPossession(sim, unit)
				end
			end
		end

		if evType == simdefs.TRG_START_TURN and self.abilityOwner:getLocation() then -- check if Dragon is in a position to possess something
			for i,device in pairs(sim:getCell(self.abilityOwner:getLocation()).units) do
				if device:getID() ~= self.abilityOwner:getID() then
					self:doPossession(sim, device)
				end
			end
		end

		if evType == simdefs.TRG_UNIT_WARP_PRE then
			-- a possessed drone is trying to move somewhere
			if not evData.unit:hasAbility("SLF_possess") and evData.unit:getTraits().controllingAgent and evData.to_cell then
				assert(evData.unit:getTraits().controllingAgent:hasAbility("SLF_possess")) --ensure this isn't some misfire and the controlling agent actually can control
				local drone, agent = evData.unit, evData.unit:getTraits().controllingAgent
				--log:write("A controlled drone, ID "..drone:getID().." is moved by agent "..agent:getUnitData().name)
				sim:warpUnit(agent, evData.to_cell)
				drone:getTraits().movedByAgent = true
			-- Dragon is trying to move somewhere
			elseif evData.unit:hasAbility("SLF_possess") then
				-- DEPOSSESSION: release units at tile
				for i, device in pairs(self:getPossessed()) do
					if sim:getCell(device:getLocation()) == evData.from_cell then
						self:undoPossession(sim, device, i)
					end
				end
			end
		end

		if evType == simdefs.TRG_UNIT_WARP then
			--ALERT GUARDS THAT DRAGON PASSES THROUGH
			if evData.to_cell and evData.unit:hasAbility("SLF_possess") then
				for i, unit in pairs(evData.to_cell.units) do
					if unit:getTraits().isGuard and not unit:getTraits().innervate and not unit:getTraits().isDrone and not unit:getTraits().alerted and not unit:isKO() then
						--simlog('DRAGON PASSING THROUGH '..unit:getName())
						self:alertUnit(sim, unit, STRINGS.SLF.REASON.GUARD_ALERTED)
					end
				end

				-- POSSESSION: control units at tile
				local targetCell = evData.to_cell
				for i,device in pairs(targetCell.units) do
					if device:getID() ~= evData.unit:getID() then
						self:doPossession(sim, device)
					end
				end
			end

			-- DEPOSSESSION: play animation (has to be here for better visuals)
			if evData.unit:getTraits().SLF_tempfxparams then
				sim:dispatchEvent( simdefs.EV_UNIT_ADD_FX, { unit = self.abilityOwner, kanim = "fx/deamon_ko", symbol = "effect", anim="in", above=true, params=self.abilityOwner:getTraits().SLF_tempfxparams} )
				self.abilityOwner:getTraits().SLF_tempfxparams = nil
			end

			--ALERT GUARDS THAT PASS THROUGH DRAGON
			if evData.to_cell and evData.unit:getTraits().isGuard and not evData.unit:getTraits().innervate and not evData.unit:getTraits().isDrone and not evData.unit:getTraits().alerted then
				for i, unit in pairs(evData.to_cell.units) do
					if unit:hasAbility("SLF_possess") then
						self:alertUnit(sim, evData.unit, STRINGS.SLF.REASON.GUARD_ALERTED)
					end
				end
			end
		end
	end,
}

return SLF_possess