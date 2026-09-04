-- adding a new resource to be displayed next to PWR and credits
-- resourcePnl = 14th item in widgets list sourced from hud file

--[[
cpuNum = table: 7B297C68
{
    _name = cpuNum,
    _base = function: 7B1C7048,
    _cont = table: 7B297DA8
    {
        _sx = 1,
        _wpx = true,
        _h = 30,
        _noInput = true,
        _isVisible = true,
        _widget = table: 7B297C68
        {
            _name = cpuNum,
            _base = function: 7B1C7048,
            _cont = table: 7B297DA8,
            _tooltip = table: 7B297C90
            {
                _bodyTxt = Hijack consoles to acquire POWER.  Use POWER to run programs in the MAINFRAME.,
                _headerTxt = POWER,
                _base = function: 7B1C6DA8,
            },
            _parent = table: 7B2976F0
            {
                _name = resourcePnl,
                _children = table: 7B297EE8,
                _base = function: 7B1C7028,
                _cont = table: 7B297808,
                _parent = table: 7AFEBB70,
                binder = table: 7B299040,
            },
        },
        _maxEditChars = 0,
        _prop = 7A7991E8 <MOAITextBox>,
        _base = function: 7B1C6EE8,
        _screen = table: 7AFEBB70,
        _str = 10/20 PWR,
        _y = -24,
        _x = 81,
        _sy = 1,
        _def = table: 7AFEA8D8
        {
            hpx = true,
            tooltipHeader = table: 7AFEA400
            {
                str = STR_517759365,
            },
            color = table: 7AFEA630
            {
                1 = 0.54901963472366,
                2 = 1,
                3 = 1,
                4 = 1,
            },
            halign = 0,
            h = 30,
            text_style = font1_18_r,
            anchor = 1,
            ypx = true,
            isVisible = true,
            noInput = true,
            wpx = true,
            valign = 0,
            w = 140,
            xpx = true,
            rotation = 0,
            x = 81,
            name = cpuNum,
            sx = 1,
            ctor = label,
            y = -24,
            sy = 1,
            tooltip = table: 7AFEA450
            {
                str = STR_1677005573,
            },
        },
        _xpx = true,
        _w = 140,
        _ypx = true,
        _hpx = true,
        _anchor = 1,
    },
    _tooltip = table: 7B297C90,
    _parent = table: 7B2976F0,
}

cpuNum
x 81
y -24
w 140
h 30

rightmost edge = 81+70=151

credits 
x 189
y -24
w 70
h 30

leftmost edge = 189-35=154
rightmost edge = 189+35=224

new resource bar
x 332
y -24
w 110
h 30

leftmost edge = 332-55=277=224+3+50
rightmost edge = 332+55=387
]]

local util = include("modules/util")

