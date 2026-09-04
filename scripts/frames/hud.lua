local dial_evs = include(SCRIPT_PATHS.advanced_cyberwarfare.."/frames/dialog_events")
local util = include("modules/util")
local modal_thread = include( "gameplay/modal_thread" )
local hudFile = include("hud/hud")
local oldCreate = hudFile.createHud

function hudFile.createHud( ... )
	local hud = oldCreate( ... )

	local oldOnEvent = hud.onSimEvent
	function hud:onSimEvent( ev, ... )
		--log:write("Append successful.")
		if ev.eventType == "ACW_frame_installed" then
			--log:write("[ACW-EV] Receiving event!")
			KLEIRenderScene:pulseUIFuzz( 2 )
			self._game.viz:addThread( modal_thread.programDialog( self._game.viz, 
				STRINGS.SLF.FRAMES.INSTALLED_MODAL_TOP_TEXT, 
				STRINGS.SLF.FRAMES.INSTALLED_MODAL_TITLE, 
				util.sformat( STRINGS.SLF.FRAMES.INSTALLED_MODAL1, ev.eventData.frameName ),
				ev.eventData.icon ) )

			local screen = self._screen
			local frame_panel = screen.binder.mainframePnl.binder.frame_panel
			local frame_active = frame_panel.binder.frame_active

			local frame = ev.eventData.frame

			if frame.active then
				if not frame.canUseActive or frame:canUseActive( self._game.simCore ) then
					frame_active:setText(frame.active_text_enabled)
					frame_active:setDisabled( false )
				else
					frame_active:setText(frame.active_text_disabled)
					frame_active:setDisabled( true )
				end

				frame_active.onClick = function( self )
					-- assert here merely to ensure an active ability exists. It'll get actually bound at runtime, in console_view
					return assert(frame.useActive, "Attempting to install a frame with an undefined active. Define a useActive!")
				end

				frame_active:setVisible(true)
			else
				frame_active:setVisible(false)
			end
		end

		if ev.eventType == 'INSTALL_MCD_DIALOG' then
	        return dial_evs.showInstallMcdDialog( self, ev.eventData.item )
	    end

		return oldOnEvent( self, ev, ... )
	end

	return hud
end