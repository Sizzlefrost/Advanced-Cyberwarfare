local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local cdefs = include( "client_defs" )
local serverdefs = include( "modules/serverdefs" )
local mainframe_common = include("sim/abilities/mainframe_common")

-------------------------------------------------------------------------------
-- These are NPC abilities.

local createDaemon = mainframe_common.createDaemon
local createReverseDaemon = mainframe_common.createReverseDaemon
local createCountermeasureInterest = mainframe_common.createCountermeasureInterest

local npc_abilities =
{
	--[[validate = util.extend( createDaemon( STRINGS.DAEMONS.VALIDATE ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0004.png",

		onSpawnAbility = function( self, sim, player )
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon=self.icon, txt = self.activedesc } )	

			if sim._params.difficulty < 3 then
				sim:getNPC():doTrackerSpawn(sim, 1, "important_guard" )
			else
				sim:getNPC():doTrackerSpawn(sim, 1, "important_guard" )
			end
			player:removeAbility(sim, self )
		end,

		onDespawnAbility = function( self, sim, unit )
		end,
	},]]--

	SLF_fear = util.extend( createDaemon( STRINGS.SLF.DAEMONS.FEAR ) )
	{
		icon = "gui/icons/daemon_icons/Daemons_fear.png",

		ENDLESS_DAEMONS = false,
		PROGRAM_LIST = true,
		OMNI_PROGRAM_LIST_EASY = false,
		OMNI_PROGRAM_LIST = true,
		REVERSE_DAEMONS = false,

		standardDaemon = false,

		onSpawnAbility = function( self, sim, player )
			--Announce the Daemon
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = self.activedesc, } )	
			--Get all agents and put them into a table
			local targets = {} --this table
			for _, unit in pairs( sim:getAllUnits() ) do --these units
				if unit:getPlayerOwner() == sim:getPC(sim, self) and simquery.isAgent( unit ) and unit:getTraits().mp then --specifically, player-controlled agents who have an AP number
					table.insert(targets,unit)	--put them in
				end
			end
			--then if there are targets within the table...
			if #targets > 0 then
				local target = targets[sim:nextRand(#targets)] --pick a random target
				target:getTraits().mp = 0	--its AP is set to 0
				local x0,y0 = target:getLocation() --it then gets a textbox saying FEARED above their head
				sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.SLF.DAEMONS.FEAR.AGENTTEXT,x=x0,y=y0,color={r=0.37890625,g=0.6640625,b=0.6640625,a=1}} )		
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = target } )		
			end
			--and finally remove the daemon indicator
			player:removeAbility( sim,self )
		end,

		onDespawnAbility = function( self, sim, unit )
		end,
	},

	SLF_transparency = util.extend( createDaemon( STRINGS.SLF.DAEMONS.TRANSPARENCY ) )
	{
		icon = "gui/icons/daemon_icons/Daemons_transparency.png",
		warning = STRINGS.SLF.DAEMONS.TRANSPARENCY.WARNING,

		ENDLESS_DAEMONS = false,
		PROGRAM_LIST = true,
		OMNI_PROGRAM_LIST_EASY = false,
		OMNI_PROGRAM_LIST = true,
		REVERSE_DAEMONS = false,

		standardDaemon = false,

		getDoors = function( self, sim )
			-- generates or fetches the table of doors in the level
			-- does not account for doors being added mid-sim (should that ever happen somehow)

			if sim._defaultExits then 
				return sim._defaultExits
			end

			local cells = {}
			local x_max, y_max = sim:getBoardSize()
			for x = 1, x_max do
				for y = 1, y_max do
					local cell = sim:getCell(x, y)
					if cell and cell.exits then
						table.insert(cells, cell)
					end
				end
			end

			local exits = {}
			for i, cell in pairs(cells) do
				for j, exit in pairs(cell.exits) do
					if exit and simquery.isDoorExit(exit) and not exit.searched then
						exit.searched = true
						exit.dir = simquery.getReverseDirection(j)
						table.insert(exits, exit)
					end
				end
				for j, exit in pairs(cell.exits) do
					exit.searched = nil
				end
			end

			sim._defaultExits = exits
			return exits
		end,

		initiateTransparency = function( self, sim )
			local doors = self:getDoors(sim)

			-- that returns all doors in the level.
			-- prune that list for only openable doors, etc.

			for i, door in pairs(doors) do
				if not door.locked and (door.keybits == 1 or door.keybits == 2) then
					if door.closed then
						sim:modifyExit( door.cell, door.dir, simdefs.EXITOP_OPEN )
					else
						door.SLF_transparency_keepOpen = true
					end
					-- possible issue: if doors_alarmOnOpen sim tag is set, lack of acting unit may make modifyExit crash
					if not door.SLF_transparency_reasons then
						door.SLF_transparency_reasons = {} -- "list of reasons this door is open" (daemon refs)
					end
					table.insert(door.SLF_transparency_reasons, self)
				end
			end
		end,

		takedownTransparency = function( self, sim )
			local doors = self:getDoors(sim)

			for i, door in pairs(doors) do
				if door.SLF_transparency_reasons then
					local selfReference = nil
					for i, reason in pairs(door.SLF_transparency_reasons) do
						if reason == self then
							selfReference = i
						end
					end
					table.remove(door.SLF_transparency_reasons, selfReference)

					if #door.SLF_transparency_reasons == 0 then
						if not door.SLF_transparency_keepOpen and not door.closed and
						not (
							door and door.dir and door.cell 
							and door.cell.exits 
							and door.cell.exits[simquery.getReverseDirection(door.dir)] 
							and door.cell.exits[simquery.getReverseDirection(door.dir)].SLF_transparency_keepOpen
						) then
							-- if no reason for door to stay open, close it again!
							-- (unless explicitly instructed to keep it open)
							sim:modifyExit( door.cell, door.dir, simdefs.EXITOP_CLOSE )
						end

						door.SLF_transparency_keepOpen = nil
						door.SLF_transparency_reasons = nil
					end
				end
			end
		end,

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim,sim:nextRand(3, 4))
			sim:addTrigger( simdefs.TRG_UNIT_USEDOOR, self )
			sim:addTrigger( simdefs.TRG_END_TURN, self )
			self:initiateTransparency(sim)
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.duration ) } )	
		end,

		onTrigger = function( self, sim, evType, evData )
			if evType == simdefs.TRG_END_TURN and sim:getCurrentPlayer() == sim:getNPC() then
				self.duration = self.duration - 1
				if (self.duration or 0) == 0 then
					self:executeTimedAbility( sim )
				end
				return
			end
			if evData and evData.unit and evData.cell and evData.tocell and evData.exitOp then
				if evData.unit:getPlayerOwner() ~= sim:getPC() then return end --force-close only on agency units
				--log:write("Door trigger fired, courtesy of "..evData.unit:getName())
				--evData:
				--.cell and .tocell allow us to determine the door's position
				--.unit is passed
				--.exitOp: see simdefs exitops

				--get delta and find the exit itself from the cells
				local d1, d2 = evData.tocell.x - evData.cell.x, evData.tocell.y - evData.cell.y
				local dir = simquery.getDirectionFromDelta(d1,d2)
				local exit = evData.cell.exits[simquery.getDirectionFromDelta(d1,d2)]
				if evData.exitOp == simdefs.EXITOP_OPEN or (evData.exitOp == simdefs.EXITOP_TOGGLE_DOOR and exit and simquery.isClosedDoor(exit)) then
					--if we open a secure door during the daemon's effect, we'll be unable to close it for the duration; but owing to this piece of code, it also stays open afterwards.
					exit.SLF_transparency_keepOpen = true
					if not exit.SLF_transparency_reasons then
						exit.SLF_transparency_reasons = {} -- "list of reasons this door is open" (daemon refs)
					end
					table.insert(exit.SLF_transparency_reasons, self)
				end
				if evData.exitOp == simdefs.EXITOP_CLOSE and exit.closed then 
					-- double checking that the door is not already open
					-- e.g. unit tries to close, Transparency forces door open
					-- 2nd Transparency fires, door is already open, can't open it again, crash
					sim:modifyExit( evData.cell, dir, simdefs.EXITOP_OPEN )
					sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=self.warning, color=cdefs.COLOR_CORP_WARNING, sound = "SpySociety/Actions/mainframe_deterrent_action" } )
				end
			end
		end,

		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_UNIT_USEDOOR, self )
			sim:removeTrigger( simdefs.TRG_END_TURN, self )
			-- if no other Transparencies are active, close the affected doors
			self:takedownTransparency(sim)
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
	},

	SLF_barricade = util.extend( createDaemon( STRINGS.SLF.DAEMONS.BARRICADE ) )
	{
		icon = "gui/icons/daemon_icons/Daemons_barricade.png",

		ENDLESS_DAEMONS = false,
		PROGRAM_LIST = true,
		OMNI_PROGRAM_LIST_EASY = false,
		OMNI_PROGRAM_LIST = true,
		REVERSE_DAEMONS = false,

		standardDaemon = false,

		_BarID = -1, -- this indicates invalid ID, will be updated upon spawn

		--secure doors stay closed; we store the keybits and change them to 8 for a while
		--8 is the value for the elevator doors while the elevator is locked - basically, unpathable no matter the keycards.

		initiateBarricade = function( cell )
			if not cell.exits then return end
			for dir, exit in pairs(cell.exits) do
				local doorIsSpecial = false
				for i = 0,9 do -- base game only goes to 9, but what if mods?
					if exit.keybits == 2^i then
						if i == 1 or i == 5 then
						--[[
						0 OFFICE 			= 1,
						1 SECURITY 		    = 2, -- THIS
						2 ELEVATOR 		    = 4,
						3 ELEVATOR_INUSE 	= 8,
						4 GUARD   		    = 16,
						5 VAULT   		    = 32, -- THIS
						6 FINAL_LEVEL	    = 64, 
						7 FINAL_RED         = 128, 
				        8 SPECIAL_EXIT      = 256, 
				        9 BLAST_DOOR        = 512, 
						]]
							doorIsSpecial = true
						end
					end
				end
				if simquery.isDoorExit(exit) and doorIsSpecial then
					exit.SLF_barricade = {
						keybits = exit.keybits,
						locked = exit.locked,
						closed = exit.closed,
					}
					exit.keybits = 4194304 -- my favourite power of 2, lol
					exit.closed = true
					exit.locked = true
				end
			end
		end,

		takedownBarricade = function( cell )
			if not cell.exits then return end
			for dir, exit in pairs(cell.exits) do
				local exit = cell.exits[dir]
				if simquery.isDoorExit(exit) and exit.SLF_barricade then
					exit.keybits = exit.SLF_barricade.keybits
					exit.locked = exit.SLF_barricade.locked
					exit.closed = exit.SLF_barricade.closed
					exit.SLF_barricade = nil
				end
			end
		end,

		otherBarricadesExist = function( self, sim )
			--log:write("Checking Barricades in play")
			for i, ability in pairs( sim:getNPC():getAbilities() ) do
				if ability._BarID then
					--log:write("Checking ability "..tostring(ability:getID()).." (Barricade ID "..ability._BarID..")")
					if ability._BarID ~= self._BarID then
						--log:write("ANOTHER BARRICADE EXISTS")
						return true
					end
				end
			end

			return false
		end,

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim,sim:nextRand(4, 5))
			--give this barricade a unique ID
			local UIDs = {}
			for i, ability in pairs( sim:getNPC():getAbilities() ) do
				--log:write("Checking ability "..tostring(ability:getID()))
				if ability._BarID then
					table.insert(UIDs, ability._BarID)
				end
			end
			self._BarID = #UIDs
			--log:write("WARNING: BARRICADE INSTALLED; ID "..self._BarID)
			--sim:addTrigger( simdefs.TRG_UNIT_USEDOOR, self )
			sim:addTrigger( simdefs.TRG_END_TURN, self )
			if self:otherBarricadesExist( sim ) ~= true then --if no other barricades are already in place
				sim:forEachCell(self.initiateBarricade)
			end
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.duration ) } )	
		end,

		onTrigger = function( self, sim, evType, evData )
			if evType == simdefs.TRG_END_TURN and sim:getCurrentPlayer() == sim:getNPC() then
				self.duration = self.duration - 1
				if (self.duration or 0) == 0 then
					self:executeTimedAbility( sim )
				end
				return
			end
		end,

		onDespawnAbility = function( self, sim, unit )
			--sim:removeTrigger( simdefs.TRG_UNIT_USEDOOR, self )
			sim:removeTrigger( simdefs.TRG_END_TURN, self )
			--log:write("Attempting to remove Barricade ID "..self._BarID)
			if self:otherBarricadesExist( sim ) ~= true then
				--log:write("All good, unlocking doors")
				sim:forEachCell(self.takedownBarricade)
			end
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
	},

	SLF_prompt = util.extend( createDaemon( STRINGS.SLF.DAEMONS.PROMPT ) )
	{
		icon = "gui/icons/daemon_icons/Daemons_EULA.png",

		onSpawnAbility = function( self, sim, player )
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, 1 ), } )	

			sim:getCurrentPlayer():addCPUs( -1 )

			local possibleDevices = {}
			for _, unit in pairs( sim:getAllUnits() ) do
				local t = unit:getTraits()
				if t.mainframe_iceMax and t.mainframe_ice and t.mainframe_status and t.mainframe_status == "active" and not t.mainframe_program and unit:getPlayerOwner() ~= sim:getPC() then
					--log:write("Possible device: "..unit:getID().." ("..unit:getName()..")")	
					table.insert( possibleDevices, unit )	
				end
			end

			for i=1,2,1 do
				if #possibleDevices > 0 then 
					local index = sim:nextRand(1, #possibleDevices)
					local unit = possibleDevices[ index ]
					table.remove(possibleDevices, index)

					unit:getTraits().mainframe_program = "SLF_prompt"
					--log:write("Now installing PROMPT onto #"..unit:getID().." ("..unit:getName()..")")									
					
					sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = unit, ice = unit:getTraits().mainframe_ice, delta = 0} )
				end
			end

			player:removeAbility(sim, self )
		end,

		onDespawnAbility = function( self, sim, unit )
		end,
	},
	-- AP tax on interacting with consoles

	--SLF_singularity = util.extend( createDaemon (STRINGS.SLF.DAEMONS.SINGULARITY) )
	-- protects the CAI from interference

	SLF_credentials = util.extend( createDaemon (STRINGS.SLF.DAEMONS.CREDENTIALS) )
	{
		icon = "gui/icons/daemon_icons/Daemons_registration.png",

		ENDLESS_DAEMONS = false,
		PROGRAM_LIST = true,
		OMNI_PROGRAM_LIST_EASY = false,
		OMNI_PROGRAM_LIST = true,
		REVERSE_DAEMONS = false,

		standardDaemon = false,

		onSpawnAbility = function( self, sim, player )
			--Announce the Daemon
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = self.activedesc, } )	
			
			local guard = nil

			local guards = sim:getNPC():getUnits()
			local i = sim:nextRand(1, #guards)
			local s = i

			while not guard do
				if guards[i]:getTraits().isGuard then
					guard = guards[i]
				else
					i = i + 1
					if i > #guards then
						i = 1
					end
					if i == s then
						break 
						-- if, for some reason, we're back where we started, then we're just shit out of luck
						-- and there is somehow no viable guard target for this daemon
					end
				end
			end

			local idle = sim:getNPC():getIdleSituation()
			if guard and guard:getBrain() and guard:getBrain():getSituation().ClassType == simdefs.SITUATION_IDLE then
	            idle:generatePatrolPath( guard )
	            if guard:getTraits().patrolPath and #guard:getTraits().patrolPath > 1 then
	                local firstPoint = guard:getTraits().patrolPath[1]
	                guard:getBrain():getSenses():addInterest(firstPoint.x, firstPoint.y, simdefs.SENSE_RADIO, simdefs.REASON_PATROLCHANGED, guard)
	            end
	        end

	        sim:processReactions()
			player:removeAbility(sim, self )
		end,
	},
	-- change patrols on a random guard

	SLF_uniform = util.extend( createDaemon( STRINGS.SLF.DAEMONS.UNIFORM ) )
	{
		icon = "gui/icons/daemon_icons/Daemons_uniform.png",

		ENDLESS_DAEMONS = false,
		PROGRAM_LIST = true,
		OMNI_PROGRAM_LIST_EASY = false,
		OMNI_PROGRAM_LIST = true,
		REVERSE_DAEMONS = false,

		standardDaemon = false,

		onSpawnAbility = function( self, sim, player )
			--Announce the Daemon
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = self.activedesc, } )	
			--Get all guards and put them into a table
			local targets = {} --this table
			for _, unit in pairs( sim:getAllUnits() ) do --these units
				if unit:getPlayerOwner() == sim:getNPC(sim, self) and unit:getTraits().isGuard and not unit:getTraits().acw_uniform == true then --specifically, corp-controlled agents (guards)
					table.insert(targets,unit)	--put them in
				end
			end
			--then if there are targets within the table...
			if #targets > 0 then
				local target = targets[sim:nextRand(#targets)] --pick a random target
				target:getTraits().armor = (target:getTraits().armor or 0) + 1
				target:getTraits().acw_uniform = true
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = target } )		
			end
			--and finally remove the daemon indicator
			player:removeAbility( sim,self )
		end,

		onDespawnAbility = function( self, sim, unit )
		end,
	},

}

return npc_abilities



	