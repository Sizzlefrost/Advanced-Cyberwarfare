local alterations = {	
	-- alter Mask
	damonHider = util.extend( createDaemon( STRINGS.SLF.DAEMONS.MASK ) )
	{
		icon = "gui/icons/daemon_icons/Daemons0002.png",

		onSpawnAbility = function( self, sim, player )
			self.duration = self.getDuration(self, sim, sim:nextRand(2, 3))
			sim:addTrigger( simdefs.TRG_END_TURN, self )	
			sim:hideDaemons(true)

			local programPool = {}
			local possibleDevices = {}
			self.hardMode = false
			for i, DLC in pairs(sim:getParams().difficultyOptions.enabledDLC) do
				if DLC.name == "Advanced Cyberwarfare" then
					self.hardMode = DLC.options.ac_mask_hardmode.enabled
				end
			end
			local daemon_cores = {}
			if self.hardMode then
				self.desc = STRINGS.SLF.DAEMONS.MASK.DESC_HARD
			end

			-- yes im looping through all units three times
			-- blame klei for writing their daemons all over the place (see: Taurus, Fractal)
			-- for the record, an attempt at a sensible approach *has* been made prior to this
			local units = util.tdupe(sim:getAllUnits())

			for i, device in pairs(units) do
				if device:getTraits().mainframe_iceMax and device:getTraits().mainframe_ice and device:getTraits().mainframe_program and  and not device:getTraits().daemonHost then
					if device:getPlayerOwner() ~= sim:getPC() then
						local daemon = device:getTraits().mainframe_program
						local sniffed = device:getTraits().daemon_sniffed
						local host = device:getTraits().daemonHost
						table.insert(programPool, { daemon, sniffed, host } )
						device:getTraits().mainframe_program = nil
						device:getTraits().daemon_sniffed = false
						device:getTraits().daemonHost = nil
					elseif device:getTraits().revealDaemons then
						table.insert(daemon_cores, device)
					end
				end
			end

			-- hard mode: reboot daemon databases for the duration of Mask
			--[[if self.hardMode then
				for i, core in pairs(daemon_cores) do
					if mainframe.canRevertIce( sim, core ) then
						mainframe.revertIce( sim, core )
					end
					if core:getTraits().mainframe_booting then
			        	core:getTraits().mainframe_booting = self.duration
			    	end
				end
			end]]

			--log:write(#programPool)

			for _, unit in pairs(units) do
				local t = unit:getTraits()
				if t.mainframe_iceMax and t.mainframe_ice and not t.mainframe_program 
					and unit:getPlayerOwner() ~= sim:getPC() then
					table.insert( possibleDevices, unit )	
				end
			end

			--log:write(#possibleDevices)

			for index, unit in pairs(possibleDevices) do
				-- there should be no more programs than devices at this point
				assert(#programPool <= #possibleDevices, #programPool - #possibleDevices)
				if #programPool > 0 then
					local k = sim:nextRand(1, #programPool)
					local daemon, sniffed, host = unpack(programPool[ k ])

					-- easy mode: preserve revealed status of daemons
					if not self.hardMode then
						unit:getTraits().daemon_sniffed = sniffed
					-- hard mode: conceal daemons
					else
						unit:getTraits().daemon_sniffed = false
					end

					unit:getTraits().mainframe_program = daemon
					unit:getTraits().daemonHost = host									
					
					sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = unit, ice = unit:getTraits().mainframe_ice, delta = 0} )
					table.remove( programPool, k )
				end
			end 

			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_daemonmove")
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_mask" )
			sim:dispatchEvent( simdefs.EV_SHOW_DAEMON, { showMainframe=true, name = self.name, icon=self.icon, txt = util.sformat(self.activedesc, self.duration ) } )	
			
		end,

		onDespawnAbility = function( self, sim )
			-- 0) Hard Mode Mask just ran out
			-- 1) No more Mask effects remain
			-- 2) A daemon core is under PC control
			-- => give fresh daemon data
			sim:hideDaemons(false) -- reduces hideDaemons counter by 1
			if self.hardMode and not sim:getHideDaemons() then
				local PC_core_owned = false
				for i, unit in pairs(sim:getPC():getUnits()) do
					if unit:getTraits().revealDaemons then
						PC_core_owned = true
						break
					end
				end

				if PC_core_owned then
					sim:forEachUnit(
						function ( u )
							if u:getTraits().mainframe_program ~= nil then
								u:getTraits().daemon_sniffed = true 
							end
						end )
				end
			end
			sim:removeTrigger( simdefs.TRG_END_TURN, self )	
		end,

		executeTimedAbility = function( self, sim )
			sim:getNPC():removeAbility(sim, self )
		end	
	},
}

return alterations