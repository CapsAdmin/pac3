local BUILDER, PART = pac.PartTemplate("base_movable")

PART.ClassName = "damage_zone"
PART.Group = 'advanced'
PART.Icon = 'icon16/package.png'

local renderhooks = {
	"PostDraw2DSkyBox",
	"PostDrawOpaqueRenderables",
	"PostDrawSkyBox",
	"PostDrawTranslucentRenderables",
	"PostDrawViewModel",
	"PostPlayerDraw",
	"PreDrawEffects",
	"PreDrawHalos",
	"PreDrawOpaqueRenderables",
	"PreDrawSkyBox",
	"PreDrawTranslucentRenderables",
	"PreDrawViewModel"
}


BUILDER:StartStorableVars()
	:SetPropertyGroup("Targets")
		:GetSet("AffectSelf",false)
		:GetSet("Players",true)
		:GetSet("NPC",true)
	:SetPropertyGroup("Shape and Sampling")
		:GetSet("Radius", 20)
		:GetSet("Length", 50)
		:GetSet("HitboxMode", "Box", {enums = {
			["Box"] = "Box",
			["Cube"] = "Cube",
			["Sphere"] = "Sphere",
			["Cylinder (Raycasts Only)"] = "Cylinder",
			["Cylinder (Hybrid)"] = "CylinderHybrid",
			["Cylinder (From Spheres)"] = "CylinderSpheres",
			["Cone (Raycasts Only)"] = "Cone",
			["Cone (Hybrid)"] = "ConeHybrid",
			["Cone (From Spheres)"] = "ConeSpheres",
			["Ray"] = "Ray"
		}})
		:GetSet("Detail", 20)
		:GetSet("ExtraSteps",0)
		:GetSet("RadialRandomize", 1)
		:GetSet("PhaseRandomize", 1)
	:SetPropertyGroup("Behaviour")
		:GetSet("Delay", 0)
	:SetPropertyGroup("Preview Rendering")
		:GetSet("NoPreview", false)
		:GetSet("RenderingHook", "PostDrawOpaqueRenderables", {enums = {
			["PostDraw2DSkyBox"] = "PostDraw2DSkyBox",
			["PostDrawOpaqueRenderables"] = "PostDrawOpaqueRenderables",
			["PostDrawSkyBox"] = "PostDrawSkyBox",
			["PostDrawTranslucentRenderables"] = "PostDrawTranslucentRenderables",
			["PostDrawViewModel"] = "PostDrawViewModel",
			["PostPlayerDraw"] = "PostPlayerDraw",
			["PreDrawEffects"] = "PreDrawEffects",
			["PreDrawHalos"] = "PreDrawHalos",
			["PreDrawOpaqueRenderables"] = "PreDrawOpaqueRenderables",
			["PreDrawSkyBox"] = "PreDrawSkyBox",
			["PreDrawTranslucentRenderables"] = "PreDrawTranslucentRenderables",
			["PreDrawViewModel"] = "PreDrawViewModel"
		}})
	:SetPropertyGroup("DamageInfo")
		:GetSet("Bullet", true)
		:GetSet("Damage", 0)
		:GetSet("DamageType", "generic", {enums = {
			generic = 0, --generic damage
			crush = 1, --caused by physics interaction
			bullet = 2, --bullet damage
			slash = 4, --sharp objects, such as manhacks or other npcs attacks
			burn = 8, --damage from fire
			vehicle = 16, --hit by a vehicle
			fall = 32, --fall damage
			blast = 64, --explosion damage
			club = 128, --crowbar damage
			shock = 256, --electrical damage, shows smoke at the damage position
			sonic = 512, --sonic damage,used by the gargantua and houndeye npcs
			energybeam = 1024, --laser
			nevergib = 4096, --don't create gibs
			alwaysgib = 8192, --always create gibs
			drown = 16384, --drown damage
			paralyze = 32768, --same as dmg_poison
			nervegas = 65536, --neurotoxin damage
			poison = 131072, --poison damage
			acid = 1048576, --
			airboat = 33554432, --airboat gun damage
			blast_surface = 134217728, --this won't hurt the player underwater
			buckshot = 536870912, --the pellets fired from a shotgun
			direct = 268435456, --
			dissolve = 67108864, --forces the entity to dissolve on death
			drownrecover = 524288, --damage applied to the player to restore health after drowning
			physgun = 8388608, --damage done by the gravity gun
			plasma = 16777216, --
			prevent_physics_force = 2048, --
			radiation = 262144, --radiation
			removenoragdoll = 4194304, --don't create a ragdoll on death
			slowburn = 2097152, --

			explosion = -1, -- util.BlastDamage
			fire = -1, -- ent:Ignite(5)

			-- env_entity_dissolver
			dissolve_energy = 0,
			dissolve_heavy_electrical = 1,
			dissolve_light_electrical = 2,
			dissolve_core_effect = 3,

			heal = -1,
			armor = -1,
		}})
