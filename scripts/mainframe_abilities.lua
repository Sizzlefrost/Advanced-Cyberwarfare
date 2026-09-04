local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "client_util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local cdefs = include( "client_defs" )
local mainframe = include( "sim/mainframe" )
local modifiers = include( "sim/modifiers" )
local mission_util = include( "sim/missions/mission_util" )
local serverdefs = include("modules/serverdefs")
local mainframe_common = include("sim/abilities/mainframe_common")
local mainframe_common_mod = include(SCRIPT_PATHS.advanced_cyberwarfare.."/mainframe_common")
local mainframe_abilities_base = include("sim/abilities/mainframe_abilities")
local commondefs = include("sim/unitdefs/commondefs")

-------------------------------------------------------------------------------
-- These are PC mainframe abilities.  They are owned and executed by the player.

--[[local function onGuardTooltip ( tooltip, unit ) = util.extend ( commondefs.onGuardTooltip )
	tooltip:addAbility( "PECKED", "Sight range reduced", "gui/icons/arrow_small.png"), targetUnit
end]]--

local DEFAULT_ABILITY = mainframe_common.DEFAULT_ABILITY
local DEFAULT_CAISSA = mainframe_common_mod.DEFAULT_CAISSA

local mainframe_abilities =
{	
	--footnote: Dragon's programs have been moved to dragon_mainframe so you can't disable them with the rest by accident while Dragon is enabled
	---------------------------------------------------------------------------
	-- PASSIVES (powergens etc.) ----------------------------------------------
	---------------------------------------------------------------------------

	-- SCHEDULED FOR DEMOLITION
	SLF_sun = util.extend( DEFAULT_ABILITY ) --CYCLE 2.0ish
	{
		name = STRINGS.SLF.PROGRAMS.SUN.NAME,
		desc = STRINGS.SLF.PROGRAMS.SUN.DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.SUN.SHORT_DESC,
		huddesc = STRINGS.SLF.PROGRAMS.SUN.HUD_DESC,
		icon = "gui/icons/programs_icons/icon-program_Sun.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Sun.png",
		value = 600,
		percentage_cpus = 50,

		alarm_cost = 1,
	
		executeAbility = function( self, sim )
			local player = sim:getCurrentPlayer()			
			if not player:isNPC() then
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, cdefs.SOUND_HUD_MAINFRAME_PROGRAM_AUTO_RUN )
				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.SLF.PROGRAMS.SUN.WARNING, color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=self.icon } )
				player:addCPUs( math.floor(self.percentage_cpus * player:getMaxCpus()) )
				sim:trackerAdvance ( self.alarm_cost )
			end
		end,

		canUseAbility = function( self, sim )
			return false 	
		end,

		onSpawnAbility = function( self, sim )
			sim:getTags().clearPWREachTurn = true
			DEFAULT_ABILITY.onSpawnAbility( self, sim )
		end,

		onDespawnAbility = function( self, sim )
			sim:getTags().clearPWREachTurn = nil
			DEFAULT_ABILITY.onDespawnAbility( self, sim )
		end,

		onTrigger = function( self, sim, evType, evData )
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )

			if evType == simdefs.TRG_START_TURN and sim:getTurnCount() ~= 1 then
				self:executeAbility(sim)	
			end						
		end,
	},

	SLF_work = util.extend( DEFAULT_ABILITY ) --Agents work, Incognita gains. Just like in the real game :thinking:
	{     
		name = STRINGS.SLF.PROGRAMS.WORK.NAME,   
		tipdesc = STRINGS.SLF.PROGRAMS.WORK.TIP_DESC,
		desc = STRINGS.SLF.PROGRAMS.WORK.DESC,
		huddesc = STRINGS.SLF.PROGRAMS.WORK.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.WORK.SHORT_DESC,

		icon = "gui/icons/programs_icons/icon-program_Work.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Work.png",
		passive = true,
		value = 600,
		pwrMod = -1,
		drain = 1,

		canUseAbility = function( self, sim )
			return false 	
		end,

		onTrigger = function( self, sim, evType, evData )
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )

			if evType == simdefs.TRG_START_TURN then
				self:executeAbility(sim)	
			end						
		end,

		executeAbility = function( self, sim )
			local player = sim:getCurrentPlayer()
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_wings_activate")

			for _, unit in pairs(sim:getAllUnits()) do
				if unit:getPlayerOwner() == player and not player:isNPC() and simquery.isAgent( unit ) then
					unit:getTraits().mp = unit:getTraits().mp - self.drain
					if unit:getTraits().mp < 0 then --In case you use this and Burst from CP on a Courier whose base AP is 5, we don't want him to end up with -1 LUL
						unit:getTraits().mp = 0
					end
					local x0,y0 = unit:getLocation()
					sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.SLF.PROGRAMS.WORK.AGENTTEXT,x=x0,y=y0,color={r=0.37890625,g=0.6640625,b=0.6640625,a=1}} )		

					sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )

					local x1, y1 = unit:getLocation()
					sim:dispatchEvent( simdefs.EV_GAIN_AP, { unit = unit } )	
				end
			end
		end,
	},

	SLF_angel = util.extend( DEFAULT_ABILITY )
	{     
		name = STRINGS.SLF.PROGRAMS.ANGEL.NAME,   
		desc = STRINGS.SLF.PROGRAMS.ANGEL.DESC,
		huddesc = STRINGS.SLF.PROGRAMS.ANGEL.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.ANGEL.SHORT_DESC,
		tipdesc = STRINGS.SLF.PROGRAMS.ANGEL.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Angel.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Angel.png",
		passive = true,
		value = 500,
		
		canUseAbility = function( self, sim )
			return false 	
		end,

		pwrMod = 1,
		daemonReversalAdd = 65,
	},

	SLF_dataBlast2 = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.DATA_BLAST2.NAME,
		desc = STRINGS.SLF.PROGRAMS.DATA_BLAST2.DESC,
		huddesc = STRINGS.SLF.PROGRAMS.DATA_BLAST2.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.DATA_BLAST2.SHORT_DESC,
		tipdesc = STRINGS.SLF.PROGRAMS.DATA_BLAST2.TIP_DESC,
 
		icon = "gui/icons/programs_icons/Programs0015.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_0015.png",
		cpu_cost = 4,
        range = 2,
        value = 600,
        break_firewalls = 2,

        PROGRAM_LIST = 10,

		acquireTargets = function( self, targets, game, sim, unit )
            local targetHandler = targets.areaCellTarget( game, self.range, sim, sim:getPC() )
            targetHandler:setUnitPredicate(
                function( u )
                    return mainframe.canBreakIce( sim, u, self )
                end )
            targetHandler:setHiliteColor( { 0.33, 0.33, 0.00, 0.33 } )
            return targetHandler
		end, 

        startTargeting = function( self, sim, unit, userUnit, targetCell )
    		MOAIFmodDesigner.playSound( "SpySociety/Actions/mainframe_datablast_select" )
        end,

        getTargetUnits = function( self, sim, cellx, celly )
            local cells = simquery.rasterCircle( sim, cellx, celly, self.range )
            local units = {}
            for i, x, y in util.xypairs( cells ) do
                local cell = sim:getCell( x, y )
                if cell then
                    for _, cellUnit in ipairs(cell.units) do
                        if sim:getCurrentPlayer():getLastKnownCell( sim, x, y ) ~= nil then
                            if mainframe.canBreakIce( sim, cellUnit, self ) then
                                table.insert( units, cellUnit )
                            end
                        end
                    end
                end
            end
            return units
        end,

		executeAbility = function( self, sim, unit, userUnit, targetCell )
			
			local player = sim:getCurrentPlayer()
            local currentProgram = player:getEquippedProgram()

    		player:equipProgram( sim, self:getID() )

			local cellx, celly = unpack(targetCell)
            sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_datablast_use" )

            local targetUnits = self:getTargetUnits( sim, cellx, celly )

           	sim:dispatchEvent( simdefs.EV_OVERLOAD_VIZ, {x = cellx, y = celly, units = targetUnits, range = self.range } )		

            local daemonUnits = {}
            for _, unit in ipairs(targetUnits) do
            	if unit:getTraits().mainframe_item or not sim:isVersion("0.17.15") then
	                -- Keep track of daemons that *Would* be invoked, so that we can invoke them only after
	                -- everything has been broken.
	                local daemonProgram = unit:getTraits().mainframe_program

	                unit:getTraits().mainframe_program = nil
	                mainframe.breakIce( sim, unit, self.break_firewalls )
	                unit:getTraits().mainframe_program = daemonProgram

	                if daemonProgram and unit:getTraits().mainframe_ice <= 0 then
	                    table.insert( daemonUnits, unit )
	                end
            	end
	        end

            self:useCPUs( sim )
    		player:equipProgram( sim, currentProgram and currentProgram:getID() )

            for i, unit in ipairs( daemonUnits ) do
                mainframe.invokeDaemon( sim, unit )
            end

            if sim:isVersion("0.17.6") then
				self:setCooldown( sim ) 
			end
		end,
	},	

	SLF_dataBlast3 = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.DATA_BLAST3.NAME,
		desc = STRINGS.SLF.PROGRAMS.DATA_BLAST3.DESC,
		huddesc = STRINGS.SLF.PROGRAMS.DATA_BLAST3.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.DATA_BLAST3.SHORT_DESC,
		tipdesc = STRINGS.SLF.PROGRAMS.DATA_BLAST3.TIP_DESC,
 
		icon = "gui/icons/programs_icons/Programs0015.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_0015.png",
		cpu_cost = 5,
        range = 7,
        value = 900,
        break_firewalls = 5,

		cooldown = 0,
		maxCooldown = 5,

        PROGRAM_LIST = 10,

        canUseAbility = function( self, sim, abilityOwner )
        	local player = sim:getCurrentPlayer()
			if player ~= abilityOwner or player == nil then
				return false
			end

        	if sim:isVersion("0.17.17") then
				if (self.cooldown or 0) > 0 then 
					return false, STRINGS.UI.REASON.EQUIPPED_ON_COOLDOWN
				end
			end

			return DEFAULT_ABILITY.canUseAbility( self, sim, abilityOwner )
		end,

		acquireTargets = function( self, targets, game, sim, unit )
            local targetHandler = targets.areaCellTarget( game, self.range, sim, sim:getPC() )
            targetHandler:setUnitPredicate(
                function( u )
                    return mainframe.canBreakIce( sim, u, self )
                end )
            targetHandler:setHiliteColor( { 0.33, 0.00, 0.00, 0.33 } )
            return targetHandler
		end, 

        startTargeting = function( self, sim, unit, userUnit, targetCell )
    		MOAIFmodDesigner.playSound( "SpySociety/Actions/mainframe_datablast_select" )
        end,

        getTargetUnits = function( self, sim, cellx, celly )
            local cells = simquery.rasterCircle( sim, cellx, celly, self.range )
            local units = {}
            for i, x, y in util.xypairs( cells ) do
                local cell = sim:getCell( x, y )
                if cell then
                    for _, cellUnit in ipairs(cell.units) do
                        if sim:getCurrentPlayer():getLastKnownCell( sim, x, y ) ~= nil then
                            if mainframe.canBreakIce( sim, cellUnit, self ) then
                                table.insert( units, cellUnit )
                            end
                        end
                    end
                end
            end
            return units
        end,

		executeAbility = function( self, sim, unit, userUnit, targetCell )
			
			local player = sim:getCurrentPlayer()
            local currentProgram = player:getEquippedProgram()

    		player:equipProgram( sim, self:getID() )

			local cellx, celly = unpack(targetCell)
            sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_datablast_use" )

            local targetUnits = self:getTargetUnits( sim, cellx, celly )

           	sim:dispatchEvent( simdefs.EV_OVERLOAD_VIZ, {x = cellx, y = celly, units = targetUnits, range = self.range } )		

            local daemonUnits = {}
            for _, unit in ipairs(targetUnits) do
            	if unit:getTraits().mainframe_item or not sim:isVersion("0.17.15") then
	                -- Keep track of daemons that *Would* be invoked, so that we can invoke them only after
	                -- everything has been broken.
	                local daemonProgram = unit:getTraits().mainframe_program

	                unit:getTraits().mainframe_program = nil
	                mainframe.breakIce( sim, unit, self.break_firewalls )
	                unit:getTraits().mainframe_program = daemonProgram

	                if daemonProgram and unit:getTraits().mainframe_ice <= 0 then
	                    table.insert( daemonUnits, unit )
	                end
            	end
	        end

            self:useCPUs( sim )
    		player:equipProgram( sim, currentProgram and currentProgram:getID() )

            for i, unit in ipairs( daemonUnits ) do
                mainframe.invokeDaemon( sim, unit )
            end

            if sim:isVersion("0.17.6") then
				self:setCooldown( sim ) 
			end
		end,
	},

	---------------------------------------------------------------------------
	-- ACTIVES (breakers etc.) ------------------------------------------------
	---------------------------------------------------------------------------
	SLF_socialmedia = util.extend( DEFAULT_ABILITY )
	{	
		name = STRINGS.SLF.PROGRAMS.NETWORK.NAME,
		desc = STRINGS.SLF.PROGRAMS.NETWORK.DESC,
		huddesc = STRINGS.SLF.PROGRAMS.NETWORK.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.NETWORK.SHORT_DESC,
		tipdesc = STRINGS.SLF.PROGRAMS.NETWORK.TIP_DESC,
		icon = "gui/icons/programs_icons/icon-program_Network.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Network.png",
		cooldown = 0,
		maxCooldown = 1,
		cpu_cost = 3,		
		equip_program = true, 
		equipped = false,
		targetGuard = true,	
		value = 450,
		linknum = 0, -- tracker for # of linked guards
		weight = 0.5, -- PWR points per guard, rounded down

		disconnectGuard = function( self, sim, unit )
			if unit:getTraits().SLF_net_cleartags then
				--this is terrible
				if unit:getTraits().SLF_net_cleartags % 2 == 0 then --check cc
					if unit:getTraits().mainframe_device then
						mainframe.revokeDaemonHost( sim, unit )
					end
					unit:getTraits().koDaemon = nil
				end
				if unit:getTraits().SLF_net_cleartags < 2 then --check tag
					unit:getTraits().tagged = nil
				end
				unit:getTraits().SLF_net_cleartags = nil
			else
				if unit:getTraits().mainframe_device then
					mainframe.revokeDaemonHost( sim, unit )
				end
				unit:getTraits().koDaemon = nil
				unit:getTraits().tagged = nil
			end
			unit:getTraits().SLF_networked = nil
		end,

		onTooltip = function( self, screen, sim, player )
			local tooltip = util.tooltip( screen )
			local section = tooltip:addSection()

			local sub = ""


			sub = util.sformat( STRINGS.PROGRAMS.POWER, self:getCpuCost() )

			section:addLine( "<ttheader>"..self.name.."</>",sub)

			section:addLine(util.sformat(STRINGS.SLF.PROGRAMS.NETWORK.GAMEDESC, 1/self.weight), string.format(""))
			
			if self.maxCooldown and self.maxCooldown > 0  then
				section:addLine( util.sformat( STRINGS.PROGRAMS.COOLDOWN, self.maxCooldown )  )
			end

			if self.equipped then
				section:addLine( STRINGS.PROGRAMS.EQUIPPED, string.format( "" ))
			end

	   		section:addAbility( self.shortdesc, self.huddesc, "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png" )

	        if sim then
			    local canUse, reason = self:canUseAbility( sim, player )
			    if not canUse and reason then
				    section:addRequirement( reason )
			    end
	        end

			if self.dlcFooter then
				section:addFooter(self.dlcFooter[1],self.dlcFooter[2])
			end	        

			return tooltip
		end,

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			if targetUnit then
				if not targetUnit:getTraits().isGuard then 				
					return false
				end

				if targetUnit:getTraits().SLF_networked then
					return false, STRINGS.SLF.PROGRAMS.NETWORK.FAIL
				end
			end

			local player = sim:getCurrentPlayer()
			if player == nil or player ~= abilityOwner then
				return false
			end

			if (self.cooldown or 0) > 0 then 
				return false, STRINGS.UI.REASON.EQUIPPED_ON_COOLDOWN
			end

			if player:getCpus() < self:getCpuCost() then
				return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
			end

			if sim:getMainframeLockout() then 
				return false, STRINGS.UI.REASON.INCOGNITA_LOCKED_DOWN
			end 

			return true	
		end,

		executeAbility = function( self, sim, targetUnit )
			DEFAULT_ABILITY.executeAbility(self, sim, targetUnit)		

			if targetUnit:getTraits().koDaemon == true then --00 = clr everything; 01 = skip cc; 10 = skip tag; 11 = skip both
				targetUnit:getTraits().SLF_net_cleartags = (targetUnit:getTraits().SLF_net_cleartags or 0) + 1 --if there was a daemon, set protection flag
			else
				targetUnit:getTraits().koDaemon = true
			end
			if targetUnit:getTraits().tagged == true then
				targetUnit:getTraits().SLF_net_cleartags = (targetUnit:getTraits().SLF_net_cleartags or 0) + 2
			else
				targetUnit:setTagged()
				sim:dispatchEvent( simdefs.EV_UNIT_TAGGED, {unit = targetUnit} )
			end
			targetUnit:getTraits().SLF_networked = true
		end,

		onDespawnAbility = function( self, sim )
	    	DEFAULT_ABILITY.onDespawnAbility( self, sim )
	    	for _, unit in pairs(  sim:getNPC():getUnits() ) do --liquidate the network
	    		if simquery.isAgent(unit) and unit:getTraits().SLF_networked then
	    			self:disconnectGuard( sim, unit )
	    		end
	    	end
	    end,

		onTrigger = function( self, sim, evType, evData )
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )

			--monstrosity. If networked guard loses TAG, at the start of NPC turn, disconnect them from the network
			if evType == simdefs.TRG_START_TURN and sim:getCurrentPlayer():isNPC() then
				for _, unit in pairs( sim:getNPC():getUnits() ) do
					if simquery.isAgent(unit) and unit:getTraits().SLF_networked and (unit:getTraits().tagged == nil or unit:getTraits().tagged == false) then
						self:disconnectGuard( sim, unit )
						local x1, y1 = unit:getLocation()
						sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.SLF.PROGRAMS.NETWORK.TRIGGER,x=x1,y=y1,color={r=1,g=0.8,b=0.8,a=1}} )
					end
				end
			end

			if evType == simdefs.TRG_START_TURN and sim:getCurrentPlayer():isPC() and sim:getTurnCount() ~= 1 then
				--not run on first turn because the trigger would fire too early and result in a myriad of errors; there wouldn't be connected guards before you play the game anyway
				local player = sim:getCurrentPlayer()

				self.linknum = 0
				for _, unit in pairs( sim:getNPC():getUnits() ) do --test for networked guards
					if simquery.isAgent(unit) and unit:getTraits().SLF_networked then 
						self.linknum = self.linknum + self.weight
					end
				end	
				player:addCPUs(math.floor(self.linknum))

				local function round(var)
					if math.floor(var) == math.floor(var+0.5) then
						return math.floor(var)
					else
						return math.floor(var+1)
					end
				end

				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=util.sformat(STRINGS.SLF.PROGRAMS.NETWORK.WARNING,round(self.linknum*(1/self.weight)),math.floor(self.linknum)), color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=self.icon } )
			end						
		end,
	},

	SLF_keyhole = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.KEYHOLE.NAME,
		huddesc = STRINGS.SLF.PROGRAMS.KEYHOLE.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.KEYHOLE.SHORT_DESC,
		desc = STRINGS.SLF.PROGRAMS.KEYHOLE.DESC,
		tipdesc = STRINGS.SLF.PROGRAMS.KEYHOLE.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Keyhole.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Keyhole.png",
		cpu_cost = 0,
		break_firewalls = 1, 
		equip_program = true, 
		equipped = false, 
		cooldown = 0,
		maxCooldown = 2,
		value = 300,

		PROGRAM_LIST = 10,

		executeAbility = function( self, sim, targetUnit )
	        DEFAULT_ABILITY.executeAbility( self, sim, targetUnit )

	        if self.resetCooldown then
	            self.cooldown = 0
	            self.resetCooldown = nil
	        end
		end,

		onSpawnAbility = function( self, sim )
			sim:addTrigger( simdefs.TRG_START_TURN, self )
			sim:addTrigger( simdefs.TRG_ICE_BROKEN, self )		
		end, 

	    onDespawnAbility = function( self, sim )
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
	        sim:removeTrigger( simdefs.TRG_ICE_BROKEN, self )
	    end,

	    onTrigger = function( self, sim, evType, evData )
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )

			if evType == simdefs.TRG_ICE_BROKEN and evData.unit and (evData.unit:getTraits().mainframe_ice < 1) then
				self.cooldown = 0
				-- works fine if another program breaks
				-- but if this breaks, the cooldown will be overridden
				-- so reset it again
				self.resetCooldown = true
			end
		end,
	},

	SLF_pendulum = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.PENDULUM.NAME,
		huddesc = STRINGS.SLF.PROGRAMS.PENDULUM.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.PENDULUM.SHORT_DESC,
		desc = STRINGS.SLF.PROGRAMS.PENDULUM.DESC,
		desc1 = STRINGS.SLF.PROGRAMS.PENDULUM.DESC1,
		tipdesc = STRINGS.SLF.PROGRAMS.PENDULUM.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Werewolf_Full.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Werewolf.png",
		cpu_cost = 2, 
		equip_program = true, 
		equipped = false, 
		moonphase = 0, -- 1 = waxing, 2 = full, 3 = waning, 0 = new
		icons = {
			"gui/icons/programs_icons/icon-program_Werewolf_New.png",
			"gui/icons/programs_icons/icon-program_Werewolf_Wax.png",
			"gui/icons/programs_icons/icon-program_Werewolf_Full.png",
			"gui/icons/programs_icons/icon-program_Werewolf_Wane.png"
		},
		value = 300,
		break_firewalls = 1, -- BASE breaking power
		variable_break = 0, -- CURRENT breaking power

		PROGRAM_LIST = 10,	

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			if abilityOwner then --wodzu enlightened me about this amazing solution for dynamic tooltips. Huge thanks!
				self.huddesc = util.sformat(STRINGS.SLF.PROGRAMS.PENDULUM.HUD_DESC, self.variable_break)
				self.tipdesc = util.sformat(STRINGS.SLF.PROGRAMS.PENDULUM.TIP_DESC, self.variable_break, self:getCpuCost())
			end

			local player = sim:getCurrentPlayer()
			if player == nil or player ~= abilityOwner then
				return false
			end

			if (self.cooldown or 0) > 0 then 
				return false, STRINGS.UI.REASON.EQUIPPED_ON_COOLDOWN
			end

			if player:getCpus() < self:getCpuCost() then 
				return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
			end

			if player:getCredits() < self.credit_cost then
				return false, STRINGS.UI.REASON.NOT_ENOUGH_CREDITS
			end

			if sim:getMainframeLockout() then 
				return false, STRINGS.UI.REASON.INCOGNITA_LOCKED_DOWN
			end

			if self.variable_break == 0 then
				return false, STRINGS.SLF.PROGRAMS.PENDULUM.REASON
			end 

			for i, x in ipairs(player:getAbilities()) do 
				if x == self then 
					for j, y in ipairs(player:getLockedAbilities()) do 
						if y == i then 
							return false, STRINGS.ABILITIES.TEMPORARY_LOSS 
						end 
					end 
				end 
			end 

			return true 
		end,

		onTooltip = function( self, screen, sim, player )
			local tooltip = util.tooltip( screen )
			local section = tooltip:addSection()

			local sub = ""


			if self:getCpuCost() > 0 then 
				sub = util.sformat( STRINGS.PROGRAMS.POWER, self:getCpuCost() )							
			end 

			section:addLine( "<ttheader>"..self.name.."</>",sub)
			
			if self.maxCooldown and self.maxCooldown > 0  then
				section:addLine( util.sformat( STRINGS.PROGRAMS.COOLDOWN, self.maxCooldown )  )
			end

			if self.equipped then
				section:addLine( STRINGS.PROGRAMS.EQUIPPED, string.format( "" ))
			end

	   		section:addAbility( self.shortdesc, util.sformat(self.desc1,self.variable_break), "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png" )

	        if sim then
			    local canUse, reason = self:canUseAbility( sim, player )
			    if not canUse and reason then
				    section:addRequirement( reason )
			    end
	        end

			if self.dlcFooter then
				section:addFooter(self.dlcFooter[1],self.dlcFooter[2])
			end	        

			return tooltip
		end,

		onSpawnAbility = function( self, sim )
			sim:addTrigger( simdefs.TRG_START_TURN, self )		
		end, 

	    onDespawnAbility = function( self, sim )
	        sim:removeTrigger( simdefs.TRG_START_TURN, self )
	    end,

	    onTrigger = function( self, sim, evType, evData )
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )

			if evType == simdefs.TRG_START_TURN and sim:getCurrentPlayer():isPC() then
				self.moonphase = self.moonphase + 1
				if self.moonphase == 4 then
					self.moonphase = 0
					self.variable_break = -1 + self.break_firewalls
				elseif self.moonphase == 3 then
					self.variable_break = 0 + self.break_firewalls
				elseif self.moonphase == 2 then
					self.variable_break = 1 + self.break_firewalls
				else
					self.variable_break = 0 + self.break_firewalls
				end

				self.icon = self.icons[self.moonphase+1]

				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=util.sformat(STRINGS.SLF.PROGRAMS.PENDULUM.WARNING, self.variable_break), color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=self.icon } )
			end
		end,

		executeAbility = function( self, sim, targetUnit )
	        self:useCPUs( sim )
	        --log:write("Attempting to use Pendulum with breaking power of "..self.variable_break.."; break_firewalls value: "..self.break_firewalls)

	        local firewallsToBreak = self.variable_break

	        if sim:getPC():getTraits().firewallBreakPenalty and firewallsToBreak > 0 then
	        	firewallsToBreak = math.max(firewallsToBreak-sim:getPC():getTraits().firewallBreakPenalty,1)
	        end

	        if targetUnit and (firewallsToBreak or 0) > 0 then
	            mainframe.breakIce( sim, targetUnit, firewallsToBreak )
	        end
	       	self:setCooldown( sim )
		end,	
	},

	SLF_feather = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.FEATHER.NAME,
		desc = STRINGS.SLF.PROGRAMS.FEATHER.DESC,
		huddesc = STRINGS.SLF.PROGRAMS.FEATHER.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.FEATHER.SHORT_DESC,
		tipdesc = STRINGS.SLF.PROGRAMS.FEATHER.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Feather.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Feather.png",
		cpu_cost = 3, 
		value = 500,

		PROGRAM_NO_BREAKER_LIST = 10,

		executeAbility = function( self, sim, targetUnit )
			self:useCPUs(sim)
			sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {txt=STRINGS.SLF.PROGRAMS.FEATHER.WARNING, color=cdefs.COLOR_PLAYER_WARNING, sound = "SpySociety/Actions/mainframe_gainCPU",icon=self.icon } )
			sim:trackerDecrement(1)
			self.cpu_cost = self.cpu_cost + 1
		end,			
	},

	SLF_focus = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.FOCUS.NAME,
		desc = STRINGS.SLF.PROGRAMS.FOCUS.DESC,
		huddesc = STRINGS.SLF.PROGRAMS.FOCUS.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.FOCUS.SHORT_DESC,
		tipdesc = STRINGS.SLF.PROGRAMS.FOCUS.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Focus.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Focus.png",
		cpu_cost = 2,
		duration = 3,
		vision_range_reduction = 2,
		cooldown = 0,
		maxCooldown = 1,
		value = 450,

		PROGRAM_NO_BREAKER_LIST = 8,

		onTrigger = function( self, sim, evType, evData )
			DEFAULT_ABILITY.onTrigger( self, sim, evType, evData )
			local player = sim:getCurrentPlayer()
			for _, unit in pairs(sim:getAllUnits()) do
				if unit:getTraits().SLF_focus then
					local statuses = unit:getTraits().SLF_focus 
					local i = #statuses
					while i > 0 do
						--log:write(util.stringize(statuses))
						statuses[i] = statuses[i] - 1
						if statuses[i] < 0 then
							table.remove(statuses, i)
							unit:getModifiers():remove("SLF_focus")
							sim:refreshUnitLOS(unit)
							sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
						end
						i = i - 1
					end
				end
			end
		end,

		executeAbility = function( self, sim )
			local player = sim:getCurrentPlayer()
            self:useCPUs( sim )
			for _, unit in pairs(sim:getAllUnits()) do
				if unit:getPlayerOwner() ~= player and unit:getTraits().mainframe_camera and unit:getTraits().hasSight then
                    unit:getModifiers():add( "LOSrange", "SLF_focus", modifiers.ADD, -self.vision_range_reduction )
                    unit:getTraits().SLF_focus = unit:getTraits().SLF_focus or {}
                    table.insert(unit:getTraits().SLF_focus, self.duration)
                    sim:refreshUnitLOS( unit )
				end
			end
			self:setCooldown( sim )
		end,
	},

	SLF_deafen = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.DEAFEN.NAME,
		desc = STRINGS.SLF.PROGRAMS.DEAFEN.DESC,
		huddesc = STRINGS.SLF.PROGRAMS.DEAFEN.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.DEAFEN.SHORT_DESC,
		tipdesc = STRINGS.SLF.PROGRAMS.DEAFEN.TIP_DESC,
		icon = "gui/icons/programs_icons/icon-program_Deafen.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Deafen.png",

		cpu_cost = 4,
		cooldown = 0,
		maxCooldown = 1,
		equip_program = true,
		equipped = false,
		targetGuard = true,
		value = 500,

		PROGRAM_NO_BREAKER_LIST = 6,

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			if targetUnit then
				if not targetUnit:getTraits().hasHearing == true then 	--checks for everything that can't hear, which is everything except human guards and sound bugs			
					return false										--units generally include all mainframe devices, drones, etc - this is what's omitted here
				end

				if not targetUnit:getPlayerOwner() == sim:getNPC() then	--checks for captured sound bugs so we don't capture them twice
					return false, STRINGS.SLF.PROGRAMS.DEAFEN.WARNING 	--technically also prevents you from deafening allied guards, if you somehow get those
				end
			end

			local player = sim:getCurrentPlayer()
			if player == nil or player ~= abilityOwner then
				return false
			end

			if (self.cooldown or 0) > 0 then 
				return false, STRINGS.UI.REASON.EQUIPPED_ON_COOLDOWN
			end

			if player:getCpus() < self:getCpuCost() then 
				return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
			end

			if sim:getMainframeLockout() then 
				return false, STRINGS.UI.REASON.INCOGNITA_LOCKED_DOWN
			end 

			return true	
		end,

		executeAbility = function( self, sim, targetUnit )
			DEFAULT_ABILITY.executeAbility(self, sim, targetUnit)
			
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_lightning_strike" )			

			if targetUnit:getTraits().isGuard then
				targetUnit:getTraits().hasHearing = false
			else
				mainframe.breakIce( sim, targetUnit, targetUnit:getTraits().mainframe_ice ) --breaks ALL the ice on the sound bug; this DOES trigger daemons
			end
		end,
	},

	SLF_peck = util.extend( DEFAULT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.PECK.NAME,
		desc = STRINGS.SLF.PROGRAMS.PECK.DESC,
		huddesc = STRINGS.SLF.PROGRAMS.PECK.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.PECK.SHORT_DESC,
		tipdesc = STRINGS.SLF.PROGRAMS.PECK.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Peck.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Peck.png",

		cpu_cost = 0,
		cooldown = 0,
		maxCooldown = 3,
		equip_program = true,
		equipped = false,
		targetGuard = true,
		value = 200,

		PROGRAM_NO_BREAKER_LIST = 8,

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			if targetUnit then
				if not targetUnit:getTraits().isGuard == true then 		--make sure you can only target guards
					return false
				end

				if not targetUnit:getTraits().cashOnHand or targetUnit:getTraits().cashOnHand == 0 then 			--checks for guards that been looted			
					return false
				end
			end

			local player = sim:getCurrentPlayer()
			if player == nil or player ~= abilityOwner then
				return false
			end

			if (self.cooldown or 0) > 0 then 
				return false, STRINGS.UI.REASON.EQUIPPED_ON_COOLDOWN
			end

			if player:getCpus() < self:getCpuCost() then 
				return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
			end

			if sim:getMainframeLockout() then 
				return false, STRINGS.UI.REASON.INCOGNITA_LOCKED_DOWN
			end

			return true	
		end,

		executeAbility = function( self, sim, targetUnit )
			DEFAULT_ABILITY.executeAbility(self, sim, targetUnit)
			
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_blackcat" )			

			sim:getPC():addCredits( targetUnit:getTraits().cashOnHand ) --add credits to the agency equal to what the guard has
			--START OF CHEATING: Right here while the game glosses over this comment, you're technically cheating, you have credits and the guard also has them LOL.
			local x,y =  targetUnit:getLocation()
			if x and y then
				sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT, {txt=string.format("%d CR",targetUnit:getTraits().cashOnHand), x=x,y=y, color={r=1,g=1,b=1,a=1},target="credits"} )	
			end
			--END OF CHEATING: Right here while the game glosses over this comment, you're technically cheating, you have credits and the guard also has them LOL.
			targetUnit:getTraits().cashOnHand = 0 --take away the credits
			targetUnit:getTraits().searched = true --mark the guard as searched
		end,
	},

	SLF_pawn = util.extend( DEFAULT_CAISSA )
	{
		name = STRINGS.SLF.PROGRAMS.PAWN.NAME,
		huddesc = STRINGS.SLF.PROGRAMS.PAWN.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.PAWN.SHORT_DESC,
		desc = STRINGS.SLF.PROGRAMS.PAWN.DESC .. STRINGS.SLF.PROGRAMS.PAWN.DESC_CAISSA,
		desc_normal = STRINGS.SLF.PROGRAMS.PAWN.DESC,
		desc_caissa = STRINGS.SLF.PROGRAMS.PAWN.DESC_CAISSA,
		tipdesc = STRINGS.SLF.PROGRAMS.PAWN.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Pawn.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Pawn.png",
		cpu_cost = 1,
		break_firewalls = 1, 
		equip_program = true, 
		equipped = false, 
		value = 500,

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			if (self.SLF_device ~= targetUnit) and targetUnit and self.SLF_device then
				return false, STRINGS.SLF.PROGRAMS.PAWN.FAIL_DESC
			end

			return DEFAULT_ABILITY:canUseAbility(sim, abilityOwner, targetUnit)
		end,

		executeAbility = function( self, sim, targetUnit )
			local kingsbound = self:isCaissaKingsbound(sim)
	        if not kingsbound then
	        	self.SLF_device = targetUnit
	        end
	        
	        DEFAULT_ABILITY.executeAbility( self, sim, targetUnit )

	        if not kingsbound and targetUnit:getTraits().mainframe_ice <= 0 then
	        	sim:getPC():equipProgram(sim)
	        end
		end,

	    onTrigger = function( self, sim, evType, evData )
	    	DEFAULT_ABILITY:onTrigger( sim, evType, evData )

	    	if evType == simdefs.TRG_START_TURN and evData:isPC() then
	    		self.SLF_device = nil
	    	end
		end,
	},

	SLF_knight = util.extend( DEFAULT_CAISSA )
	{
		name = STRINGS.SLF.PROGRAMS.KNIGHT.NAME,
		huddesc = STRINGS.SLF.PROGRAMS.KNIGHT.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.KNIGHT.SHORT_DESC,
		desc = STRINGS.SLF.PROGRAMS.KNIGHT.DESC .. STRINGS.SLF.PROGRAMS.KNIGHT.DESC_CAISSA,
		desc_normal = STRINGS.SLF.PROGRAMS.KNIGHT.DESC,
		desc_caissa = STRINGS.SLF.PROGRAMS.KNIGHT.DESC_CAISSA,
		tipdesc = STRINGS.SLF.PROGRAMS.KNIGHT.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Knight.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Knight.png",
		cpu_cost = 2,
		break_firewalls = 2, 
		equip_program = true, 
		equipped = false, 
		value = 500,

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			if self.SLF_device and targetUnit and self.SLF_device:getName() == targetUnit:getName() then
				return false, STRINGS.SLF.PROGRAMS.KNIGHT.FAIL_DESC
			end

			return DEFAULT_ABILITY:canUseAbility(sim, abilityOwner, targetUnit)
		end,

		executeAbility = function( self, sim, targetUnit )
			local kingsbound = self:isCaissaKingsbound(sim)
	        if not kingsbound then
	        	self.SLF_device = targetUnit
	        end
	        
	        DEFAULT_ABILITY.executeAbility( self, sim, targetUnit )
		end,
	},

	SLF_bishop = util.extend( DEFAULT_CAISSA )
	{
		name = STRINGS.SLF.PROGRAMS.BISHOP.NAME,
		huddesc = STRINGS.SLF.PROGRAMS.BISHOP.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.BISHOP.SHORT_DESC,
		desc = STRINGS.SLF.PROGRAMS.BISHOP.DESC .. STRINGS.SLF.PROGRAMS.BISHOP.DESC_CAISSA,
		desc_normal = STRINGS.SLF.PROGRAMS.BISHOP.DESC,
		desc_caissa = STRINGS.SLF.PROGRAMS.BISHOP.DESC_CAISSA,
		tipdesc = STRINGS.SLF.PROGRAMS.BISHOP.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Bishop.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Bishop.png",
		cpu_cost = 2,
		break_firewalls = 2, 
		equip_program = true, 
		equipped = false, 
		value = 500,

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			local kingsbound = self:isCaissaKingsbound(sim)

			if targetUnit and not kingsbound and targetUnit:getTraits().mainframe_program then
				return false, STRINGS.SLF.PROGRAMS.BISHOP.FAIL_DESC
			end

			return DEFAULT_ABILITY:canUseAbility(sim, abilityOwner, targetUnit)
		end,
	},

	SLF_rook = util.extend( DEFAULT_CAISSA )
	{
		name = STRINGS.SLF.PROGRAMS.ROOK.NAME,
		huddesc = STRINGS.SLF.PROGRAMS.ROOK.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.ROOK.SHORT_DESC,
		desc = STRINGS.SLF.PROGRAMS.ROOK.DESC .. STRINGS.SLF.PROGRAMS.ROOK.DESC_CAISSA,
		desc_normal = STRINGS.SLF.PROGRAMS.ROOK.DESC,
		desc_caissa = STRINGS.SLF.PROGRAMS.ROOK.DESC_CAISSA,
		tipdesc = STRINGS.SLF.PROGRAMS.ROOK.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Rook.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Rook.png",
		cpu_cost = 3,
		break_firewalls = 3, 
		equip_program = true, 
		equipped = false,
		value = 700,
		maxCooldown = 3,
		cooldown = 0,

		setCooldown = function( self, sim )
			local kingsbound = self:isCaissaKingsbound(sim)
			if kingsbound then
				return 
			end
			DEFAULT_ABILITY.setCooldown(self, sim)
		end,
	},

	SLF_queen = util.extend( DEFAULT_CAISSA )
	{
		name = STRINGS.SLF.PROGRAMS.QUEEN.NAME,
		huddesc = STRINGS.SLF.PROGRAMS.QUEEN.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.QUEEN.SHORT_DESC,
		desc = STRINGS.SLF.PROGRAMS.QUEEN.DESC .. STRINGS.SLF.PROGRAMS.QUEEN.DESC_CAISSA,
		desc_normal = STRINGS.SLF.PROGRAMS.QUEEN.DESC,
		desc_caissa = STRINGS.SLF.PROGRAMS.QUEEN.DESC_CAISSA,
		tipdesc = STRINGS.SLF.PROGRAMS.QUEEN.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_Queen.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Queen.png",
		cpu_cost = 2,
		break_firewalls = 5, 
		equip_program = true, 
		equipped = false, 
		value = 700,

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			local kingsbound = self:isCaissaKingsbound(sim)

			if targetUnit and not kingsbound then
				return false, STRINGS.SLF.PROGRAMS.QUEEN.FAIL_DESC
			end

			return DEFAULT_ABILITY:canUseAbility(sim, abilityOwner, targetUnit)
		end,
	},

	SLF_king = util.extend( DEFAULT_CAISSA )
	{
		name = STRINGS.SLF.PROGRAMS.KING.NAME,
		huddesc = STRINGS.SLF.PROGRAMS.KING.HUD_DESC,
		shortdesc = STRINGS.SLF.PROGRAMS.KING.SHORT_DESC,
		desc = STRINGS.SLF.PROGRAMS.KING.DESC,
		tipdesc = STRINGS.SLF.PROGRAMS.KING.TIP_DESC,

		icon = "gui/icons/programs_icons/icon-program_King.png",
		icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_King.png",
		passive = true,
		value = 300,

        PROGRAM_NO_BREAKER_LIST = 8,
        PROGRAM_LIST = nil,

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			return false
		end,

		onSpawnAbility = function( self, sim )
			DEFAULT_CAISSA:onSpawnAbility(sim)

			if not sim:getPC() then return end

			for i, program in pairs(sim:getPC():getAbilities()) do
				if program.desc_caissa and program.desc_normal then
					-- clear previous target
					program.SLF_device = nil
					-- clear cooldown
					program.cooldown = 0

					program.desc = program.desc_normal .. program.desc_caissa
				end
			end
		end,

		onDespawnAbility = function( self, sim )
			DEFAULT_ABILITY:onDespawnAbility(sim)

			for i, program in pairs(sim:getPC():getAbilities()) do
				if program.desc_caissa and program.desc_normal then
					program.desc = program.desc_normal
				end
			end
		end
	}
}
 
-- now find all attaching programs and give them a trojan label

-- clrs used
-- 140/255, 255/255, 140/255 8CFF8C SCRIPT CHIPS
-- 255/255, 0/255, 96/255 FF0060 CAISSA
-- 204, 96, 255 CC60FF BREAKER
-- 255, 204, 204 FFCCCC TROJAN
-- 96, 204, 255 60CCFF sky blue - do not use, UI, for colour blind testing only

function mainframe_common.applySubtypes()
	for i, program in pairs(mainframe_abilities_base) do
		if program.break_firewalls then 
			program = mainframe_common.applySubtypeTooltips(program, STRINGS.SLF.PROGRAMS.CONVERTED_TYPES.BREAKER)
			program.specialized_type_clr = util.color(204/255, 96/255, 255/255)
		end
		if program.parasite_hosts or program.plague_hosts then
			program = mainframe_common.applySubtypeTooltips(program, STRINGS.SLF.PROGRAMS.CONVERTED_TYPES.TROJAN)
			program.specialized_type_clr = util.color(255/255, 204/255, 204/255)
		end
	end
end

return mainframe_abilities
