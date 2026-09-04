local util = include( "modules/util" )
local commondefs = include( "sim/unitdefs/commondefs" )
local simquery = include( "sim/simquery" )

local abilityDetail = function(tooltip, unit)
    for i, tip in pairs(unit:getUnitData().acw_aug_tips) do
        --log:write("Initializing tooltipdef: "..tip[1].." engaged.")
        if tip[4] then
            local skillTable = tip[4][1]
            local skillid, req = skillTable[1], skillTable[2]
            local c_true, c_false = tip[4][2], tip[4][3]
            local use_c = c_false
            local level = 1

            if unit:getUnitOwner() then -- agent select screen
                local target = unit:getUnitOwner()
                local skills = target:getSkills()
                for i, skill in pairs(skills) do
                    if skill._skillID == skillid then
                        level = skill._currentLevel
                    end
                end
            end

            if req and (level >= req) then
                use_c = c_true
            end

            tooltip:addAbility(tip[1],util.sformat(tip[2],use_c,level),tip[3])
        else
            tooltip:addAbility(tip[1],tip[2],tip[3])
        end
    end
end

local onDragonTooltip = function(tooltip, unit, userUnit)
    local name = util.toupper( unit:getName() )

    -- supports custom resources via acw_resource
    -- (mechanisms of filling them up, including at the start of the mission, not included)
    if unit:getTraits().ammo and unit:getTraits().maxAmmo then
        tooltip:addLine( "<ttheader>"..name.."</>" , string.format("%s %s/%s",util.toupper(unit:getUnitData().acw_resource),unit:getTraits().ammo,unit:getTraits().maxAmmo) )
    else
        tooltip:addLine( "<ttheader>"..name.."</>" )
    end

    if unit:getUnitData().flavor then
        tooltip:addDesc( "<c:61AAAA>"..unit:getUnitData().flavor.."</>" )
    end 

    if unit:getTraits().augment and unit:getTraits().installed == false then        
        tooltip:addLine( "<c:FF8411>".. STRINGS.UI.TOOLTIPS.NOT_INSTALLED .."</c>" )
    end

    if unit:getUnitData().desc then
        tooltip:addDesc( unit:getUnitData().desc )
    end

    local range_tip = nil
    if unit:getTraits().stored_range then
        range_tip = table.remove(unit:getUnitData().acw_aug_tips, 1)

        local range = unit:getTraits().stored_range
        if unit:getUnitOwner() and unit:getTraits().installed then
            range = unit:getUnitOwner():getTraits().LOSrange
        end
        tooltip:addAbility(range_tip[1], util.sformat(range_tip[2], range), range_tip[3])
    end

    abilityDetail(tooltip, unit)

    if range_tip then
        table.insert(unit:getUnitData().acw_aug_tips, 1, range_tip)
    end

    tooltip:addDesc( "<c:ffffff>".. STRINGS.UI.TOOLTIPS.NOT_STACKABLE .."</>")

    if unit:getTraits().dlcFooter then
        tooltip:addFooter( unit:getTraits().dlcFooter[1],unit:getTraits().dlcFooter[2] )
    end
end

