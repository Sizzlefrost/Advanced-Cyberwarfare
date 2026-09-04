----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------
local util = include( "modules/util" )
local commondefs = include( "sim/unitdefs/commondefs" )

local itemdefs = 
{
    SLF_confidence_booster = util.extend(commondefs.item_template)
    {
        name = STRINGS.SLF.ITEMS.CONFIDENCE_BOOSTER.NAME,
        desc = STRINGS.SLF.ITEMS.CONFIDENCE_BOOSTER.DESC,
        flavor = STRINGS.SLF.ITEMS.CONFIDENCE_BOOSTER.FLAVOR,
        icon = "itemrigs/FloorProp_Bandages.png",
        profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_bottle_small.png",
        profile_icon_100 = "gui/icons/item_icons/icon-item_bottle.png",
        traits = {
            damage = 2, 
            melee = true, 
            level = 1,
            disposable = true,
            mpRestored = 4,
            slot = "melee",
        },
        abilities = { "carryable", "use_stim", "equippable" },
        value = 100, --price of item
        floorWeight = 3,
        ITEM_LIST = true,

        onTooltip = function( tooltip, unit, userUnit )
            commondefs.onItemTooltip( tooltip, unit, userUnit )

            local simquery = include( "sim/simquery" )
            local armorPiercing = unit:getTraits().armorPiercing or 0
            local damage = simquery.calculateMeleeDamage( unit:getSim(), unit )

            if damage > 0 then
                tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.KO_DAMAGE, util.sformat(STRINGS.ITEMS.TOOLTIPS.KO_DAMAGE_DESC, damage), "gui/icons/arrow_small.png" )
            end 

            if userUnit and userUnit:getTraits().tempMeleeBoost and  userUnit:getTraits().tempMeleeBoost > 0 then
                tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.MELEE_BOOST, util.sformat(STRINGS.ITEMS.TOOLTIPS.MELEE_BOOST_DESC, userUnit:getTraits().tempMeleeBoost ), "gui/icons/arrow_small.png" )
            end  

            if unit:getTraits().dlcFooter then
                tooltip:addFooter( unit:getTraits().dlcFooter[1],unit:getTraits().dlcFooter[2] )
            end
        end,

        createUpgradeParams = function( self, unit )
            return { traits = { autoEquip = (unit:getTraits().equipped == true) } }
        end,
    },

    SLF_script_piece = util.extend(commondefs.item_template)
    {
        name = STRINGS.SLF.ITEMS.SCRIPT_CHIP.NAME,
        desc = STRINGS.SLF.ITEMS.SCRIPT_CHIP.DESC,
        flavor = STRINGS.SLF.ITEMS.SCRIPT_CHIP.FLAVOR,
        icon = "itemrigs/FloorProp_AmmoClip.png",
        profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_chip_hyper_buster_small.png",
		profile_icon_100 = "gui/icons/item_icons/icon-item_chip_ice_breaker.png",	
        createUpgradeParams = function( self, unit )
			return { traits = { icebreak = unit:getTraits().icebreak } }
		end,
		abilities = { 
			"carryable", --"SLF_compile",
		},
		value = 300,
		floorWeight = 1,

        onTooltip = function( tooltip, unit, userUnit )
            commondefs.onItemTooltip( tooltip, unit, userUnit )

            local simquery = include( "sim/simquery" )

            --[[if damage > 0 then
                tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.KO_DAMAGE, util.sformat(STRINGS.ITEMS.TOOLTIPS.KO_DAMAGE_DESC, damage), "gui/icons/arrow_small.png" )
            end 

            if userUnit and userUnit:getTraits().tempMeleeBoost and  userUnit:getTraits().tempMeleeBoost > 0 then
                tooltip:addAbility( STRINGS.ITEMS.TOOLTIPS.MELEE_BOOST, util.sformat(STRINGS.ITEMS.TOOLTIPS.MELEE_BOOST_DESC, userUnit:getTraits().tempMeleeBoost ), "gui/icons/arrow_small.png" )
            end  

            if unit:getTraits().dlcFooter then
                tooltip:addFooter( unit:getTraits().dlcFooter[1],unit:getTraits().dlcFooter[2] )
            end]]
        end,
    },
}

return itemdefs
