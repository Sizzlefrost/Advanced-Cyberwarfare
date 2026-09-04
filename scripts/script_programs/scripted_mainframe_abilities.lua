local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "client_util" )
local mainframe_common = include("sim/abilities/mainframe_common")
local commondefs = include("sim/unitdefs/commondefs")
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local simplayer = include("sim/simplayer")
local mainframe = include("sim/mainframe")
local mission_util = include( "sim/missions/mission_util" )
local cdefs = include( "client_defs" )
local abilitydefs = include("sim/abilitydefs")


-------------------------------------------------------------------------------
-- 

local nonbreakIceTooltip = include( "hud/tooltip_nonbreakice" )
local booster_tooltip = class(nonbreakIceTooltip)

function booster_tooltip:init( mainframePanel, targetWidget, unit, reason )
	util.tooltip.init( self, mainframePanel._hud._screen )
	self._targetWidget = targetWidget
	self.mainframePanel = mainframePanel

	local localPlayer = mainframePanel._hud._game:getLocalPlayer()
	local equippedProgram = nil
	if localPlayer then 
		equippedProgram = localPlayer:getEquippedProgram()
		if equippedProgram then
			local programWidget = mainframePanel._panel.binder.programsPanel:findWidget( equippedProgram:getID() )		
			if programWidget and programWidget:isVisible() then            	
				self._ux0, self._uy0 = programWidget.binder.btn:getAbsolutePosition()
				if equippedProgram:canUseAbility( mainframePanel._hud._game.simCore, localPlayer ) then
					self.programWidget = programWidget
					self.equippedProgram = equippedProgram
				end
			end
		end
	end

	local section = self:addSection()
	section:addLine( "<ttheader>"..util.sformat( "TARGET {1}", unit:getName() ).."</>" )

	if equippedProgram then
		section:addAbility( 
			string.format(STRINGS.UI.TOOLTIPS.CURRENTLY_EQUIPPED, 
				equippedProgram:getDef().name), 
			equippedProgram:getDef().tip_desc,  
			"gui/icons/arrow_small.png" )
	end 

	if reason then
		section:addRequirement( reason )
	end
end

-------------------------------------------------------------------------------
-- These are PC mainframe abilities.  They are owned and executed by the player.
local DEFAULT_ABILITY = mainframe_common.DEFAULT_ABILITY

local round = function( number )
	if number % 1 >= 0.5 then
		return math.ceil(number)
	else
		return math.floor(number)
	end
end

