local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local cdefs = include( "client_defs" )
local serverdefs = include( "modules/serverdefs" )
local mainframe_common = include("sim/abilities/mainframe_common")
local abilityutil = include("sim/abilities/abilityutil")
local inventory = include("sim/inventory")
local abilitydefs = include("sim/abilitydefs")

local chip_abilities =
{
	SLF_script_setup = 	{

		name = "Chip On-Spawn", --where the heck is this shown or referenced? It's the name of the ability, not the augment; but the ability is referenced via SLF_dragon_scout
		getName = function( self, sim, unit )
			return self.name --aka, where the heck is this called?
		end,				 --in short, do I even need this section? LOL

		onSpawnAbility = function( self, sim, unit )
			-- Schysm bugfix. Differentiate the table pointer for each newly spawned chip.
			local newPtr = util.tcopy(unit:getUnitData())
			unit._unitData = newPtr
			--log:write("Chip ID "..unit:getID()..": "..tostring(unit:getUnitData()))

			if unit:getTraits().SLF_base then -- if previous data is present, restore it
				unit:getTraits().SLF_base = abilitydefs.lookupAbility(unit:getTraits().SLF_base)
            	unit:getTraits().SLF_launcher = abilitydefs.lookupAbility(unit:getTraits().SLF_launcher)
            	unit:getTraits().SLF_module = abilitydefs.lookupAbility(unit:getTraits().SLF_module)
            	unit:getUnitData().profile_icon = unit:getTraits()[unit:getTraits().SLF_chip_mode].chip_icon or unit:getUnitData().profile_icon
            	unit:getUnitData().profile_icon_100 = unit:getTraits()[unit:getTraits().SLF_chip_mode].chip_icon_100 or unit:getUnitData().profile_icon_100
            	return
			end

			-- if previous data is not there, roll a new set of it
            local script_abilities = abilitydefs.getScriptAbilities()
            local s_main, s_launcher, s_module = {}, {}, {}
            for i, ability in pairs(script_abilities) do
                if string.find(i, "SLF_BASE_") then
                	local npc_abilities = include("sim/abilities/npc_abilities")
            		if not ability.PE_AI_required or 
            			(npc_abilities["W93_AI_assembly"] and
                		sim:getNPC():hasMainframeAbility("W93_AI_assembly")) then
                    	table.insert(s_main, ability)
                    end
                elseif string.find(i, "SLF_LAUNCHER_") then
                    table.insert(s_launcher, ability)
                elseif string.find(i, "SLF_MODULE_") then
                    table.insert(s_module, ability)
                end
            end

            s_main, s_launcher, s_module = s_main[sim:nextRand(#s_main)], s_launcher[sim:nextRand(#s_launcher)], s_module[sim:nextRand(#s_module)] 

            unit:getTraits().SLF_base = s_main
            unit:getTraits().SLF_launcher = s_launcher
            unit:getTraits().SLF_module = s_module
            unit:getTraits().SLF_chip_mode = "SLF_base"
            unit:getUnitData().profile_icon = unit:getTraits()[unit:getTraits().SLF_chip_mode].chip_icon or unit:getUnitData().profile_icon
            unit:getUnitData().profile_icon_100 = unit:getTraits()[unit:getTraits().SLF_chip_mode].chip_icon_100 or unit:getUnitData().profile_icon_100
		end,

		onDespawnAbility = function( self, sim, unit )
			if unit:getTraits().SLF_compile_console then
				unit:getTraits().SLF_compile_console = nil
				chip:giveAbility("carryable")
			end
		end,
	},

	SLF_script_switch = {
		name = STRINGS.SLF.ITEMS.SCRIPT_CHIP.TIP,
		createToolTip = function( self,sim,unit,targetCell)
			return abilityutil.formatToolTip( STRINGS.SLF.ITEMS.SCRIPT_CHIP.TIP, STRINGS.SLF.ITEMS.SCRIPT_CHIP.TIP_USE_DESC )
		end,

		--profile_icon = "gui/items/icon-item_ammo.png",
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_chargeweapon_small.png",

		alwaysShow = true,

		getName = function( self, sim, unit )
			return self.name
		end,

		canUseAbility = function( self, sim, unit )
			if unit:getTraits().SLF_compilation then
				return false, STRINGS.SLF.ITEMS.SCRIPT_CHIP.CANNOT_SWITCH
			end

			return true
		end,
		
		executeAbility = function( self, sim, unit )
			if unit:getTraits().SLF_chip_mode == "SLF_base" then
		        unit:getTraits().SLF_chip_mode = "SLF_launcher"
		    elseif unit:getTraits().SLF_chip_mode == "SLF_launcher" then
		        unit:getTraits().SLF_chip_mode = "SLF_module"
		    elseif not unit:getTraits().SLF_chip_mode or unit:getTraits().SLF_chip_mode == "SLF_module" then
		        unit:getTraits().SLF_chip_mode = "SLF_base"
		    end

		    if unit:getTraits().timedupeCopiedItem and not unit._ACW_desynced then
		    	-- desynchronize Schysm-shifted chips. Do not even ask.

		    	-- (this only needs to happen once per timehop, and timehops don't 
		    	-- preserve the desynced state if it's defined not in actual traits)
		    	local newnitData = util.tcopy(unit._unitData) 
		    	unit._unitData = newnitData
		    	unit._ACW_desynced = true
		    end
            unit:getUnitData().profile_icon = unit:getTraits()[unit:getTraits().SLF_chip_mode].chip_icon or unit:getUnitData().profile_icon
            unit:getUnitData().profile_icon_100 = unit:getTraits()[unit:getTraits().SLF_chip_mode].chip_icon_100 or unit:getUnitData().profile_icon_100
		    sim:dispatchEvent( simdefs.EV_HUD_REFRESH )

		    local x1, y1 = unit:getUnitOwner():getLocation()
		    sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, {
		    	txt="Selected script: "..unit:getTraits()[unit:getTraits().SLF_chip_mode].name,
		    	x=x1,y=y1,color={r=0,g=163/255,b=163/255,a=1},alwaysShow=true} )		
	
		end
	},

	SLF_script_compile = {
		proxy = true,
		HUDpriority = -50,
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png",
		name = STRINGS.SLF.ITEMS.SCRIPT_CHIP.COMPILE,
		--iconColor= util.color( 82/255, 163/255, 0/255 ),
		--iconColorHover= util.color( 1,1,1 ),

		getName = function( self, sim, chip, abilityUser, targetUnitID )
			local targetUnit = sim:getUnit( targetUnitID )

			return self.name .. " (" .. string.upper(chip:getTraits()[chip:getTraits().SLF_chip_mode].name) .. ")"
		end,

		getProfileIcon = function( self, sim, chip )
            return chip:getUnitData().profile_icon or self.profile_icon
        end,

		onTooltip = function( self, hud, sim, owner, abilityUser, targetUnitID )
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			local canUse, reason = abilityUser:canUseAbility( sim, self, owner, targetUnitID )		
			local targetUnit = sim:getUnit( targetUnitID )
	        section:addLine( targetUnit:getName() )
			section:addAbility( 
				self:getName(sim, owner, abilityUser, targetUnitID), 
				util.sformat( STRINGS.SLF.ITEMS.SCRIPT_CHIP.COMPILE_DESC, owner:getTraits()[owner:getTraits().SLF_chip_mode].name),
				"gui/items/icon-action_hack-console.png" )
			if reason then
				section:addRequirement( reason )
			end
			return tooltip
		end,

		isTarget = function( self, chip, unit, targetUnit )
			if not targetUnit:getTraits().mainframe_console then
				return false
			end

			if targetUnit:getTraits().mainframe_status ~= "active" then
				return false
			end

			if targetUnit:getTraits().SLF_compilation then
				local c_tbl = targetUnit:getTraits().SLF_compilation
				-- chip in use; redundant, but just in case
				for i, usedChip in pairs(c_tbl["chips"]) do
					if usedChip == chip then
						--log:write("Chip already used.")
						return false
					end
				end
				-- chip in wrong mode
				if chip:getTraits().SLF_chip_mode ~= c_tbl["nextStage"] then
					--log:write("Chip not in "..c_tbl["nextStage"].." mode. ["..chip:getTraits().SLF_chip_mode.."]")
					return false
				end
			else
				-- chip in wrong mode 
				if chip:getTraits().SLF_chip_mode ~= "SLF_base" then
					--log:write("Chip not in SLF_base mode. ["..chip:getTraits().SLF_chip_mode.."]")
					return false
				end
			end

			return true
		end,

		acquireTargets = function( self, targets, game, sim, abilityOwner, unit )
			local x0, y0 = unit:getLocation()
			local units = {}
			for _, targetUnit in pairs(sim:getAllUnits()) do
				local x1, y1 = targetUnit:getLocation()
				if x1 and self:isTarget( abilityOwner, unit, targetUnit ) then
					local range = mathutil.dist2d( x0, y0, x1, y1 )
					
					-- This handles manual jacking. (heh)
					if range <= 1 and simquery.isConnected( sim, sim:getCell( x0, y0 ), sim:getCell( x1, y1 ) ) then
						table.insert( units, targetUnit )
					end
				end
			end

			return targets.unitTarget( game, units, self, abilityOwner, unit )
		end,

		canUseAbility = function( self, sim, chip, unit )
			-- This is a proxy ability, but only usable if the proxy is in the inventory of the user.
			if chip:getUnitOwner() ~= unit then
			    return false
			end

			-- Chip in use 
			if chip:getTraits().SLF_compile_console then
				--log:write("CHIP IN USE")
				return false
			end

			-- No other chip to combine with
			local found = false
			for i, child in pairs(unit:getChildren()) do
				if child:getID() ~= chip:getID() and child:getTraits().SLF_chip_mode then
					found = true
				end
			end
			if not found then return end

			--log:write("CANUSE TRUE")

			return true
		end,

		executeAbility = function( self, sim, chip, unit, targetUnitID )
			local targetUnit = sim:getUnit( targetUnitID )

			if not targetUnit:getTraits().SLF_compilation then
				local compile_table = {}
				compile_table["nextStage"] = "SLF_launcher"
				local stages = {}
				stages["SLF_base"] = chip:getTraits().SLF_base
				compile_table["stages"] = stages
				local chips = {}
				chips["SLF_base"] = chip
				compile_table["chips"] = chips
				targetUnit:getTraits().SLF_compilation = compile_table
			else
				local compile_table = targetUnit:getTraits().SLF_compilation
				local nextStage = compile_table["nextStage"]
				if nextStage then
					compile_table["stages"][nextStage] = chip:getTraits()[nextStage]
					compile_table["chips"][nextStage] = chip
					if nextStage == "SLF_launcher" then
						compile_table["nextStage"] = "SLF_module"
					else
						compile_table["nextStage"] = nil
					end
				end
				targetUnit:getTraits().SLF_compilation = compile_table
			end

			chip:getTraits().SLF_compile_console = targetUnit
			chip:removeAbility(sim, "carryable")
		end,
	},

	SLF_script_compile_finalize = {
		proxy = true,
		HUDpriority = -49,
		profile_icon = "gui/icons/action_icons/Action_icon_Small/actionicon_talk.png",
		name = STRINGS.SLF.ITEMS.SCRIPT_CHIP.COMPILE_COMPLETE,
		iconColor= util.color( 97/255, 170/255, 170/255 ), --commondefs.FLAVOUR_COLOUR
		iconColorHover= util.color( 1,1,1 ),

		getName = function( self, sim, chip, abilityUser, targetUnitID )
			local targetUnit = sim:getUnit( targetUnitID )

			return self.name
		end,

		onTooltip = function( self, hud, sim, owner, abilityUser, targetUnitID )
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			local canUse, reason = abilityUser:canUseAbility( sim, self, owner, targetUnitID )		
			local targetUnit = sim:getUnit( targetUnitID )
	        section:addLine( "Use "..owner:getName() )
			section:addAbility( 
				self:getName(sim, owner, abilityUser, targetUnitID), 
				util.sformat( 
					STRINGS.SLF.ITEMS.SCRIPT_CHIP.COMPILE_COMPLETE_DESC, 
					targetUnit:getTraits().SLF_compilation.stages.SLF_base.name,
					targetUnit:getTraits().SLF_compilation.stages.SLF_launcher.name.." ",
					(targetUnit:getTraits().SLF_compilation.stages.SLF_module and 
						targetUnit:getTraits().SLF_compilation.stages.SLF_module.name.." " or "")
					),
				"gui/items/icon-action_hack-console.png" )

			local addDoppleWarning = false
			local chips = targetUnit:getTraits().SLF_compilation["chips"]
			for i, chip in pairs(chips) do
				if chip:getTraits().isTimeDupUnit then
					addDoppleWarning = true
				end
			end
			if addDoppleWarning then
				section:addLine(STRINGS.SLF.ITEMS.SCRIPT_CHIP.COMPILE_DOPPLE_WARNING)
			end

			if reason then
				section:addRequirement( reason )
			end
			return tooltip
		end,

		isTarget = function( self, chip, unit, targetUnit )
			if not targetUnit:getTraits().mainframe_console then
				return false
			end

			if targetUnit:getTraits().mainframe_status ~= "active" then
				return false
			end

			if not targetUnit:getTraits().SLF_compilation then
				return false
			elseif targetUnit:getTraits().SLF_compilation["nextStage"] == "SLF_launcher" then
				return false
			elseif targetUnit:getTraits().SLF_compilation["complete_option_added"] 
				and targetUnit:getTraits().SLF_compilation["complete_option_added"] ~= self then
				return false
			else
				local scripts = targetUnit:getTraits().SLF_compilation["stages"]
				local programID = ""
				for i, script in pairs(scripts) do
					programID = programID .. script.name
				end

				for _, ability in ipairs( targetUnit:getSim():getPC()._mainframeAbilities ) do
					if ability:getID() == programID then
						return false
					end
				end

				targetUnit:getTraits().SLF_compilation["complete_option_added"] = self
			end

			

			return true
		end,

		acquireTargets = function( self, targets, game, sim, abilityOwner, unit )
			local x0, y0 = unit:getLocation()
			local units = {}
			for _, targetUnit in pairs(sim:getAllUnits()) do
				local x1, y1 = targetUnit:getLocation()
				if x1 and self:isTarget( abilityOwner, unit, targetUnit ) then
					local range = mathutil.dist2d( x0, y0, x1, y1 )
					
					-- This handles manual jacking. (heh)
					if range <= 1 and simquery.isConnected( sim, sim:getCell( x0, y0 ), sim:getCell( x1, y1 ) ) then
						table.insert( units, targetUnit )
					end
				end
			end

			return targets.unitTarget( game, units, self, abilityOwner, unit )
		end,

		canUseAbility = function( self, sim, chip, unit )
			-- This is a proxy ability, but only usable if the proxy is in the inventory of the user.
			if chip:getUnitOwner() ~= unit then
			    return false
			end

			-- too many programs
			-- this relies on Sim Constructor by Cyberboy2000
			local max_programs = simquery.getMaxPrograms(sim)
			local current_programs = sim:getPC():getAbilities()
			local total_spec_slots = 0
			if sim:getPC().getIncognitaFrame then
				total_spec_slots = sim:getPC():getIncognitaFrame():getTotalSpecSlots()
			end

			--[[MM compatibility. Why is this not included in the above simquery check (I mean, fair enough, not SC's job)?
			-- but in fact, why is this not just sim:getParams().agency.extraPrograms?
			if sim:getParams().agency.W93_aiTerminals then -- AFTER the ai terminal mission(s)
				max_programs = max_programs + sim:getParams().agency.W93_aiTerminals
			end
			if sim:getPC():getTraits().W93_incognitaUpgraded then -- DURING the ai terminal mission
				max_programs = max_programs + sim:getPC():getTraits().W93_incognitaUpgraded	
			end]]
			if #current_programs >= max_programs then
				return false, STRINGS.SLF.ITEMS.SCRIPT_CHIP.COMPILE_COMPLETE_TOO_MANY
			elseif #current_programs >= max_programs - total_spec_slots then
				-- It's possible that only spec slots remain
				local specSlots = sim:getPC():getIncognitaFrame().spec_programs
				local specCounts = sim:getPC():countSpecSlots()
				local needsUntypedSlot = true

				local scriptType = mainframe_common.SLF_SPECIALIZED_TYPES.SCRIPT.id
				local scriptSlot = array.findIf(specSlots, function(s) return s.type == scriptType end)
				if scriptSlot then
					-- there are slots of the right spec. Are they full?
					local scriptCount = specCounts[scriptType] or 0
					needsUntypedSlot = scriptCount >= scriptSlot.slots
				end

				if needsUntypedSlot and specCounts.EMPTY >= max_programs - total_spec_slots then
					-- if there are no available chip-specific slots, block the install
					return false, STRINGS.SLF.FRAMES.REASON_SPEC_SLOTS
				end
			end

			return true
		end,

		executeAbility = function( self, sim, chip, unit, targetUnitID )
			local targetUnit = sim:getUnit( targetUnitID )

			-- consume the chips
			local chips = targetUnit:getTraits().SLF_compilation["chips"]
			local chronoshift = 0
			for i, chip in pairs(chips) do
				chip:getTraits().SLF_compile_console = nil
				--chip:giveAbility(sim, "carryable")
				-- Schysm: Chronoshifted Scripts
				if chip:getTraits().isTimeDupUnit then
					chronoshift = chronoshift + 1
				end
				inventory.trashItem(sim, unit, chip)
			end

			local scripts = targetUnit:getTraits().SLF_compilation["stages"]

			-- make def
			local def_to_add, programID = abilitydefs:SLF_assembleMainframeScript(scripts["SLF_base"], scripts["SLF_launcher"], scripts["SLF_module"], chronoshift)
			-- add it to programdef list
			local mainframe_abilities = include("sim/abilities/mainframe_abilities")

			-- MM append: check for AI Terminal upgrades
			if SCRIPT_PATHS.more_missions then
				
			end

			mainframe_abilities[programID] = def_to_add
			-- remember that this program got added. When the save is reloaded, the def is reassembled/restored.
			local user = savefiles.getCurrentGame()
            local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
            local savedPrograms = campaign.scriptChipsAssembled or {}
            table.insert( savedPrograms, {
                SLF_base = scripts["SLF_base"] and scripts["SLF_base"].main,
                SLF_launcher = scripts["SLF_launcher"] and scripts["SLF_launcher"].launcher,
                SLF_module = scripts["SLF_module"] and scripts["SLF_module"].module,
            } )
            campaign.scriptChipsAssembled = savedPrograms
            -- instantiate the def
			local simability = include("sim/simability")
			local program = simability.create(programID)
			-- add it to the actual program list for the agency
			if program then	
				table.insert( sim:getPC()._mainframeAbilities, program )
				program:spawnAbility( sim, sim:getPC() )			
				sim:getPC():sortSpecSlots()
			end

			targetUnit:getTraits().SLF_compilation = nil

			local x1, y1 = targetUnit:getLocation()
			sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, {
		    	txt=program.name.." assembled!",
		    	x=x1,y=y1,color={r=97/255, g=170/255, b=170/255,a=1},alwaysShow=true} )	
		end,
	},

	SLF_script_compile_abort = {
		proxy = true,
		HUDpriority = -48,
		profile_icon = "gui/icons/action_icons/Action_icon_Small/actionicon_noentry.png",
		name = STRINGS.SLF.ITEMS.SCRIPT_CHIP.COMPILE_ABORT,
		iconColor = util.color( 255/255, 132/255, 17/255 ), -- commondefs.EQUIPPED_COLOUR
		iconColorHover = util.color( 1,1,1 ),

		getName = function( self, sim, chip, abilityUser, targetUnitID )
			--local targetUnit = sim:getUnit( targetUnitID )

			return self.name
		end,

		onTooltip = function( self, hud, sim, owner, abilityUser, targetUnitID )
			local tooltip = util.tooltip( hud._screen )
			local section = tooltip:addSection()
			local canUse, reason = abilityUser:canUseAbility( sim, self, owner, targetUnitID )		
			local targetUnit = sim:getUnit( targetUnitID )
	        section:addLine( targetUnit:getName() )
			section:addAbility( 
				self:getName(sim, owner, abilityUser, targetUnitID), 
				STRINGS.SLF.ITEMS.SCRIPT_CHIP.COMPILE_ABORT_DESC,
				"gui/items/icon-action_hack-console.png" )
			if reason then
				section:addRequirement( reason )
			end
			return tooltip
		end,

		isTarget = function( self, chip, unit, targetUnit )
			if not targetUnit:getTraits().mainframe_console then
				return false
			end

			if targetUnit:getTraits().mainframe_status ~= "active" then
				return false
			end

			if not targetUnit:getTraits().SLF_compilation then
				return false
			elseif targetUnit:getTraits().SLF_compilation["abort_option_added"]
				and targetUnit:getTraits().SLF_compilation["abort_option_added"] ~= self then
				return false
			else
				targetUnit:getTraits().SLF_compilation["abort_option_added"] = self
			end

			return true
		end,

		acquireTargets = function( self, targets, game, sim, abilityOwner, unit )
			local x0, y0 = unit:getLocation()
			local units = {}
			for _, targetUnit in pairs(sim:getAllUnits()) do
				local x1, y1 = targetUnit:getLocation()
				if x1 and self:isTarget( abilityOwner, unit, targetUnit ) then
					local range = mathutil.dist2d( x0, y0, x1, y1 )
					
					-- This handles manual jacking. (heh)
					if range <= 1 and simquery.isConnected( sim, sim:getCell( x0, y0 ), sim:getCell( x1, y1 ) ) then
						table.insert( units, targetUnit )
					end
				end
			end

			return targets.unitTarget( game, units, self, abilityOwner, unit )
		end,

		canUseAbility = function( self, sim, chip, unit )
			-- This is a proxy ability, but only usable if the proxy is in the inventory of the user.
			if chip:getUnitOwner() ~= unit then
			    return false
			end

			return true
		end,

		executeAbility = function( self, sim, chip, unit, targetUnitID )
			local targetUnit = sim:getUnit( targetUnitID )

			local chips = targetUnit:getTraits().SLF_compilation["chips"]
			for i, chip in pairs(chips) do
				chip:getTraits().SLF_compile_console = nil
				chip:giveAbility("carryable")
			end

			targetUnit:getTraits().SLF_compilation = nil
		end,
	},

}

return chip_abilities
