local util = include( "modules/util" )
local commondefs = include("sim/unitdefs/commondefs")
local speechdefs = include( "sim/speechdefs" )
local simdefs = include("sim/simdefs")
local SCRIPTS = include('client/story_scripts')
-----------------------------------------------------
-- Agent templates

local DRAGON_SOUNDS =
{	
	bio = "",
    escapeVo = "",
	speech="SpySociety/Agents/dialogue_player",  
	step = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_NORMAL, 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_FEMALE_HARDWOOD_SOFT, 

	wallcover = "SpySociety/Movement/foley_trench/wallcover",
	crouchcover = "SpySociety/Movement/foley_trench/crouchcover",
	fall = "SpySociety/Movement/foley_trench/fall",
	land = "SpySociety/Movement/deathfall_agent_hardwood",
	land_frame = 16,						
	getup = "SpySociety/Movement/foley_trench/getup",	
	grab = "SpySociety/Movement/foley_trench/grab_guard",
	pin = "SpySociety/Movement/foley_trench/pin_guard",
	pinned = "SpySociety/Movement/foley_trench/pinned",
	peek_fwd = "SpySociety/Movement/foley_trench/peek_forward",	
	peek_bwd = "SpySociety/Movement/foley_trench/peek_back",	
	move = "SpySociety/Movement/foley_trench/move",
	hit = "SpySociety/HitResponse/hitby_ballistic_flesh",
}