DEFAULT_SCRIPT_ABILITY = util.extend( DEFAULT_ABILITY )
{
	-- override these
	name = STRINGS.SLF.PROGRAMS.SCRIPT.NAME,   
	desc = STRINGS.SLF.PROGRAMS.SCRIPT.DESC,
	huddesc = STRINGS.SLF.PROGRAMS.SCRIPT.HUD_DESC,
	shortdesc = STRINGS.SLF.PROGRAMS.SCRIPT.SHORT_DESC,
	tipdesc = STRINGS.SLF.PROGRAMS.SCRIPT.TIP_DESC,

	icon = "gui/icons/programs_icons/icon-program_Compile.png",
	icon_100 = "gui/icons/programs_icons/store_icons/StorePrograms_Compile.png",
	value = 600,

	effectMod = 1,
	cpu_cost = 0,
	cooldown = 0,
	maxCooldown = 0,
	equip_program = true,
	equipped = false,
	-- no costs flag: dynamically set before executeAbility
	-- in order to fire doAlternate instead of doEffect, without consuming PWR/CD
	-- useful for retargeting or other similar purposes
	no_costs = false, 

	customTargetTooltip = function( mainframePanel, widget, unit, reason )
		return booster_tooltip( mainframePanel, widget, unit, reason )
	end,

	onTooltip = function( self, screen, sim, player )
		local tooltip = util.tooltip( screen )
		local section = tooltip:addSection()

		local sub = ""

		if self:getCpuCost() > 0 then 
			sub = util.sformat( STRINGS.PROGRAMS.POWER, self:getCpuCost() )							
		elseif (self.credit_cost or 0) > 0 then
			sub = self.credit_cost .. " " .. STRINGS.SLF.PROGRAMS.RESOURCE_CREDITS
		elseif (self.alarm_cost or 0) > 0 then
			sub = "+" .. self.alarm_cost .. " " .. STRINGS.SLF.PROGRAMS.RESOURCE_ALARM
		end

		local headerLine = "<ttheader>"..self.name.."</>"
		if self.specialized_type then
			headerLine = headerLine.."\n".."<font1_12_l><c:F4FF78>"..STRINGS.SLF.PROGRAMS.PROGRAM_TITLE.." - </c>"
            for i, spec_type in ipairs(self.specialized_type) do
                local typeData = mainframe_common.SLF_specializedType(spec_type)
                local clrStr = util.color.clrToHex(typeData.clr)
                headerLine = headerLine..clrStr..typeData.name.."</c> "
            end
            headerLine = headerLine.."</font>"
		end

		section:addLine( headerLine, sub )
		
		if self.maxCooldown and self.maxCooldown > 0  then
			section:addLine( util.sformat( STRINGS.PROGRAMS.COOLDOWN, self.maxCooldown )  )
		end

		if self.equipped then
			section:addLine( STRINGS.PROGRAMS.EQUIPPED, string.format( "" ))
		end

   		section:addAbility( self:makeAbilityDescription(sim) )

   		if self.module then
   			local moduledef = abilitydefs.lookupAbility(self.module)
   			if moduledef then
	   			local moduleName = moduledef.name
	   			local moduleDesc = moduledef.chip_desc

	   			section:addAbility(
	   				"MODULE: "..string.upper(moduleName),
	   				moduleDesc,
	   				"gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png"
	   				)
	   		end
   		end

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

	getOwnBaseCost = function( self )
		-- https://www.youtube.com/watch?v=PlKDQqKh03Y
		-- he GETS OWN BASE

		local cost_type, cost, syntax_order = "PWR", self.cpu_cost, 1

		local colour = cdefs.COLOR_PLAYER_WARNING

		-- ordering 1: 2 PWR/CR CONSUMED
		-- ordering 2: ALARM ADVANCED BY 2

		if self.module == "SLF_MODULE_gold" then
			cost_type = "CR"
			cost = self.credit_cost
		elseif self.module == "SLF_MODULE_hardcore" then
			cost_type = "ALARM"
			cost = self.alarm_cost
			syntax_order = 2
			colour = cdefs.COLOR_HUD_YELLOW_1
		end

		return cost, cost_type, syntax_order, colour
	end,

	makeAbilityDescription = function( self, sim )
		return util.sformat(self.shortdesc, self.name), -- USE <fullname>
   			self:makeBaseDescription()..				-- Breaks <X> firewalls ...
   			self:makeLauncherDescription(), 			-- ... for <Y> PWR.
   			"gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png"
	end,

	makeBaseDescription = function( self )
		return util.sformat(self.base_desc, round(self.break_firewalls*self.effectMod))
	end,

	makeLauncherDescription = function( self )
		-- determine resource
		local cost, cost_type = self:getOwnBaseCost()

		return util.sformat(
			self.launcher_desc, 
			cost,
			cost_type,
			self.maxCooldown)
	end,

	canUseAbility = function( self, sim, abilityOwner, targetUnit )
		if self.passive and not self.evaluation then
			return false -- cannot be used manually
		elseif self.evaluation then
			-- triggered programs get special rules
			-- they care about the costs, but not the active player
			-- below is a pasted DEFAULT_ABILITY canUse, but with the player being always PC instead of current_player
			-- I'm not keen on appending DEFAULT_ABILITY so it has to be done in this scuffed manner
			local player = sim:getPC()
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
			-- support alarm as a resource; if using the program would put you over the limit, ...
			if self.alarm_cost and sim:getTrackerStage() + self.alarm_cost >= simdefs.TRACKER_MAXSTAGE then
				return false, STRINGS.SLF.PROGRAMS.SCRIPT.ERROR_NOALARM
			end

			if sim:getMainframeLockout() then 
				return false, STRINGS.UI.REASON.INCOGNITA_LOCKED_DOWN
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

			-- extra block for targeted triggered abilities
			if self.randomTargeting and self.targets and self.targets ~= 0 then
				local targets = {}
	        	for i, unit in pairs(sim:getAllUnits()) do
		        	if self:targetingCriteria(sim, unit) then
		        		table.insert(targets, unit)
		        	end
		        end
		        if #targets == 0 then
		        	return false, STRINGS.SLF.PROGRAMS.SCRIPT.NO_TARGETS
		        end
	        end

			return true
		end

		local canUse, reason = DEFAULT_ABILITY.canUseAbility( self, sim, abilityOwner, targetUnit )

		if canUse then
			-- support alarm as a resource
			if self.alarm_cost and sim:getTrackerStage() + self.alarm_cost >= simdefs.TRACKER_MAXSTAGE then
				return false, STRINGS.SLF.PROGRAMS.SCRIPT.ERROR_NOALARM
			end
			-- support random targeting running out of targets
			if self.randomTargeting then
				local targets = {}
	        	for i, unit in pairs(sim:getAllUnits()) do
		        	if self:targetingCriteria(sim, unit) then
		        		table.insert(targets, unit)
		        	end
		        end
		        if #targets == 0 then
		        	return false, STRINGS.SLF.PROGRAMS.SCRIPT.NO_TARGETS
		        end
	        end
		end

		return canUse, reason
	end,

	executeAbility = function( self, sim, targetUnit, userUnit, targetCell )
		if self.no_costs then
			--self:doAlternate(sim, targetUnit, userUnit, targetCell)
			self.no_costs = false
			return
		end

		self:useCPUs( sim )
		if self.credit_cost then
			sim:getPC():addCredits( -self.credit_cost, sim )
		end
		if self.alarm_cost and self.alarm_cost ~= 0 then
			sim:trackerAdvance( self.alarm_cost ) -- is this silent? (edit: yes-ish. Alarm wheel moves, but no alert inherently pops up)
		end

        local targets = {}
        if targetUnit and not targetUnit._isPlayer then
        	table.insert(targets, targetUnit)
        end
        --log:write("EXECUTING: targetUnit is "..tostring(targetUnit and "non-nil"))
        if self.randomTargeting then
        	for i, unit in pairs(sim:getAllUnits()) do
        		--log:write("Unit "..tostring(unit:getID()).." / "..unit:getName()..": "..tostring(self:targetingCriteria(sim, unit)))
	        	if self:targetingCriteria(sim, unit) then
	        		table.insert(targets, unit)
	        	end
	        end
	        --log:write("Random targeting complete, painted "..#targets)
        end
        local j
        for i = #targets, 2, -1 do
        	j = sim:nextRand(i)
        	targets[i], targets[j] = targets[j], targets[i]
        end
        --log:write("targets: "..tostring(#targets).."; "..util.stringize(targets,1))

        local targetsPainted = 0
        for i, target in pairs(targets) do
       		--log:write("TARGET PAINTED: "..util.stringize(target, 2))
       		--log:write("Executing on "..target:getName().." ("..target:getID()..")")
        	local result = self:doEffect(sim, target, userUnit, targetCell)

        	if result then
        		targetsPainted = targetsPainted + 1
        	end
        	--log:write("DONE/TOTAL: "..targetsPainted.." / "..(self.targets or "nil"))
        	if (self.targets and targetsPainted == self.targets) or (not self.targets and targetsPainted == 1) then
        		break
        	end
        end
        if #targets == 0 then
        	self:doEffect(sim, targetUnit, userUnit, targetCell) -- for untargeted abilities, just run the effect once
        end

       	self:setCooldown( sim )

       	if self.queuedUses then
       		log:write("LOG_SPAM", "[ACW-SCRIPTQUEUE] Tick: "..self.queuedUses)
       		self.queuedUses = (self.queuedUses > 0) and (self.queuedUses - 1) or 0
       	end

       	if self.launcher_callback then
       		self:launcher_callback(sim)
       	end
	end,

	doEffect = function( self, sim, unit )
		local firewallsToBreak = round(self.break_firewalls * self.effectMod)

        if sim:getPC():getTraits().firewallBreakPenalty and firewallsToBreak > 0 then
        	firewallsToBreak = math.max(firewallsToBreak-sim:getPC():getTraits().firewallBreakPenalty,1)
        end

        if (firewallsToBreak or 0) > 0 and unit then
        	mainframe.breakIce( sim, unit, firewallsToBreak )
        	return true
    	end

    	return false
	end,

	-- qualifier for random targeting
	targetingCriteria = function( self, sim, unit )
		-- default: active mainframe devices known to the player
		if sim:getPC():hasSeen(unit) 
    	and unit:getTraits().mainframe_status and unit:getTraits().mainframe_status == "active" 
    	and unit:getTraits().mainframe_ice and unit:getTraits().mainframe_ice > 0 then
    		return true
	    end

	    return false
	end,

	onTrigger = function( self, sim, evType, evData )
		DEFAULT_ABILITY.onTrigger(self, sim, evType, evData)

		if evType == simdefs.TRG_START_TURN and evData:isPC() then
			if self.cooldown == 0 then
				self:onCooldownRecovered( sim )
			elseif self.cooldown == self.maxCooldown - 1 then
				self:oneTurnLaterCallback( sim )
			end
		end

		self:triggerCallback( sim, evType, evData )
	end,

	triggerCallback = function( self, sim, evType, evData )
		-- fires after onTrigger, safe to append for program bases without interference with launchers
	end,

	oneTurnLaterCallback = function(self, sim)
		-- fires at the start of the next turn after program was used
	end,

	onCooldownRecovered = function(self, sim)
		-- fires when program comes off cooldown
	end,
}

local script_abilities = {
	SLF_BASE_blast = util.extend( DEFAULT_SCRIPT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.BLAST.NAME,
		base_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.BLAST.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.BLAST.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.BLAST.CHIP_DESC_SHORT,
		huddesc = DEFAULT_SCRIPT_ABILITY.huddesc .. STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.BLAST.HUD_DESC,
		tip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.BLAST.TIP_DESC,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_blast_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_blast.png",

		main = "SLF_BASE_blast",
		break_firewalls = 2,
	},

	SLF_BASE_wave = util.extend( DEFAULT_SCRIPT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.WAVE.NAME,
		base_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.WAVE.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.WAVE.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.WAVE.CHIP_DESC_SHORT,
		huddesc = DEFAULT_SCRIPT_ABILITY.huddesc .. STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.WAVE.HUD_DESC,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_wave_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_wave.png",

		main = "SLF_BASE_wave",
		break_firewalls = 1,
		targets = 3,
		randomTargeting = true,
		equip_program = false,
		equipped = nil,

		makeBaseDescription = function( self )
			return util.sformat(self.base_desc, 
				round(self.break_firewalls*self.effectMod), 
				self.targets)
		end,
	},

	SLF_BASE_heat = util.extend( DEFAULT_SCRIPT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.HEAT.NAME,
		base_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.HEAT.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.HEAT.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.HEAT.CHIP_DESC_SHORT,
		huddesc = DEFAULT_SCRIPT_ABILITY.huddesc .. STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.HEAT.HUD_DESC,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_heat_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_heat.png",

		main = "SLF_BASE_heat",
		pwrGain = 2,
		equip_program = false,
		equipped = nil,

		makeBaseDescription = function( self )
			return util.sformat(self.base_desc, round(self.pwrGain*self.effectMod))
		end,

		doEffect = function( self, sim )
			local pwrToGain = round(self.pwrGain * self.effectMod)

			sim:getPC():addCPUs( pwrToGain )
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_gainCPU" )

			return true
        end,
	},

	SLF_BASE_swift = util.extend( DEFAULT_SCRIPT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SWIFT.NAME,
		base_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SWIFT.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SWIFT.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SWIFT.CHIP_DESC_SHORT,
		huddesc = DEFAULT_SCRIPT_ABILITY.huddesc .. STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SWIFT.HUD_DESC,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_swift_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_swift.png",

		main = "SLF_BASE_swift",
		mpGain = 2,
		targets = 2,
		randomTargeting = true,
		equip_program = false,
		equipped = nil,

		-- qualifier for random targeting
		targetingCriteria = function( self, sim, unit )
			-- target agents that can move
			if unit:getPlayerOwner() == sim:getPC() and simquery.isAgent(unit) and not unit:isKO() then
	    		return true
		    end

		    return false
		end,

		makeBaseDescription = function( self )
			return util.sformat(self.base_desc,
				self.targets,
				round(self.mpGain*self.effectMod))
		end,

		doEffect = function( self, sim, targetUnit )
			local mpToGain = round(self.mpGain * self.effectMod)

			--log:write("Granting "..mpToGain.." AP to "..targetUnit:getName().." ("..targetUnit:getID()..")")

			targetUnit:getTraits().mp = targetUnit:getTraits().mp + mpToGain

			local x1, y1 = targetUnit:getLocation()
			sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, {
		    	txt=util.sformat("+{1} AP", mpToGain),
		    	x=x1,y=y1,color={r=0/255,g=0/255,b=163/255,a=1},alwaysShow=true} )

			return true
        end,
	},

	SLF_BASE_shatter = util.extend( DEFAULT_SCRIPT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SHATTER.NAME,
		base_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SHATTER.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SHATTER.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SHATTER.CHIP_DESC_SHORT,
		huddesc = DEFAULT_SCRIPT_ABILITY.huddesc .. STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SHATTER.HUD_DESC,
		tip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SHATTER.TIP_DESC,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_shatter_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_shatter.png",

		main = "SLF_BASE_shatter",
		resistPenalty = 1,
		targets = 1,
		targetGuard = true,
		equip_program = true,
		equipped = false,

		-- qualifier for random targeting
		targetingCriteria = function( self, sim, unit )
			-- target known guards that can move
			if unit:getPlayerOwner() == sim:getNPC() and unit:getTraits().isGuard and not unit:isKO() then
				if sim:canPlayerSeeUnit(sim:getPC(), unit) then		-- guards seen directly...
	    			return true
	    		elseif sim:getPC()._ghost_units[unit:getID()] then	-- or their ghosts count
	    			return true
	    		end
		    end

		    return false
		end,

		makeBaseDescription = function( self )
			return util.sformat(self.base_desc, round(self.resistPenalty*self.effectMod))
		end,

		doEffect = function( self, sim, targetUnit )
			--log:write("Doing effect of SHATTER on "..tostring(targetUnit:getID()))
			local resistToLose = round(self.resistPenalty * self.effectMod)

			--log:write("Granting "..mpToGain.." AP to "..targetUnit:getName().." ("..targetUnit:getID()..")")

			targetUnit:getTraits().resistKO = (targetUnit:getTraits().resistKO or 0) - resistToLose

			local x1, y1 = targetUnit:getLocation()
			sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, {
		    	txt="VULNERABILITY",
		    	x=x1,y=y1,color={r=163/255,g=163/255,b=0,a=1},alwaysShow=true} )

			return true 
        end,
	},

	SLF_BASE_shuffle = util.extend( DEFAULT_SCRIPT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SHUFFLE.NAME,
		base_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SHUFFLE.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SHUFFLE.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SHUFFLE.CHIP_DESC_SHORT,
		huddesc = DEFAULT_SCRIPT_ABILITY.huddesc .. STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.SHUFFLE.HUD_DESC,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_shuffle_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_shuffle.png",

		main = "SLF_BASE_shuffle",
		daemonReversalAdd = 0,
		daemonReversalCooldown = 30,
		equip_program = false,
		equipped = nil,

		makeBaseDescription = function( self )
			return util.sformat(self.base_desc, round(self.daemonReversalCooldown * self.effectMod)..[[%%]])
		end,

		doEffect = function( self, sim )
			self.daemonReversalAdd = round(self.daemonReversalCooldown * self.effectMod)

			return true
        end,

        onCooldownRecovered = function( self, sim )
        	self.daemonReversalAdd = 0
    	end,
	},

	SLF_BASE_trick = util.extend( DEFAULT_SCRIPT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.TRICK.NAME,
		base_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.TRICK.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.TRICK.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.TRICK.CHIP_DESC_SHORT,
		huddesc = DEFAULT_SCRIPT_ABILITY.huddesc .. STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.TRICK.HUD_DESC,
		tip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.TRICK.TIP_DESC,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_trick_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_trick.png",

		main = "SLF_BASE_trick",
		targets = 1,
		equip_program = true,
		equipped = false,

		-- qualifier for random targeting
		targetingCriteria = function( self, sim, unit )
			-- target known devices with daemons on them
			if sim:getPC():hasSeen(unit) 
	    	and unit:getTraits().mainframe_status and unit:getTraits().mainframe_status == "active" 
	    	and unit:getTraits().mainframe_ice and unit:getTraits().mainframe_ice > 0 and
	    	(unit:getTraits().mainframe_program or sim:getHideDaemons()) then
	    		return true
		    end

		    return false
		end,

		makeBaseDescription = function( self )
			return util.sformat(self.base_desc, self.targets)
		end,

		doEffect = function( self, sim, targetUnit )
			if targetUnit:getTraits().mainframe_program == nil then
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_HUD_INCIDENT_NEGATIVE.path )
				if not self.randomTargeting then 	-- don't clog output if target happened randomly
					mission_util.showDialog( sim, STRINGS.UI.DIALOGS.NO_DAEMON_TITLE, STRINGS.UI.DIALOGS.NO_DAEMON_BODY )
				else 								-- show some floating text instead
					local x1, y1 = targetUnit:getLocation()
				    sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, {
				    	txt=STRINGS.UI.DIALOGS.NO_DAEMON_BODY,
				    	x=x1,y=y1,color={r=163/255,g=163/255,b=0,a=1},alwaysShow=true} )
				    return true
				end
			else
				targetUnit:getTraits().mainframe_program = nil
				sim:dispatchEvent( simdefs.EV_KILL_DAEMON, {unit = targetUnit})
				
				if targetUnit:getTraits().daemonHost then
					sim:getUnit(targetUnit:getTraits().daemonHost):killUnit(sim)
					targetUnit:getTraits().daemonHost =nil
				end

				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, simdefs.SOUND_DAEMON_REVEAL.path )
			end

			local programList = sim:getIcePrograms()
			local daemon = programList:getChoice( sim:nextRand( 1, programList:getTotalWeight() ))

			local x1, y1 = targetUnit:getLocation()
			sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, {
		    	txt="DAEMON KILLED",
		    	x=x1,y=y1,color={r=163/255,g=163/255,b=0,a=1},alwaysShow=true} )	
				
			sim:getNPC():addMainframeAbility( sim, daemon )

			return true 
        end,
	},

	SLF_BASE_crypto = util.extend( DEFAULT_SCRIPT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.CRYPTO.NAME,
		base_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.CRYPTO.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.CRYPTO.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.CRYPTO.CHIP_DESC_SHORT,
		huddesc = DEFAULT_SCRIPT_ABILITY.huddesc .. STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.CRYPTO.HUD_DESC,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_crypto_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_crypto.png",

		main = "SLF_BASE_crypto",
		keyGain = 1,
		equip_program = false,
		equipped = nil,

		PE_AI_required = true, -- only shows up in Hostile AI campaigns with PE

		makeBaseDescription = function( self )
			return util.sformat(self.base_desc, round(self.keyGain*self.effectMod))
		end,

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			local canUse, reason = DEFAULT_SCRIPT_ABILITY.canUseAbility( self, sim, abilityOwner, targetUnit )

			if canUse then
				if not sim:getPC():getTraits().aiTokenMax then
					return false, STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.CRYPTO.NO_AI
				end
			end

			return canUse, reason
		end,

		doEffect = function( self, sim )
			local keysToGain = round(self.keyGain * self.effectMod)

			sim:getPC():getTraits().aiToken = math.min((sim:getPC():getTraits().aiToken or 0) + keysToGain, (sim:getPC():getTraits().aiTokenMax or 0))
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_gainCPU" )

			return true
        end,
	},

	--[[SLF_BASE_counter = util.extend( DEFAULT_SCRIPT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.COUNTER.NAME,
		base_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.COUNTER.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.COUNTER.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.COUNTER.CHIP_DESC_SHORT,
		huddesc = DEFAULT_SCRIPT_ABILITY.huddesc .. STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.COUNTER.HUD_DESC,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_crypto_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_crypto.png",

		main = "SLF_BASE_counter",
		cooldownGain = 1,
		currentSub = nil,
		equip_program = false,
		equipped = nil,

		PE_AI_required = true, -- only shows up in Hostile AI campaigns with PE

		makeBaseDescription = function( self )
			return util.sformat(self.base_desc, round(self.cooldownGain*self.effectMod), (self.currentSub and self.currentSub:getName() or "None"))
		end,

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			local canUse, reason = DEFAULT_SCRIPT_ABILITY.canUseAbility( self, sim, abilityOwner, targetUnit )

			if canUse then
				local ai = sim:getNPC():hasMainframeAbility("W93_AI_assembly")
				if not ai or not sim:getPC():getTraits().aiTokenMax then
					return false, STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.COUNTER.NO_AI
				end

				local cd_present = false
				for i, sub in ipairs(ai.getAiAbilities(ai)) do
					if sub.cooldown then
						cd_present = true
					end
				end

				if not cd_present then
					return false, STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.COUNTER.NO_SUB
				end
			end

			return canUse, reason
		end,

		doEffect = function( self, sim )
			local cdToGain = round(self.cooldownGain * self.effectMod)

			-- get a hold of a random sub that has a cooldown
			local ai = sim:getNPC():hasMainframeAbility("W93_AI_assembly")
			local subs = ai.getAiAbilities(ai)
			local target = nil
			while not target do
				target = subs[sim:nextRand(1, #subs)]
				if not target.cooldown then
					target = nil
				end
			end

			target.cooldown = target.cooldown + cdToGain
			sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {
					txt=util.sformat(STRINGS.SLF.PROGRAMS.SCRIPT.COUNTER.SUCCESS_TXT,
						target.identified and target.name or "???",
						cdToGain),
					color=cdefs.COLOR_PLAYER_WARNING, 
					sound = "SpySociety/Actions/mainframe_gainCPU",
					icon=self.icon } )
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_gainCPU" )

			return true
        end,
	},]]

	SLF_BASE_flicker = util.extend( DEFAULT_SCRIPT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.FLICKER.NAME,
		base_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.FLICKER.DESC,
		tip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.FLICKER.TIP_DESC,
		ends_turn = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.FLICKER.ENDS_TURN,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.FLICKER.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.FLICKER.CHIP_DESC_SHORT,
		huddesc = DEFAULT_SCRIPT_ABILITY.huddesc .. STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.FLICKER.HUD_DESC,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_flicker_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_flicker.png",

		main = "SLF_BASE_flicker",
		range = 2,
		targets = 1,
		equipped = nil,
		equip_program = false,
		randomTargeting = false,
		suggestedSwitch = nil, -- suggestion to switch unit to this one. May be inaccurate.
		selectedAgent = nil,

		canUseAbility = function( self, sim, abilityOwner, targetUnit, fallbackTarget )
			local canUse, reason = DEFAULT_SCRIPT_ABILITY.canUseAbility( self, sim, abilityOwner, targetUnit )

			if canUse and targetUnit then
				if not targetUnit:getTraits().isAgent then 				
					return false
				end

				if targetUnit:getPlayerOwner() ~= sim:getPC() then
					return false
				end
			end

			return canUse, reason
		end,

		acquireTargets = function( self, targets, game, sim, unit )
			local anchor = self.selectedAgent or game.hud:getSelectedUnit()
			-- good devs, avert yer eyes
			self.hud = game.hud
			self.selectedAgent = anchor
			self.incomplete_execution = true
			-- having targeted, we still need to activate the program.
			-- do not incur a cooldown or Alpha restriction

			local results = {targets.flickerTarget( game, 0, sim, self, anchor )}

			if self.no_costs then
				self.equipped = true
			end

    		return unpack(results)
		end, 

		-- qualifier for random targeting
		targetingCriteria = function( self, sim, unit )
			--log:write("Received target: "..util.stringize(unit, 2))
			if not unit or not unit.getPlayerOwner then return false end
			-- target agents that can move
			if unit:getPlayerOwner() == sim:getPC() and simquery.isAgent(unit) and not unit:isKO() then
				-- ...and have at least one valid space to flicker to
				local cell = sim:getCell(unit:getLocation())
				if not cell then return false end
				local cells = {}
				cells[1] = sim:getCell(cell.x+self.range*self.effectMod, cell.y)
				cells[2] = sim:getCell(cell.x-self.range*self.effectMod, cell.y)
				cells[3] = sim:getCell(cell.x, cell.y+self.range*self.effectMod)
				cells[4] = sim:getCell(cell.x, cell.y-self.range*self.effectMod)

				--log:write(tostring(cell1).."; "..tostring(cell2).."; "..tostring(cell3).."; "..tostring(cell4))
	    		return cells[sim:nextRand(1,4)]
		    end

		    return false
		end,

		makeBaseDescription = function( self )
			return util.sformat(self.base_desc..
				(not self.randomTargeting and self.ends_turn or ""),
				self.targets,
				round(self.range*self.effectMod))
		end,

		doEffect = function( self, sim, targetUnit, userUnit, targeterData )
			--log:write("Entered doEffect")
			--log:write("targetUnit: "..util.stringize(targetUnit, 1))
			targetUnit = targeterData and sim:getUnit(targeterData[3]) or self.selectedAgent 
			--log:write("targetCell: "..util.stringize(targetCell, 1))
			if not targeterData then
				-- no target cell or unit: we targeted randomly. Make up a random valid one. There should be at least one.
				local candidates = {}
				for i, unit in pairs(sim:getPC():getUnits()) do
					if self:targetingCriteria(sim, unit) then
						table.insert(candidates, unit)
					end
				end
				targetUnit = candidates[sim:nextRand(#candidates)]

				local cell = sim:getCell(targetUnit:getLocation())
				local cells = { 
					sim:getCell(cell.x+self.range*self.effectMod, cell.y),
					sim:getCell(cell.x-self.range*self.effectMod, cell.y),
					sim:getCell(cell.x, cell.y+self.range*self.effectMod),
					sim:getCell(cell.x, cell.y-self.range*self.effectMod)
				}

				for i, cell in pairs(cells) do
					if cell then
						targeterData = { cell = cell }
						break
					end
				end
			elseif not targeterData.x then
				targeterData.cell = sim:getCell(targeterData[1], targeterData[2])
			end

			-- teleport the target to the target cell
			local startCell = sim:getCell(targetUnit:getLocation())
			sim:dispatchEvent( simdefs.EV_SCRIPT_EXIT_MAINFRAME )
			sim:dispatchEvent( simdefs.EV_OVERLOAD_VIZ, {x = startCell.x, y = startCell.y, units = nil, range = round(self.effectMod*self.range/2) } )
			sim:warpUnit(targetUnit, targeterData.cell)
			sim:dispatchEvent( simdefs.EV_OVERLOAD_VIZ, {x = targeterData.cell.x, y = targeterData.cell.y, units = nil, range = round(self.effectMod*self.range) } )
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/HitResponse/hitby_ballistic_cyborg")
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = targetUnit })

			if not self.randomTargeting then
				if self.queuedUses then
					-- schedule the end of the turn
					self.queueEndTurn = true
				else
					self.queueEndTurn = nil
					sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 120*0.65 )
					sim:endTurn()
				end
			elseif self.queueEndTurn and not self.queuedUses then
				self.queueEndTurn = nil
				sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 120*0.65 )
				sim:endTurn()
			end

			self.selectedAgent = nil
			self.incomplete_execution = false
        end,
	},

	SLF_BASE_gorge = util.extend( DEFAULT_SCRIPT_ABILITY )
	{
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.GORGE.NAME,
		base_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.GORGE.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.GORGE.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.GORGE.CHIP_DESC_SHORT,
		huddesc = DEFAULT_SCRIPT_ABILITY.huddesc .. STRINGS.SLF.PROGRAMS.SCRIPT.MAINS.GORGE.HUD_DESC,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_gorge_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_gorge.png",

		main = "SLF_BASE_gorge",
		capacityBonus = 5,

		makeBaseDescription = function( self )
			return util.sformat(self.base_desc, round(self.capacityBonus * self.effectMod))
		end,

		doEffect = function( self, sim )
			sim:getPC():getTraits().PWRmaxBouns = (sim:getPC():getTraits().PWRmaxBouns or 0) + round(self.capacityBonus * self.effectMod)

			return true
        end,

        onCooldownRecovered = function( self, sim )
        	if sim:getPC():getTraits().PWRmaxBouns then
				sim:getPC():getTraits().PWRmaxBouns = sim:getPC():getTraits().PWRmaxBouns - round(self.capacityBonus * self.effectMod)
			end
    	end,
	},

	SLF_LAUNCHER_spike = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.SPIKE.NAME,
		launcher_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.SPIKE.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.SPIKE.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.SPIKE.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_spike_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_spike.png",

		launcher = "SLF_LAUNCHER_spike",
		cpu_cost = 0,
		maxCooldown = 2,
	},

	SLF_LAUNCHER_helix = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.HELIX.NAME,
		launcher_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.HELIX.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.HELIX.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.HELIX.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_helix_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_helix.png",

		launcher = "SLF_LAUNCHER_helix",
		cpu_cost = 0,
		maxCooldown = 3,
		queuedUses = 1,

		launcher_callback = function( self, sim )
			if self.evaluation then
				self.evaluation = false
				self.randomTargeting = self.savedRandomTargeting
				self.savedRandomTargeting = nil
				self.passive = false
				return
			end
			self.evaluation = true
			self.savedRandomTargeting = self.randomTargeting
			self.randomTargeting = true
			self.passive = true

			self._sim = sim --for some reason this happens to matter now, and the previous definition there is somehow not cutting it

			self:executeAbility( sim )
			self.queuedUses = 1
		end,
	},

	SLF_LAUNCHER_forge = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.FORGE.NAME,
		launcher_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.FORGE.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.FORGE.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.FORGE.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_forge_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_forge.png",

		launcher = "SLF_LAUNCHER_forge",
		cpu_cost = 3,
		maxCooldown = 0,

		makeLauncherDescription = function( self ) -- omit the cooldown, unless it's nonzero
			-- determine resource
			local cost, cost_type = self:getOwnBaseCost()

			return util.sformat( 
				self.launcher_desc..(self.maxCooldown == 0 and "" 
					or " "..tostring(self.maxCooldown).." turn cooldown."),
				cost,
				cost_type)
		end,
	},

	SLF_LAUNCHER_load = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.LOAD.NAME,
		launcher_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.LOAD.DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.LOAD.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.LOAD.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_load_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_load.png",

		launcher = "SLF_LAUNCHER_load",
		cpu_cost = 5,
		maxCooldown = 1,
		pwrRefund = 3,

		makeLauncherDescription = function( self )
			-- determine resource
			local cost, cost_type = self:getOwnBaseCost()

			return util.sformat(self.launcher_desc, 
				cost,
				cost_type, 
				round(self.pwrRefund*self.effectMod), 
				self.maxCooldown)
		end,

		launcher_callback = function( self, sim )
			local pwrToGain = round(self.pwrRefund * self.effectMod)

			sim:getPC():addCPUs(pwrToGain)
		end,
	},

	SLF_LAUNCHER_link = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.LINK.NAME,
		launcher_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.LINK.DESC,
		cost_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.LINK.COST_DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.LINK.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.LINK.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_link_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_link.png",

		launcher = "SLF_LAUNCHER_link",
		cpu_cost = 0,
		maxCooldown = 1,
		randomTargeting = true,
		passive = true,
		evaluation = false,

		makeLauncherDescription = function( self ) -- omit the cooldown, unless it's nonzero			
			-- determine resource
			local cost, cost_type = self:getOwnBaseCost()

			return util.sformat( 
				((cost > 0) and self.cost_desc or ""),
				cost,
				cost_type)..
				self.launcher_desc
		end,

		onTrigger = function( self, sim, evType, evData )
			DEFAULT_SCRIPT_ABILITY.onTrigger( self, sim, evType, evData ) -- onCooldownRecovered fires, PWR reset 

			self.evaluation = true
			--log:write("LINK: "..tostring(evData and evData.isPC and evData:isPC())..tostring(self:canUseAbility( sim, sim:getPC() )))
			if evType == simdefs.TRG_START_TURN and evData:isPC() and self:canUseAbility( sim, sim:getPC() ) then
				--log:write("LINK TRIGGER!")
				self._sim = sim --for some reason this happens to matter now, and the previous definition there is somehow not cutting it
				self:executeAbility( sim ) -- doEffect fires, PWR set
				--log:write("LINK EXECUTE DONE!")

				local txt = string.upper(self.name.." triggers")
				-- determine resource
				local cost, cost_type, syntax_order, clr = self:getOwnBaseCost()

				local addendum = "."
				if cost > 0 then
					addendum = util.sformat(
						STRINGS.SLF.PROGRAMS.SCRIPT.AUTOMATIC_COST_PAID[syntax_order],
						cost,
						cost_type)
				end

				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {
					txt=txt..addendum,
					color=clr, 
					sound = "SpySociety/Actions/mainframe_gainCPU",
					icon=self.icon } )
			end
			self.evaluation = false
		end,
	},

	SLF_LAUNCHER_strike = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.STRIKE.NAME,
		launcher_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.STRIKE.DESC,
		cost_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.STRIKE.COST_DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.STRIKE.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.STRIKE.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_strike_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_strike.png",

		launcher = "SLF_LAUNCHER_strike",
		cpu_cost = 1,
		maxCooldown = 0,
		randomTargeting = true,
		passive = true,
		evaluation = false,

		makeLauncherDescription = function( self ) -- omit the cooldown, unless it's nonzero
			-- determine resource
			local cost, cost_type = self:getOwnBaseCost()

			return util.sformat( 
				((cost > 0) and self.cost_desc or ""),
				cost,
				cost_type)..
				self.launcher_desc
		end,

		onSpawnAbility = function( self, sim )
			DEFAULT_SCRIPT_ABILITY.onSpawnAbility( self, sim )

			sim:addTrigger( simdefs.TRG_UNIT_KO, self )
		end,

		onDespawnAbility = function( self, sim )
			DEFAULT_SCRIPT_ABILITY.onDespawnAbility( self, sim )

			sim:removeTrigger( simdefs.TRG_UNIT_KO, self )
		end,

		onTrigger = function( self, sim, evType, evData )
			DEFAULT_SCRIPT_ABILITY.onTrigger( self, sim, evType, evData )

			self.evaluation = true
			if evType == simdefs.TRG_UNIT_KO and evData.unit and evData.unit:getTraits().isGuard and evData.ticks ~= 0 and self:canUseAbility( sim, sim:getPC() ) then
				self._sim = sim --for some reason this happens to matter now, and the previous definition there is somehow not cutting it
				self.queuedUses = 2
				while self.queuedUses > 0 do
					self:executeAbility( sim )
				end

				local txt = string.upper(self.name.." triggers")
				-- determine resource
				local cost, cost_type, syntax_order, clr = self:getOwnBaseCost()

				local addendum = "."
				if cost > 0 then
					addendum = util.sformat(
						STRINGS.SLF.PROGRAMS.SCRIPT.AUTOMATIC_COST_PAID[syntax_order],
						cost,
						cost_type)
				end

				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {
					txt=txt..addendum,
					color=clr, 
					sound = "SpySociety/Actions/mainframe_gainCPU",
					icon=self.icon } )
			end
			self.evaluation = false
		end,
	},

	SLF_LAUNCHER_ward = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.WARD.NAME,
		launcher_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.WARD.DESC,
		cost_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.WARD.COST_DESC,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.WARD.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.LAUNCHERS.WARD.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_ward_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_ward.png",

		launcher = "SLF_LAUNCHER_ward",
		cpu_cost = 0,
		maxCooldown = 0,
		randomTargeting = true,
		passive = true,
		evaluation = false,

		makeLauncherDescription = function( self ) -- omit the cooldown, unless it's nonzero
			-- determine resource
			local cost, cost_type = self:getOwnBaseCost()

			return util.sformat( 
				((cost > 0) and self.cost_desc or ""),
				cost,
				cost_type)..
				self.launcher_desc
		end,

		onSpawnAbility = function( self, sim )
			DEFAULT_SCRIPT_ABILITY.onSpawnAbility( self, sim )

			sim:addTrigger( simdefs.TRG_ALARM_STATE_CHANGE, self )
		end,

		onDespawnAbility = function( self, sim )
			DEFAULT_SCRIPT_ABILITY.onDespawnAbility( self, sim )

			sim:removeTrigger( simdefs.TRG_ALARM_STATE_CHANGE, self )
		end,

		onTrigger = function( self, sim, evType, evData )
			DEFAULT_SCRIPT_ABILITY.onTrigger( self, sim, evType, evData )

			self.evaluation = true
			--log:write("eval commencing")
			local result, reason = self:canUseAbility(sim, sim:getPC())
			if evType == simdefs.TRG_ALARM_STATE_CHANGE and result then
				--log:write("eval done")
				self._sim = sim --for some reason this happens to matter now, and the previous definition there is somehow not cutting it
				self:executeAbility( sim )

				local txt = string.upper(self.name.." triggers")
				-- determine resource
				local cost, cost_type, syntax_order, clr = self:getOwnBaseCost()

				local addendum = "."
				if cost > 0 then
					addendum = util.sformat(
						STRINGS.SLF.PROGRAMS.SCRIPT.AUTOMATIC_COST_PAID[syntax_order],
						cost,
						cost_type)
				end

				sim:dispatchEvent( simdefs.EV_SHOW_WARNING, {
					txt=txt..addendum,
					color=clr, 
					sound = "SpySociety/Actions/mainframe_gainCPU",
					icon=self.icon } )
			end
			self.evaluation = false
		end,
	},

	SLF_MODULE_omega = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.OMEGA.NAME,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.OMEGA.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.OMEGA.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_omega_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_omega.png",

		module = "SLF_MODULE_omega",
		effectMod = 2,
		cpu_costAdd = 1,
		maxCooldownAdd = 1,
	},

	SLF_MODULE_alpha = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.ALPHA.NAME,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.ALPHA.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.ALPHA.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_alpha_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_alpha.png",

		module = "SLF_MODULE_alpha",
		effectMod = 3,
		cpu_cost = 0,
		maxCooldownAdd = -math.huge,
		alpha_used = false,

		pre_assembly = function( self )
			local oldExec = self.executeAbility

			self.executeAbility = function( self, ... )
				oldExec(self, ...)

				if not self.incomplete_execution then
					self.alpha_used = true
				end
			end

			local oldCanUse = self.canUseAbility

			self.canUseAbility = function( self, sim, abilityOwner, targetUnit )
				local result, reason = oldCanUse( self, sim, abilityOwner, targetUnit )

				if self.alpha_used then
					return false, STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.ALPHA.REASON
				end

				return result, reason
			end
		end,
	},

	SLF_MODULE_lite = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.LITE.NAME,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.LITE.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.LITE.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_lite_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_lite.png",

		module = "SLF_MODULE_lite",
		cpu_costAdd = -2,

		pre_assembly = function( self )
			local oldExec = self.executeAbility

			self.executeAbility = function( self, ... )
				oldExec(self, ...)

				if not self.incomplete_execution then
					-- presumably we just put the program on cooldown, so update both the max and the current ones
					self.maxCooldown = self.maxCooldown + 1
					self.cooldown = self.cooldown + 1
				end
			end
		end,
	},

	SLF_MODULE_evo = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.EVO.NAME,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.EVO.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.EVO.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_evo_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_evo.png",

		module = "SLF_MODULE_evo",
		effectMod = 0.5,

		pre_assembly = function( self )
			local oldOnSpawn = self.onSpawnAbility

			self.onSpawnAbility = function( self, sim )
				oldOnSpawn( self, sim )

				-- this one *should* be dupe-safe anyway
				if array.findIf( sim._triggers[ simdefs.TRG_ALARM_STATE_CHANGE ], function( t ) return t._obj == self end ) == nil then
					sim:addTrigger( simdefs.TRG_ALARM_STATE_CHANGE, self )
				end
			end

			local oldOnDespawn = self.onDespawnAbility

			self.onDespawnAbility = function( self, sim )
				oldOnDespawn( self, sim )

				-- this one *should* be dupe-safe anyway
				sim:removeTrigger( simdefs.TRG_ALARM_STATE_CHANGE, self )
			end

			local oldTrigger = self.onTrigger

			self.onTrigger = function( self, sim, evType, evData )
				oldTrigger(self,sim,evType,evData)

				if evType == simdefs.TRG_ALARM_STATE_CHANGE then
					self.effectMod = self.effectMod + 0.25
				end
			end
		end,
	},

	--[[SLF_MODULE_duo = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.DUO.NAME,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.DUO.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.DUO.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_duo_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_duo.png",

		module = "SLF_MODULE_duo",
		targetsMult = 2,
		randomTargeting = true,
		equip_program = false,
		equipped = nil,
	},]]

	SLF_MODULE_gold = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.GOLD.NAME,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.GOLD.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.GOLD.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_gold_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_gold.png",

		module = "SLF_MODULE_gold",

		pre_assembly = function( self )
			self.credit_cost = self.cpu_cost * 10
			self.cpu_cost = 0
		end,
	},

	SLF_MODULE_hardcore = {
		name = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.HARDCORE.NAME,
		chip_desc = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.HARDCORE.CHIP_DESC,
		chip_desc_short = STRINGS.SLF.PROGRAMS.SCRIPT.MODULES.HARDCORE.CHIP_DESC_SHORT,

		chip_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_trial_small.png",
		chip_icon_100 = "gui/icons/item_icons/icon-item_script_chip_trial.png",

		module = "SLF_MODULE_hardcore",

		pre_assembly = function( self )
			self.alarm_cost = math.ceil(self.cpu_cost / 2)
			self.cpu_cost = 0
		end,
	},
}
 

