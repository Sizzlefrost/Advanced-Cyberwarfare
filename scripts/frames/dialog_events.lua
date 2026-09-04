-- ===
-- simactions.lua
-- ===
local simactions = include("sim/simactions")
local simdefs = include('sim/simdefs')
local mission_util = include("sim/missions/mission_util")

local oldBuyItem = simactions.buyItem
function simactions.buyItem( sim, unitID, shopUnitID, itemIndex, discount, itemType, buyback, ... )
	local unit = sim:getUnit( unitID ) or sim:getPlayerByID(unitID)
	local shopUnit = sim:getUnit( shopUnitID )
	local player = sim:getCurrentPlayer()
	assert( unit )
	assert( unit == player or unit:getPlayerOwner() == player )
    if buyback then
        return oldBuyItem( sim, unitID, shopUnitID, itemIndex, discount, itemType, buyback, ... )
    end
    local item = nil
    if itemType == "item" then
        item = shopUnit.items[itemIndex]
    elseif itemType == "weapon" then
        item = shopUnit.weapons[itemIndex]
    elseif itemType == "augment" then
        item = shopUnit.augments[itemIndex]
    end
    if not item:getTraits().SLF_incogFrame then
        return oldBuyItem( sim, unitID, shopUnitID, itemIndex, discount, itemType, buyback, ... )
    end
    -- Special handling for MCDs. Time to recreate the purchase process.

    -- Actually remove it from the shop list now.
    if itemType == "item" then
        item = table.remove( shopUnit.items, itemIndex )
    elseif itemType == "weapon" then
        item = table.remove( shopUnit.weapons, itemIndex )
    elseif itemType == "augment" then
        item = table.remove( shopUnit.augments, itemIndex )
    end
    sim:spawnUnit( item )
    unit:addChild( item )

    local result
    if unit:getTraits().isMainframeGhost then
        -- Autoselect INSTALL
        result = 2
    else
        -- Present a choice dialog.
        result = sim:dispatchChoiceEvent( 'INSTALL_MCD_DIALOG', { item = item }, true )
        -- Why does this always return nil without presenting the dialog?
        simlog("[DEBUG] buy MCD - Choice: %s", result or "nil")
    end
    if result == 2 then
        local abilityDef = unit:ownsAbility( "SLF_install_framework" )
        if abilityDef:canUseAbility( sim, item, unit ) then -- self, sim, unit
            abilityDef:executeAbility( sim, item, unit ) -- self, sim, unit, userUnit
        else
            mission_util.showDialog( sim, STRINGS.UI.INSTALL_AUGMENT, STRINGS.UI.PUTTING_AUGMENT_IN_INVENTORY )
        end
    end
    unit:checkOverload( sim )

	sim:triggerEvent( simdefs.TRG_BUY_ITEM, {shopUnit = shopUnit, unit = unit, item = item} )

	sim:dispatchEvent( simdefs.EV_ITEMS_PANEL ) -- Triggers refresh.
end

-- ===
-- proper events
-- ===
local util = include( "client_util" )
local mui = include("mui/mui")
local modal_thread = include( "gameplay/modal_thread" )

local DIA_HEADER = STRINGS.SLF.FRAMES.INSTALL -- This same string shows up on so many parts of this UI.
local DIA_BODY = STRINGS.SLF.FRAMES.INSTALL_DESC 
local DIA_INSTALL_BTN = STRINGS.SLF.FRAMES.INSTALL

