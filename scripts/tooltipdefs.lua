local util = include("modules/util")

-- AFFECTED BY VOID FIELD (GUARD & AGENT)
local t_func = function( tooltip, unit )
    local traits = unit:getTraits()

    if traits.voided then
        tooltip:addAbility( string.format(STRINGS.SLF.GUARDS.VOIDBLOCK.TOOLTIP), util.sformat(STRINGS.SLF.GUARDS.VOIDBLOCK.TOOLTIP_DESC), "gui/icons/arrow_small.png" )
    end
end

local tooltips = { 
    -- NETWORK (program)
    NetworkTooltip = {
        onGuardTooltip = function( tooltip, unit )
            local traits = unit:getTraits()

            if traits.SLF_networked then --if guard is Cyber Conscious and is tagged, they are connected to the network
                tooltip:addAbility( string.format( STRINGS.SLF.PROGRAMS.NETWORK.TOOLTIP ), util.sformat( STRINGS.SLF.PROGRAMS.NETWORK.TOOLTIP_DESC), "gui/icons/arrow_small.png" )
            end  
        end
    },
    -- SUPERUSER BASE
    MainframeTooltip = {
        onGuardTooltip = function( tooltip, unit )
            local traits = unit:getTraits()

            if traits.isMainframeGhost then
                tooltip:addAbility( string.format(STRINGS.SLF.GUARDS.MGHOST.TOOLTIP), util.sformat(STRINGS.SLF.GUARDS.MGHOST.TOOLTIP_DESC), "gui/icons/arrow_small.png" )
            end
        end
    },
    -- UNALERTABLE
    HyperfocusedTooltip = {
        onGuardTooltip = function( tooltip, unit )
            local traits = unit:getTraits()

            if traits.innervate then
                tooltip:addAbility( string.format(STRINGS.SLF.GUARDS.HYPERFOCUS.TOOLTIP), util.sformat(STRINGS.SLF.GUARDS.HYPERFOCUS.TOOLTIP_DESC), "gui/icons/arrow_small.png" )
            end
        end
    },
    -- VOID FIELD EMITTER
    VoidEmitterTooltip = {
        onGuardTooltip = function( tooltip, unit )
            local traits = unit:getTraits()

            if traits.voidFieldRange then
                tooltip:addAbility( string.format(STRINGS.SLF.GUARDS.VOIDFIELD.TOOLTIP), util.sformat(STRINGS.SLF.GUARDS.VOIDFIELD.TOOLTIP_DESC, traits.voidFieldRange), "gui/icons/arrow_small.png" )
            end
        end
    },
    VoidedTooltip = {
        onGuardTooltip = t_func,
        onAgentTooltip = t_func
    },
    -- FADING/FRAIL (DRAGON)
    GhostTooltip = {
        onAgentTooltip = function( tooltip, unit )
            if unit:hasAbility("SLF_persist") then
                if unit:getTraits().fadeTimer then
                    tooltip:addAbility( string.format( STRINGS.SLF.ABILITIES.PERSIST.TOOLTIP_EFFECTIVE ), util.sformat( STRINGS.SLF.ABILITIES.PERSIST.TOOLTIP_DESC_EFFECTIVE), "gui/icons/thought_icons/status_run.png" )
                else
                    tooltip:addAbility( string.format( STRINGS.SLF.ABILITIES.PERSIST.TOOLTIP ), util.sformat( STRINGS.SLF.ABILITIES.PERSIST.TOOLTIP_DESC), "gui/icons/thought_icons/status_run.png" )
                end
            end
            if unit:getTraits().acw_anchor then
                if unit:getTraits().acw_gc then
                    tooltip:addAbility( string.format( STRINGS.SLF.ABILITIES.PROJECT.TOOLTIP_EFFECTIVE ), util.sformat( STRINGS.SLF.ABILITIES.PROJECT.TOOLTIP_DESC_EFFECTIVE), "gui/icons/thought_icons/status_run.png" )
                else
                    tooltip:addAbility( string.format( STRINGS.SLF.ABILITIES.PROJECT.TOOLTIP ), util.sformat( STRINGS.SLF.ABILITIES.PROJECT.TOOLTIP_DESC), "gui/icons/thought_icons/status_run.png" )
                end
            end
        end
    },
    -- UNIFORM (DAEMON)
    UniformTooltip = {
        onGuardTooltip = function(tooltip, unit)
            if unit:getTraits().acw_uniform then
                tooltip:addAbility( string.format(STRINGS.SLF.DAEMONS.UNIFORM.TOOLTIP), util.sformat(STRINGS.SLF.DAEMONS.UNIFORM.TOOLTIP_DESC), "gui/icons/arrow_small.png" )
            end
        end
    },
    -- PROMPT (DAEMON)
    PromptTooltip = {
        onConsoleTooltip = function(tooltip, unit)
            local daemon = unit:getSim():getNPC():hasAbility("SLF_prompt")

            if daemon and daemon.tax then
                tooltip:addAbility( string.format(STRINGS.SLF.DAEMONS.PROMPT.TOOLTIP), util.sformat(STRINGS.SLF.DAEMONS.UNIFORM.PROMPT_DESC, daemon.tax), "gui/icons/arrow_small.png" )
            end
        end
    },
    -- DJUPSTAD (GRID)
    DjupstadTooltip = {
         onAgentTooltip = function( tooltip, unit )
            if unit.getModifiers and unit:getModifiers():has("mpMax","ACW_djupstad") then
                tooltip:addAbility( STRINGS.SLF.SITREPS.DJUPSTAD.NAME..STRINGS.SLF.SITREPS.GRID_DEFAULT, STRINGS.SLF.SITREPS.DJUPSTAD.AFFECTED, "gui/icons/arrow_small.png" )
            end  
        end
    },
}

return tooltips