BUILDER:EndStorableVars()

function PART:OnShow()
	if not self.NoPreview then
		self:PreviewHitbox()
	end
	if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
	local tbl = {}
	for key in pairs(self:GetStorableVars()) do
		tbl[key] = self[key]
	end
	net.Start("pac_request_zone_damage")
	net.WriteVector(self:GetWorldPosition())
	net.WriteAngle(self:GetWorldAngles())
	net.WriteTable(tbl)
	net.WriteEntity(self:GetPlayerOwner())
	net.SendToServer()
end

function PART:OnHide()
	--self:BuildCylinder()
	hook.Remove(self.RenderingHook, "pace_draw_hitbox")
	for _,v in pairs(renderhooks) do
		hook.Remove(v, "pace_draw_hitbox")
	end
end

function PART:OnRemove()
	--self:BuildCylinder()
	hook.Remove(self.RenderingHook, "pace_draw_hitbox")
	for _,v in pairs(renderhooks) do
		hook.Remove(v, "pace_draw_hitbox")
	end
end

local previousRenderingHook

function PART:PreviewHitbox()
	if previousRenderingHook ~= self.RenderingHook then
		for _,v in pairs(renderhooks) do
			hook.Remove(v, "pace_draw_hitbox")
		end
		previousRenderingHook = self.RenderingHook
	end

	hook.Add(self.RenderingHook, "pace_draw_hitbox", function()
		self:GetWorldPosition()
		if self.HitboxMode == "Box" then
			local mins =  Vector(-self.Radius, -self.Radius, -self.Length)
			local maxs = Vector(self.Radius, self.Radius, self.Length)
			render.DrawWireframeBox( self:GetWorldPosition(), Angle(0,0,0), mins, maxs, Color( 255, 255, 255 ) )
		elseif self.HitboxMode == "Cube" then
			--mat:Rotate(Angle(SysTime()*100,0,0))
			local mins =  Vector(-self.Radius, -self.Radius, -self.Radius)
			local maxs = Vector(self.Radius, self.Radius, self.Radius)
			render.DrawWireframeBox( self:GetWorldPosition(), Angle(0,0,0), mins, maxs, Color( 255, 255, 255 ) )
		elseif self.HitboxMode == "Sphere" then
			render.DrawWireframeSphere( self:GetWorldPosition(), self.Radius, 10, 10, Color( 255, 255, 255 ) )
		elseif self.HitboxMode == "Cylinder" or self.HitboxMode == "CylinderHybrid" then
			local obj = Mesh()
			self:BuildCylinder(obj)
			render.SetMaterial( Material( "models/wireframe" ) )
			mat = Matrix()
			mat:Translate(self:GetWorldPosition())
			mat:Rotate(self:GetWorldAngles())
			cam.PushModelMatrix( mat )
			obj:Draw()
			cam.PopModelMatrix()
			if LocalPlayer() == self:GetPlayerOwner() then
				if self.Radius ~= 0 then
					local sides = self.Detail
					if self.Detail < 1 then sides = 1 end
					
					local area_factor = self.Radius*self.Radius / (400 + 100*self.Length/math.max(self.Radius,0.1)) --bigger radius means more rays needed to cast to approximate the cylinder detection
					local steps = 3 + math.ceil(4*(area_factor / ((4 + self.Length/4) / (20 / math.max(self.Detail,1)))))
					if self.HitboxMode == "CylinderHybrid" and self.Length ~= 0 then
						area_factor = 0.15*area_factor
						steps = 1 + math.ceil(4*(area_factor / ((4 + self.Length/4) / (20 / math.max(self.Detail,1)))))
					end
					steps = math.max(steps + math.abs(self.ExtraSteps),1)
					
					--print("steps",steps, "total casts will be "..steps*self.Detail)
					for ringnumber=1,0,-1/steps do --concentric circles go smaller and smaller by lowering the i multiplier
						phase = math.random()
						for i=1,0,-1/sides do
							if ringnumber == 0 then i = 0 end
							x = self:GetWorldAngles():Right()*math.cos(2 * math.pi * i + phase * self.PhaseRandomize)*self.Radius*ringnumber*(1 - math.random() * (ringnumber) * self.RadialRandomize)
							y = self:GetWorldAngles():Up()   *math.sin(2 * math.pi * i + phase * self.PhaseRandomize)*self.Radius*ringnumber*(1 - math.random() * (ringnumber) * self.RadialRandomize)
							local startpos = self:GetWorldPosition() + x + y
							local endpos = self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length + x + y
							render.DrawLine( startpos, endpos, Color( 255, 255, 255 ), false )
						end
					end
					if self.HitboxMode == "CylinderHybrid" and self.Length ~= 0 then
						--fast sphere check on the wide end
						if self.Length/self.Radius >= 2 then
							render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length - self.Radius), self.Radius, 10, 10, Color( 255, 255, 255 ) )
							render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Radius), self.Radius, 10, 10, Color( 255, 255, 255 ) )
							if self.Radius ~= 0 then
								local counter = 0
								for i=math.floor(self.Length / self.Radius) - 1,1,-1 do
									render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Radius*i), self.Radius, 10, 10, Color( 255, 255, 255 ) )
									if counter == 100 then break end
									counter = counter + 1
								end
							end
							--render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length - 0.5*self.Radius), 0.5*self.Radius, 10, 10, Color( 255, 255, 255 ) )
						end
					end
				elseif self.Radius == 0 then render.DrawLine( self:GetWorldPosition(), self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length, Color( 255, 255, 255 ), false ) end
			end
		elseif self.HitboxMode == "CylinderSpheres" then
			local obj = Mesh()
			self:BuildCylinder(obj)
			render.SetMaterial( Material( "models/wireframe" ) )
			mat = Matrix()
			mat:Translate(self:GetWorldPosition())
			mat:Rotate(self:GetWorldAngles())
			cam.PushModelMatrix( mat )
			obj:Draw()
			cam.PopModelMatrix()
			if self.Length ~= 0 and self.Radius ~= 0 then
				local counter = 0
				--render.DrawWireframeSphere( self:GetWorldPosition(), self.Radius, 10, 10, Color( 255, 255, 255 ) )
				for i=0,1,1/(math.abs(self.Length/self.Radius)) do
					render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length*i, self.Radius, 10, 10, Color( 255, 255, 255 ) )
					if counter == 200 then break end
					counter = counter + 1
				end
				render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length), self.Radius, 10, 10, Color( 255, 255, 255 ) )
			elseif self.Radius == 0 then
				render.DrawLine( self:GetWorldPosition(), self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length, Color( 255, 255, 255 ), false )
			end
		elseif self.HitboxMode == "Cone" or self.HitboxMode == "ConeHybrid" then
			local obj = Mesh()
			self:BuildCone(obj)
			render.SetMaterial( Material( "models/wireframe" ) )
			mat = Matrix()
			mat:Translate(self:GetWorldPosition())
			mat:Rotate(self:GetWorldAngles())
			cam.PushModelMatrix( mat )
			obj:Draw()
			cam.PopModelMatrix()
			if LocalPlayer() == self:GetPlayerOwner() then
				if self.Radius ~= 0 then
					local sides = self.Detail
					if self.Detail < 1 then sides = 1 end
					local startpos = self:GetWorldPosition()
					local area_factor = self.Radius*self.Radius / (400 + 100*self.Length/math.max(self.Radius,0.1)) --bigger radius means more rays needed to cast to approximate the cylinder detection
					local steps = 3 + math.ceil(4*(area_factor / ((4 + self.Length/4) / (20 / math.max(self.Detail,1)))))
					if self.HitboxMode == "ConeHybrid" and self.Length ~= 0 then
						area_factor = 0.15*area_factor
						steps = 1 + math.ceil(4*(area_factor / ((4 + self.Length/4) / (20 / math.max(self.Detail,1)))))
					end
					steps = math.max(steps + math.abs(self.ExtraSteps),1)
					
					--print("steps",steps, "total casts will be "..steps*self.Detail)
					for ringnumber=1,0,-1/steps do --concentric circles go smaller and smaller by lowering the i multiplier
						phase = math.random()
						local ray_thickness = math.Clamp(0.5*math.log(self.Radius) + 0.05*self.Radius,0,10)*(1.5 - 0.7*ringnumber)
						for i=1,0,-1/sides do
							if ringnumber == 0 then i = 0 end
							x = self:GetWorldAngles():Right()*math.cos(2 * math.pi * i + phase * self.PhaseRandomize)*self.Radius*ringnumber*(1 - math.random() * (ringnumber) * self.RadialRandomize)
							y = self:GetWorldAngles():Up()   *math.sin(2 * math.pi * i + phase * self.PhaseRandomize)*self.Radius*ringnumber*(1 - math.random() * (ringnumber) * self.RadialRandomize)
							local endpos = self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length + x + y
							render.DrawLine( startpos, endpos, Color( 255, 255, 255 ), false )
						end
						--[[render.DrawWireframeBox(self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length + self:GetWorldAngles():Right() * self.Radius * ringnumber, Angle(0,0,0),
							Vector(ray_thickness,ray_thickness,ray_thickness),
							Vector(-ray_thickness,-ray_thickness,-ray_thickness),
							Color(255,255,255))]]
					end
					if self.HitboxMode == "ConeHybrid" and self.Length ~= 0 then
						--fast sphere check on the wide end
						local radius_multiplier = math.atan(math.abs(self.Length/self.Radius)) / (1.5 + 0.1*math.sqrt(self.Length/self.Radius))
						if self.Length/self.Radius > 0.5 then
							render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length - self.Radius * radius_multiplier), self.Radius * radius_multiplier, 10, 10, Color( 255, 255, 255 ) )
							--render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length - 0.5*self.Radius), 0.5*self.Radius, 10, 10, Color( 255, 255, 255 ) )
						end
					end
				elseif self.Radius == 0 then
					render.DrawLine( self:GetWorldPosition(), self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length, Color( 255, 255, 255 ), false )
				end
			end
		elseif self.HitboxMode == "ConeSpheres" then
			local obj = Mesh()
			self:BuildCone(obj)
			render.SetMaterial( Material( "models/wireframe" ) )
			mat = Matrix()
			mat:Translate(self:GetWorldPosition())
			mat:Rotate(self:GetWorldAngles())
			cam.PushModelMatrix( mat )
			obj:Draw()
			cam.PopModelMatrix()
			if self.Radius ~= 0 then
				local steps
				steps = math.Clamp(4*math.ceil(self.Length / (self.Radius or 1)),1,50)
				for i = 1,0,-1/steps do
					render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length*i, i * self.Radius, 10, 10, Color( 255, 255, 255 ) )
				end

				steps = math.Clamp(math.ceil(self.Length / (self.Radius or 1)),1,4)
				for i = 0,1/8,1/128 do
					render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length*i, i * self.Radius, 10, 10, Color( 255, 255, 255 ) )
				end
			elseif self.Radius == 0 then
				render.DrawLine( self:GetWorldPosition(), self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length, Color( 255, 255, 255 ), false )
			end
		elseif self.HitboxMode == "Ray" then
			render.DrawLine( self:GetWorldPosition(), self:GetWorldPosition() + self:GetWorldAngles():Forward()*self.Length, Color( 255, 255, 255 ), false )
		end
	end)
	timer.Simple(5, function() if self.NoPreview then hook.Remove(self.RenderingHook, "pace_draw_hitbox") end end)
