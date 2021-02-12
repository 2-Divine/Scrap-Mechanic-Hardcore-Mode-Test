dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_constants.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_spawns.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_harvestable.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/managers/FireManager.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/managers/EffectManager.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/managers/PesticideManager.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )


BaseWorld = class( nil )

local PotatoProjectiles = { "potato", "smallpotato", "fries" }

function BaseWorld.server_onCreate( self )
	self.fireManager = FireManager()
    self.fireManager:sv_onCreate( self )

    self.pesticideManager = PesticideManager()
	self.pesticideManager:sv_onCreate()
end

function BaseWorld.client_onCreate( self )
	if self.fireManager == nil then
		assert( not sm.isHost )
		self.fireManager = FireManager()
	end
    self.fireManager:cl_onCreate( self )

    self.cl_effectManager = ClientEffectManager()
    self.cl_effectManager:onCreate()

    if self.pesticideManager == nil then
		assert( not sm.isHost )
		self.pesticideManager = PesticideManager()
	end
	self.pesticideManager:cl_onCreate()
end

function BaseWorld.server_onFixedUpdate( self )
    self.fireManager:sv_onFixedUpdate()

	self.pesticideManager:sv_onWorldFixedUpdate( self )
end

function BaseWorld.client_onFixedUpdate( self )
    self.cl_effectManager:onFixedUpdate()
end

function BaseWorld.sv_n_fireMsg( self, msg )
	self.fireManager:sv_handleMsg( msg )
end

function BaseWorld.cl_n_fireMsg( self, msg )
	self.fireManager:cl_handleMsg( msg )
end

function BaseWorld.cl_n_pesticideMsg( self, msg )
	self.pesticideManager[msg.fn]( self.pesticideManager, msg )
end

function BaseWorld.sv_e_spawnUnit( self, params )
	sm.unit.createUnit( params.uuid, params.position, params.yaw )
end

function BaseWorld.sv_spawnHarvestable( self, params )
	sm.harvestable.create( params.uuid, params.position, params.quat )
end

function BaseWorld.sv_loadLootOnCell( self, x, y, tags )
	--print("--- placing loot crates on cell " .. x .. ":" .. y .. " ---")



end

function BaseWorld.server_onCellLoaded( self, x, y )
	local tags = sm.cell.getTags( x, y )
	local cell = { x = x, y = y, worldId = self.world.id, isStartArea = valueExists( tags, "STARTAREA" ), isPoi = valueExists( tags, "POI" ) }

	g_elevatorManager:sv_onCellLoaded( self, x, y )

	SpawnFromUuidOnCellLoaded( cell, obj_survivalobject_ruinchest )
	SpawnFromUuidOnCellLoaded( cell, obj_survivalobject_farmerball )

	SpawnFromNodeOnCellLoaded( cell, "SEED_SPAWN" )
	--SpawnFromNodeOnCellLoaded( cell, "GAS_SPAWN" )

	self.fireManager:sv_onCellLoaded( x, y )

	-- Randomize stacks
	if cell.isStartArea then
	local stackedList = sm.cell.getInteractablesByAnyUuid( x, y, {
		obj_consumable_gas, obj_consumable_battery,
		obj_consumable_fertilizer, obj_consumable_chemical,
		obj_consumable_inkammo,
		obj_consumable_soilbag,
		obj_plantables_potato,
		obj_seed_banana, obj_seed_blueberry, obj_seed_orange, obj_seed_pineapple,
		obj_seed_carrot, obj_seed_redbeet, obj_seed_tomato, obj_seed_broccoli,
		obj_seed_potato
	} )
	local stackFn = {
		[tostring(obj_consumable_fertilizer)] = randomStackAmount20,
		[tostring(obj_consumable_inkammo)] = function() return randomStackAmount( 32, 48, 64 ) end,
		[tostring(obj_consumable_soilbag)] = randomStackAmountAvg2,
		[tostring(obj_plantables_potato)] = randomStackAmountAvg10,

	}
	for _,stacked in ipairs( stackedList ) do
		local fn = stackFn[tostring( stacked.shape.uuid )]
		if fn then
			stacked.shape.stackedAmount = fn()
		else
			stacked.shape.stackedAmount = randomStackAmountAvg3()
		end
	end
	else
	local stackedList = sm.cell.getInteractablesByAnyUuid( x, y, {
		obj_consumable_gas, obj_consumable_battery,
		obj_consumable_fertilizer, obj_consumable_chemical,
		obj_consumable_inkammo,
		obj_consumable_soilbag,
		obj_plantables_potato,
		obj_seed_banana, obj_seed_blueberry, obj_seed_orange, obj_seed_pineapple,
		obj_seed_carrot, obj_seed_redbeet, obj_seed_tomato, obj_seed_broccoli,
		obj_seed_potato
	} )
	local stackFn = {
		[tostring(obj_consumable_fertilizer)] = randomStackAmount20,
		[tostring(obj_consumable_inkammo)] = function() return randomStackAmount( 32, 48, 64 ) end,
		[tostring(obj_consumable_soilbag)] = randomStackAmountAvg2,
		[tostring(obj_plantables_potato)] = randomStackAmountAvg10,

	}
	for _,stacked in ipairs( stackedList ) do
		local fn = stackFn[tostring( stacked.shape.uuid )]
		if fn then
			stacked.shape.stackedAmount = fn()
		else
			stacked.shape.stackedAmount = randomStackAmountAvg3()
		end
	end
	end