local agent_templates =
{
	SLF_dragon =
	{
		type = "simunit",
	    agentID = "SLF_Dragon",
		name = STRINGS.SLF.AGENTS.DRAGON.NAME,
		file =  STRINGS.SLF.AGENTS.DRAGON.FILE,
		fullname = STRINGS.SLF.AGENTS.DRAGON.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_FILE,
		yearsOfService = STRINGS.SLF.AGENTS.DRAGON.YEARS_OF_SERVICE,
		age = STRINGS.SLF.AGENTS.DRAGON.AGE,
		homeTown = STRINGS.SLF.AGENTS.DRAGON.HOMETOWN,
		gender = "female",
		class = "Stealth",
		toolTip = STRINGS.SLF.AGENTS.DRAGON.ALT_1.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/lady_ai_36.png",
		profile_icon_64x64= "gui/profile_icons/dragon_64x64.png",
		splash_image = "gui/agents/dragon_1024.png",
		team_select_img = {
			"gui/agents/team_select_1_dragon.png",
		},

		profile_anim = "portraits/lady_stealth_face",
		profile_build = "portraits/dragon_face",
		kanim = "kanim_female_dragon",
		hireText = STRINGS.SLF.AGENTS.DRAGON.RESCUED,
		--centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_DRAGON,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { 
			mp=8, 
			mpMax =8, 
			augmentMaxSize = 3, 
			isSLFDragon = true,
			corpse_template = nil,
			hits = "spark",
			canBeShot = false,
			canBeCritical = false,
			canKO = false,
			shaderOverrides = {
				live = { 45/255, 100/255, 170/255, 0.3 },
				fade = { 130/255, 130/255, 45/255, 0.3 },
				crit = { 170/255, 100/255, 45/255, 0.3 },
			},
			mainframeShaderOverride = { 45/255, 100/255, 170/255, 0.3 },
		},
		skills = { "stealth", "acw_stability"},
		startingSkills = {},
		abilities = { "peek", "escape", "jackin", "observePath", "SLF_possess", "SLF_ghostForm", "SLF_persist", "SLF_burnout", "SLF_nullblock" },
		children = { },																					--I explain why in dragon_augments.lua, but the gist of it is
		sounds = DRAGON_SOUNDS,																			--Dragon's ability list is a mess anyways, so customisation
		speech = STRINGS.SLF.AGENTS.DRAGON.BANTER,														--is not a concern.
		blurb = STRINGS.SLF.AGENTS.DRAGON.ALT_1.BIO,
		upgrades = { "SLF_augment_dragon_immaterial", "SLF_augment_dragon_subvert", "SLF_augment_dragon_burnout", "SLF_augment_dragon_weaknesses" },
	},

	SLF_dragon_a =
	{
		type = "simunit",
	    agentID = "SLF_Dragon",
		name = STRINGS.SLF.AGENTS.DRAGON.NAME,
		file =  STRINGS.SLF.AGENTS.DRAGON.FILE,
		codename = STRINGS.SLF.AGENTS.DRAGON.ALT_2.FULLNAME,
		fullname = STRINGS.SLF.AGENTS.DRAGON.ALT_1.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		yearsOfService = STRINGS.SLF.AGENTS.DRAGON.YEARS_OF_SERVICE,
		age = STRINGS.SLF.AGENTS.DRAGON.ALT_2.AGE,
		homeTown = STRINGS.SLF.AGENTS.DRAGON.HOMETOWN,
		gender = "female",
		class = "Stealth",
		toolTip = STRINGS.SLF.AGENTS.DRAGON.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/lady_ai_36.png",
		profile_icon_64x64= "gui/profile_icons/dragon_64x64.png",
		splash_image = "gui/agents/dragon_1024.png",
		team_select_img = {
			"gui/agents/team_select_2_dragon.png",
		},

		profile_anim = "portraits/lady_stealth_face",
		profile_build = "portraits/dragon_face_2",
		kanim = "kanim_female_dragon",
		hireText = STRINGS.SLF.AGENTS.DRAGON.RESCUED,
		--centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_DRAGON,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) { mp=8, mpMax =8 },	--passiveKey = simdefs.DOOR_KEYS.SECURITY
		skills = util.extend( commondefs.DEFAULT_AGENT_SKILLS ) {}, 
		startingSkills = { hacking = 2 },
		abilities = util.tconcat( { "sprint",  }, commondefs.DEFAULT_AGENT_ABILITIES ), -- "stealth"
		children = { }, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = DRAGON_SOUNDS,
		speech = STRINGS.SLF.AGENTS.DRAGON.BANTER,
		blurb = STRINGS.SLF.AGENTS.DRAGON.ALT_2.BIO,
		upgrades = { "SLF_augment_dragon_archive", "item_armor_tazer_1", "item_tag_pistol" },
	},

	--[[SLF_dragon_a =
	{
		type = "simunit",
	    agentID = "SLF_Dragon",
		name = STRINGS.SLF.AGENTS.DRAGON.NAME,
		file =  STRINGS.SLF.AGENTS.DRAGON.FILE,
		fullname = STRINGS.SLF.AGENTS.DRAGON.ALT_2.FULLNAME,
		loadoutName = STRINGS.UI.ON_ARCHIVE,
		yearsOfService = STRINGS.SLF.AGENTS.DRAGON.YEARS_OF_SERVICE,
		age = STRINGS.SLF.AGENTS.DRAGON.ALT_2.AGE,
		homeTown = STRINGS.SLF.AGENTS.DRAGON.HOMETOWN,
		gender = "female",
		class = "Stealth",
		toolTip = STRINGS.SLF.AGENTS.DRAGON.ALT_2.TOOLTIP,
		onWorldTooltip = commondefs.onAgentTooltip,
		profile_icon_36x36= "gui/profile_icons/lady_ai_36.png",
		profile_icon_64x64= "gui/profile_icons/dragon_64x64.png",
		splash_image = "gui/agents/dragon_1024.png",
		team_select_img = {
			"gui/agents/team_select_2_dragon.png",
		},

		profile_anim = "portraits/lady_stealth_face",
		profile_build = "portraits/dragon_face_2",
		kanim = "kanim_female_dragon",
		hireText = STRINGS.SLF.AGENTS.DRAGON.RESCUED,
		--centralHireSpeech = SCRIPTS.INGAME.CENTRAL_AGENT_ESCAPE_DRAGON,
		traits = util.extend( commondefs.DEFAULT_AGENT_TRAITS ) 
		{ 
			mp=8, 
			mpMax =8, 
			isSLFDragon =true, 
			shaderOverrides = {
				live = { 45/255, 170/255, 100/255, 0.3 },
				fade = { 170/255, 100/255, 45/255, 0.3 },
			},
			bypassLevel = 3,
			acw_will_be_dependent = true,
			mainframeShaderOverride = { 45/255, 170/255, 100/255, 0.3 },
			selectPriority = 0, -- can't be selected right away, because doesn't spawn right away 
		},
		skills = { "acw_resolution", "acw_synchronicity" },
		startingSkills = {},
		abilities = { "peek", "jackin", "observePath", "SLF_possess", "SLF_ghostForm", "SLF_burnout", "SLF_dragon_succulent" },
		children = { }, -- Dont add items here, add them to the upgrades table in createDefaultAgency()
		sounds = DRAGON_SOUNDS,
		speech = STRINGS.SLF.AGENTS.DRAGON.BANTER,
		blurb = STRINGS.SLF.AGENTS.DRAGON.ALT_2.BIO,
		upgrades = { "SLF_augment_dragon_ephemeral", "SLF_augment_dragon_immaterial", "SLF_augment_dragon_subvert" },
	},]]
}

return agent_templates
