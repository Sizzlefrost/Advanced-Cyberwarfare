local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local simunit = include( "sim/simunit" )
local commondefs = include( "sim/unitdefs/commondefs" )
local itemdefs = include( "sim/unitdefs/itemdefs" )
local speechdefs = include( "sim/speechdefs" )
local guarddefs = include( "sim/unitdefs/guarddefs" )

local setAlertedOld = simunit.setAlerted

function simunit.setAlerted(self, alerted) -- bypass to make alert-immune units happen
	if self:getTraits().innervate == true then
		return
	end

	return setAlertedOld(self, alerted)
end

---------------------------------------------------------------------------------------------------------
-- NPC templates

local SOUNDS = commondefs.SOUNDS

SILENT_SOUNDS = {
	appeared="SpySociety/HUD/gameplay/peek_negative", 
	rustle = "SpySociety/Movement/foley/gear_light",
	alert ="SpySociety/Actions/guard/guard_alerted", 
	speech="SpySociety/Agents/dialogue_KO", 
	stealthStep = simdefs.SOUNDPATH_FOOTSTEP_MALE_HARDWOOD_SOFT, 
	--stealthStep = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL,
	step = simdefs.SOUNDPATH_FOOTSTEP_GUARD_HARDWOOD_NORMAL,

	getup = "SpySociety/Movement/foley_guard/getup",
	fall = "SpySociety/Movement/foley_guard/fall",
	fall_knee = "SpySociety/Movement/bodyfall_agent_knee_hardwood",
	fall_kneeframe = 9,
	fall_hand = "SpySociety/Movement/bodyfall_agent_hand_hardwood",
	fall_handframe = 20,
	land = "SpySociety/Movement/deathfall_agent_hardwood",
	land_frame = 34,					
	grabbed = "SpySociety/Movement/foley_guard/grabbed",
	pin = "SpySociety/Movement/foley_guard/pin_guard",
	pinned = "SpySociety/Movement/foley_guard/pinned",
	move ="SpySociety/Movement/foley_guard/move",
	hit = "SpySociety/HitResponse/hitby_ballistic_flesh",	
						
	die = "die",
	hurt_small = "SpySociety/Agents/<voice>/hurt_small",	
	hurt_large = "SpySociety/Agents/<voice>/hurt_large",	
}

local DEFAULT_IDLES = commondefs.DEFAULT_IDLES

local DEFAULT_ABILITIES = commondefs.DEFAULT_ABILITIES

local DEFAULT_DRONE = commondefs.DEFAULT_DRONE

local onGuardTooltip = commondefs.onGuardTooltip

local nildrop = {	{nil,100} 	}

local superuser_traits = {
	isAgent = true,
	sightable = true,
	dynamicImpass = false,
	hasSight = false, -- FIX!
	hasHearing = false,
	apMax = 1, 
	mp_max = 20,
	mp = 20,	
	ap = 1,
	silencer = true,
	meleeDamage = 0,
	maxThrow = 10,
	inventoryMaxSize = 3,
	augmentMaxSize = 0,
	skillsInjected = false,
	corpseTemplate = nil,
	canBeShot = false,
	canBeCritical = false,
	canKO = false,
	baseDamage = 0,
	wounds = 0,	
	woundsMax = 1,
	hits = "blood",
	dashSoundRange = 0,
	isAiming=false, 
	selectpriority = 1,	
	sneaking = true,
	dragCostMod = 0,
	isGuard = true,
    cleanup = false, 	
	cashOnHand = 0,
	closedoors = true,
	patrolObserved = false, 
	observablePatrol = true,
	walk=true,
	heartMonitor="disabled",
	enforcer = false,
	recap_icon = "guard",
	no_look_around = true,
	always_patrol = true,
	noInterestDistraction = true,
	isMainframeGhost = true,
	mainframeShaderOverride = { 192/255, 192/255, 192/255, 0.75 },
}

local superuser_template = {
	type = "simunit",
	name = STRINGS.GUARDS.GUARD,
	profile_anim = "portraits/portrait_animation_template",
	profile_build = "portraits/ko_med_build",
	profile_image = "KO_med.png",	
	onWorldTooltip = onGuardTooltip,
	kanim = "kanim_ghost_male_plastek",
	traits = superuser_traits,
	dropTable = nildrop,
	anarchyDropTable = nildrop,
	speech = speechdefs.NPC,
	voices = {"Guard_1", "Guard_2", "Guard_3"},
	abilities = {},
	skills = {},
	children = {},
	idles = DEFAULT_IDLES,
	sounds = SILENT_SOUNDS,
	brain = "PacifistBrain", -- develop a new brain for SuperUsers
}

local npc_templates = {
	acw_superuser_stonewall = util.extend( superuser_template )
	{
		name = STRINGS.SLF.GUARDS.STONEWALL,
		traits = util.extend( superuser_traits )
		{
			mainframe_suppress_rangeMax = 0, --secures the tile it's on; prevents Dragon pathing into the tile, as well
			mainframe_suppress_range = 0,

			mainframeShaderOverride = { 255/255, 0/255, 0/255, 0.75 },
		},
		abilities = { "SLF_stonewall_patrols" },
	},
	acw_superuser_noctis = util.extend( guarddefs.ko_guard )
	{
		name = STRINGS.SLF.GUARDS.NOCTIS,
		traits = util.extend( superuser_traits )
		{
			mp_max = 8,
			mainframeShaderOverride = { 0/255, 0/255, 0/255, 1 },
			voidFieldRange = 3,
		},
		abilities = { "recon_protocol_passive", "SLF_noctis_curtain" },
	},
	acw_superuser_pandora = util.extend( guarddefs.ko_guard )
	{
		name = STRINGS.SLF.GUARDS.PANDORA,
		traits = util.extend( superuser_traits )
		{
			mp_max = 10,
			innervate = true, -- HYPERFOCUSED AI
			mainframeShaderOverride = { 0/255, 0/255, 255/255, 1 },
		},
		abilities = { "SLF_pandoras_box" },
		brain = "PandoraBrain",
	},
}

return npc_templates