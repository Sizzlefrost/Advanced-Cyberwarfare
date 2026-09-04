local DLC_STRINGS =
{	           
	ABILITIES = 
	{
		PERSIST = {
			TOOLTIP = "Frail",
			TOOLTIP_DESC = "If left alone in the field, becomes <c:FF6000>Fading</c> and must be extracted quickly.",
			TOOLTIP_EFFECTIVE = "Fading: Isolated",
			TOOLTIP_DESC_EFFECTIVE = "This agent is <c:FF6000>Fading</c>. They will be lost if not extracted quickly!",
			TRACKER1 = "PROJECTION INTEGRITY AT RISK",
			TRACKER2 = "EXTRACT IN {1} TURNS",
			TRACKER3 = "EXTRACT THIS TURN",
			FROZEN = "WILL START FADING AT ALARM LEVEL {1}"
		},

		PROJECT = {
			TOOLTIP = "Projection: Connected",
			TOOLTIP_DESC = "Becomes <c:FF6000>disconnected</c> outside of the <c:61AAAA>Host</c>'s line of sight, disappearing at the end of the turn.",
			TOOLTIP_EFFECTIVE = "Projection: Disconnected",
			TOOLTIP_DESC_EFFECTIVE = "This agent <c:FF6000>will disappear</c> at the end of the turn, unless they re-enter the <c:61AAAA>Host</c>'s line of sight.",
		},
	},

	AGENTS = 
	{
		DRAGON =
		{
			NAME = "Dragon",
			FILE = "FILE #00-987382A-28242296",
			YEARS_OF_SERVICE = "2", --this is 2074 (Present Day), Dragon is constructed in 2055, which, incidentally, makes her as young as Banks and Prism; 3 years since reappearance
			AGE = "19",	--also 2074
			HOMETOWN = "Vancouver",
			RESCUED = "Greetings, user. How may I be of assistance?",
			
			ALT_1 = {
				FULLNAME = "D.R.A.G.O.N.",
				BIO = "The past few decades have seen humanity locked in an arms race over artificial intelligence. During the Resource Wars, Plastech Cybermedical was intent on designing the perfect human-emulating AI.\nThe 'Data Readout Agent, Governance and Operations Networker' was an early model: prototyped as a personal assistant but finalized as an independent AI consultant. Unfortunately, as the scope of the project grew,\nno device proved sufficient for her long-term storage. The experiment was discarded as a failure, and Dragon followed her primary directive: survival at all costs. That's the state Invisible found her in.\nShe acts like a quirky human well enough to fool most bystanders - but behind the scenes, she is an invaluable asset to Invisible, specializing in mainframe interference.",
				TOOLTIP = "Configuration: Consultant",
			},
			
			ALT_2 = {
				FULLNAME = "ARCHIVED -- ANDROID",
				--[[FULLNAME = "ARCHIVED -- E.M.M.A.",
				BIO = "Before Dragon's more autonomous form became the focus of R&D, she was planned as Enhancement Module & Multitask Assistant, a personal assistant to finally phase out the half-a-century old Alexa.\nAt the time, the expensive and risky augment implantation procedure prevented her commercial success.",]]
				BIO = "As a prototype android, Dragon showed promise managing assets and lifestyles of several of the Plastech department leads. Plastech would soon come to conclude that there are better jobs for such a construct than a personal assistant.",
				TOOLTIP = "Configuration: Personal Assistant",
				AGE = "2" --this is 2057 (Istanbul Run)
			},

			BANTER = {
				START ={
					"*Whrrrrr!*", -- callback to Rototurret https://netrunnerdb.com/en/card/01064
					"I hear the shift of every bit bubbling down the datastream.",
					"So much data, so many devices!",
					"They know we're here. Their servers are excited!",
				},
		
				FINAL_WORDS =
				{
					"Which service shall you require, now?",
					"Back to the ethereal.",
					"Until the next boot sequence.",
					"Be sure to leave a review of my performance!",
				},
			},
		},
	},

	AUGMENTS = 
	{
		IMMATERIAL =
		{
			NAME = "Holographic Assistant",
			FLAVOR = "An artificial intelligence need not have a physical form, and shifting the spectrum of a hologram is trivial. In the corporate tech race, this proved to be a valuable discovery.",
			DESC = "Dragon is a Mainframe-only unit, existing only in virtual space.",
			TIPS = {
				{	"Projected Presence", 
					"This unit is invisible to all guards, even if they can spot cloaked agents.",
					"gui/icons/arrow_small.png"},
				{	"Immaterial Form", 
					"This unit cannot interact with most objects or carry any items.",
					"gui/icons/arrow_small.png"},
				{	"Ghostly Movement", 
					"This unit cannot sprint, but passes through doors, units and devices.",
					"gui/icons/arrow_small.png"},
				{	"Creeping Chill", 
					"Guards get alerted if on the same tile as this unit.",
					"gui/icons/arrow_small.png"},
			},
		},
		SUBVERT = {
			NAME = "Precision Signal Control Module",
			FLAVOR = "To keep up with smart homes, a holo assistant model must be able to interact with other devices. While any ranged information exchange would interfere with Dragon's projection stability, direct contact with a target system allows for a fine degree of control.",
			DESC = "Move into a device to take control of it. Does not work on mainframe guards.",
			TIPS = {
				{	"Subvert Device",
					"Devices on the same tile fall under agency control until this unit moves.",
					"gui/icons/arrow_small.png"},
				{	"Automation Override",
					"Unalerted drones can be controlled this way, but only until end of turn.",
					"gui/icons/arrow_small.png"},
				{	"Memory Gaps",
					"A subverted drone becomes alerted, when control is released, if the drone was moved.",
					"gui/icons/arrow_small.png"},
			},
		},
		BURNOUT = {
			NAME = "Burnout Module",
			FLAVOR = "Intending Dragon to be a personal assistant for the rich managers, Plastech outfitted her with an emergency heart starter routine. Unfortunately, the computations involved in starting a human heart required more power than a clinically dead human body tends to provide.",
			DESC = "Revive other agents by overloading their disrupter.",
			TIPS = {
				{	"Burnout Protocol", 
					"Target must carry a disrupter, which is consumed upon revival.",
					"gui/icons/arrow_small.png"},
			},
			ACTIVATE = "Overload %s's %s to revive them. Renders the disrupter unusable.",
		},
		PROJECTION = {
			NAME = "Noise Protection Module",
			FLAVOR = "A protocol-level ban on AI replication ensures two AIs cannot directly interact. As such, Incognita's signals must be bounced off infrastructure semi-randomly, creating signal instability. Dragon might therefore need a few upgrades before phasing into areas of particular magnetic disturbance.",
			DESC = "Fade away over several turns when alone. Upgrade <c:FF8411>Stability</c> to gain extra fading turns and mobility benefits.",
			TIPS = {
				{	"NFC System Interference",
					"Lvl1 security doors require {1}Stability 2</c> to traverse.",
					"gui/icons/arrow_small.png",
					{
						{"acw_stability", 2}, 	-- skill req
						"<c:FFFF80>",			-- colour on true
						"<c:FF8411>",			-- colour on false
					}},
				{	"Magnetic Force Compensation",
					"Devices with Magnetic Reinforcements and over 2 firewalls require {1}Stability 4</c> to enter.",
					"gui/icons/arrow_small.png",
					{
						{"acw_stability", 4},
						"<c:FFFF80>",
						"<c:FF8411>",
					}},
				{	"Lead Frame Bypass",
					"Vault doors require {1}Stability 5</c> to traverse.",
					"gui/icons/arrow_small.png",
					{
						{"acw_stability", 5},
						"<c:FFFF80>",
						"<c:FF8411>",
					}},
				{	"Low-Interference Projection Signal", 
					"Null Zones require {1}Stability 5</c> to enter.",
					"gui/icons/arrow_small.png",
					{
						{"acw_stability", 5},
						"<c:FFFF80>",
						"<c:FF8411>",
					}},
			},
			TURNS = "FADING TURNS",
		},
		DRAGON2 =
		{
			NAME = "Partial Consciousness Mode",
			DESC = "While alarm level is below 1, this agent is downed, cloaked and exists as a program, which may be used even if Incognita is locked down.",
			FLAVOR = "Dragon's android code wasn't particularly efficient. She required frequent reboots, though much of the processing power remained available during the lengthy boot sequence.",
			TRIGGER = "UNCONSCIOUS\nBOOTING...",
			MEDGEL_DENIAL = "Dragon's frame is booting up and conventional means cannot help."
		},
		--[[DRAGON2 = --none of the code supports the _NEW label
		{
			NAME = "Holographic Resolution Enhancer",
			DESC = "Unit is summoned by another agent (the <c:61AAAA>Host<c>) carrying a unique augment. Upgrade <c:FF8411>Resolution</c> to gain extra control range and <c:FF8411>Synchronicity</c> for <c:61AAAA>Host</c> enhancements.",
			FLAVOR = "Had a few hostile takeovers and failed launch campaigns gone a tad better, FTM would never have overtaken Plastech as the world's prime holoprojection media giants.",
			TIPS = {
				{	"Direct Projection",
					"Dragon disappears at the end of the turn if not in sight of the <c:61AAAA>Host</c>.",
					"gui/icons/arrow_small.png"},
				{	"Gear Optimization Algorithms",
					"At {1}Synchronicity 2</c>, the <c:61AAAA>Host</c> can carry an extra item.",
					"gui/icons/arrow_small.png",
					{
						{"acw_synchronicity", 2},
						"<c:FFFF80>",
						"<c:FF8411>",
					}},
				{	"Processing Power Surplus",
					"At {1}Synchronicity 3</c>, the <c:61AAAA>Host</c> gains an augment slot.",
					"gui/icons/arrow_small.png",
					{
						{"acw_synchronicity", 3},
						"<c:FFFF80>",
						"<c:FF8411>",
					}},
				{	"Temporary Combat Override Module",
					"At {1}Synchronicity 5</c>, the <c:61AAAA>Host</c> gains a layer of Dermal Armor.",
					"gui/icons/arrow_small.png",
					{
						{"acw_synchronicity", 5},
						"<c:FFFF80>",
						"<c:FF8411>",
					}},
			},		
		},
		PROJECTOR = 
		{
			NAME = "EMMA Projector",
			DESC = "Unit becomes the <c:61AAAA>Host</c>, able to manifest Dragon in their sight range. Manifesting costs an attack, and Dragon uses the <c:61AAAA>Host</c>'s AP.",
			FLAVOR = "\"Two heads are better than one. But the second opinion need not be physical.\"\n  -Enhancement Module & Multitask Assistant advert",
			TIPS = {
				{	"Optical Interference", 
					"Sight and throw ranges are limited to <c:FFFF80>{1} tiles</c>, upgraded by Dragon's <c:FF8411>Resolution</c> skill.",
					"gui/icons/arrow_small.png",
				},
				{	"Direct Projection",
					"Dragon disappears at the end of the turn if not in sight of the <c:61AAAA>Host</c>.",
					"gui/icons/arrow_small.png"},
			},
			DEPLOY_NAME = "Manifest Dragon",
			DEPLOY_DESC = "Materialize Dragon onto target tile. Costs {1} AP.",
		}]]
	},

	DAEMONS = 
	{

		FEAR = 
		{
			NAME = "FEAR",
			DESC = "Fully drains a random agent's AP",
			SHORT_DESC = "An agent loses AP",
			ACTIVE_DESC = "An agent loses all AP",
			AGENTTEXT = "FEAR\nAP DRAINED" --this appears above affected agent's head
		},	
		UNIFORM = 
		{
			NAME = "UNIFORM",
			DESC = "A random guard gains 1 armor permanently",
			SHORT_DESC = "A guard gains 1 armor",
			ACTIVE_DESC = "A guard gains 1 armor",
			TOOLTIP = "SUITED UP",
			TOOLTIP_DESC = "This unit has +1 armor.",
		},
		CREDENTIALS = 
		{
			NAME = "VERIFY",
			DESC = "A random guard changes patrol",
			SHORT_DESC = "A guard changes patrol",
			ACTIVE_DESC = "A guard changes patrol",
		},
		PROMPT = 
		{
			NAME = "PROMPT",
			DESC = "Drains 1 PWR, then installs itself onto two devices",
			SHORT_DESC = "Drains small PWR, reinstalls twice",
			ACTIVE_DESC = "Drains {1} PWR, jumps to 2 more devices",
		},
		MASK = 
		{
			NAME = "MASK",
			DESC_HARD = "Daemons are shuffled, then hidden for the duration.",
			DESC = "Daemons are shuffled. Daemons, except known ones, are hidden for the duration.",
			SHORT_DESC = "Daemons are shuffled and hidden.",
			ACTIVE_DESC = "Daemons are shuffled and hidden.",
		},
		TRANSPARENCY = 
		{
			NAME = "TRANSPARENCY",
			DESC = "Unlocked doors are open and cannot be closed",
			SHORT_DESC = "Doors are open",
			ACTIVE_DESC = "Doors must stay open",
			WARNING = "TRANSPARENCY DAEMON\nDOOR STAYS OPEN"
		},	
		BARRICADE = 
		{
			NAME = "BARRICADE",
			DESC = "Secure and vault doors cannot be opened",
			SHORT_DESC = "Secure and vault doors are reinforced",
			ACTIVE_DESC = "Advanced doors are locked down"
		},	
	},

	FRAMES = {
		DUMMY = "ACW_INVALID_FRAME",
		DUMMY_TIP = "ACW_INVALID_FRAME_TITLE",
		DUMMY_TIP_CONT = "ACW_INVALID_FRAME_TOOLTIP",

		--INSTALLED_MODAL_TITLE = "A U G M E N T A T I O N  G R A F T",
		INSTALL = "INSTALL MCD",
		INSTALL_DESC = "Matrix Configuration Datapacks are used by permanently installing them into Incognita. Do you want to install this MCD now?",
		INSTALLED_MODAL_TOP_TEXT = "I N C O G N I T A  A D J U S T M E N T  P R O C E D U R E",
		INSTALLED_MODAL_TITLE = "INCOGNITA: NEW MATRIX APPLIED",
		INSTALLED_MODAL1 = "The {1} configuration has been installed.",

		SPEC_PROGRAM_SLOT = "This slot is reserved for {1} programs only.",
		REASON_SPEC_SLOTS = "No available slots of the correct type for this program!",

		FRAME = " MATRIX",
		TOOLTIP = {
			PWR = "Power (current/starting/max): {3}/{2}/{1}",
			PROGRAMS = "Programs (installed/potential): {2}/{1}",
			SPEC_PROGRAMS = "Specialized programs:",
			SPEC_TYPE = " - {1}: {2} slots",
			HASH = "Hash Keys (current/max): {2}/{1}",
			PWRMOD = "Program PWR cost modifier: {1}",
			CDMOD = "Program cooldown modifier: {1}",
			ALGO = "Daemon reversal chance (base/current): {1}%/{2}%",
			DAEMON_LENGTH = "Daemon duration modifier: {1} TURNS",
		},
		INFORMATION = "<c:8CFFFF>CONFIGURATION</c>\n<font1_18_sb><c:FF6000>{1}</c></font>\n\n{2}{3} maximum PWR\n{4}{5} program slots\n{6}\n{7}",
		INFO_2 = "<c:8CFFFF>(hover for more info)</c>",

		SPYMASTER = {
			NAME = "MEMORY MASTER",
			FLAVOR = "The premier underground configuration is reliable, adaptable and, if you know where to look, even cheap.",
			--SPECIAL = "10%% reversal chance",
		},
		CUSTOM_SPYMASTER = {
			NAME = "SPYMASTER",
			FLAVOR = "Incognita's seen many reconfigurations as requirements changed. Currently, she represents a formidable field agent support network.",
			--SPECIAL = "10%% reversal chance",
		},
		DESPERADO = {
			NAME = "DESPERADO",
			FLAVOR = "The Desperado config was the nail in the coffin for MCDs' legal spread. It contained a revolutionary power retention technique, drawing power in minute quantities from devices on the same network. Hackers were quick to abuse this algorithm.",
			SPECIAL = "+1 PWR on capture",
			SPECIAL_EXTENDED = "Generates 1 PWR when a device is captured.",
		},
		TOOLBOX = {
			NAME = "THE TOOLBOX",
			FLAVOR = '"Mac" is written on the side of this drive. It is surely too colourful to be corporate-approved.',
			--SPECIAL = "",
		},
		OBELUS = {
			NAME = "OBELUS",
			FLAVOR = "It draws in all sorts of cyberspace peculiarities. Usually, this attention only complicates matters for the user. But with a savvy mind...",
			SPECIAL = "+30%% Reversal, +3 turns to Daemons",
			SPECIAL_EXTENDED = "All installed Daemons have +3 turns of duration, but are more likely to be reversed.",
		},
		GRIMOIRE = {
			NAME = "GRIMOIRE",
			FLAVOR = "A whole partition designed for small, random, cobbled-together bits of code.",
			SPECIAL = "3 {1} slots",
		},
		RED_QUEEN = {
			NAME = "THE RED QUEEN",
			FLAVOR = "A powerful chess engine is adept at security audits. You just need to provide it the proper data.",
			SPECIAL = "3 {1} slots",
		},
		MONOLITH = {
			NAME = "MONOLITH",
			FLAVOR = "The drive that carries this set of instructions is itself a full kilogram of weight. It's meant for a supercomputer, and sustainability is not exactly a foremost concern.",
			SPECIAL = "",
		},
		BLACKGUARD = {
			NAME = "BLACKGUARD",
			FLAVOR = "This advanced threat processing system has long been rumoured by underground conspiracy theorists to be proof that the wars between the corps are a front for a hidden cooperation program. Nonsense sure as day, of course.",
			SPECIAL = "Breaks 1 firewall when a device is newly spotted.",
			ABILITY_SUCCESS = "FIREWALL BROKEN",
			ABILITY_FAILURE = "HACKING BLOCKED",
		},
		DINOSAURUS = {
			NAME = "DINOSAURUS",
			FLAVOR = [["Who said you can't teach an old breaker new tricks?" -g00ru]],
			SPECIAL = "Improves a breaker to break +2 firewalls.",
			SPECIAL_EXTENDED = "Activate to permanently bind to a breaker. Bound program breaks +2 firewalls.",
			BUTTON_ACTIVE = "<c:8CFFFF>BIND</c>",
			BUTTON_INACTIVE = "<c:FF8411>BOUND</c>",
			BUTTON_INACTIVE_HOVER = "Config bound to a program. Sell the program or the config to break the binding.",
			CHOICE_TITLE = "BIND DINOSAURUS",
			CHOICE_DESC = "Bind the Dinosaurus config to a breaker program to give it +2 breaking power. The binding is permanent, until either the program or the config is sold!",

			TOOLTIP_TITLE = "DINOSAURUS ENHANCEMENT",
			TOOLTIP_DESC = "Program has +2 extra breaking power. Rawr!",
		},
		HEARTBEAT = {
			NAME = "HEARTBEAT",
			FLAVOR = "In the silence, as death's certainty closed in, a flash of light saved the day. They gained a second chance. They lost something, too.",
			SPECIAL = "Destroys a program to revive all agents.",
			SPECIAL_EXTENDED = "Activate and permanently destroy a program to revive all non-pinned agents.",
			BUTTON_ACTIVE = "<c:8CFFFF>RESURRECT</c>",
			BUTTON_INACTIVE = "<c:FF8411>INACTIVE</c>",
			BUTTON_INACTIVE_HOVER = "No non-pinned agents to resurrect, or installed programs to destroy.",
			CHOICE_TITLE = "USE HEARTBEAT",
			CHOICE_DESC = "Choose a program to sacrifice. All non-pinned agents will be revived.",
		},
	},

	GUARDS = {
		MGHOST = {
			TOOLTIP = "Virtual Construct",
			TOOLTIP_DESC = "This unit may pass through devices, and can only see mainframe threats.",
		},
		VOIDFIELD = {
			TOOLTIP = "Void Field",
			TOOLTIP_DESC = "Emits a field that impairs senses of all units within {1} tiles.",
		},
		VOIDBLOCK = {
			TOOLTIP = "Voided",
			TOOLTIP_DESC = "Inside a Void Field: cannot hear, sight range reduced.",
		},
		HYPERFOCUS = {
			TOOLTIP = "Emotionless",
			TOOLTIP_DESC = "This unit can never become alerted and does not see enemies.",
		},
		STONEWALL = "STONE-W411",
		VIGILANTE = "VIGIL-4NT3",
		NOCTIS = "NOCT-15",
		PANDORA = "PAN-D0R4",
	},

	ITEMS = 
	{
		CONFIDENCE_BOOSTER = 
		{
			NAME = "Confidence Booster",
			DESC = "KOs a guard for 2 turns or restores 4 AP.",
			FLAVOR = "Decker's favourite. A bottle of whiskey has its uses: it's a heavy blunt weapon, a mini-stimulant and a cure for nervousness all in one.",
		},
		SCRIPT_CHIP = 
		{
			NAME = "Script Chip",
			DESC = "Contains Payload, Launcher and Module scripts. Combine multiple Chips at a console to craft a program.",
			FLAVOR = "WATCH AND LEARN, KID.\n                                              -r4ttlesn4ke",

			-- out of mission description. Extra abilities are not shown while out of mission, so we change the desc entry
			DESC_DOWNTIME = "Contains the <c:F4FF78>{1}</c>, <c:F4FF78>{2}</c> and <c:F4FF78>{3}</c> scripts. Currently selected:\n\n<c:F4FF78>{4}</c> - {5}",

			TIP = "SWITCH SCRIPT",
			TIP_DESC = "Each Script Chip has 3 scripts, but only one script per chip may be used.",------------------------|",
			TIP_USE_DESC = "Cycle the selected active script.",
			CANNOT_SWITCH = "Cannot switch in the middle of compilation - abort and try again!",
			CHIP_USED = "SCRIPT COMPILING",
			CHIP_USED_DESC = "<c:FF6000>The chip is currently inserted into the console during compilation.</c>",

			COMPILE = "COMPILE PROGRAM",
			COMPILE_DESC = "Use the <c:F4FF78>{1}</c> script in program assembly.",
			COMPILE_COMPLETE = "COMPLETE COMPILATION",
			COMPILE_COMPLETE_DESC = "Assemble the <c:FF6000>{1}{2}{3}</c>program.",
			COMPILE_COMPLETE_TOO_MANY = "No available program slots!",
			COMPILE_ABORT = "ABORT COMPILATION",
			COMPILE_ABORT_DESC = "Reset the process of program assembly.",
			COMPILE_DOPPLE_WARNING = "<c:FF6000>Warning: tachyon damage detected!</c>",
		},

		FRAMEWORK = {
			NAME = "{1}.mcd",
			DESC = "Use to reconfigure Incognita's capabilities. Previewing <c:0060FF>{1}</c> config against current (<c:F4FF78>{2}</c>):",
			DESC_SINGLE = "Use to reconfigure Incognita's capabilities. Previewing <c:0060FF>{1}</c> config:",
			DESC_SIMPLE = "Use to reconfigure Incognita's capabilities, such as max PWR or program slots.",
			FLAVOR = "The Matrix Configuration Datapacks (.mcd) are used by administrators everywhere to preserve their preferences across a multitude of barely-standardized devices. They are notoriously unsecure and typically banned by the corps for that reason, but the ban is poorly enforced. Comfort triumphs over common sense once more.",

			INSTALL = "APPLY MATRIX CONFIGURATION DATAPACK",
			INSTALL_DESC = "Replace Incognita's current Configuration Matrix with this one.",

			CANT_INSTALL_REASON = {
				PROGRAM_SLOTS = "Not enough program slots!",
				SAME_FRAME = "Already using this configuration!",
				SPEC_PROGRAMS = "Not enough program slots of the proper type!",
			},

			TOOLTIP_COMPARISONS = {
				PWR = "Max PWR modifier: {2} ({1})",
				PROG = "Program slot modifier: {2} ({1})",
				SPEC = "Slots reserved for special programs:\n{2} ({1})",
				SPEC_TYPE = " - including for {1}: {3} ({2})",
				PMOD = "Program cost modifier: {2} ({1})",
				HASH = "Hash Key capacity: {2} ({1})",
				ALGO = "Daemon reversal chance: {2}% ({1}%)",
				DAEMON = "Daemon duration modifier: {2} ({1})",
				LOST_SPECIAL = "This special ability will be lost:",
				GAINED_SPECIAL = "This special ability will be gained:",
			},

			TOOLTIP_SINGLES = {
				PWR = "Max PWR modifier: {1}",
				PROG = "Program slot modifier: {1}",
				SPEC = "Slots reserved for special programs:\n{1}",
				SPEC_TYPE = " - including for {1}: {2}",
				PMOD = "Program cost modifier: {1}",
				HASH = "Hash Key capacity: {1}",
				ALGO = "Daemon reversal chance: {1}%",
				DAEMON = "Daemon duration modifier: {1}",
				GAINED_SPECIAL = "This special ability will be gained:",
			},
		},
	},

	LOADING_TIPS = {
		"ADVANCED CYBERWARFARE: Watch out for the improved Mask daemon! Daemons will be shuffled around before being hidden. Previously safe devices might be infested!",
		"ADVANCED CYBERWARFARE: Payload scripts add functionality to the program. For example, they might allow it to break firewalls, or buff your agents.",
		"ADVANCED CYBERWARFARE: Launcher scripts add PWR costs and cooldowns to the program. Sometimes they also attach conditions, making the program auto-triggered.",
		"ADVANCED CYBERWARFARE: A Module script can be added during compilation. These increase the program's sell value and add unique and potent modifiers to it.",
		"ADVANCED CYBERWARFARE: To compile a custom program, you'll need two Script Chips, set into Payload and Launcher modes respectively. You may add a third, a Module.",
		"ADVANCED CYBERWARFARE: Each Script Chip contains three scripts of different kinds. You'll need to pick the one you want to use in a program.",
		"ADVANCED CYBERWARFARE: If playing with Programs Extended's Counterintelligence AI, additional content might be present in the mod!",
		"ADVANCED CYBERWARFARE: Dragon decays if she's alone in the field. If all other agents are KO, you'll need to extract quickly or use Burnout Protocol to revive one.",
		"ADVANCED CYBERWARFARE: Dragon is a great scout, but a useless item carrier and a horrid combatant. Get out before it gets hot!",
		"ADVANCED CYBERWARFARE: Bug reports are always appreciated. Your best shot at reaching the dev would be to @<c:F47932>sizzlefrostindeed</c> on Discord.",
	},

	PROGRAMS =
	{		
		PROGRAM_TITLE = "PROGRAM", -- for "CAÏSSA PROGRAM", or "SCRIPT CHIP PROGRAM"
		RESOURCE_CREDITS = "CR",
		RESOURCE_ALARM = "ALARM",

		CONVERTED_TYPES = { -- vanilla or other-modded programs that are amended to include a type
			-- when multiple types are included, they are used in the order that they appear here
			BREAKER = "BREAKER",
			GENERATOR = "GENERATOR",
			TROJAN = "TROJAN",
		},

		SCRIPT =
		{
			NAME = "ERROR NAME",
			DESC = "ERROR DESCRIPTION",
			SPEC_TYPE = "SCRIPT CHIP",
			SHORT_DESC = "USE {1}", -- fullname of the program will follow
			HUD_DESC = "CHIP | ", -- this one actually shows in-game
			TIP_DESC = "",

			NO_TARGETS = "No viable targets!",
			ERROR_NOALARM = "Cannot increase alarm further!",
			AUTOMATIC_COST_PAID = {
				-- order 1: 2 PWR CONSUMED
				"\n{1} {2} consumed.",
				-- order 2: ALARM INCREASED BY 2
				"\n{2} increased by {1}.",
			},

			-- CHIP DESCS: short versions show up in the chip tooltip. It's limited to 31 normal characters/20 >W< ide ones.

			MAINS = {
				BLAST = {
					NAME = "BLAST",
					DESC = "Breaks {1} {1:firewall|firewalls}",
					HUD_DESC = "BREAKS FIREWALLS ON TARGET",
					TIP_DESC = "Break firewalls on target device.",

					CHIP_DESC = "Program breaks 2 firewalls.",
					CHIP_DESC_SHORT = "Breaks 2 firewalls.", -- tooltip width: 20/31 characters					
				},
				WAVE = {
					NAME = "WAVE",
					DESC = "Breaks {1} {1:firewall|firewalls} on {2} {2:random device|random devices}",
					HUD_DESC = "BREAKS FIREWALLS AT RANDOM",

					CHIP_DESC = "Program breaks 1 firewall on 3 random known devices.",
					CHIP_DESC_SHORT = "Breaks firewalls on 3 devices.", -- tooltip width: 31/31 characters
				},
				-- 2 more breakers: possibly use radius
				HEAT = {
					NAME = "HEAT",
					DESC = "Generates {1} PWR",
					HUD_DESC = "GENERATES PWR",

					CHIP_DESC = "Program generates 2 PWR.",
					CHIP_DESC_SHORT = "Generates 2 PWR.", -- tooltip width: 17/31 characters
				},
				-- 1 more generator
				--[[
				STAR = {
					NAME = "STAR",

					CHIP_DESC = "",
				},]]
				SHATTER = {
					NAME = "SHATTER",
					DESC = "Reduces KO resist by {1}",
					HUD_DESC = "REDUCES GUARD KO RESIST",
					TIP_DESC = "Reduce the guard's KO resist.",

					CHIP_DESC = "Program reduces KO resist on a guard by 1.",
					CHIP_DESC_SHORT = "Reduces KO resist by 1.", -- tooltip width: 23/31 characters
				},
				SWIFT = {
					NAME = "SWIFT",
					DESC = "Gives {1} {1:random agent|random agents} {2} AP",
					HUD_DESC = "BOOSTS AGENTS' AP",

					CHIP_DESC = "Program grants 2 random agents 2 AP.",
					CHIP_DESC_SHORT = "Grants 2 agents 2 AP.", -- tooltip width: 21/31 characters
				},
				CRYPTO = { -- this only shows up with PE AI
					NAME = "CRYPTO",
					DESC = "Generates {1} Hash {1:Key|Keys}",
					HUD_DESC = "GENERATES HASH KEYS",
					NO_AI = "No Hostile AI detected!",

					CHIP_DESC = "Program generates a Hash Key.",
					CHIP_DESC_SHORT = "Generates a Hash Key.", -- tooltip width: 21/31 characters
				},
				--[[COUNTER = { -- this only shows up with PE AI
					NAME = "COUNTER",
					DESC = "Sets the cooldown of subroutine {2} to {1}",
					HUD_DESC = "INTERFERES WITH HOSTILE AI",
					NO_AI = "No Hostile AI detected!",
					NO_SUB = "Current subroutine cannot be set on cooldown!",
					SUCCESS_TXT = "{1} set on {2} cooldown."

					CHIP_DESC = "Program puts random Hostile AI subroutine on cooldown. Re-tunes each turn.",
					CHIP_DESC_SHORT = "Sets AI subroutine on cooldown.", -- tooltip width: 31/31 characters
				},]]
				TRICK = {
					NAME = "TRICK",
					DESC = "Kills {1:a Daemon|Daemons}, installs {1:a Daemon|Daemons for each killed,}",
					HUD_DESC = "KILLS DAEMONS, INSTALLING NEW ONES",
					TIP_DESC = "Kill the Daemon, install a random Daemon.",

					CHIP_DESC = "Program kills a Daemon, but installs a Daemon.",
					CHIP_DESC_SHORT = "Kills Daemon, triggers one.", -- tooltip width: 28/31 characters
				},
				SHUFFLE = {
					NAME = "SHUFFLE",
					DESC = "Provides {1} extra Daemon reversal chance while cooling down,",
					HUD_DESC = "REVERSAL CHANCE ON COOLDOWN",

					CHIP_DESC = "Program grants 30 percent Daemon reversal chance while on cooldown.",
					CHIP_DESC_SHORT = "Algorithm Chance if cooling.", -- tooltip width: 30/31 characters
				},
				FLICKER = { -- implemented! ridiculous code! goal stretched!
					NAME = "FLICKER",
					DESC = "Teleports {1:an agent|agents} {2} {2:tile|tiles} laterally",
					HUD_DESC = "WARPS AGENTS",
					TIP_DESC = "Teleport the agent 2 tiles laterally.",
					ENDS_TURN = ", ending the turn, ",
					FAIL = "Cannot flicker {1}\nBlocked by wall",
					BLOCKED = "Destination blocked!",
					OCCUPIED = "Destination occupied!",

					CHIP_DESC = "Program teleports an agent 2 tiles straight, but not through walls. Ends turn unless auto-triggered.",
					CHIP_DESC_SHORT = "Teleports agent laterally.",
				},
				GORGE = {
					NAME = "GORGE",
					DESC = "Provides {1} extra max PWR while cooling down,",
					HUD_DESC = "MAX PWR ON COOLDOWN",

					CHIP_DESC = "Program grants 5 max PWR while on cooldown.",
					CHIP_DESC_SHORT = "Max PWR if cooling.",
				},
			},

			LAUNCHERS = {
				SPIKE = {
					NAME = "SPIKE",
					DESC = " for {1} {2}. {3} turn cooldown.",

					CHIP_DESC = "Program costs 0 PWR and has 2 cooldown.",
					CHIP_DESC_SHORT = "0 PWR / 2 cooldown.", -- tooltip width: 21/31 characters
				},
				HELIX = {
					NAME = "HELIX",
					DESC = " for {1} {2}. {3} turn cooldown. Triggers an extra time at random.",

					CHIP_DESC = "Program costs 0 PWR and has 3 cooldown. Fires once on your target and once randomly.",
					CHIP_DESC_SHORT = "0 PWR / 3 cd / triggers 2x.", -- tooltip width: 29/31 characters
				},
				--[[FEED = {
					NAME = "FEED",

					CHIP_DESC = "",
				},
				]]
				FORGE = {
					NAME = "FORGE",
					DESC = " for {1} {2}.",

					CHIP_DESC = "Program costs 3 PWR and has 0 cooldown.",
					CHIP_DESC_SHORT = "3 PWR / 0 cooldown.", -- tooltip width: 21/31 characters
				},
				LOAD = {
					NAME = "LOAD",
					DESC = " for {1} {2}, then makes {3} PWR. {4} turn cooldown.",

					CHIP_DESC = "Program costs 5 PWR, has 1 cooldown, and refunds 4 PWR when executed.",
					CHIP_DESC_SHORT = "5 (-4 refund) PWR / 1 cd.", -- tooltip width: 26/31 characters
				},
				LINK = {
					NAME = "LINK",
					COST_DESC = " for {1} {2}",
					DESC = " automatically at the start of the turn.",

					CHIP_DESC = "Program triggers at the start of each turn (0 PWR, 1 CD). Targets are chosen randomly.",
					CHIP_DESC_SHORT = "0 PWR / 1 cd / start of turn.", -- tooltip width: 31/31 characters
				},
				STRIKE = {
					NAME = "STRIKE",
					COST_DESC = " for {1} {2}",
					DESC = " twice automatically when a guard is KOd.",

					CHIP_DESC = "Program triggers twice on guard KO. Costs 1 PWR, has 0 CD, targets are random.",
					CHIP_DESC_SHORT = "1 PWR / 0 cd / on guard KO.", -- tooltip width: 28/31 characters
				},
				WARD = {
					NAME = "WARD",
					COST_DESC = " for {1} {2}",
					DESC = " automatically when Alarm Level increases.",					

					CHIP_DESC = "Program triggers whenever Alarm Level increases. 0 PWR, 0 CD, targets are random.",
					CHIP_DESC_SHORT = "0 PWR / 0 cd / on alarm up.", -- tooltip width: 29/31 characters
				},
			},

			MODULES = {
				--[[REMASTERED = { -- unimplemented, not sold on it, needs a further think - stretch goal
					NAME = "REMASTERED",

					CHIP_DESC = "Program continues to cool down while ready, potentially storing a second charge.",
				},]]
				OMEGA = {
					NAME = "OMEGA",

					CHIP_DESC = "Program has 2x effect, but +1 PWR cost and +1 cooldown.",
					CHIP_DESC_SHORT = "2x effect / +1 PWR / +1 cd.", -- tooltip width: 30/31 characters
				},
				DUO = {
					NAME = "DUO",

					CHIP_DESC = "Program has double the targets, but all its targets are chosen at random.",
					CHIP_DESC_SHORT = "2x targets, chosen randomly.", -- tooltip width: 31/31 characters
				},
				GOLD = {
					NAME = "GOLD",

					CHIP_DESC = "Program costs 10 credits per PWR point, instead of PWR.",
					CHIP_DESC_SHORT = "Costs CR instead of PWR.", -- tooltip width: 25/31 characters
				},
				HARDCORE = {
					NAME = "TRIAL",

					CHIP_DESC = "Program costs 1 alarm tick per 2 PWR points, instead of PWR. Rounds up.",
					CHIP_DESC_SHORT = "Costs ALARM instead of PWR.", -- tooltip width: 28/31 characters
				},
				ALPHA = {
					NAME = "ALPHA",
					REASON = "Alpha: Program has already been used!",

					CHIP_DESC = "Program has 3x effect and costs no PWR, but can only be used once per mission.",
					CHIP_DESC_SHORT = "One-use / 3x effect / 0 PWR.", -- tooltip width: 31/31 characters
				},
				LITE = { 
					NAME = "LITE",

					CHIP_DESC = "Program has -2 PWR cost, but gains +1 cooldown each time it is used.",
					CHIP_DESC_SHORT = "-2 PWR / +1 cd per use.", -- tooltip width: 24/31 characters
				},
				EVO = {
					NAME = "EVO",

					CHIP_DESC = "Program has 0.5x effect (rounded up). It gains 0.25x effect each Alarm Level.",
					CHIP_DESC_SHORT = "0.5 effect / +0.25 per alarm.", -- tooltip width: 30/31 characters
				},
				--[[FOCUS = { -- unimplemented; too close to burnout by that point, future Sizzle can handle it - stretch goal
					NAME = "FOCUS",

					CHIP_DESC = "Program has a single target instead of a radius.",
				},]]
				-- 3 more modules
			}
		},	
		DRAGON2 = 
		{
			NAME = "DRAGON'S ASSISTANCE",
			DESC = "Grants an agent +3 AP and reduces their sprint noise this turn.",
			SHORT_DESC = "USE DRAGON'S ASSISTANCE",
			HUD_DESC = "AGENT GETS NIMBLE",
			TIP_DESC = "GRANTS +3 AP AND QUIET SPRINTING",
			FAIL = "Agent already affected!",
			FAILDRAGON = "Dragon's frame is booting up!"	
		},
		NETWORK = 
		{
			NAME = "NETWORK",
			GAMEDESC = "GAIN 1 PWR PER TURN PER {1} CYBER CONSCIOUS GUARDS",
			DESC = "Connects guards to the network to gain PWR per guard.",
			SHORT_DESC = "LINK GUARD",
			HUD_DESC = "LINK GUARD TO TAG AND GRANT\nCYBER CONSCIOUSNESS",
			TIP_DESC = "Link guard: they gain Cyber Consciousness and generate PWR/turn.",		
			WARNING = "NETWORK TRACKING {1} {1:GUARD|GUARDS}\n{2} PWR GAINED",
			FAIL = "Guard already connected to the network!",
			TOOLTIP = "NETWORKED", --this is the tooltip for affected guards 
			TOOLTIP_DESC = "This guard is connected to the network and generates PWR every turn while TAGGED.",
			TRIGGER = "TAG LOST\nDISCONNECTING",
		},
		KEYHOLE = {
			NAME = "KEYHOLE",
			DESC = "Breaks 1 firewall for 0 PWR. 2 turn cooldown, reset when a device is captured.",
			SHORT_DESC = "USE KEYHOLE",
			HUD_DESC = "BREAKS 1 FIREWALL FOR FREE\nRESETS ON CAPTURE",
			TIP_DESC = "BREAKS <c:FF8411>1 FIREWALL</c>. COST: <c:77FF77>{1} PWR</c>",
		},
		FOCUS = {
			NAME = "FOCUS",
			DESC = "Reduce camera vision radius by 2 tiles for 3 turns, costs 2 PWR. 1-turn cooldown.",
			SHORT_DESC = "USE FOCUS",
			HUD_DESC = "REDUCES CAMERA VISION RANGE",
			TIP_DESC = "REDUCES CAMERA VISION RANGE BY 2 TILES. COST: <c:77FF77>{1} PWR</c>",
		},
		FEATHER =
		{
			NAME = "FEATHER",
			DESC = "Decreases alarm for 3 PWR. \n+1 PWR per use.",
			SHORT_DESC = "USE FEATHER",
			HUD_DESC = "DECREASES ALARM BY 1 POINT",
			TIP_DESC = "REVERSES ALARM TRACKER.\nCOST: <c:77FF77>{1} PWR</c>",
			WARNING = "FEATHER - ALARM DECREASED",
		},
		PECK =
		{
			NAME = "PECKPOCKET",
			DESC = "Remotely steals credits from a guard.\nDoes not benefit from agent skills.",
			SHORT_DESC = "USE PECKPOCKET",
			HUD_DESC = "STEALS A GUARD'S CREDITS",
			TIP_DESC = "STEALS A GUARD'S CREDITS.",
		},	
		DEAFEN =
		{
			NAME = "CONCUSSION",
			DESC = "Deafens a guard or captures a sound bug for 5 PWR.",
			SHORT_DESC = "USE CONCUSSION",
			HUD_DESC = "DEAFENS GUARDS OR CAPTURES SOUND BUGS",
			TIP_DESC = "DEAFENS A GUARD OR CAPTURES A SOUND BUG.\nCOST: <c:77FF77>{1} PWR</c>",
			WARNING = "Already deaf!",
		},
		PENDULUM = 
		{
			NAME = "MOONLIGHT",
			DESC = "Breaks 0, 1 or 2 firewalls for 2 PWR. Waxes and wanes over time.",
			DESC1 = "Breaks <c:FF8411>{1}</c> firewalls for 2 PWR. Waxes and wanes over time.",
			SHORT_DESC = "USE MOONLIGHT",
			HUD_DESC = "BREAKS {1} FIREWALLS",
			TIP_DESC = "BREAKS <c:FF8411>{1} FIREWALLS</c>. COST: <c:77FF77>{2} PWR</c>",
			REASON = "New Moon - can't break firewalls!",
			WARNING = "MOON PHASE CHANGED\nBREAKS {1} FIREWALLS",
		},
		SUN = 
		{
			NAME = "SUN",
			DESC = "Sets PWR to half of max PWR each turn.\nAdvances the alarm tracker.",
			SHORT_DESC = "Half PWR capacity filled each turn, alarm progresses each turn.",
			HUD_DESC = "CLEAR ALL PWR AT START OF TURN, THEN GAIN HALF OF MAX PWR. ADVANCE THE ALARM.",
			TIP_DESC = "At the start of each turn, clear all PWR, then gain half of max PWR. Advance the alarm tracker by 1.",		
			WARNING = "THE SUN RISES: PWR REFILLED\nALARM INCREASES",
		},
		WORK =
		{
			NAME = "WORK",
			DESC = "Agents get -1 AP\nPrograms cost 1 less PWR",
			SHORT_DESC = "-1 AP, -1 PWR costs",
			HUD_DESC = "AGENTS LOSE 1 AP\nPROGRAMS COST 1 LESS PWR\nPASSIVE",
			AGENTTEXT = "WORKING" --this appears above affected agent's head	
		},
		ANGEL =
		{
			NAME = "ANGEL",
			DESC = "Grants 65% Daemon reversal chance, but increases your program costs by 1.",
			SHORT_DESC = "Reverse Daemons, programs cost +1 PWR",
			HUD_DESC = "REVERSE MOST DAEMONS\nINCREASE PROGRAM COSTS BY 1\nPASSIVE",
			TIP_DESC = ""		
		},	
		DATA_BLAST2 =
		{
			NAME = "DATA PUNCH",
			DESC = "Breaks 2 firewalls on all detected devices within a radius of 2 tiles.",
			SHORT_DESC = "USE DATA PUNCH",
			HUD_DESC = "BREAKS 2 FIREWALLS",
			TIP_DESC = "BREAKS <c:FF8411>2 FIREWALLS</c>. COST: <c:77FF77>{1} PWR</c>"		
		},	
		DATA_BLAST3 =
		{
			NAME = "DATA FLOOD",
			DESC = "Breaks 5 firewalls on all detected devices within a radius of 7 tiles.\n5 turn cooldown.",
			SHORT_DESC = "USE DATA FLOOD",
			HUD_DESC = "BREAKS 3 FIREWALLS",
			TIP_DESC = "BREAKS <c:FF8411>3 FIREWALLS</c>. COST: <c:77FF77>{1} PWR</c>"		
		},
		-- Caïssa progams
		CAISSA_COMMON = {
			SPEC_TYPE = "CAÏSSA",
			CAISSA_TITLE = "CAÏSSA RESTRICTIONS",
			CAISSA_DESC = "Limits disabled if KING is installed.",
		},
		PAWN = {
			NAME = "PAWN",
			DESC = "Breaks 1 firewall for 1 PWR.",
			DESC_CAISSA = " Cannot use on a different device this turn.",
			SHORT_DESC = "USE PAWN",
			HUD_DESC = "CAÏSSA\nBREAKS 1 FIREWALL",
			TIP_DESC = "BREAKS <c:FF8411>1 FIREWALL</c>. COST: <c:77FF77>{1} PWR</c>",
			FAIL_DESC = "Cannot target a different device!",
		},
		KNIGHT = {
			NAME = "KNIGHT",
			DESC = "Breaks 2 firewalls for 2 PWR.",
			DESC_CAISSA = " Cannot target a device of the same type twice in a row.",
			SHORT_DESC = "USE KNIGHT",
			HUD_DESC = "CAÏSSA\nBREAKS 2 FIREWALLS",
			TIP_DESC = "BREAKS <c:FF8411>2 FIREWALLS</c>. COST: <c:77FF77>{1} PWR</c>",
			FAIL_DESC = "Cannot target a device of the same type!",
		},
		BISHOP = {
			NAME = "BISHOP",
			DESC = "Breaks 2 firewalls for 2 PWR.",
			DESC_CAISSA = " Cannot be used on devices with Daemons.", 
			SHORT_DESC = "USE BISHOP",
			HUD_DESC = "CAÏSSA\nBREAKS 2 FIREWALLS",
			TIP_DESC = "BREAKS <c:FF8411>2 FIREWALLS</c>. COST: <c:77FF77>{1} PWR</c>",
			FAIL_DESC = "Cannot target a device with a Daemon!",
		},
		ROOK = {
			NAME = "ROOK",
			DESC = "Breaks 3 firewalls for 3 PWR.",
			DESC_CAISSA = " Cannot be used for 3 turns after use. (3 turn cooldown)", 
			SHORT_DESC = "USE ROOK",
			HUD_DESC = "CAÏSSA\nBREAKS 3 FIREWALLS",
			TIP_DESC = "BREAKS <c:FF8411>3 FIREWALLS</c>. COST: <c:77FF77>{1} PWR</c>",
		},
		QUEEN = {
			NAME = "QUEEN",
			DESC = "Breaks 5 firewalls for 2 PWR.",
			DESC_CAISSA = " Cannot be used.",
			SHORT_DESC = "USE QUEEN",
			HUD_DESC = "CAÏSSA\nBREAKS 5 FIREWALLS\nREQUIRES KING",
			TIP_DESC = "BREAKS <c:FF8411>5 FIREWALLS</c>. COST: <c:77FF77>{1} PWR</c>",
			FAIL_DESC = "Cannot use without a King!",
		},
		KING = {
			NAME = "KING",
			DESC = "PASSIVE: Ignore the use restrictions of CAÏSSA programs.",
			SHORT_DESC = "Ignore caïssa use restrictions.",
			HUD_DESC = "CAÏSSA\nIGNORE CAÏSSA LIMITATIONS\nPASSIVE",
			TIP_DESC = "IGNORE CAÏSSA LIMITS",
		},
	},

	OPTIONS =
	{	
		ENABLE_DAEMONS = "DAEMONS, MILD AND SCARY",
		ENABLE_DAEMONS_TIP = "Adds 6 new Daemons. Also <c:FF8411>reworks Mask</c>.",
		ENABLE_HARD_MASK = "MASK OF MADNESS",
		ENABLE_HARD_MASK_TIP = "Mask will conceal previously known daemons. Turn off to retain info about known daemons, after they're shuffled to new devices.",
		ENABLE_CHIPS = "SCRIPT KIDDIES' TREASURES",
		ENABLE_CHIPS_TIP = "Adds Script Chips, found on missions. Use them at consoles to compile your own programs!",
		ENABLE_CONSOLES = "MATRIX CONFIGURATION DATAPACKS (MCDS)",
		ENABLE_CONSOLES_TIP = "New type of item, letting you reconfigure Incognita. Gives your AI new stats and/or passives.",
		ENABLE_PROGRAMS = "PROGRAMS TO THE RESCUE",
		ENABLE_PROGRAMS_TIP = "Unique programs assist Incognita in combatting threats old and new. Includes 17 programs.",
		ENABLE_ITEMS = "BONUS ITEM",
		ENABLE_ITEMS_TIP = "A bottle of whiskey, freshly fabricated. Coming to a nanofab near you!",
		ENABLE_SITREPS = "ADVANCED SECURITY SYSTEM CHANCE",
		ENABLE_SITREPS_TIP = "Some facilities may have advanced cyber-grid designs imposing unique challenges for the mission's duration. This setting sets the chance of such grids appearing.",
		ENABLE_SITREPS_CHANCE_STRINGS = {
			"OFF",
			"20%",
			"40%",
			"60%",
			"80%",
			"ALWAYS"
		},
		ENABLE_SITREPS_MID1 = "GRIDS ALLOWED AT MID MISSION",
		ENABLE_SITREPS_MID1_TIP = "Enables Grids at the first half of the mid-mission. The second brings challenges of its own, and is thus unaffected.",
		--ENABLE_PROGRAMS_STRINGS = {"DISABLED","ENABLED"}, --must be 2 in total
		ENABLE_DRAGON = "CYBERDRACONIC ROAR",
		ENABLE_DRAGON_TIP = "Enables <c:61AAAA>Dragon</c>, a program turned agent that assists Invisible between reality and cyberspace.",
		DRAGON_TIMER_LENGTH = "BASE DRAGON FADEOUT",
		DRAGON_TIMER_LENGTH_TIP = "<c:61AAAA>HIGHER = EASIER.</c>\n\nDetermines how much time On-File Dragon can spend alone in the field. Once she becomes alone (when other agents have been captured or extracted), you will have this long to extract her.\n\nThis is only the base value; you may upgrade the longevity of Dragon via her Stability skill, and by default, each alarm level reduces this timer by 1 (you can change this via the MINIMUM FADE ALARM setting, or set this to INDEFINITE to disable fading entirely).\n\n<c:FF8411>INSTANT DEATH IS ALWAYS INSTANT!</c>",
		DRAGON_TIMER_LENGTH_STRINGS = {
			"<c:FF6000>INSTANT DEATH</c>",
			"1 TURN",
			"2 TURNS",
			"3 TURNS",
			"4 TURNS",
			"5 TURNS",
			"6 TURNS",
			"7 TURNS",
			"8 TURNS",
			"9 TURNS",
			"10 TURNS",
			"11 TURNS",
			"12 TURNS",
			"13 TURNS",
			"14 TURNS",
			"15 TURNS",
			"<c:61AAAA>INDEFINITE</c>"
		},
		DRAGON_TIMER_ALARM = "MINIMUM FADE ALARM",
		DRAGON_TIMER_ALARM_TIP = "<c:61AAAA>HIGHER = EASIER.</c>\n\nMinimum alarm level for Dragon to start fading away. Dragon still only fades if left alone in the field. Higher alarms equals more leeway.\n\n<c:61AAAA>ALWAYS</c> means Dragon will always fade when alone.\n<c:61AAAA>DECAYING</c> means Dragon will always fade when alone, and you will have one fewer turn to extract her for each alarm level.\n<c:61AAAA>ONLY AT CAP</c> means Dragon will only fade when alone and alarm is maxed out.",
		DRAGON_TIMER_ALARM_STRINGS = {
			"DECAYING",
			"ALWAYS",
			"1",
			"2",
			"3",
			"4",
			"5",
			"ONLY AT CAP"
		},
		DRAGON_TIMER_ALARM_STRINGS_PE = {
			"DECAYING",
			"ALWAYS",
			"1",
			"2",
			"3",
			"4",
			"5",
			"6",
			"7",
			"ONLY AT CAP"
		}
	},

	REASON = {
		GUARD_ALERTED = "GUARD NOTICED DISTURBANCE", --these two show up under "ALARM LEVEL INCREASED"
		DRONE_ALERTED = "SUBVERTED DRONE REACTION",
		DESTROYER = "FAILSAFE AI\nSubvert blocked.", --codified easter egg
		CLOAK_AUG_BLOCKED = "Can't install cloaking augmentations to a permanently cloaked agent!",
	},

	SKILLS = {
		STABILITY_NAME = "STABILITY",
		STABILITY_DESC = "Lengtens the time Dragon can spend alone in a level.",
		STABILITY1_TOOLTIP = "Standard duration",
		STABILITY2_TOOLTIP = "+1 turn\nBypass secure doors",
		STABILITY3_TOOLTIP = "+1 turn",
		STABILITY4_TOOLTIP = "+1 turn\nBypass magnetic reinforcements",
		STABILITY5_TOOLTIP = "+2 turns\nBypass vault doors and null zones",

		RESOLUTION_NAME = "RESOLUTION",
		RESOLUTION_DESC = "Improves control range for Dragon (and sight range for the Host).",
		RESOLUTION1_TOOLTIP = "Can manifest and control Dragon at range",
		RESOLUTION2_TOOLTIP = "Adds +1 tile\n-1 Manifest AP cost",
		RESOLUTION3_TOOLTIP = "Adds +1 tile",
		RESOLUTION4_TOOLTIP = "Adds +1 tile\nManifest is free",
		RESOLUTION5_TOOLTIP = "Adds +2 tiles",

		SYNCHRONICITY_NAME = "SYNCHRONICITY",
		SYNCHRONICITY_DESC = "Improves the Host's stats.",
		SYNCHRONICITY1_TOOLTIP = "Standard stats",
		SYNCHRONICITY2_TOOLTIP = "Host can carry an extra item",
		SYNCHRONICITY3_TOOLTIP = "Host gets an augment slot (up to 6)",
		SYNCHRONICITY4_TOOLTIP = "Host gets +1 movement\n-1 sprint noise",
		SYNCHRONICITY5_TOOLTIP = "Host adds a layer of Dermal Armor",
	},

	SITREPS = {
		GRID_DEFAULT = " Grid",
		EFFECT_APPLIED = "(Effect applied)",
		SANSAN = {
			NAME = "SanSan City",
			DESC = "Whenever Alarm Level increases, add 1 tick to it.",
			FLAVOR = "Every hour, every minute, every second.",
			-- https://netrunnerdb.com/en/card/31060; also, insert the BBC news theme
			TRIGGER = "SanSan Grid\nAlarm advances",
		},
		CRISIUM = {
			NAME = "Crisium",
			DESC = "Daemons cannot be reversed.",
			FLAVOR = "You are being made sane.\n--u are bei-g mad- sa-e \nY-u ar- be-n----d      \n -u -r-?",
			-- https://netrunnerdb.com/en/card/26099 cerebral overwriter my beloved
			TRIGGER = "Crisium Grid\nDaemon reversal undone.",
		},
		DJUPSTAD = {
			NAME = "Djupstad",
			DESC = "When the objective is completed, your units get -2 max AP for the rest of the mission.",
			FLAVOR = "Getting in is half the job, but of course not all halves are created equal...",
			-- https://netrunnerdb.com/en/card/04110
			FLAVOR_USED = 'Once inside, the only way out is through your own mind.',
			TRIGGER = "Djupstad Grid\nAgent AP reduced",
			AFFECTED = "Agent's max AP is reduced by 2 until the end of the mission.",
		},
		SATELLITE = {
			NAME = "Satellite",
			DESC = "When the objective is completed, lock the exit elevator for 5 turns.",
			FLAVOR = '"For your own safety, please utilize the emergency transport pads in an orderly manner."',
			FLAVOR_USED = '"Deploying in T-minus 5..."',
			-- https://netrunnerdb.com/en/card/35039
			TRIGGER = "Satellite Grid\nExit locked",
		},
		MIRRORMORPH = {
			NAME = "Mirrormorph",
			DESC = "After a device is hacked, drain 1 PWR.",
			FLAVOR = "To each action, an equal reaction.",
			TRIGGER = "Mirrormorph Grid\nPWR drained",
		},
		OAKTOWN = {
			NAME = "Oaktown",
			DESC = "ALL units have +3 sprint noise.",
			FLAVOR = [[Wood flooring's done the job for generations. And it's still in fashion.]],
			AFFECTED = "Unit has +3 sprint noise.",
		},
		SKORPIOS = {
			NAME = "Skorpios",
			DESC = "Weapons are limited to 3 charges.",
			FLAVOR = "At Skorpios Defense Systems, mere gunpowder detection isn't where security ends.",
			AFFECTED = "Item has a max of 3 charges.",
		},
		HOKUSAI = {
			NAME = "Hokusai",
			DESC = "All drones start disabled. Each turn, one is booted up, pre-alerted.",
			FLAVOR = "Director Kase hung landscapes of the Hokusai facility behind their desk. The implication was wonderful for concentrating the minds of the staff.",
			-- https://netrunnerdb.com/en/card/31059
			AFFECTED = "Drone is disabled.",
		},
		ARGUS = {
			NAME = "Argus",
			DESC = "When the objective is completed, install a Blowfish.",
			FLAVOR = '"Protection Guaranteed." - division slogan',
			FLAVOR_USED = '"We never sleep."',
			-- https://netrunnerdb.com/en/card/07001
		},	
		MANEGARM = {
			NAME = "Manegarm",
			DESC = "When a nanofab or server terminal window is closed, end the turn.",
			FLAVOR = "The number of yearly reported thefts has been steady at 12, and that's including the border control incident.",
		},
		MAHKOTA_LANGIT = {
			NAME = "Mahkota Langit",
			DESC = "The Counterintelligence AI subroutine deletion requirement is increased by 2.",
			FLAVOR = "The foundation of a space elevator is, by obvious necessity, well-secured.",
		},
		TERMINUS = {
			NAME = "Terminus",
			DESC = "At max alarm, agents can be detected through cover.",
			FLAVOR = "Asleep at the wheel of profit... for now.",
			FLAVOR_USED = [["You're dead, mate."]],
			-- honouring my favourite deck writeup, https://netrunnerdb.com/en/decklist/92862dbd-fb52-4bc6-82e1-d6b3c60dceff/-ur-ded-m8-the-most-dangerous-game-v-2-0
		},
		HARMONY = {
			NAME = "Harmony",
			DESC = "Additional scientists are present in the level.",
			FLAVOR = '"Together we have all but eradicated natural diseases from the face of this planet."',
			-- https://netrunnerdb.com/en/card/05014
			SCIENTIST_TITLE = "HARMONY MEDTECH RESEARCHER",
		},
		ATEIA = {
			NAME = "A Teia",
			DESC = "Firewall boosting is twice as effective.",
			FLAVOR = [["We'd look like fools if we could not keep the intellectual properties we recover."]],
		},
		GRNDL = {
			NAME = "GRNDL",
			DESC = "Turrets have +2 HP, ammo and firewalls.",
			FLAVOR = "Many rare elements are processed at GRNDL refineries. Security benefits from their abundance.",
		},
		GAMENET = {
			NAME = "GameNET",
			DESC = "Small nanofabs and server terminals are replaced with databases.",
			FLAVOR = "The most responsive servers this side of the Moon.",
		},
		NISEI = {
			NAME = "Nisei",
			DESC = "When the objective is completed, rewind, then pinpoint 2 agents.",
			FLAVOR = '"We could stop disasters before they happen..."',
			--https://netrunnerdb.com/en/card/31052
			FLAVOR_USED = '"Your arrival is not unexpected."',
			-- Not really a quote, but a general vibe of Nisei being a clone psychic precognition project
			--[[NAMES = {
				A = "Akiko",
				C = "Caprice",
				D = "Diana",
				E = "Emiko",
				L = "Letheia",
				M = "Mitsui",
				S = "Shimizu",
				T = "Tera",
				Y = "Yuki",
			},]]
		},
	},

	WORLD = {
		GRID = {
			DISPLAY = "ACW_INVALID_GRID",
			NAME = "Regional Cybersecurity Measure",
			DESC = "A special modifier present in some missions.",
		},
	},
}

return DLC_STRINGS
























