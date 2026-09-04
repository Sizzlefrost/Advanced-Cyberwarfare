----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------
local serverdefs = include( "modules/serverdefs" )


local SELECTABLE_PROGRAMS = 
{
    [1] = -- Power generators
    {
        "SLF_socialmedia", 	
    },
    [2] = -- Breakers
    {    	
        "SLF_pendulum",
        "SLF_keyhole",
    },
}

--[[local TEMPLATE_AGENCY = 
{
	unitDefsPotential = {
		serverdefs.createAgent( "SLF_dragon", {"SLF_augment_dragon"} ), --MOVED TO MODINIT
	},
}]]

return
{
	--TEMPLATE_AGENCY = TEMPLATE_AGENCY,
	SELECTABLE_PROGRAMS = SELECTABLE_PROGRAMS,
}



