local skills = {
	acw_stability = 
	{
		name = STRINGS.SLF.SKILLS.STABILITY_NAME,
		levels = 5, 
		description = STRINGS.SLF.SKILLS.STABILITY_DESC,

		[1] = 
		{
			tooltip = STRINGS.SLF.SKILLS.STABILITY1_TOOLTIP, 
			cost = 0,
		},

		[2] = 
		{
			tooltip = STRINGS.SLF.SKILLS.STABILITY2_TOOLTIP, 
			cost = 300, 
			onLearn = function(sim, unit)
				unit:getTraits().fade_bonus = (unit:getTraits().fade_bonus or 0) + 1
			    unit:getTraits().bypassLevel = (unit:getTraits().bypassLevel or 0) + 1
			end,
			onUnLearn = function(sim, unit)
				unit:getTraits().fade_bonus = unit:getTraits().fade_bonus - 1
			    unit:getTraits().bypassLevel = unit:getTraits().bypassLevel - 1
			end,			
		},

		[3] = 
		{
			tooltip = STRINGS.SLF.SKILLS.STABILITY3_TOOLTIP,
			cost = 500, 
			onLearn = function(sim, unit)
			    unit:getTraits().fade_bonus = unit:getTraits().fade_bonus + 1
			end, 
			onUnLearn = function(sim, unit)
			    unit:getTraits().fade_bonus = unit:getTraits().fade_bonus - 1
			end, 			
		},

		[4] = 
		{
			tooltip = STRINGS.SLF.SKILLS.STABILITY4_TOOLTIP, 
			cost = 700, 
			onLearn = function(sim, unit)
				unit:getTraits().fade_bonus = unit:getTraits().fade_bonus + 1
			    unit:getTraits().bypassLevel = unit:getTraits().bypassLevel + 1
			end,
			onUnLearn = function(sim, unit)
				unit:getTraits().fade_bonus = unit:getTraits().fade_bonus - 1
			    unit:getTraits().bypassLevel = unit:getTraits().bypassLevel - 1
			end,			 
		},

		[5] = 
		{
			tooltip = STRINGS.SLF.SKILLS.STABILITY5_TOOLTIP,
			cost = 1000, 
			onLearn = function(sim, unit)
				unit:getTraits().fade_bonus = unit:getTraits().fade_bonus + 2
			    unit:getTraits().bypassLevel = unit:getTraits().bypassLevel + 1
			end,
			onUnLearn = function(sim, unit)
				unit:getTraits().fade_bonus = unit:getTraits().fade_bonus - 2
			    unit:getTraits().bypassLevel = unit:getTraits().bypassLevel - 1
			end,				
		},
	},
	acw_resolution = 
	{
		name = STRINGS.SLF.SKILLS.RESOLUTION_NAME,
		levels = 5, 
		description = STRINGS.SLF.SKILLS.RESOLUTION_DESC,

		[1] = 
		{
			tooltip = STRINGS.SLF.SKILLS.RESOLUTION1_TOOLTIP, 
			cost = 0,
		},

		[2] = 
		{
			tooltip = STRINGS.SLF.SKILLS.RESOLUTION2_TOOLTIP, 
			cost = 250, 
			onLearn = function(sim, unit)
				unit:getTraits().acw_range_bonus = (unit:getTraits().acw_range_bonus or 0) + 1
				unit:getTraits().acw_cost_bonus = (unit:getTraits().acw_cost_bonus or 0) + 1
			end,
			onUnLearn = function(sim, unit)
				unit:getTraits().acw_range_bonus = unit:getTraits().acw_range_bonus - 1
				unit:getTraits().acw_cost_bonus = unit:getTraits().acw_cost_bonus - 1
			end,			
		},

		[3] = 
		{
			tooltip = STRINGS.SLF.SKILLS.RESOLUTION3_TOOLTIP,
			cost = 300, 
			onLearn = function(sim, unit)
			    unit:getTraits().acw_range_bonus = unit:getTraits().acw_range_bonus + 1
			end, 
			onUnLearn = function(sim, unit)
				unit:getTraits().acw_range_bonus = unit:getTraits().acw_range_bonus - 1
			end, 			
		},

		[4] = 
		{
			tooltip = STRINGS.SLF.SKILLS.RESOLUTION4_TOOLTIP, 
			cost = 350, 
			onLearn = function(sim, unit)
				unit:getTraits().acw_range_bonus = unit:getTraits().acw_range_bonus + 1
				unit:getTraits().acw_cost_bonus = unit:getTraits().acw_cost_bonus + 1
			end,
			onUnLearn = function(sim, unit)
				unit:getTraits().acw_range_bonus = unit:getTraits().acw_range_bonus - 1
				unit:getTraits().acw_cost_bonus = unit:getTraits().acw_cost_bonus - 1
			end,			 
		},

		[5] = 
		{
			tooltip = STRINGS.SLF.SKILLS.RESOLUTION5_TOOLTIP,
			cost = 500, 
			onLearn = function(sim, unit)
				unit:getTraits().acw_range_bonus = unit:getTraits().acw_range_bonus + 2
			end,
			onUnLearn = function(sim, unit)
				unit:getTraits().acw_range_bonus = unit:getTraits().acw_range_bonus - 2
			end,				
		},
	},
	acw_synchronicity = 
	{
		name = STRINGS.SLF.SKILLS.SYNCHRONICITY_NAME,
		levels = 5, 
		description = STRINGS.SLF.SKILLS.SYNCHRONICITY_DESC,

		[1] = 
		{
			tooltip = STRINGS.SLF.SKILLS.SYNCHRONICITY1_TOOLTIP, 
			cost = 0,
		},

		[2] = 
		{
			tooltip = STRINGS.SLF.SKILLS.SYNCHRONICITY2_TOOLTIP, 
			cost = 300, 
			onLearn = function(sim, unit)
				unit:getTraits().acw_inv_bonus = 1
			end,
			onUnLearn = function(sim, unit)
				unit:getTraits().acw_inv_bonus = nil
			end,			
		},

		[3] = 
		{
			tooltip = STRINGS.SLF.SKILLS.SYNCHRONICITY3_TOOLTIP,
			cost = 500, 
			onLearn = function(sim, unit)
				unit:getTraits().acw_aug_bonus = 1
			end, 
			onUnLearn = function(sim, unit)
				unit:getTraits().acw_aug_bonus = nil
			end, 			
		},

		[4] = 
		{
			tooltip = STRINGS.SLF.SKILLS.SYNCHRONICITY4_TOOLTIP, 
			cost = 600, 
			onLearn = function(sim, unit)
				unit:getTraits().acw_move_bonus = 1
			end,
			onUnLearn = function(sim, unit)
				unit:getTraits().acw_move_bonus = nil
			end,			 
		},

		[5] = 
		{
			tooltip = STRINGS.SLF.SKILLS.SYNCHRONICITY5_TOOLTIP,
			cost = 900, 
			onLearn = function(sim, unit)
				unit:getTraits().acw_hp_bonus = 1
			end,
			onUnLearn = function(sim, unit)
				unit:getTraits().acw_hp_bonus = nil
			end,				
		},
	},
}

return skills