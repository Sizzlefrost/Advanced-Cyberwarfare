---------------------------------------------------------------------
-- Invisible Inc. mod.
--
-- The function is responsible for initializing the mod and doing whatever
-- the mod needs to do up front.
--

-- reminder for future sizzle: do not leave includes in this scope
-- beyond init or load
-- otherwise bad things will happen to any translations while this mod is installed
-- because the includes fire before initStrings

-- util should be fine, as it doesn't have any strings or includes with strings
local util = include( "modules/util" )


local function appendUI( modApi, UI_inserts, UI_mods, optName )
    --log:write("[ACW-LOAD] APPEND ENTER IN")
    local inserts, mods = {}, {}
    for i, UI_insert in pairs(UI_inserts) do
        if UI_insert.opt and UI_insert.opt == optName then
            log:write(string.format("[ACW-LOAD] Adding UI element <%s> as part of <%s>",(UI_insert[3].name or "nameless"),UI_insert.opt))
            table.insert(inserts, UI_insert)

            -- for some reason the game expects all UI to use the vanilla STRINGS.SCREENS space
            -- else it throws a warning that, for the sake of avoiding logspam, this bit of code bypasses

            -- we create a dummy string and put it where the game expects
            -- default (error) strings have an ACW prefix because the indexing is terribly unfortunate
            -- and searches STRINGS.SCREENS[locstr], directly with an index of string contents
            for i, cont in pairs(UI_insert) do
                if type(cont) == type({}) and cont.str then
                    STRINGS.SCREENS[cont.str] = "dummy"
                end
            end
        end
    end
    for i, UI_mod in pairs(UI_mods) do
        if UI_mod.opt and UI_mod.opt == optName then
            log:write(string.format("[ACW-LOAD] Adding UI modification <%s> as part of <%s>",(UI_mod[3].name or "nameless"),UI_mod.opt))
            table.insert(mods, UI_mod)
        end
    end

    modApi:insertUIElements( inserts )
    modApi:modifyUIElements( mods )

    --log:write("[ACW-LOAD] APPEND EXIT IN")
end