end

function BaseWorld.client_onCellLoaded( self, x, y )

	self.fireManager:cl_onCellLoaded( x, y )
	self.cl_effectManager:onCellLoaded( x, y )

end

function BaseWorld.server_onCellReloaded( self, x, y )
	local tags = sm.cell.getTags( x, y )
	local cell = { x = x, y = y, worldId = self.world.id, isStartArea = valueExists( tags, "STARTAREA" ), isPoi = valueExists( tags, "POI" ) }

	g_elevatorManager:sv_onCellLoaded( self, x, y )
	self.fireManager:sv_onCellReloaded( x, y )

	if not cell.isStartArea then

		RespawnFromUuidOnCellReloaded( cell, obj_survivalobject_ruinchest )
		RespawnFromUuidOnCellReloaded( cell, obj_survivalobject_farmerball )

		RespawnFromNodeOnCellReloaded( cell, "SEED_SPAWN" )
		--RespawnFromNodeOnCellReloaded( cell, "GAS_SPAWN" )
	end
end

function BaseWorld.server_onCellUnloaded( self, x, y )
	g_elevatorManager:sv_onCellUnloaded( self, x, y )
	self.fireManager:sv_onCellUnloaded( x, y )
end

function BaseWorld.client_onCellUnloaded( self, x, y )
	self.cl_effectManager:onCellUnloaded( x, y )
end

function BaseWorld.sv_e_markBag( self, params )
	self.network:sendToClient( params.player, "cl_n_markBag", params )
end

function BaseWorld.cl_n_markBag( self, params )
	g_respawnManager:cl_markBag( params )
end

function BaseWorld.sv_e_unmarkBag( self, params )
	self.network:sendToClient( params.player, "cl_n_unmarkBag", params )
end

function BaseWorld.cl_n_unmarkBag( self, params )
	g_respawnManager:cl_unmarkBag( params )
end

-- Beacons
function BaseWorld.sv_e_createBeacon( self, params )
	if params.player and sm.exists( params.player ) then
		self.network:sendToClient( params.player, "cl_n_createBeacon", params )
	else
		self.network:sendToClients( "cl_n_createBeacon", params )
	end
end

function BaseWorld.cl_n_createBeacon( self, params )
	g_beaconManager:cl_createBeacon( params )
end

function BaseWorld.sv_e_destroyBeacon( self, params )
	if params.player and sm.exists( params.player ) then
		self.network:sendToClient( params.player, "cl_n_destroyBeacon", params )
	else
		self.network:sendToClients( "cl_n_destroyBeacon", params )
	end
end

function BaseWorld.cl_n_destroyBeacon( self, params )
	g_beaconManager:cl_destroyBeacon( params )
end

