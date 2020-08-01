dofile("$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

CornPlant = class()

function CornPlant.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage )
	self:sv_onHit()
end

function CornPlant.server_onMelee( self, hitPos, attacker, damage )
	self:sv_onHit()
end

function CornPlant.server_onExplosion( self, center, destructionLevel )
	self:sv_onHit()
end

function CornPlant.sv_onHit( self )
	if not self.destroyed and sm.exists( self.harvestable ) then

		local lootList = {}
		local slots = math.random( 3, 6 )
		for i = 1, slots do
			lootList[i] = { uuid = obj_resource_corn, quantity = 1 }
		end
		SpawnLoot( self.harvestable, lootList, self.harvestable.worldPosition + sm.vec3.new( 0, 0, 1.0 ) )
		
		sm.harvestable.create( hvs_farmables_growing_cornplant, self.harvestable.worldPosition, self.harvestable.worldRotation )
		
		self.harvestable:destroy()
		self.destroyed = true
	end
end

function CornPlant.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal ) 
	if type( other ) == "Shape" and sm.exists( other ) then 
		if otherPointVelocity:length() > 6 then 
			self:sv_onHit() 
		end 
	end 
end