-- init will be called once
local function init( modApi )
    local simdefs = include( "sim/simdefs" )
   
    local dataPath = modApi:getDataPath()
    local scriptPath = modApi:getScriptPath()

    rawset(_G,"SCRIPT_PATHS",rawget(_G,"SCRIPT_PATHS") or {})
    SCRIPT_PATHS.advanced_cyberwarfare = scriptPath 
    
    KLEIResourceMgr.MountPackage( dataPath .. "/gui.kwad", "data" )
    KLEIResourceMgr.MountPackage( dataPath .. "/anims.kwad", "data" )
    modApi.requirements = { "Sim Constructor", "Contingency Plan", "Function Library", "Programs Extended" }
    include( scriptPath .. "/guards/brains" )

    modApi:addGenerationOption("ac_dragon", STRINGS.SLF.OPTIONS.ENABLE_DRAGON , STRINGS.SLF.OPTIONS.ENABLE_DRAGON_TIP, {
            noUpdate = true, 
            enabled = true,
            masks = {
                {mask = "ac_dragon_enabled", requirement = true}
            }
    } )
    modApi:addGenerationOption("ac_dragon_extraction_timer", STRINGS.SLF.OPTIONS.DRAGON_TIMER_LENGTH , STRINGS.SLF.OPTIONS.DRAGON_TIMER_LENGTH_TIP, {
            noUpdate=true,
            values = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,-1},
            strings = STRINGS.SLF.OPTIONS.DRAGON_TIMER_LENGTH_STRINGS,
            value = 8,
            difficulties = {
                {simdefs.NORMAL_DIFFICULTY, 8},
                {simdefs.EXPERIENCED_DIFFICULTY, 6},
                {simdefs.HARD_DIFFICULTY, 5},
                {simdefs.VERY_HARD_DIFFICULTY, 4},
                {simdefs.ENDLESS_DIFFICULTY, 5},
                {simdefs.ENDLESS_PLUS_DIFFICULTY, 4},
                {simdefs.TIME_ATTACK_DIFFICULTY, 6}
            },
            masks = {
                {mask = "ac_dragon_extract", raw = true}
            },
            requirements = {
                {mask = "ac_dragon_enabled", requirement = true}
            }
        } )
    modApi:addGenerationOption("ac_dragon_extraction_alarm", STRINGS.SLF.OPTIONS.DRAGON_TIMER_ALARM , STRINGS.SLF.OPTIONS.DRAGON_TIMER_ALARM_TIP, {
            noUpdate=true,
            values = {-1,0,1,2,3,4,5,6},
            strings = STRINGS.SLF.OPTIONS.DRAGON_TIMER_ALARM_STRINGS,
            value = -1,
            difficulties = {
                {simdefs.NORMAL_DIFFICULTY, -1},
                {simdefs.EXPERIENCED_DIFFICULTY, -1},
                {simdefs.HARD_DIFFICULTY, -1},
                {simdefs.VERY_HARD_DIFFICULTY, -1},
                {simdefs.ENDLESS_DIFFICULTY, -1},
                {simdefs.ENDLESS_PLUS_DIFFICULTY, -1},
                {simdefs.TIME_ATTACK_DIFFICULTY, -1}
            },
            requirements = {
                {passFunction = 
                    function(masks)
                        return masks.ac_dragon_enabled and (not masks.mask_extended_alarms or masks.mask_extended_alarms == 0) and masks.ac_dragon_extract and masks.ac_dragon_extract > 0
                    end
                }
            },
        } )
    modApi:addGenerationOption("ac_dragon_extraction_alarm_pe", STRINGS.SLF.OPTIONS.DRAGON_TIMER_ALARM , STRINGS.SLF.OPTIONS.DRAGON_TIMER_ALARM_TIP, {
            noUpdate=true,
            values = {-1,0,1,2,3,4,5,6,7,8},
            strings = STRINGS.SLF.OPTIONS.DRAGON_TIMER_ALARM_STRINGS_PE,
            value = -1,
            difficulties = {
                {simdefs.NORMAL_DIFFICULTY, -1},
                {simdefs.EXPERIENCED_DIFFICULTY, -1},
                {simdefs.HARD_DIFFICULTY, -1},
                {simdefs.VERY_HARD_DIFFICULTY, -1},
                {simdefs.ENDLESS_DIFFICULTY, -1},
                {simdefs.ENDLESS_PLUS_DIFFICULTY, -1},
                {simdefs.TIME_ATTACK_DIFFICULTY, -1}
            },
            requirements = {
                {passFunction = 
                    function(masks)
                        return masks.ac_dragon_enabled and masks.mask_extended_alarms and masks.mask_extended_alarms ~= 0 and masks.ac_dragon_extract and masks.ac_dragon_extract > 0
                    end
                }
            }
        } )
    modApi:addGenerationOption("ac_chips", STRINGS.SLF.OPTIONS.ENABLE_CHIPS , STRINGS.SLF.OPTIONS.ENABLE_CHIPS_TIP, {
            noUpdate = true, 
            enabled = true,
    } )
    modApi:addGenerationOption("ac_items", STRINGS.SLF.OPTIONS.ENABLE_ITEMS , STRINGS.SLF.OPTIONS.ENABLE_ITEMS_TIP, {noUpdate=true, enabled = false})
    modApi:addGenerationOption("ac_daemons", STRINGS.SLF.OPTIONS.ENABLE_DAEMONS , STRINGS.SLF.OPTIONS.ENABLE_DAEMONS_TIP, {
            noUpdate=true, 
            enabled = true, 
            difficulties = {{simdefs.NORMAL_DIFFICULTY, true}},
            masks = {
                {mask = "ac_daemons", requirement = true},
            }
        } )
        --[[{
        values = {0,1}, 
        strings = STRINGS.SLF.OPTIONS.ENABLE_DAEMONS_STRINGS, 
        value= 0,
        noUpdate = true,
    })]]--
    modApi:addGenerationOption("ac_mask_hardmode", STRINGS.SLF.OPTIONS.ENABLE_HARD_MASK , STRINGS.SLF.OPTIONS.ENABLE_HARD_MASK_TIP, {
            noUpdate=true, 
            enabled = true, 
            difficulties = {{simdefs.NORMAL_DIFFICULTY, false}}, 
            requirements = {
                {mask = "ac_daemons", requirement = true}
            },
        } )
    modApi:addGenerationOption("ac_programs", STRINGS.SLF.OPTIONS.ENABLE_PROGRAMS , STRINGS.SLF.OPTIONS.ENABLE_PROGRAMS_TIP, {noUpdate=true, enabled = true})
        --[[{
        values = {0,1},  
        strings = STRINGS.SLF.OPTIONS.ENABLE_PROGRAMS_STRINGS, 
        value= 0,
        noUpdate = true,
    })]]--
    modApi:addGenerationOption("ac_sitreps", STRINGS.SLF.OPTIONS.ENABLE_SITREPS , STRINGS.SLF.OPTIONS.ENABLE_SITREPS_TIP , {
            noUpdate = true, 
            values = {0, 0.2, 0.4, 0.6, 0.8, 1},
            strings = STRINGS.SLF.OPTIONS.ENABLE_SITREPS_CHANCE_STRINGS,
            value = 0.4,
            masks = {
                {mask = "ac_sitreps", raw = true}
            },
        })
    modApi:addGenerationOption("ac_sitreps_mid1", STRINGS.SLF.OPTIONS.ENABLE_SITREPS_MID1 , STRINGS.SLF.OPTIONS.ENABLE_SITREPS_MID1_TIP, {
            noUpdate=true,
            enabled = true,
            requirements = {
                {passFunction = 
                    function(masks)
                        return masks.ac_sitreps and masks.ac_sitreps > 0
                    end
                }
            }
        })
    modApi:addGenerationOption("ac_frames", STRINGS.SLF.OPTIONS.ENABLE_CONSOLES, STRINGS.SLF.OPTIONS.ENABLE_CONSOLES_TIP, {
            noUpdate = true,
            enabled = true,
    })
    
    util.tmerge( STRINGS.LOADING_TIPS, STRINGS.SLF.LOADING_TIPS  ) --add new loading screen tooltips
