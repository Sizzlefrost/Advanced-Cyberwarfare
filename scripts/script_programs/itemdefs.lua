local util = include( "modules/util" )
local commondefs = include( "sim/unitdefs/commondefs" )
local simquery = include( "sim/simquery" )

local mission_util = include("sim/missions/mission_util")
local itemdefs = include("sim/unitdefs/itemdefs")
local simfactory = include("sim/simfactory")
local abilitydefs = include("sim/abilitydefs")

local oldConnect = mission_util.makeAgentConnection

mission_util.makeAgentConnection = function(script, sim, ...)
    oldConnect(script, sim, ...)

    local safes = {}
    for i, safe in pairs(sim:getAllUnits()) do
        if safe:getTraits().safeUnit and safe:getUnitData().lootTable then
            table.insert(safes, safe)
        end
    end

    if #safes > 0 then
        local safe = safes[ sim:nextRand( 1, #safes ) ]

        local item = itemdefs["SLF_script_chip"]
        if not item then return end
        local newItem = simfactory.createUnit( item, sim )
        sim:spawnUnit( newItem )
        safe:addChild( newItem )
    end
end

local onChipTooltip = function(tooltip, unit, userUnit)
    local name = util.toupper( unit:getName() )

    tooltip:addLine( "<ttheader>"..name.."</>" )
    
    if unit:getUnitData().flavor then
        tooltip:addDesc( "<c:61AAAA>"..unit:getUnitData().flavor.."</>" )
    end 

    local n_base, n_launcher, n_module = nil, nil, nil
    local d_base, d_launcher, d_module = nil, nil, nil
    local s_name, s_desc = nil, nil
    if unit:getTraits().SLF_base and unit:getTraits().SLF_base.name then
        n_base, n_launcher, n_module = unit:getTraits().SLF_base.name, unit:getTraits().SLF_launcher.name, unit:getTraits().SLF_module.name
        d_base, d_launcher, d_module = unit:getTraits().SLF_base.chip_desc_short, unit:getTraits().SLF_launcher.chip_desc_short, unit:getTraits().SLF_module.chip_desc_short
        s_desc = unit:getTraits()[unit:getTraits().SLF_chip_mode].chip_desc
    elseif not unit:getTraits().SLF_base.name then
        local def_base, def_launcher, def_module = abilitydefs.lookupAbility(unit:getTraits().SLF_base), abilitydefs.lookupAbility(unit:getTraits().SLF_launcher), abilitydefs.lookupAbility(unit:getTraits().SLF_module)
        n_base, n_launcher, n_module = def_base.name, def_launcher.name, def_module.name
        d_base, d_launcher, d_module = def_base.chip_desc_short, def_launcher.chip_desc_short, def_module.chip_desc_short
        s_desc = abilitydefs.lookupAbility(unit:getTraits()[unit:getTraits().SLF_chip_mode]).chip_desc
    end

    if unit:getUnitData().desc then
        local appends = {"<c:61AAAA>", "<c:61AAAA>", "<c:61AAAA>"}
        if unit:getTraits().SLF_chip_mode == "SLF_base" then
            appends = {"> <c:F4FF78>", "<c:61AAAA>", "<c:61AAAA>"}
        elseif unit:getTraits().SLF_chip_mode == "SLF_launcher" then
            appends = {"<c:61AAAA>", "> <c:F4FF78>", "<c:61AAAA>"}
        elseif unit:getTraits().SLF_chip_mode == "SLF_module" then
            appends = {"<c:61AAAA>", "<c:61AAAA>", "> <c:F4FF78>"}
        end

        local desc = unit:getUnitData().desc

        if n_base and d_base then
            desc = desc .. "\n\n" .. appends[1] .. n_base .. " (Payload)\n" .. d_base .."</c>" 
        end
        if n_launcher and d_launcher then
            desc = desc .. "\n" .. appends[2] .. n_launcher .. " (Launcher)\n" .. d_launcher .."</c>"
        end
        if n_module and d_module then
            desc = desc .. "\n" .. appends[3] .. n_module .. " (Module)\n" .. d_module .."</c>"
        end
        tooltip:addDesc(desc)
        tooltip:addAbility(
                "PAYLOAD SCRIPTS",
                "Payloads contain program functions and effects.",
                "gui/icons/arrow_small.png"
            )
        tooltip:addAbility(
                "LAUNCHER SCRIPTS",
                "Launchers contain program costs and trigger circumstances.",
                "gui/icons/arrow_small.png"
            )
        tooltip:addAbility(
                "MODULE SCRIPTS",
                "Modules are optional program modifiers.",
                "gui/icons/arrow_small.png"
            )
    end
    tooltip:addAbility(
        STRINGS.SLF.ITEMS.SCRIPT_CHIP.TIP,
        STRINGS.SLF.ITEMS.SCRIPT_CHIP.TIP_DESC,
        "gui/icons/arrow_small.png"
    )

    if unit:getTraits().SLF_chip_mode == "SLF_base" then
        s_name = string.upper(n_base)
    elseif unit:getTraits().SLF_chip_mode == "SLF_launcher" then
        s_name = string.upper(n_launcher)
    elseif unit:getTraits().SLF_chip_mode == "SLF_module" then
        s_name = string.upper(n_module)
    end
    if s_name then
        tooltip:addAbility(
            "SELECTED: " .. s_name,
            "<c:F4FF78>" .. s_desc .. "</c>",
            "gui/icons/arrow_small.png"
        )
    end

    if unit:getTraits().SLF_compile_console then
        tooltip:addAbility(
            STRINGS.SLF.ITEMS.SCRIPT_CHIP.CHIP_USED,
            STRINGS.SLF.ITEMS.SCRIPT_CHIP.CHIP_USED_DESC,
            "gui/icons/arrow_small.png"
        )
    end

    if unit:getTraits().dlcFooter then
        tooltip:addFooter( unit:getTraits().dlcFooter[1],unit:getTraits().dlcFooter[2] )
    end
end

local itemdefs = 
{
    SLF_script_chip = util.extend(commondefs.item_template)
    {
        name = STRINGS.SLF.ITEMS.SCRIPT_CHIP.NAME,
        desc = STRINGS.SLF.ITEMS.SCRIPT_CHIP.DESC,
        desc_extra = STRINGS.SLF.ITEMS.SCRIPT_CHIP.DESC_EXTRA,
        flavor = STRINGS.SLF.ITEMS.SCRIPT_CHIP.FLAVOR,
        icon = "itemrigs/FloorProp_AmmoClip.png",
        profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_script_chip_small_module.png",
        profile_icon_100 = "gui/icons/item_icons/icon-item_script_chip_module.png",
        traits = { 
            SLF_base = nil,
            SLF_launcher = nil,
            SLF_module = nil,
            SLF_chip_mode = nil,
        },
        abilities = { "carryable", "SLF_script_setup", "SLF_script_switch", "SLF_script_compile", "SLF_script_compile_finalize", "SLF_script_compile_abort" },
        value = 50,
        floorWeight = 1,

        onTooltip = function( tooltip, unit, userUnit )
            return onChipTooltip( tooltip, unit, userUnit )
        end,

        createUpgradeParams = function( self, unit )
            return { traits = { -- store these by names instead of scriptdefs; no longer breaks save files - thanks cyberboy
                SLF_base = unit:getTraits().SLF_base.main,
                SLF_launcher = unit:getTraits().SLF_launcher.launcher,
                SLF_module = unit:getTraits().SLF_module.module,
                SLF_chip_mode = unit:getTraits().SLF_chip_mode,
            },
            profile_icon = unit:getTraits()[unit:getTraits().SLF_chip_mode].chip_icon or unit:getUnitData().profile_icon,
            profile_icon_100 = unit:getTraits()[unit:getTraits().SLF_chip_mode].chip_icon_100 or unit:getUnitData().profile_icon_100,
        }
        end,
    },
}

return itemdefs