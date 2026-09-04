local simdefs = include( "sim/simdefs" )
local simunit = include( "sim/simunit" )
local modifiers = include( "sim/modifiers" )
local unitdefs = include( "sim/unitdefs" )
local simquery = include( "sim/simquery" )
local simfactory = include( "sim/simfactory" )
local abilityutil = include( "sim/abilities/abilityutil" )
local util = include ( "modules/util" )

SLF_dragon_project = {
	profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_peek_small.png",
	HUDpriority = 2,
	alwaysShow = true,
	--usesAction = true,
	showTargets = true,
	mp_cost = 2,

	name = STRINGS.SLF.AUGMENTS.PROJECTOR.DEPLOY_NAME,
	getName = function( self, sim, unit )
		return self.name
	end,
	createToolTip = function( self, sim, abilityOwner, abilityUser, targetID )
		return abilityutil.formatToolTip( STRINGS.SLF.AUGMENTS.PROJECTOR.DEPLOY_NAME, 
			util.sformat(STRINGS.SLF.AUGMENTS.PROJECTOR.DEPLOY_DESC, self.mp_cost)
			 )
	end,

	onSpawnAbility = function( self, sim, unit )
		--print("[acw] ONSPAWN RUNNING // UNIT: "..(unit and tostring(unit:getName())))

		self.anchor = unit
		local rangeBonus, augBonus, invBonus, augBonus, moveBonus, hpBonus = 0,0,0,0,0,0

		--print("PARAMS: \n"..util.stringize(sim:getParams()),1)

		-- CASE I: if dragon exists as a stored unit, she is simply re-summoned.
		-- no need to do anything, because re-summons are warp-ins, not spawn-ins
		-- they use a self.storedUnit ref

		-- CASE II: if there is no stored unit yet, we're first-timing the summon in the mission
		-- possibly in the campaign. If it's campaign-first, ephemeral should have put
		-- dragon into limbo, so she'll be loaded up just fine
		log:write("Attempting to detect dragon binding: "..tostring(self.anchor:getTraits().acw_dependent))
		if not self.storedUnit and not self.ACW_bound then
			self.storedUnit = sim:getPC()._dragon_in_limbo
		end

		-- CASE III (CASE CASE CASE): if there is no stored unit, and we're bound
		-- then first time summoning in the mission. Fetch from agency.
		if not self.storedUnit and self.ACW_bound then
			local agency = sim:getParams().agency
			for i, unit in pairs(agency.unitDefs) do
				print(util.stringize(unit, 2))
				if unit.template == self.ACW_bound then
					self.storedBlueprint = unit
				end
			end
			-- transform storedBlueprint into a valid, deploy-ready storedUnit
			local unitData = unitdefs.lookupTemplate( self.storedBlueprint.template )
			local unit = simfactory.createUnit( unitData, sim )
			unit:setPlayerOwner( sim:getPC() )
			-- prevent Dragon from being selected as soon as she spawns, at level load
			unit:getTraits().selectpriority = -1
			sim:spawnUnit(unit)
			if sim and sim:getPC() then
				sim:getPC()._dragon_in_limbo = unit 
			end
			self.storedUnit = unit
		end


		self.storedUnit:getTraits().acw_genie_lamp = self --reference to this ability
		self.storedUnit:getTraits().acw_anchor = self.anchor --reference to the "controller" unit

		rangeBonus = self.storedUnit:getTraits().acw_range_bonus or 0
		self.mp_cost = 2 - (self.storedUnit:getTraits().acw_cost_bonus or 0)
		invBonus = self.storedUnit:getTraits().acw_inv_bonus or 0
		augBonus = self.storedUnit:getTraits().acw_aug_bonus or 0
		moveBonus = self.storedUnit:getTraits().acw_move_bonus or 0
		hpBonus = self.storedUnit:getTraits().acw_hp_bonus or 0

		-- losrange is actually omitted by default, so we set it to math.huge, which does nothing by itself
		if not self.anchor:getTraits().LOSrange then
			self.anchor:getTraits().LOSrange = math.huge
		end
		local range = self.anchor:getTraits().LOSrange
		-- cap sight and throw ranges; defaults are 0 (equivalent to math.huge) and 10
		self.anchor:getModifiers():add("LOSrange", "ACW_archdragon", modifiers.CLA, range, 0, 8+rangeBonus)
		self.anchor:getModifiers():add("maxThrow", "ACW_archdragon", modifiers.CLA, range, 0, 8+rangeBonus)
		-- inventory size is handled via a trait on the augment
		-- handle inventory cap
		local oldCap = self.anchor:getTraits().inventoryMaxSize
		self.anchor:getModifiers():add("inventoryMaxSize", "ACW_archdragon", modifiers.CLA, oldCap+invBonus, 0, 10)
		-- handle augment cap
		local oldAugCap = self.anchor:getTraits().augmentMaxSize
		self.anchor:getModifiers():add("augmentMaxSize", "ACW_archdragon", modifiers.CLA, oldAugCap+augBonus, 0, simdefs.MAX_AUGMENT_CAPACITY)
		-- handle movement bonuses (+1 AP, -1 noise)
		-- TODO: do not use modifiers system for mpMax, it's incompatible with a lot of other mpMax stuff
		--self.anchor:getModifiers():add("mpMax", "ACW_archdragon", modifiers.ADD, moveBonus)
		--self.anchor:getModifiers():add("dashSoundRange", "ACW_archdragon", modifiers.ADD, -moveBonus)
		-- handle dermal armour
		self.anchor:getModifiers():add("woundsMax", "ACW_archdragon", modifiers.ADD, hpBonus)
	end,

	onDespawnAbility = function( self, sim )
		if self.anchor then
			local dep = self.anchor:getTraits().acw_dependent
			if not dep then 
				-- dragon was never deployed this mission
				-- that's fine, fake-deploy her
				log:write("[ACW] Deploying Dragon, "..util.stringize(self.storedUnit, 1))
				if self.storedUnit.type then
					dep = simfactory.createUnit( self.storedUnit, sim )
				else 
					dep = self.storedUnit
				end
				log:write(util.stringize(dep, 1))
			end
			--store dragon ref, this is probably done differently now
			--self.anchor.storedUnit = dep
			if dep:getLocation() then
				sim:warpUnit(dep)
			end
			-- if we just escaped, so did Dragon
			local deployed_list = sim:getPC():getDeployed()
			local escaped, anchor = false, nil
			for i, agent in pairs(deployed_list) do
				if self.anchor:getID() == agent.id and agent.escapedUnit then
					escaped = agent.exitID
					anchor = agent.id
				end
			end
			if escaped then
				log:write("Confirmed anchor escape")
				log:write("Dep ID: "..dep:getUnitData().agentID.." ("..dep:getID()..")")
				log:write("[ACW] Dragon binding confirmed.")
				self.anchor:getTraits().acw_dependent = "SLF_dragon_a"
				for i, agent in pairs(deployed_list) do
					if agent.agentDef and agent.agentDef.id == dep:getUnitData().agentID then
						if not agent.id then
							-- dragon leaves, but was never deployed this mission
							-- that's fine, pretend we deployed her, smile and wave
							agent.id = 8675309
						end
						agent.escapedUnit = dep
						agent.exitID = escaped
						agent.anchor = anchor -- anchor field represents an agentdef ID
					end
					--[[if agent and agent.id then
						log:write("ITER. Def ID: "..agent.agentDef.id.."; details: "..util.stringize(agent, 2))
					end]]
				end
				sim:triggerEvent( simdefs.TRG_UNIT_ESCAPED, dep )
				--simlog( "%s escaped!", dep:getName())
			end
			sim:despawnUnit(dep)
			-- the process of despawning should clean up the self.acw_dependent reference
		end
	end,

	acquireTargets = function( self, targets, game, sim, grenadeUnit, unit)
		if not self:canUseAbility( sim, grenadeUnit, unit ) then
			return nil
		end
		return targets.throwMainframeTarget( game, grenadeUnit:getTraits().range or 0, sim, unit, unit:getTraits().maxThrow, grenadeUnit:getTraits().targeting_ignoreLOS)
	end,

	canUseAbility = function( self, sim, deployedUnit, unit, targetCell )
		if unit:getTraits().movingBody then
			return false, STRINGS.UI.REASON.DROP_BODY_TO_USE
		end

		if unit:getMP() < self.mp_cost then
			return false, string.format(STRINGS.UI.REASON.REQUIRES_AP,self.mp_cost)
		end

		if targetCell then
			local targetX,targetY = unpack(targetCell)
			local unitX, unitY = unit:getLocation()
			local raycastX, raycastY = sim:getLOS():raycast(unitX, unitY, targetX, targetY)
			if raycastX ~= targetX or raycastY ~= targetY then
				return false, "No line of sight!"
			end
		end

		if self.anchor and self.anchor:getTraits().acw_dependent then -- Dragon already in the field
			return false, "Projection already underway!"
		end

		return true
	end,

	executeAbility = function( self, sim, deployable, anchor, targetCell )
		local anchor = self.anchor or anchor
		local targetCell = sim:getCell( unpack(targetCell) )
		local x0, y0 = anchor:getLocation()
		local x1, y1 = targetCell.x, targetCell.y
		local cell = sim:getCell( anchor:getLocation() )

		local facing = simquery.getDirectionFromDelta(x1-x0, y1-y0)
		simquery.suggestAgentFacing(anchor, facing)

		anchor:useMP(self.mp_cost)

		-- recover the unit whole from memory
		local newUnit = self.storedUnit or sim:getPC()._dragon_in_limbo
		-- if the unit wasn't selectable, make it selectable again
		newUnit:getTraits().selectpriority = nil
		newUnit:setPlayerOwner( anchor:getPlayerOwner() )
		newUnit._mp = anchor:getMP()
		--log:write("Attempting to spawn Dragon onto "..util.stringize(targetCell, 1))
		newUnit:getTraits().acw_cleared_to_spawn = true
		sim:warpUnit( newUnit, targetCell )
		newUnit:getTraits().acw_cleared_to_spawn = nil
		self.storedUnit = nil
		self.anchor:getTraits().acw_dependent = newUnit
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = newUnit })
	end,
}

return SLF_dragon_project