function abilitydefs.SLF_assembleMainframeScript(self, s_main, s_launcher, s_module, chronoshift)
	local newdef = {}

	for field, value in pairs(s_main) do
		newdef[field] = value
	end

	for field, value in pairs(s_launcher) do
		newdef[field] = value
	end

	local programName = s_main.name .. s_launcher.name
	local programID = programName

	if s_module then
		newdef.value = 1200 --if you've invested a module, you get more out of it
		programName = programName .. " " .. s_module.name
		programID = programID .. s_module.name

		for field, value in pairs(s_module) do
			if field == "cpu_costAdd" then
				newdef.cpu_cost = math.max(newdef.cpu_cost + value, 0)
			elseif field == "maxCooldownAdd" then
				newdef.maxCooldown = math.max(newdef.maxCooldown + value, 0)
			elseif field == "targetsMult" and newdef.targets then
				newdef.targets = round(newdef.targets * value)
			else
				newdef[field] = value
			end
		end

		if s_module.pre_assembly then
			newdef:pre_assembly()
		end
	end

	newdef.name = programName
	newdef.max_count = 1
	if chronoshift and chronoshift ~= 0 then
		-- subtle joke: doppled programs will have their first letter eaten by time corruption
		newdef.name = programName:sub(2)
	end
	-- value is cut based on amount of chronoshifted parts used
	newdef.value = newdef.value * (1 - (chronoshift or 0) / (s_module and 3 or 2) )
	--log:write("Chronocut: "..tostring(newdef.value))
	newdef.desc = newdef:makeBaseDescription()..newdef:makeLauncherDescription()

	-- Prettier Programs may have a say at this point
	if SCRIPT_PATHS.alternate_costs_framework then
		local typeHandler = include( SCRIPT_PATHS.alternate_costs_framework .. "/program_subtypes" )
		typeHandler.applyACFToProgram(newdef)
	end

	return newdef, programID
end

return script_abilities