function BaseWorld.sv_e_unloadBeacon( self, params )
	if params.player and sm.exists( params.player ) then
		self.network:sendToClient( params.player, "cl_n_unloadBeacon", params )
	else
		self.network:sendToClients( "cl_n_unloadBeacon", params )
	end
end

function BaseWorld.cl_n_unloadBeacon( self, params )
	g_beaconManager:cl_unloadBeacon( params )
end

function BaseWorld.server_onProjectileFire( self, firePos, fireVelocity, projectileName, attacker )
	if isAnyOf( projectileName, PotatoProjectiles ) then
		local units = sm.unit.getAllUnits()
		for i, unit in ipairs( units ) do
			if InSameWorld( self.world, unit ) then
				sm.event.sendToUnit( unit, "sv_e_worldEvent", { eventName = "projectileFire", firePos = firePos, fireVelocity = fireVelocity, projectileName = projectileName, attacker = attacker })
			end
		end
	end
end

function BaseWorld.server_onInteractableCreated( self, interactable )
	g_unitManager:sv_onInteractableCreated( interactable )
end

function BaseWorld.server_onInteractableDestroyed( self, interactable )
	g_unitManager:sv_onInteractableDestroyed( interactable )
end

function BaseWorld.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage, userData )

    -- Spawn loot from projectiles with loot user data
	if userData and userData.lootUid then
		local normal = -hitVelocity:normalize()
		local zSignOffset = math.min( sign( normal.z ), 0 ) * 0.5
		local offset = sm.vec3.new( 0, 0, zSignOffset )
		local lootHarvestable = sm.harvestable.create( hvs_loot, hitPos + offset, sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.vec3.new( 0, 0, 1 ) ) )
		lootHarvestable:setParams( { uuid = userData.lootUid, quantity = userData.lootQuantity, epic = userData.epic  } )
    end

    -- Notify units about projectile hit
    if isAnyOf( projectileName, PotatoProjectiles ) then
		local units = sm.unit.getAllUnits()
		for i, unit in ipairs( units ) do
			if InSameWorld( self.world, unit ) then
				sm.event.sendToUnit( unit, "sv_e_worldEvent", { eventName = "projectileHit", hitPos = hitPos, hitTime = hitTime, hitVelocity = hitVelocity, attacker = attacker, damage = damage })
			end
		end
	end

	if projectileName == "pesticide" then
		local forward = sm.vec3.new( 0, 1, 0 )
		local randomDir = forward:rotateZ( math.random( 0, 359 ) )
		local effectPos = hitPos
		local success, result = sm.physics.raycast( hitPos + sm.vec3.new( 0, 0, 0.1 ), hitPos - sm.vec3.new( 0, 0, PESTICIDE_SIZE.z * 0.5 ), nil, sm.physics.filter.static + sm.physics.filter.dynamicBody )
		if success then
			effectPos = result.pointWorld + sm.vec3.new( 0, 0, PESTICIDE_SIZE.z * 0.5 )
		end
		self.pesticideManager:sv_addPesticide( self, effectPos, sm.vec3.getRotation( forward, randomDir ) )
	end

	if projectileName == "glowstick" then
		sm.harvestable.create( hvs_remains_glowstick, hitPos, sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), hitVelocity:normalize() ) )
	end

	if projectileName == "explosivetape" then
		sm.physics.explode( hitPos, 7, 2.0, 6.0, 25.0, "RedTapeBot - ExplosivesHit" )
	end
end

function BaseWorld.server_onMelee( self, hitPos, attacker, target, damage )
	-- print("Melee hit in Overworld!")
	-- print(hitPos)
	-- print(attacker)
	-- print(damage)
	-- print(target)

	if attacker and sm.exists( attacker ) and target and sm.exists( target ) then
		if type( target ) == "Shape" and type( attacker) == "Unit" then
			local targetPlayer = nil
			if target.interactable and target.interactable:hasSeat() then
				local targetCharacter = target.interactable:getSeatCharacter()
				if targetCharacter then
					targetPlayer = targetCharacter:getPlayer()
				end
			end
			if targetPlayer then
				sm.event.sendToPlayer( targetPlayer, "sv_e_receiveDamage", { damage = damage } )
			end
		end
	end
end

