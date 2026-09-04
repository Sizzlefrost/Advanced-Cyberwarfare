local sim = include("sim/engine")
local mainframe = include("sim/mainframe")

-- invokeDaemon fires when a daemon device is hacked
-- it installs the daemon, then deletes it from the device (or moves it, if it's a Cyber Consciousness daemon)

-- append resets the Sniffed (revealed) status of a daemon before installing it
-- future daemons on this device (should it get rebooted and reinfested) will not come pre-sniffed
local oldInvokeDaemon = mainframe.invokeDaemon
function mainframe.invokeDaemon(sim, unit, ...)
	if unit:getTraits().mainframe_program then
		unit:getTraits().daemon_sniffed = false
	end

	return oldInvokeDaemon(sim, unit, ...)
end

-- moveDaemon fires when Taurus is used, or when Cyber Consciousness daemon is installed (and then moved)

-- append tries to preserve the sniffed status from original device onto the target device
-- vanilla behaviour is to always do nothing to the original device
-- and to always set destination device to not sniffed
local oldMoveDaemon = sim.moveDaemon
function sim:moveDaemon(daemon, ...)
	-- i forgot what daemon queue does, but it's in vanilla code -Sizzle
	if not self._daemonQueue then
		local departureDevice = self:getUnit( daemon:getTraits().mainframe_device )
		local sniffed_status = false
		-- sometimes, the daemon is not hosted by a device. When you KO a Plastech hacker,
		-- their daemon is moved from nil-void into the closest device to the hacker
		if departureDevice then
			sniffed_status = departureDevice:getTraits().daemon_sniffed
			departureDevice:getTraits().daemon_sniffed = nil
		end

		-- there's no return, but for mod compatibility...
		local results = {oldMoveDaemon(self, daemon, ...)}

		-- after the vanilla code runs, the daemon's host has been changed
		local destinationDevice = self:getUnit( daemon:getTraits().mainframe_device )
		-- ...might as well be safe
		if destinationDevice then
			destinationDevice:getTraits().daemon_sniffed = sniffed_status
		end

		return unpack(results)
	else -- vanilla code already handles the daemon queue, let it do so
		return oldMoveDaemon(self, daemon, ...)
	end
end