local function showInstallMcdDialog( hud, item )
	assert( hud._choice_dialog == nil )
	assert( item )

	local screen

	screen = mui.createScreen( "modal-install-augment.lua" )
    screen.binder.pnl.binder.headerTxt:setText( DIA_HEADER )
    screen.binder.pnl.binder.subheader2:setText( DIA_HEADER )
    screen.binder.pnl.binder.bodyTxt1:setText( DIA_BODY )
    screen.binder.pnl.binder.installAugmentBtn:setText( DIA_INSTALL_BTN )
	
	hud._choice_dialog = screen
	mui.activateScreen( screen )

	MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/popup" )

    -- Incognita, instead of the agent
	screen.binder.pnl.binder.yourface.binder.portrait:bindBuild( "portraits/incognita_face" )
	screen.binder.pnl.binder.yourface.binder.portrait:bindAnim( "portraits/incognita_face" )
	screen.binder.pnl.binder.portrait:setVisible(true)

	if item then
		screen.binder.pnl.binder.Item:setVisible(true)

		local widget = screen:findWidget( "Item" )						
		widget.binder.img:setImage( item:getUnitData().profile_icon )

        local tooltip = util.tooltip( screen )
        local section = tooltip:addSection()
        item:getUnitData().onTooltip( section, item )
        widget.binder.img:setTooltip( tooltip )
		widget.binder.itemName:setText(item:getName())
	end

	-- Fill out the dialog options.
    local result = nil


    screen:findWidget( "installAugmentBtn" ).onClick = util.makeDelegate( nil, function() result = 2 end )
    screen:findWidget( "leaveInInventoryBtn" ).onClick =util.makeDelegate( nil, function() result = 1 end )  

	-- We are running in the vizThread coroutine.  Yield until a response is chosen by the UI.
	-- Note that the click handler will be triggered by the main coroutine, but we use a closure
	-- to inform us what the chosen result is.
	while result == nil do
		coroutine.yield()
        result = result or modal_thread.checkAutoClose( hud, hud._game )
	end

	mui.deactivateScreen( screen )
	hud._choice_dialog = nil

	hud._game.simCore:setChoice( result )

	return result
end

local function showProgramBindDialog( hud, title, desc, options )
    assert( hud._choice_dialog == nil, "CHOICE DIALOG ALREADY PRESENT" )
    assert(options, "NO OPTS SUPPLIED")

    log:write("[ACW-CHOICE] NOW ENTERING DINO CHOICE")

    local screen = mui.createScreen( "modal-event.lua" ) --modal_thread.generalDialog( hud._game.viz, "modal-event.lua" ).screen

    hud._choice_dialog = screen
    mui.activateScreen( screen )

    screen.binder.pnl.binder.headerTxt:setText( title )
    screen.binder.pnl.binder.bodyTxt:setText("<c:8CFFFF>".. desc .."</>" )

    screen.binder.pnl.binder.yourface.binder.portrait:bindBuild( "portraits/incognita_face" )
    screen.binder.pnl.binder.yourface.binder.portrait:bindAnim( "portraits/incognita_face" )
    screen.binder.pnl.binder.Item:setVisible(false)
    screen.binder.pnl.binder.theirface:setVisible(false)

    local result = nil

    local use_list = false
    if #options > 5 then
        use_list = true
    end

    -- Fill out the dialog options.
    local result = nil
    local x = 1 --RaXaH: What is this used for? Remove?
    for i, btn in screen.binder.pnl.binder:forEach( "optionBtn" ) do
        if use_list or options[i] == nil then
            btn:setVisible( false )
        else
            btn:setVisible( true )
            btn:setText("<c:8CFFFF>"..  options[i] .."</>")
            btn.onClick = util.makeDelegate( nil, function() result = i end )
            x = x + 1
        end
    end

    if use_list then
        local lb = screen:findWidget("optionList")
        lb:setVisible(true)
        lb:clearItems()
        for i=#options, 1, -1 do
            local entry = lb:addItem(nil , nil)
            local btn = entry.binder.optionListBtn
            btn:setText("<c:8CFFFF>"..  options[i] .."</>")
            btn.onClick = util.makeDelegate( nil, function() result = i end )
        end
    end

    while result == nil do
        coroutine.yield()
        result = result or modal_thread.checkAutoClose( hud, hud._game )
    end

    mui.deactivateScreen( screen )
    hud._choice_dialog = nil    

    if options[result] == "CANCEL" then result = 0 end -- 0 is standard fallback for situations like "ran out of time in time attack"

    hud._game.simCore:setChoice( result )

    return result
end

return {
    showInstallMcdDialog = showInstallMcdDialog,
    showProgramBindDialog = showProgramBindDialog,
}