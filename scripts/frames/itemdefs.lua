local util = include("modules/util")
local simdefs = include("sim/simdefs")

local compareWithColour = function( val1, val2, reverse )
    -- compares val2 against val1.
    -- str1 will always be yellow
    -- str2 will be green or red. Green for larger values
    -- reverse makes it green for smaller values
    local str1 = tostring(val1)
    local str2 = tostring(val2)

    if val1 == val2 then
        str2 = "<c:F4FF78>"..str2
    elseif (val1 - val2) * (reverse and 1 or -1) > 0 then
        str2 = "<c:00FF60>"..str2
    else
        str2 = "<c:FF6000>"..str2
    end

    return "<c:F4FF78>"..str1.."</c>", str2.."</c>"
end

local onFrameItemTooltip = function(tooltip, unit, userUnit, game)
    local name = util.toupper( unit:getName() )

    tooltip:addLine( "<ttheader>"..name.."</>" )
    
    if unit:getUnitData().flavor then
        tooltip:addDesc( "<c:61AAAA>"..unit:getUnitData().flavor.."</>" )
    end

    local sim = unit._sim
    local old_frame, new_frame
    if sim then
        old_frame = sim:getPC():getIncognitaFrame()
        new_frame = sim:getPC():getIncognitaFramedef(unit:getTraits().SLF_incogFrame)
    else
        -- how get frame data outside of sim?
        local user = savefiles.getCurrentGame()
        local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
        local old_name = campaign.agency.SLF_incogFrame
        local framedefs = include(SCRIPT_PATHS.advanced_cyberwarfare.."/frames/framedefs")
        for i, def in pairs(framedefs) do
            if def.name == unit:getTraits().SLF_incogFrame then
                new_frame = def
            end
            if def.name == old_name then
                old_frame = def
            end
        end
    end
    if not new_frame then
        assert(false, "Attempting to create a tooltip for an MCD item with no embedded matrix!")
    end
    if not old_frame then
        assert(false, "Attempting to create a tooltip for an MCD item with no matrix to compare to!")
    end
    tooltip:addDesc(util.sformat(unit:getUnitData().rawdesc, new_frame.name, old_frame.name ))

    local strSpace = STRINGS.SLF.ITEMS.FRAMEWORK.TOOLTIP_COMPARISONS

    if (old_frame.max_pwr_mod ~= 0) or (new_frame.max_pwr_mod ~= 0) then
        tooltip:addLine(util.sformat(strSpace.PWR, compareWithColour(old_frame.max_pwr_mod, new_frame.max_pwr_mod)))
    end
    if (old_frame.max_programs_mod ~= 0) or (new_frame.max_programs_mod ~= 0) then
        tooltip:addLine(util.sformat(strSpace.PROG, compareWithColour(old_frame.max_programs_mod, new_frame.max_programs_mod)))
    end
    if (#old_frame.spec_programs > 0) or (#new_frame.spec_programs > 0) then
        -- make a compare table for spec slots of various kinds
        local specsTotal, specsNew = util.tcopy(old_frame.spec_programs), util.tcopy(new_frame.spec_programs)
        for i, spec in pairs(specsNew) do
            local match = false
            for j, spec_match in pairs(specsTotal) do
                if spec.type == spec_match.type then
                    spec_match.slots_new = spec.slots
                    match = true
                    break
                end
            end
            if not match then 
                spec.slots_new = spec.slots
                spec.slots = nil
                table.insert(specsTotal, spec) 
            end
        end
        -- calculate total spec slots
        local slotsOld, slotsNew = old_frame:getTotalSpecSlots(), new_frame:getTotalSpecSlots()

        -- reverse; specialized slots are a drawback, slots that cannot be used as freely
        slotsOld, slotsNew = compareWithColour(slotsOld, slotsNew, true)

        tooltip:addLine(util.sformat(strSpace.SPEC, slotsOld, slotsNew))
        for i, spec in pairs(specsTotal) do
            tooltip:addLine(util.sformat(
                strSpace.SPEC_TYPE, 
                util.color.clrToHex(spec.color)..spec.type.."</c>", 
                compareWithColour(spec.slots or 0, spec.slots_new or 0, true)
                ))
        end
    end
    if (old_frame.pwr_mod ~= 0) or (new_frame.pwr_mod ~= 0) then
        tooltip:addLine(util.sformat(strSpace.PMOD, compareWithColour(old_frame.pwr_mod, new_frame.pwr_mod, true)))
    end
    if (old_frame.max_hash_mod ~= 0) or (new_frame.max_hash_mod ~= 0) then
        tooltip:addLine(util.sformat(strSpace.HASH, compareWithColour(old_frame.max_hash_mod, new_frame.max_hash_mod)))
    end
    if (old_frame.algorithm_odds ~= 0) or (new_frame.algorithm_odds ~= 0) then
        tooltip:addLine(util.sformat(strSpace.ALGO, compareWithColour(old_frame.algorithm_odds, new_frame.algorithm_odds)))
    end
    if (old_frame.daemon_duration_mod ~= 0) or (new_frame.daemon_duration_mod ~= 0) then
        tooltip:addLine(util.sformat(strSpace.DAEMON, compareWithColour(old_frame.daemon_duration_mod, new_frame.daemon_duration_mod, true)))
    end
    if old_frame.unique_special then
        tooltip:addAbility(strSpace.LOST_SPECIAL, "<c:FF6000>"..old_frame.special.."</c>", "gui/icons/item_icons/items_icon_small/icon-item_incognita_small.png")
    end
    if new_frame.unique_special then
        tooltip:addAbility(strSpace.GAINED_SPECIAL, "<c:00FF60>"..new_frame.special.."</c>", "gui/icons/item_icons/items_icon_small/icon-item_incognita_small.png")
    end

    if unit:getTraits().dlcFooter then
        tooltip:addFooter( unit:getTraits().dlcFooter[1],unit:getTraits().dlcFooter[2] )
    end
end

local commondefs = include("sim/unitdefs/commondefs")
local SLF_construct_framework = util.extend(commondefs.item_template)
{
    name = STRINGS.SLF.ITEMS.FRAMEWORK.NAME,
    desc = STRINGS.SLF.ITEMS.FRAMEWORK.DESC_SIMPLE,
    rawdesc = STRINGS.SLF.ITEMS.FRAMEWORK.DESC,
    flavor = STRINGS.SLF.ITEMS.FRAMEWORK.FLAVOR,
    icon = "itemrigs/FloorProp_AmmoClip.png",
    profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_data_disk_small.png",
    profile_icon_100 = "gui/icons/item_icons/icon-item_data_disk.png",
    traits = { 
        SLF_incogFrame = nil,
        disposable = true,
    },
    abilities = { "carryable", "SLF_install_framework" },
    value = 800,
    floorWeight = 1,
    ITEM_LIST = true,
    type = "simunit",

    onSpawn = function( self, sim )
        -- can't use pcplayer here, it's not yet spawned
        local frames = include(SCRIPT_PATHS.advanced_cyberwarfare.."/frames/framedefs")
        for i, frame in pairs(frames) do
            if frame.name == self:getTraits().SLF_incogFrame then
                self:hasAbility("SLF_install_framework").frame = frame
                break
            end
        end
    end,

    onTooltip = function( tooltip, unit, userUnit, game )
        return onFrameItemTooltip( tooltip, unit, userUnit, game )
    end,

    createUpgradeParams = function( self, unit )
        return { traits = 
            { -- store these by names instead of scriptdefs; doesn't break save files that way
                SLF_incogFrame = unit:getTraits().SLF_incogFrame,
            },
        }
    end,
}

return SLF_construct_framework