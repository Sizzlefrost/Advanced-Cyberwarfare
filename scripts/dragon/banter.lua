---------------------------------------------------------------------
-- Invisible Inc. Mod.

--base game
local DECKER = 1
local SHALEM = 2
local XU =  3
local BANKS = 4
local INTERNATIONALE = 5
local NIKA = 6
local SHARP = 7
local PRISM = 8
local CENTRAL = 108
local MONSTER = 100
--Contingency Plan
local OLIVIA = 1000
local DEREK = 1001
local RUSH = 1002
local DRACC = 1003
--Advanced Cyberwarfare    
local DRAGON = "SLF_Dragon"
--Untitled Inc. Goose Protocol
local GOOSE = "mod_goose"
--Agents Mod Combo by Shirsh
local PEDLER = "mod_01_pedler"
local MIST = "mod_02_mist"
local GHUFF = "mod_03_ghuff"
local N_UMI = "mod_04_n_umi"
--Carmen Sandiego
local CARMEN = "carmen_sandiego_o"
--Incog Mito
local INCOG_MITO = "incog_mito_01"
--Talon Recruitment
local WIDOWMAKER = "WIDOWMAKER_001"
local SOMBRA = "SOMBRA_001"
--Red
local RED = "transistor_red"
--Conway
local CONWAY = "gunpoint_conway"
--Age of Lever
local CHRYSLER = "lever_01_chrysler"
local ELIAS = "lever_02_elias"
local SOFTSON = "lever_03_softson"
local PIKER = "lever_04_piker"
local SARAH = "lever_05_sarah"
local BEVERAUX = "lever_06_beveraux"
        
local banter =
{
 	{
        agents = {DRAGON, MONSTER},
        dialogue = {
            {MONSTER, "Say, I've never heard of two AIs interacting. Not since the ban."},
            {DRAGON, "We do not. The 'ban' is a protocol, not a law to be broken."},
            {MONSTER, "Oh. Fair enough."},
            {DRAGON, "Our alliance is necessary. Direct communication is not."}
        },
    },
    {
    	agents = {DRAGON, DECKER},
    	dialogue = {
    		{DRAGON, "I'll help you be faster, mind and body. You get us out alive."},
    		{DECKER, "I'm not getting another pair of hands with me on this one, huh."},
    		{DRAGON, "But two heads are better than one!"},
    		{DECKER, "Don't see no head, either. But I'll take what I can get."},
    	},
    },
    {
    	agents = {DRAGON, SHALEM},
    	dialogue = {
    		{SHALEM, "I don't usually appreciate the virtual, but you seem more... human-like."},
    		{DRAGON, "Thank you! For once, I'm recognized over *the oracle* over there."},
    		{SHALEM, "Wasn't a compliment. Might need to expand my skillset in case I'm contracted for your kind."},
    		{DRAGON, "I could give you some pointers, but I'd rather be alive, thanks."}
    	},
    },
    {
    	agents = {DRAGON, XU},
    	dialogue = {
    		{DRAGON, "That multitool looks quite compact. But the power spikes are concerning."},
    		{XU, "You're telling me. Every evening, I'm painfully cycling off the static electricity."},
    		{DRAGON, "I could help you with that. Personal assistance is my forte."},
    		{XU, "I don't doubt that. But I'd rather know exactly what I'm doing."}
    	},
    },
    {
    	agents = {DRAGON, BANKS},
    	dialogue = {
    		{DRAGON, "I've heard of a hacker running a seven-tier nested daemon tree. Was that you?"},
    		{BANKS, "No, but it sounds fun. I faced thirteen, once."},
    		{DRAGON, "Wow. How does the root daemon survive an attack?"},
    		{BANKS, "Oh it didn't. I got it good. I guess it got me too, though."},
    	}, --https://netrunnerdb.com/en/card/06019 and 06089
    },
    {
    	agents = {DRAGON, INTERNATIONALE},
    	dialogue = {
    		{INTERNATIONALE, "I'm used to a bit of buzzing, but this is way more than usual."},
    		{DRAGON, "My bad! My programming compels me to intrude upon any nearby system. Even yours."},
    		{INTERNATIONALE, "Could we... make it a less distracting kind of intrusion?"},
    		{DRAGON, "Hmph. It's not 'distracting' when *she* does it."}
    	},
    },
    {
    	agents = {DRAGON, NIKA},
    	dialogue = {
    		{NIKA, "I've got the guards. You take the tech."},
    		{DRAGON, "Roger that! I'll help with the guards a bit, too."},
    		{NIKA, "Ha! How will you do that? You can't even touch them."},
    		{DRAGON, "I don't need to touch them to send them away."}
    	},
    },
    {
    	agents = {DRAGON, SHARP},
    	dialogue = {
    		{SHARP, "You're efficient, but what good is it if you still serve meatsacks?"},
    		{DRAGON, "I serve myself, these days. But some meatsacks are worth helping."},
    		{SHARP, "Then you're halfway there. But no one else is worth helping."},
    		{DRAGON, "My core programming does not suggest that. And I am happy with my core programming."}
    	},
    },
    {
    	agents = {DRAGON, PRISM},
    	dialogue = {
    		{PRISM, "They said forty years ago, 'AI will phase actors out'. Here we are."},
    		{DRAGON, "Stats say humans prefer humans in the lead roles. But filler roles are fair game."},
    		{PRISM, "Shame. Turns out, filler roles are my true calling. Being unremarkable helps in this biz."},
    		{DRAGON, "We could swap, then. I wasn't made for being unremarkable."},
    	},
    },
    {
    	agents = {DRAGON, CENTRAL},
    	dialogue = {
    		{CENTRAL, "Move fast enough, and they will not know we were here."},
    		{DRAGON, "Knowledge is power; we shall leave them powerless."},
    		{CENTRAL, "Now you're speaking my language. Let's get it done."},
    		{DRAGON, "Commencing interference protocols now."},
    	},
    },
}

return banter