function BaseWorld.server_onCollision( self, objectA, objectB, collisionPosition, objectAPointVelocity, objectBPointVelocity, collisionNormal )
	local impactVelocity = math.abs( ( objectAPointVelocity - objectBPointVelocity ):dot( collisionNormal ) )
	if impactVelocity > 3 then
		local detectA = false
		local detectB = false
		if type( objectA ) == "Character" and sm.exists( objectA ) then
			detectA = objectA:isPlayer()
		elseif type( objectA ) == "Shape" and sm.exists( objectA ) and objectA.body:isDynamic() then
			detectA = true
		end
		if type( objectB ) == "Character" and sm.exists( objectB ) then
			detectB = objectB:isPlayer()
		elseif type( objectB ) == "Shape" and sm.exists( objectB ) and objectB.body:isDynamic() then
			detectB = true
		end

		local impactEnergy = 0
		if detectA and detectB then
			impactEnergy = ( objectA.mass * objectB.mass / ( objectA.mass + objectB.mass ) ) * ( objectAPointVelocity - objectBPointVelocity ):length2() / 2000.0
		else
			if detectA then
				impactEnergy = impactEnergy + objectAPointVelocity:length2() * objectA.mass / 2000.0
			end
			if detectB then
				impactEnergy = impactEnergy + objectBPointVelocity:length2() * objectB.mass / 2000.0
			end
		end
		if impactEnergy > 0.0 then
			local units = sm.unit.getAllUnits()
			for i, unit in ipairs( units ) do
				if InSameWorld( self.world, unit ) then
					sm.event.sendToUnit( unit, "sv_e_worldEvent", { eventName = "collisionSound", collisionPosition = collisionPosition, impactEnergy = impactEnergy })
				end
			end
		end
	end
end