end

-- load may be called multiple times with different options enabled
local function load( modApi, options, params )

    local scriptPath = modApi:getScriptPath()

    local UI_inserts = include( scriptPath.."/screen_inserts" )
    local UI_mods = include( scriptPath.."/screen_modifications" )

    --GRIDS/SITREPS
    if options["ac_sitreps"] and options["ac_sitreps"].value ~= 0 then
        include( scriptPath.."/sitreps/appends" )
        appendUI( modApi, UI_inserts, UI_mods, "ac_sitreps" )
    end
    
--    local commondefs = include( scriptPath .. "/commondefs" )
--    modApi:addTooltipDef( commondefs )
    
    --PROGRAMS
    if options["ac_programs"] and options["ac_programs"].enabled then
        local mainframe_abilities = include( scriptPath.."/mainframe_abilities" )
        local mainframe_common = include(scriptPath.."/mainframe_common")
        for name, ability in pairs(mainframe_abilities) do
            modApi:addMainframeAbility( name, ability )
        end
        -- alternate costs
        --include( scriptPath.."/alt_mainframe_resources" )
    end
    --DAEMONS & ALGORITHMS
    if options["ac_daemons"] and options["ac_daemons"].enabled then
        local npc_abilities = include( scriptPath .. "/npc_abilities" )
        for name, ability in pairs(npc_abilities) do
            modApi:addDaemonAbility( name, ability )
        end   
    end

    if options["ac_items"] and options["ac_items"].enabled then
        local itemdefs = include( scriptPath .. "/itemdefs" ) --add ITEMDEFS
        for name, item in pairs(itemdefs) do
            modApi:addItemDef( name, item )
        end
    end

    --MAINFRAME GUARDS/SUPERUSERS
    --[[if options["ac_guards"] and options["ac_guards"].enabled then
        local guarddefs = include( scriptPath .. "/guards/guarddefs" ) --add GUARDDEFS
        for name, guard in pairs(guarddefs) do
            modApi:addGuardDef( name, guard )
        end

        local abilitydefs = include( "sim/abilitydefs" )
        local guard_abilitydefs = include( scriptPath .. "/guards/guard_abilitydefs")
        for name, def in pairs(guard_abilitydefs) do
            abilitydefs._abilities[ name ] = def
        end
    end]]

    if options["ac_chips"] and options["ac_chips"].enabled then
        -- flicker targeter
        include( scriptPath.."/targeting" )
        -- alternate costs
        --include( scriptPath.."/alt_mainframe_resources" )
        local mainframe_common = include(scriptPath.."/mainframe_common")

        local scriptdefs = include( scriptPath.."/script_programs/scripted_mainframe_abilities")
        local abilitydefs = include( "sim/abilitydefs" )
        local oldLookup = abilitydefs.lookupAbility
        function abilitydefs.lookupAbility( abilityID )
            return oldLookup(abilityID) or scriptdefs[abilityID]
        end
        function abilitydefs.getScriptAbilities()
            return scriptdefs
        end
        
        local itemdefs = include( scriptPath.."/script_programs/itemdefs")
        for name, itemdef in pairs(itemdefs) do
            modApi:addItemDef(name, itemdef)
        end
        local ACW_abilitydefs = include( scriptPath.."/script_programs/chip_abilitydefs")
        for name, abilitydef in pairs(ACW_abilitydefs) do
            abilitydefs._abilities[name] = abilitydef
        end

        -- for mid-campaign loads. We add new defs during the campaign; they are lost when the mod is unloaded; this restores them
        local user = savefiles.getCurrentGame()
        local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
        local mainframe_abilities = include( "sim/abilities/mainframe_abilities" )  
        if campaign and campaign.scriptChipsAssembled then
            for i, scriptName in pairs(campaign.scriptChipsAssembled) do
                local def_to_add, programID = abilitydefs:SLF_assembleMainframeScript(
                    scriptdefs[scriptName["SLF_base"]], 
                    scriptdefs[scriptName["SLF_launcher"]], 
                    scriptdefs[scriptName["SLF_module"]]
                    )
                modApi:addMainframeAbility(programID, def_to_add)
            end
        end
    end

    -- cleaned up, should be safe outside the genoption
    include(scriptPath.."/frames/console_view")
    -- likewise, secure
    local frames = include(scriptPath.."/frames/framedefs")
    if params then
        params.ACW_frames_enabled = options["ac_frames"] and options['ac_frames'].enabled
    end
    if options["ac_frames"] and options["ac_frames"].enabled then
        local mainframe_common = include(scriptPath.."/mainframe_common")
        appendUI( modApi, UI_inserts, UI_mods, "ac_frames" )
        modApi:addAbilityDef("SLF_install_framework", scriptPath.."/frames/install_frame")
        include(scriptPath.."/frames/hud")
        local basedef = include(scriptPath.."/frames/itemdefs")
        include(scriptPath.."/frames/store_append")
        local simdefs = include("sim/simdefs")
        simdefs.frame_itemdefs = {}
        local itemdefs = {}
        for id, frame in pairs(frames) do
            local newdef = util.extend(basedef){
                name = util.sformat(basedef.name, util.tolower(frame.name):gsub(" ","_")),
                value = frame.value or basedef.value,
                floorWeight = frame.floorWeight or basedef.floorWeight,
                soldAfter = frame.soldAfter or basedef.soldAfter,
                notSoldAfter = frame.notSoldAfter or basedef.notSoldAfter,
            }
            newdef.traits["SLF_incogFrame"] = frame.name

            --log:write("[ACW-FRAMELOAD] Creating def SLF_frame_"..id.." / "..newdef.name)
            local allowed = false
            if frame.dependency then
                local optName = frame.dependency.option
                local modName = frame.dependency.mod -- can be nil

                -- get the mod
                local modManager, modID = modApi.mod_manager, modApi.mod_id -- by default, this mod
                if modName then
                    for i, mod in pairs(modManager.mods) do
                        if mod.name == modName then
                            -- first mod that matches the name counts
                            -- technically, unsafe in case modinfo gets overwritten, but what are you going to do
                            modID = mod.id
                        end
                    end
                end

                -- get the option's status
                if modManager:isDLCOptionEnabled(modID,optName) then
                    allowed = true
                end
            else
            	-- no dependencies
            	allowed = true
            end

            if allowed then
                itemdefs["SLF_frame_"..id] = newdef
                if not frame.do_not_sell then
                   simdefs.frame_itemdefs["SLF_frame_"..id] = newdef
                end
            end
        end

        for name, item in pairs(itemdefs) do
            modApi:addItemDef( name, item )
        end
    end

    local serverdefs = include( scriptPath .. "/serverdefs" )
    --STARTING PROGRAMS
    if serverdefs.SELECTABLE_PROGRAMS then   
        if options["ac_programs"] and options["ac_programs"].enabled then 
            for i,program in ipairs(serverdefs.SELECTABLE_PROGRAMS[1]) do 
                modApi:addStartingGenerator( program )      
            end
            for i,program in ipairs(serverdefs.SELECTABLE_PROGRAMS[2]) do 
                modApi:addStartingBreaker( program )
            end   
        end
    end

    -- a global inclusion that doesn't depend on options is bad,
    -- but this one *should* have no side effects and is required for both Dragon and bioroids
    include(scriptPath .."/mainframe_ghost")
    -- defines what a "mainframe ghost" unit does, how it differs from a normal unit
    include(scriptPath .."/cdefs")

    --PILE OF DRAGON: Augment defs, augment item defs, ability defs, program defs, anim defs and agent defs
    if options["ac_dragon"] and options["ac_dragon"].enabled then
        --add SPECIAL DRAGON VIEW
        include(scriptPath .."/dragon/cyberspace_view") -- a view override stolen from Qoala
        --add ITEMDEFS (augments)
        local itemdefs = include( scriptPath .. "/dragon/augments" )                    --There's just two augments there; on-file is a dummy one
        for name, item in pairs(itemdefs) do                                            --Archive actually does things, adds the ability
            modApi:addItemDef( name, item )
        end
        --add ABILITYDEFS (the actual things the augments do)
        modApi:addAbilityDef( "SLF_ghostForm" , scriptPath .. "/dragon/onfile_ghost")       --Ghost is Program Form and handles intangibility and passive things
        modApi:addAbilityDef( "SLF_dragon_scout" , scriptPath .. "/dragon/archive_scout")   --Scout is the archive augment ability, handles the program form pre-alarm 1
        --modApi:addAbilityDef( "SLF_dragon_ephemeral" , scriptPath .. "/dragon/archive_ephemeral")   --Ephemeral is the archive ability, making Dragon disappear unless summoned via Projector
        --modApi:addAbilityDef( "SLF_dragon_project" , scriptPath .. "/dragon/archive_project")   --Projector is the archive ability, handling the logic to project Dragon from her Anchor
        --modApi:addAbilityDef( "SLF_dragon_succulent" , scriptPath .. "/dragon/archive_dependency")   --Succulent is the archive ability, handling the logic to despawn Dragon out of LoS
        modApi:addAbilityDef( "SLF_persist" , scriptPath .. "/dragon/onfile_fade")          --Fade is the Frail ability, handles what happens when Dragon is alone in the field
        modApi:addAbilityDef( "SLF_possess" , scriptPath .. "/dragon/onfile_possess")       --Possess is the ability to control mainframe devices
        modApi:addAbilityDef( "SLF_burnout" , scriptPath .. "/dragon/onfile_burnout")       --Burnout is the ability to revive agents with disrupters
        --add AGENTDEFS (Dragon proper)
        local agentdefs = include( scriptPath .. "/dragon/agentdefs" )                  --serverdefs are checked here too
        local serverdefs = include( "modules/serverdefs" )                              --this is to merge the on-file and archive versions into a single agent
        
        --insert NULLBLOCK ability
        modApi:addAbilityDef( "SLF_nullblock" , scriptPath .. "/dragon/onfile_nullblock") --Nullblock prevents Dragon from entering Null Zones.
        table.insert(agentdefs.SLF_dragon.abilities, "SLF_nullblock")

        for name, agentDef in pairs(agentdefs) do
            modApi:addAgentDef( name, agentDef )
        end
        table.insert( serverdefs.SELECTABLE_AGENTS, "SLF_dragon" )
        serverdefs.LOADOUTS[ "SLF_dragon" ] = { "SLF_dragon","SLF_dragon_a" }
        --add PROGRAM (Dragon's Assistance)
        local mainframe_abilities = include( scriptPath .. "/dragon/archive_program" )  --Not much to say, this adds the program
        for name, ability in pairs(mainframe_abilities) do                              --which archive Dragon turns into pre-alarm 1
            modApi:addMainframeAbility( name, ability )
        end
        --add ANIMDEFS
        for k, v in pairs(include( scriptPath .. "/dragon/animdefs" )) do               --animations are here. They reference anims.kwad
            modApi:addAnimDef( k, v )                                                   --fair warning, gui.kwad is referenced from a lot of places in the mod
        end                                                                             --so if you mess with them, you can touch anims but not gui
        --add SKILLDEFS
        local acw_skilldefs = include( scriptPath .. "/dragon/skilldefs" )
        local skilldefs_vanilla = include("sim/skilldefs")
        local lookup_old = skilldefs_vanilla.lookupSkill
        function skilldefs_vanilla.lookupSkill( skillID, ... )
            local skill = lookup_old( skillID, ... )

            if acw_skilldefs and not skill then
                for name, def in pairs(acw_skilldefs) do
                    if name == skillID then
                        return def
                    end
                end
            end

            return skill
        end

        local dragonbanter= include( scriptPath.."/dragon/banter" )                      --Banter here. Oneliners are in strings, instead.
        for i,  banter in pairs( dragonbanter ) do                                      --for the purpose of banter-writing, the Dragon Agent ID is "SLF_dragon"
                modApi:addBanter( banter )
        end
    end

    local tooltipdefs = include( scriptPath.."/tooltipdefs" )
    for i, tooltip in pairs(tooltipdefs) do
        modApi:addTooltipDef( tooltip )
    end
end

-- gets called before localization occurs and before content is loaded
local function initStrings( modApi )
    local dataPath = modApi:getDataPath()
    local scriptPath = modApi:getScriptPath()

    local DLC_STRINGS = include( scriptPath .. "/strings" )
    modApi:addStrings( dataPath, "SLF", DLC_STRINGS )    
end

return {
    init = init,
    load = load,
    initStrings = initStrings,
}