local itemdefs = 
{
    SLF_augment_dragon_immaterial = util.extend( commondefs.augment_template )
    {
        name = STRINGS.SLF.AUGMENTS.IMMATERIAL.NAME,
        desc = STRINGS.SLF.AUGMENTS.IMMATERIAL.DESC,
        flavor = STRINGS.SLF.AUGMENTS.IMMATERIAL.FLAVOR,
        acw_aug_tips = STRINGS.SLF.AUGMENTS.IMMATERIAL.TIPS,
        profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_energy_small.png",
        profile_icon_100 = "gui/icons/skills_icons/icon-skill_energy.png",
        AUGMENT_LIST = false, --true to show in shops
        traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){ --augment = true, installed = false
            stackable = false,
            grafterWeight = 0,
            installed = true,
        },
        onTooltip = onDragonTooltip,
        value = 574, --price of augment in shops
    },

    SLF_augment_dragon_subvert = util.extend( commondefs.augment_template )
    {
        name = STRINGS.SLF.AUGMENTS.SUBVERT.NAME,
        desc = STRINGS.SLF.AUGMENTS.SUBVERT.DESC,
        flavor = STRINGS.SLF.AUGMENTS.SUBVERT.FLAVOR,
        acw_aug_tips = STRINGS.SLF.AUGMENTS.SUBVERT.TIPS,
        profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_oravirus_small.png",
        profile_icon_100 = "gui/icons/item_icons/icon-item_ora_virus.png",
        AUGMENT_LIST = false, --true to show in shops
        traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){ --augment = true, installed = false
            stackable = false,
            grafterWeight = 0,
            installed = true,
        },
        onTooltip = onDragonTooltip,
        value = 574, --price of augment in shops
    },

    SLF_augment_dragon_burnout = util.extend( commondefs.augment_template )
    {
        name = STRINGS.SLF.AUGMENTS.BURNOUT.NAME,
        desc = STRINGS.SLF.AUGMENTS.BURNOUT.DESC,
        flavor = STRINGS.SLF.AUGMENTS.BURNOUT.FLAVOR,
        acw_aug_tips = STRINGS.SLF.AUGMENTS.BURNOUT.TIPS,
        profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_heart_monitor_small.png",
        profile_icon_100 = "gui/icons/item_icons/icon-item_heart_monitor.png",   
        AUGMENT_LIST = false, --true to show in shops
        traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){ --augment = true, installed = false
            stackable = false,
            grafterWeight = 0,
            installed = true,
        },
        onTooltip = onDragonTooltip,
        value = 574, --price of augment in shops
    },

    SLF_augment_dragon_weaknesses = util.extend( commondefs.augment_template )
    {
        name = STRINGS.SLF.AUGMENTS.PROJECTION.NAME,
        desc = STRINGS.SLF.AUGMENTS.PROJECTION.DESC,
        flavor = STRINGS.SLF.AUGMENTS.PROJECTION.FLAVOR,
        acw_aug_tips = STRINGS.SLF.AUGMENTS.PROJECTION.TIPS,
        acw_resource = STRINGS.SLF.AUGMENTS.PROJECTION.TURNS,
        profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_personal_shield_small.png",
        profile_icon_100 = "gui/icons/item_icons/icon-item_personal_shield.png",   
        AUGMENT_LIST = false, --true to show in shops
        traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){ --augment = true, installed = false
            stackable = false,
            grafterWeight = 0,
            installed = true,
            userFadeout = 0, -- both of these are now separate from ammo and change dynamically
            maxUserFadeout = 0,
        },
        onTooltip = onDragonTooltip,
        value = 574, --price of augment in shops
    },

    SLF_augment_dragon_ephemeral = util.extend( commondefs.augment_template )
    {
        name = STRINGS.SLF.AUGMENTS.DRAGON2.NAME,
        desc = STRINGS.SLF.AUGMENTS.DRAGON2.DESC,
        flavor = STRINGS.SLF.AUGMENTS.DRAGON2.FLAVOR,
        acw_aug_tips = STRINGS.SLF.AUGMENTS.DRAGON2.TIPS,
        profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_head_small.png",
        profile_icon_100 = "gui/icons/item_icons/icon-item_generic_head.png",
        AUGMENT_LIST = false, --true to show in shops
        traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){ --augment = true, installed = false
            stackable = false,
            grafterWeight = 0,
            installed = true,
        },
        onTooltip = onDragonTooltip,
        value = 500, --price of augment in shops
        abilities = util.tconcat( commondefs.augment_template.abilities, { "SLF_dragon_ephemeral" }),
    },

    --[[SLF_augment_dragon_projector = util.extend( commondefs.augment_template )
    {
        name = STRINGS.SLF.AUGMENTS.PROJECTOR.NAME,
        desc = STRINGS.SLF.AUGMENTS.PROJECTOR.DESC,
        flavor = STRINGS.SLF.AUGMENTS.PROJECTOR.FLAVOR,
        acw_aug_tips = STRINGS.SLF.AUGMENTS.PROJECTOR.TIPS,
        profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_head_small.png",
        profile_icon_100 = "gui/icons/item_icons/icon-item_generic_head.png",
        AUGMENT_LIST = false, --true to show in shops
        traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){ --augment = true, installed = false
            stackable = false,
            grafterWeight = 0,
            installed = false,
            addAbilities = "SLF_dragon_project",
            stored_range = 8,
        },
        onTooltip = onDragonTooltip,
        onWorldTooltip = onDragonTooltip,
        value = 500, --price of augment in shops
        abilities = commondefs.augment_template.abilities,

        createUpgradeParams = function(self, unit)
            local stored_range = self.traits.stored_range
            if self.traits.installed then
                -- 8 + dragon's range bonus
                for i, agent in pairs(unit:getPlayerOwner():getAgents()) do
                    if agent:getTraits().acw_range_bonus then
                        stored_range = stored_range + agent:getTraits().acw_range_bonus
                        break
                    end
                end
            end
            return {
                traits = { stored_range = stored_range }
            }
        end,
    }, -- incompatible with translations due to Resolution calculation append]]

    SLF_augment_dragon_archive = util.extend( commondefs.augment_template )
    {
        name = STRINGS.SLF.AUGMENTS.DRAGON2.NAME,
        desc = STRINGS.SLF.AUGMENTS.DRAGON2.DESC,
        flavor = STRINGS.SLF.AUGMENTS.DRAGON2.FLAVOR,
        profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_generic_head_small.png",
        profile_icon_100 = "gui/icons/item_icons/icon-item_generic_head.png",
        AUGMENT_LIST = false, --true to show in shops
        traits = util.extend( commondefs.DEFAULT_AUGMENT_TRAITS ){ --augment = true, installed = false
            stackable = false,
            grafterWeight = 0,
            installed = true,
        },
        value = 500, --price of augment in shops
        abilities = util.tconcat( commondefs.augment_template.abilities, { "SLF_dragon_scout" }),
    },
}

return itemdefs