end

function PART:BuildCylinder(obj)
	local sides = 30
	local circle_tris = {}
	for i=1,sides,1 do
		local vert1 = {pos = Vector(0,          self.Radius*math.sin((i-1)*(2*math.pi / sides)),self.Radius*math.cos((i-1)*(2*math.pi / sides))), u = 0, v = 0 }
		local vert2 = {pos = Vector(0,          self.Radius*math.sin((i-0)*(2*math.pi / sides)),self.Radius*math.cos((i-0)*(2*math.pi / sides))), u = 0, v = 0 }
		local vert3 = {pos = Vector(self.Length,self.Radius*math.sin((i-1)*(2*math.pi / sides)),self.Radius*math.cos((i-1)*(2*math.pi / sides))), u = 0, v = 0 }
		local vert4 = {pos = Vector(self.Length,self.Radius*math.sin((i-0)*(2*math.pi / sides)),self.Radius*math.cos((i-0)*(2*math.pi / sides))), u = 0, v = 0 }
		--print(vert1.pos,vert3.pos,vert2.pos,vert4.pos)
		--{vert1,vert2,vert3}
		--{vert4,vert3,vert2}
		table.insert(circle_tris, vert1)
		table.insert(circle_tris, vert2)
		table.insert(circle_tris, vert3)

		table.insert(circle_tris, vert3)
		table.insert(circle_tris, vert2)
		table.insert(circle_tris, vert1)

		table.insert(circle_tris, vert4)
		table.insert(circle_tris, vert3)
		table.insert(circle_tris, vert2)

		table.insert(circle_tris, vert2)
		table.insert(circle_tris, vert3)
		table.insert(circle_tris, vert4)

		--circle_tris[8*(i-1) + 1] = vert1
		--circle_tris[8*(i-1) + 2] = vert2
		--circle_tris[8*(i-1) + 3] = vert3
		--circle_tris[8*(i-1) + 4] = vert4
		--circle_tris[8*(i-1) + 5] = vert3
		--circle_tris[8*(i-1) + 6] = vert2
	end
	obj:BuildFromTriangles( circle_tris )
