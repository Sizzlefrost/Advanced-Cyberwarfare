local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )
local inventory = include( "sim/inventory" )

local SLF_burnout = {
		name = STRINGS.ABILITIES.REVIVE,
		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_tazer_small.png",
		iconColor = util.color( 163/255, 0/255, 0/255 ),
		iconColorHover = util.color( 1,1,1 ),
		alwaysShow = true,
		getName = function( self, sim, unit )
			return self.name
		end,

		tazer_cost = nil,

		createToolTip = function(  self,sim, abilityOwner, abilityUser, targetID )
			local targetUnit = sim:getUnit(targetID)
			return abilityutil.formatToolTip(string.format(STRINGS.ABILITIES.REVIVE_NAME,targetUnit:getName()), string.format(STRINGS.SLF.AUGMENTS.BURNOUT.ACTIVATE,targetUnit:getName(),self.tazer_cost:getName()), simdefs.DEFAULT_COST)
		end,

		acquireTargets = function( self, targets, game, sim, unit )
			--simlog('acquireTargets entry')
			-- Check adjacent tiles
			local targetUnits = {}
			local cell = sim:getCell( unit:getLocation() )
			--check for pinned guards
			for i,cellUnit in ipairs(cell.units) do
				if self:isValidTarget( sim, unit, unit, cellUnit ) then
					table.insert( targetUnits,cellUnit )
				end
			end
			--simlog('acquireTargets pass')
			return targets.unitTarget( game, targetUnits, self, unit, unit )
		end,

		isValidTarget = function( self, sim, unit, userUnit, targetUnit )
			--simlog('validtarget entry, user '..unit:getName()..'; target '..targetUnit:getName())
			-- only rez valid KOd targets
			if targetUnit == nil or targetUnit:isGhost() or not targetUnit:isKO() then
				return false
			end
			--simlog('target exists and is KO')
			-- on the same team
			if simquery.isEnemyTarget( userUnit:getPlayerOwner(), targetUnit ) then
				return false
			end
			--simlog('target is allied to user')
			-- not pinned or dragged
			local pinned, pinner = simquery.isUnitPinned(sim, targetUnit)
			if pinned or simquery.isUnitDragged( sim, targetUnit ) then
				return false
			end
			--simlog('target is not pinned/dragged')
			-- and has somewhere to get up to
			if simquery.isUnitCellFull( sim, targetUnit ) then
				return false
			end
			--simlog('cell is not full')
			-- and carries a disrupter
			local found_tazer = false
			for i, child in pairs(targetUnit:getChildren()) do
				if child:getTraits().tazer or child:getUnitData().id == "item_tazer" or child:getUnitData().id == "item_tazer_shalem" then
					--simlog('verified tazer')
					found_tazer = true
					self.tazer_cost = child
					break
				end
			end
			if not found_tazer then
				return false
			end
			--simlog('tazer was found')
			-- also, just in case it wasn't clear, don't rez yourself! (not even by accident!)
			if unit:getID() == targetUnit:getID() then
				return false
			end
			--simlog('validtarget pass')
			return true
		end,

		canUseAbility =  function( self, sim, abilityOwner, userUnit, targetUnitID )
			--simlog('canUse entry')
			if not simquery.isAgent( userUnit ) then
				return false
			end

			if abilityOwner ~= userUnit then
				return false
			end

			if targetUnitID then
				if not self:isValidTarget( sim, abilityOwner, userUnit, sim:getUnit( targetUnitID ) ) then
					return false
				end
			else
				local units = self:findTargets( sim, abilityOwner, userUnit )
				if #units == 0 then
					return false, STRINGS.UI.REASON.NO_INJURED_TARGETS
				end
			end
			--simlog('canUse pass')
			return abilityutil.checkRequirements( abilityOwner, userUnit )
		end,

		findTargets = function( self, sim, abilityOwner, userUnit )
			--simlog('findtargets entry')
			local cell = sim:getCell( userUnit:getLocation() )
			local units = {}

			for i, cellUnit in ipairs( cell.units ) do
				if self:isValidTarget( sim, userUnit, userUnit, cellUnit ) then
					table.insert( units, cellUnit )
				end
			end
			--simlog('findtargets pass')
			return units
		end,

		executeAbility = function( self, sim, unit, userUnit, target )
			local target = sim:getUnit(target)	
	  		local newFacing = userUnit:getFacing()
	  		local revive = true

			sim:dispatchEvent( simdefs.EV_UNIT_HEAL, { unit = userUnit, target = target, revive = revive, facing = newFacing } )
			
			-- pay cost: destroy a tazer
			inventory.trashItem( sim, target, self.tazer_cost )

			local x1,y1 = target:getLocation()
			if target:isKO() then
				if target:isDead() then
					assert( target:getWounds() >= target:getTraits().woundsMax ) -- Cause they're dead, should have more wounds than max
					target:getTraits().dead = nil
					target:addWounds( target:getTraits().woundsMax - target:getWounds() - 1 )			
				end

				sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.REVIVED,x=x1,y=y1,color={r=1,g=1,b=1,a=1}} )

				target:setKO( sim, nil )
		        target:getTraits().mp = math.max( 0, target:getMPMax() - (target:getTraits().overloadCount or 0) )

				sim:emitSpeech( target, speechdefs.EVENT_REVIVED )
			end

			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit =target, fx = "emp" } )
			sim:triggerEvent( "dragon_burnout" )
		end,
	}
return SLF_burnout