local inserts =
{
    {
        "hud.lua",
        { "widgets", 9, "children" }, -- insert an item into "hud/widgets/9 (mainframePnl)/children"
        {
            name = "frame_panel",
            isVisible = true,
            noInput = true,
            anchor = 1,
            rotation = 0,
            x = 308,
            xpx = true,
            y = 140,
            ypx = true,
            w = 0,
            h = 0,
            sx = 1,
            sy = 1,
            ctor = "group",
            halign = 0,
            valign = 0,
            --color = {1,1,1,1}, -- 140/255, 255/255, 255/255, 1/1
            children =
            {
                {
                    name = "frame_panel",
                    isVisible = true,
                    noInput = true,
                    anchor = 1,
                    rotation = 0,
                    x = 0,
                    xpx = true,
                    y = 0,
                    ypx = true,
                    w = 210,
                    wpx = true,
                    h = 176,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = "image",
                    halign = 0,
                    valign = 0,
                    color = {1,1,1,1}, -- 140/255, 255/255, 255/255, 1/1
                    images =
                    {
                        {
                            file = [[gui/hud3/frame_panel.png]],
                            name = [[]],
                        },
                    },
                },  
                {
                    name = [[label]],
                    isVisible = true,
                    noInput = true,
                    anchor = 1,
                    rotation = 0,
                    x = -13,
                    xpx = true,
                    y = 5,
                    ypx = true,
                    w = 152, -- 39 space left, 13 right
                    wpx = true,
                    h = 142, -- 24 bottom, 10 top
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = [[label]],
                    halign = MOAITextBox.CENTER_JUSTIFY,
                    valign = MOAITextBox.TOP_JUSTIFY,
                    text_style = [[font1_14_r]],          
                    color = {1, 1, 1, 1},
                    str = STRINGS.SLF.FRAMES.DUMMY,
                    tooltipHeader = {
                        str = STRINGS.SLF.FRAMES.DUMMY_TIP,
                    },
                    tooltip = {
                        str = STRINGS.SLF.FRAMES.DUMMY_TIP_CONT,
                    },              
                },
                {
                    name = "frame_active",
                    isVisible = false,
                    noInput = false,
                    anchor = 1,
                    rotation = 0,
                    x = -13, -- 158 true mid; 105 apparent mid
                    xpx = true,
                    y = 109,
                    ypx = true,
                    w = 103,
                    wpx = true,
                    h = 53,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = "button",
                    halign = MOAITextBox.CENTER_JUSTIFY,
                    valign = 0,
                    color = {1,1,1,1}, -- 140/255, 255/255, 255/255, 1/1
                    images =
                    {
                        {
                            file = [[gui/hud3/frame_activate_push.png]],
                            name = [[inactive]],
                        },
                        {
                            file = [[gui/hud3/frame_activate_hl.png]],
                            name = [[hover]],
                        },
                        {
                            file = [[gui/hud3/frame_activate.png]],
                            name = [[active]],
                        },
                    },
                    clickSound = [[SpySociety/HUD/menu/click]],
                    hoverSound = [[SpySociety/HUD/menu/rollover]],
                    hoverScale = 1.1,
                    text_style = [[font1_16_sb]],          
                    color = {140/255, 1, 1, 1},
                    str = "<c:8CFFFF>ACTIVATE</c>",
                    offset =
                    {
                        x = 0,
                        xpx = true,
                        y = -8,
                        ypx = true,
                    },
                    line_spacing = 0,     
                },             
            },
        },
        opt = "ac_frames",
    },
    {
        "hud.lua",
        { "widgets", 2, "children" }, -- "widgets / statsPnl (2) / children"
        {
            name = [[statsGridTxt]],
            isVisible = true,
            noInput = true,
            x = -0.19,     -- -0.175
            y = -75,
            ypx = true,
            w = 0.25,       -- 0.35
            h = 150,         -- 50
            hpx = true,
            anchor = 1,
            rotation = 0,
            sx = 1,
            sy = 1,
            halign = MOAITextBox.CENTER_JUSTIFY,
            valign = 0,
            ctor = [[label]],
            text_style = [[font1_12_r]],
            str = STRINGS.SLF.WORLD.GRID.DISPLAY,
            color = {255/255, 255/255, 255/255, 1/1},--140/255, 255/255, 255/255, 1/1},
            --[[tooltipHeader = {
                str = STRINGS.SLF.WORLD.GRID.NAME,
            },
            tooltip = {
                str = STRINGS.SLF.WORLD.GRID.DESC,
            },]]
        },
        opt = "ac_sitreps",
    },
    {
        "mission_preview_dialog.lua",
        { "widgets", 2, "children" },
        {
            name = [[SLF_Sitrep]],
            isVisible = true,
            noInput = false,
            anchor = 1,
            rotation = 0,
            x = 284,
            xpx = true,
            y = -216,
            ypx = true,
            w = 0,
            h = 0,
            sx = 1,
            sy = 1,
            ctor = [[group]],
            children =
            {
                {
                    name = [[bg]],
                    isVisible = true,
                    noInput = true,
                    anchor = 1,
                    rotation = 0,
                    x = 200,
                    xpx = true,
                    y = 316,
                    ypx = true,
                    w = 217,
                    wpx = true,
                    h = 111,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = [[image]],
                    color =
                    {
                        1,
                        1,
                        1,
                        1,
                    },
                    images =
                    {
                        {
                            file = [[gui/menu pages/map_screen/sitrep_bg.png]],
                            name = [[]],
                        },
                    },
                },  
                {
                    name = [[label]],
                    isVisible = true,
                    noInput = false,
                    anchor = 1,
                    rotation = 0,
                    x = 202,
                    xpx = true,
                    y = 310,
                    ypx = true,
                    w = 200,
                    wpx = true,
                    h = 110,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = [[label]],
                    halign = MOAITextBox.LEFT_JUSTIFY,
                    valign = MOAITextBox.TOP_JUSTIFY,
                    text_style = [[font1_14_r]],
                    --[[color =
                    { --yellow
                        245/255,
                        1,
                        120/255,
                        1,
                    },     ]]             
                    color =
                    { --orange
                        --244/255,
                        --129/255,
                        --52/255,
                        --1, --0.7843137383461,
                        1, 1, 1, 1
                    },               
                },            
            },
        },
        opt = "ac_sitreps",
    },
    --[[{   -- modals for MCD stuff; copied from MM, which itself was built upon Interactive Events
        "modal-event.lua",
        { "widgets", 2, "children"},
        {
            name = "optionBtn5",
            isVisible = true,
            noInput = false,
            anchor = 1,
            rotation = 0,
            x = 1,
            xpx = true,
            y = -96,
            ypx = true,
            w = 500,
            wpx = true,
            h = 38,
            hpx = true,
            sx = 1,
            sy = 1,
            ctor = "button",
            clickSound = "SpySociety/HUD/menu/click",
            hoverSound = "SpySociety/HUD/menu/rollover",
            hoverScale = 1,
            halign = MOAITextBox.CENTER_JUSTIFY,
            valign = MOAITextBox.CENTER_JUSTIFY,
            text_style = "font1_16_r",
            images =
            {
                {
                    file = "white.png",
                    name = "inactive",
                    color =
                    {
                        0.219607844948769,
                        0.376470595598221,
                        0.376470595598221,
                        1,
                    },
                },
                {
                    file = "white.png",
                    name = "hover",
                    color =
                    {
                        0.39215686917305,
                        0.690196096897125,
                        0.690196096897125,
                        1,
                    },
                },
                {
                    file = "white.png",
                    name = "active",
                    color =
                    {
                        0.39215686917305,
                        0.690196096897125,
                        0.690196096897125,
                        1,
                    },
                },
            },
        },  
        opt = "ac_frames",
    },
    {
        "modal-event.lua",
        { "widgets", 2, "children"},
        {
            name = "optionList",
            isVisible = false,
            noInput = false,
            anchor = 1,
            rotation = 0,
            x = -10,
            xpx = true,
            y = -190,
            ypx = true,
            w = 500,
            wpx = true,
            h = 240,
            hpx = true,
            sx = 1,
            sy = 1,
            ctor = "listbox",
            item_template = "optionListElement",
            scrollbar_template = "listbox_vscroll",
            orientation = 2,
            item_spacing = 48,
            images =
            {
            {
                file = "",
                name = "inactive",
                },
                {
                file = "",
                name = "active",
                },
                {
                file = "",
                name = "hover",
                },
            },
        },
        opt = "ac_frames",
    },
    {
        "modal-event.lua",
        { "skins" },
        {
            name = "optionListElement",
            isVisible = true,
            noInput = false,
            anchor = 1,
            rotation = 0,
            x = 0,
            y = 0,
            w = 0,
            h = 0,
            sx = 1,
            sy = 1,
            ctor = "group",
            children =
            {
                {
                    name = "optionListBtn",
                    isVisible = true,
                    noInput = false,
                    anchor = 1,
                    rotation = 0,
                    x = 1,
                    xpx = true,
                    y = 0,
                    ypx = true,
                    w = 480,
                    wpx = true,
                    h = 38,
                    hpx = true,
                    sx = 1,
                    sy = 1,
                    ctor = "button",
                    clickSound = "SpySociety/HUD/menu/click",
                    hoverSound = "SpySociety/HUD/menu/rollover",
                    hoverScale = 1,
                    halign = MOAITextBox.CENTER_JUSTIFY,
                    valign = MOAITextBox.CENTER_JUSTIFY,
                    text_style = "font1_16_r",
                    images =
                    {
                        {
                            file = "white.png",
                            name = "inactive",
                            color =
                            {
                                0.219607844948769,
                                0.376470595598221,
                                0.376470595598221,
                                1,
                            },
                        },
                        {
                            file = "white.png",
                            name = "hover",
                            color =
                            {
                                0.39215686917305,
                                0.690196096897125,
                                0.690196096897125,
                                1,
                            },
                        },
                        {
                            file = "white.png",
                            name = "active",
                            color =
                            {
                                0.39215686917305,
                                0.690196096897125,
                                0.690196096897125,
                                1,
                            },
                        },
                    },
                },
            },
        },
        opt = "ac_frames",
    },--]]
} 

return inserts