end

function PART:BuildCone(obj)
	local sides = 30
	local circle_tris = {}
	local verttip = {pos = Vector(0,0,0), u = 0, v = 0 }
	for i=1,sides,1 do
		local vert1 = {pos = Vector(self.Length,self.Radius*math.sin((i-1)*(2*math.pi / sides)),self.Radius*math.cos((i-1)*(2*math.pi / sides))), u = 0, v = 0 }
		local vert2 = {pos = Vector(self.Length,self.Radius*math.sin((i-0)*(2*math.pi / sides)),self.Radius*math.cos((i-0)*(2*math.pi / sides))), u = 0, v = 0 }
		--print(vert1.pos,vert3.pos,vert2.pos,vert4.pos)
		--{vert1,vert2,vert3}
		--{vert4,vert3,vert2}
		table.insert(circle_tris, verttip)
		table.insert(circle_tris, vert1)
		table.insert(circle_tris, vert2)

		table.insert(circle_tris, vert2)
		table.insert(circle_tris, vert1)
		table.insert(circle_tris, verttip)

		--circle_tris[8*(i-1) + 1] = vert1
		--circle_tris[8*(i-1) + 2] = vert2
		--circle_tris[8*(i-1) + 3] = vert3
		--circle_tris[8*(i-1) + 4] = vert4
		--circle_tris[8*(i-1) + 5] = vert3
		--circle_tris[8*(i-1) + 6] = vert2
	end
	obj:BuildFromTriangles( circle_tris )
end



BUILDER:Register()