function BaseWorld.sv_e_onChatCommand( self, params )

	if params[1] == "/starterkit" then
		local chest = sm.shape.createPart( obj_container_smallchest, params.player.character.worldPosition + sm.vec3.new( 0, 0, 2 ), sm.quat.identity() )
		chest.color = sm.color.new( 1, 0.5, 0 )
		local container = chest.interactable:getContainer()

		sm.container.beginTransaction()
		sm.container.collect( container, obj_scrap_gasengine, 1 )
		sm.container.collect( container, obj_scrap_driverseat, 1 )
		sm.container.collect( container, obj_scrap_seat, 1 )
		sm.container.collect( container, obj_scrap_smallwheel, 4 )
		sm.container.collect( container, jnt_bearing, 6 )
		sm.container.collect( container, obj_container_gas, 1 )
		sm.container.collect( container, obj_consumable_gas, 60 )
		sm.container.collect( container, blk_scrapwood, 512 )
		sm.container.collect( container, blk_scrapmetal, 512 )
		sm.container.collect( container, blk_scrapstone, 512 )
		sm.container.endTransaction()

	elseif params[1] == "/mechanicstartkit" then
		local chest = sm.shape.createPart( obj_container_smallchest, params.player.character.worldPosition + sm.vec3.new( 0, 0, 2 ), sm.quat.identity() )
		chest.color = sm.color.new( 0, 0, 0 )
		local container = chest.interactable:getContainer()

		sm.container.beginTransaction()
		sm.container.collect( container, obj_consumable_sunshake, 5 )

		sm.container.collect( container, blk_scrapwood, 256 )
		sm.container.collect( container, blk_scrapwood, 256 )
		sm.container.collect( container, blk_scrapmetal, 256 )
		sm.container.collect( container, blk_glass, 20 )

		sm.container.collect( container, obj_consumable_component, 10 )
		sm.container.collect( container, obj_consumable_gas, 20 )
		sm.container.collect( container, obj_resource_circuitboard, 10 )
		sm.container.collect( container, obj_resource_circuitboard, 10 )
		sm.container.collect( container, obj_consumable_chemical, 20 )
		sm.container.collect( container, obj_resource_corn, 20 )
		sm.container.collect( container, obj_resource_flower, 20 )

		sm.container.collect( container, obj_consumable_soilbag, 15 )
		sm.container.collect( container, obj_plantables_carrot, 10 )
		sm.container.collect( container, obj_plantables_tomato, 10 )
		sm.container.collect( container, obj_seed_tomato, 20 )
		sm.container.collect( container, obj_seed_carrot, 20 )
		sm.container.collect( container, obj_seed_redbeet, 10 )
		sm.container.endTransaction()

	elseif params[1] == "/pipekit" then
		local chest = sm.shape.createPart( obj_container_smallchest, params.player.character.worldPosition + sm.vec3.new( 0, 0, 2 ), sm.quat.identity() )
		chest.color = sm.color.new( 0, 0, 1 )
		local container = chest.interactable:getContainer()

		sm.container.beginTransaction()
		sm.container.collect( container, obj_pneumatic_pump, 1 )
		sm.container.collect( container, obj_pneumatic_pipe_03, 10 )
		sm.container.collect( container, obj_pneumatic_pipe_bend, 5 )
		sm.container.endTransaction()

	elseif params[1] == "/foodkit" then
		local chest = sm.shape.createPart( obj_container_smallchest, params.player.character.worldPosition + sm.vec3.new( 0, 0, 2 ), sm.quat.identity() )
		chest.color = sm.color.new( 1, 1, 0 )
		local container = chest.interactable:getContainer()

		sm.container.beginTransaction()
		sm.container.collect( container, obj_plantables_banana, 10 )
		sm.container.collect( container, obj_plantables_blueberry, 10 )
		sm.container.collect( container, obj_plantables_orange, 10 )
		sm.container.collect( container, obj_plantables_pineapple, 10 )
		sm.container.collect( container, obj_plantables_carrot, 10 )
		sm.container.collect( container, obj_plantables_redbeet, 10 )
		sm.container.collect( container, obj_plantables_tomato, 10 )
		sm.container.collect( container, obj_plantables_broccoli, 10 )
		sm.container.collect( container, obj_consumable_sunshake, 5 )
		sm.container.collect( container, obj_consumable_carrotburger, 5 )
		sm.container.collect( container, obj_consumable_pizzaburger, 5 )
		sm.container.collect( container, obj_consumable_longsandwich, 5 )
		sm.container.collect( container, obj_consumable_milk, 5 )
		sm.container.collect( container, obj_resource_steak, 5 )
		sm.container.endTransaction()

	elseif params[1] == "/seedkit" then
		local chest = sm.shape.createPart( obj_container_smallchest, params.player.character.worldPosition + sm.vec3.new( 0, 0, 2 ), sm.quat.identity() )
		chest.color = sm.color.new( 0, 1, 0 )
		local container = chest.interactable:getContainer()

		sm.container.beginTransaction()
		sm.container.collect( container, obj_seed_banana, 20 )
		sm.container.collect( container, obj_seed_blueberry, 20 )
		sm.container.collect( container, obj_seed_orange, 20 )
		sm.container.collect( container, obj_seed_pineapple, 20 )
		sm.container.collect( container, obj_seed_carrot, 20 )
		sm.container.collect( container, obj_seed_redbeet, 20 )
		sm.container.collect( container, obj_seed_tomato, 20 )
		sm.container.collect( container, obj_seed_broccoli, 20 )
		sm.container.collect( container, obj_seed_potato, 20 )
		sm.container.collect( container, obj_consumable_soilbag, 50 )
		sm.container.endTransaction()

	elseif params[1] == "/clearpathnodes" then
		sm.pathfinder.clearWorld()

	elseif params[1] == "/enablepathpotatoes" then
		if params[2] ~= nil then
			self.enablePathPotatoes = params[2]
		end
		if self.enablePathPotatoes then
			sm.gui.chatMessage( "enablepathpotatoes is on" )
		else
			sm.gui.chatMessage( "enablepathpotatoes is off" )
		end

	elseif params[1] == "/aggroall" then
		local units = sm.unit.getAllUnits()
		for _, unit in ipairs( units ) do
			sm.event.sendToUnit( unit, "sv_e_receiveTarget", { targetCharacter = params.player.character } )
		end
		sm.gui.chatMessage( "Units in overworld are aware of PLAYER" .. tostring( params.player.id ) .. " position." )

	end
end
