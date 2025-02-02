local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "force"
PART.Group = "combat"
PART.Icon = "icon16/database_go.png"

PART.ManualDraw = true
PART.HandleModifiersManually = true

BUILDER:StartStorableVars()
	:SetPropertyGroup("AreaShape")
		:GetSet("HitboxMode", "Box", {enums = {
			["Box"] = "Box",
			["Cube"] = "Cube",
			["Sphere"] = "Sphere",
			["Cylinder"] = "Cylinder",
			["Cone"] = "Cone",
			["Ray"] = "Ray"
		}})
		:GetSet("Length", 50, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,-32768,32767)) end})
		:GetSet("Radius", 50, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,-32768,32767)) end})
		:GetSet("Preview",false, {description = "preview target selection boxes"})
		:GetSet("PreviewForces",false, {description = "preview the predicted forces"})

	:SetPropertyGroup("BaseForces")
		:GetSet("BaseForce", 0)
		:GetSet("AddedVectorForce", Vector(0,0,0))
		:GetSet("Torque", Vector(0,0,0))
		:GetSet("BaseForceAngleMode","Radial",{enums = {["Radial"] = "Radial", ["Locus"] = "Locus", ["Local"] = "Local"},
			description = 
[[Radial points the base force outward from the force part. To point in, use negative values

Locus points out from the locus (external point)

Local points forward (red arrow) from the force part]]})
		:GetSet("VectorForceAngleMode", "Global", {enums = {["Global"] = "Global", ["Local"] = "Local", ["Radial"] = "Radial",  ["RadialNoPitch"] = "RadialNoPitch"},
		description = 
[[Global applies the vector force on world coordinates

Local applies it based on the force part's angles

Radial gets the base directions from the targets to the force part

RadialNoPitch gets the base directions from the targets to the force part, but making pitch horizon-level]]})
		:GetSet("TorqueMode", "TargetLocal", {enums = {["Global"] = "Global", ["TargetLocal"] = "TargetLocal", ["Local"] = "Local", ["Radial"] = "Radial"},
		description = 
[[Global applies the angular force on world coordinates

TargetLocal applies it on the target's local angles

Local applies it based on the force part's angles

Radial gets the base directions from the targets to the force part]]})
		:GetSetPart("Locus", nil)

	:SetPropertyGroup("Behaviors")
		:GetSet("Continuous", true, {description = "If set to false, the force will be a single, stronger impulse"})
		:GetSet("AccountMass", false, {description = "Apply acceleration according to mass."})
		:GetSet("Falloff", false, {description = "Whether the force to apply should fade with distance"})
		:GetSet("ReverseFalloff", false, {description = "The reverse of the falloff means the force fades when getting closer."})
		:GetSet("Levitation", false, {description = "Tries to stabilize the force to levitate targets at a certain height relative to the part.\nRequires vertical forces. Easiest way is to enter 0 0 500 in 'added vector force' with the Global vector mode which is already there by default."})
		:GetSet("LevitationHeight", 0)

	:SetPropertyGroup("Damping")
		:GetSet("Damping", 0, {editor_clamp = {0,1}, editor_sensitivity = 0.1, description = "Reduces the existing velocity before applying force, by way of multiplication by (1-damping). 0 doesn't change it, while 1 is a full negation of the initial speed."})
		:GetSet("DampingFalloff", false, {description = "Whether the damping should fade with distance (further is weaker influence)"})
		:GetSet("DampingReverseFalloff", false, {description = "Whether the damping should fade with distance but reverse (closer is weaker influence)"})

	:SetPropertyGroup("Targets")
		:GetSet("AffectSelf",false)
		:GetSet("Players",true)
		:GetSet("PhysicsProps", true)
		:GetSet("PointEntities",true, {description = "other entities not covered by physics props but with potential physics"})
		:GetSet("NPC",false)
:EndStorableVars()

local force_hitbox_ids = {["Box"] = 0,["Cube"] = 1,["Sphere"] = 2,["Cylinder"] = 3,["Cone"] = 4,["Ray"] = 5}
local base_force_mode_ids = {["Radial"] = 0, ["Locus"] = 1, ["Local"] = 2}
local vect_force_mode_ids = {["Global"] = 0, ["Local"] = 1, ["Radial"] = 2,  ["RadialNoPitch"] = 3}
local ang_torque_mode_ids = {["Global"] = 0, ["TargetLocal"] = 1, ["Local"] = 2, ["Radial"] = 3}

function PART:OnRemove()
end

function PART:Initialize()
	self.next_impulse = CurTime() + 0.05
	if not GetConVar("pac_sv_force"):GetBool() or pac.Blocked_Combat_Parts[self.ClassName] then self:SetError("force parts are disabled on this server!") end
end

function PART:OnShow()
	self.next_impulse = CurTime() + 0.05
	self:Impulse(true)
end

function PART:OnHide()
	pac.RemoveHook("PostDrawOpaqueRenderables", "pac_force_Draw"..self.UniqueID)
	self:Impulse(false)
end

function PART:OnRemove()
	pac.RemoveHook("PostDrawOpaqueRenderables", "pac_force_Draw"..self.UniqueID)
	self:Impulse(false)
end


local white = Color(255,255,255)
local red = Color(255,0,0)
local green = Color(0,255,0)
local blue = Color(0,0,255)
local red2 = Color(255,100,100)
local red3 = Color(255,200,200)
local function draw_force_line(pos, amount)
	local length = amount:Length()
	local magnitude = length / 20
	amount:Normalize()
	local x = amount.x
	local y = amount.y
	local z = amount.z
	local dir = amount:Angle()
	render.DrawLine( pos, 9 * magnitude * x * Vector(1,0,0) + pos, red, false)
	render.DrawLine( pos, 9 * magnitude * y * Vector(0,1,0) + pos, green, false)
	render.DrawLine( pos, 9 * magnitude * z * Vector(0,0,1) + pos, blue, false)
	cam.IgnoreZ( true )
	for i=0,8,1 do
		local scrolling = -i + math.floor((CurTime() % 1) * 8) + 2
		if scrolling == 0 then
			render.DrawLine( (i) * magnitude * amount + pos, (i+1) * magnitude * amount + pos, red, false)
		elseif scrolling == 1 then
			render.DrawLine( (i) * magnitude * amount + pos, (i+1) * magnitude * amount + pos, red2, false)
		elseif scrolling == 2 then
			render.DrawLine( (i) * magnitude * amount + pos, (i+1) * magnitude * amount + pos, red3, false)
		else
			render.DrawLine( (i) * magnitude * amount + pos, (i+1) * magnitude * amount + pos, white, false)
		end

	end
	cam.IgnoreZ( false )
end


--convenience functions and tables from net_combat

local pre_excluded_ent_classes = {
	["info_player_start"] = true,
	["aoc_spawnpoint"] = true,
	["info_player_teamspawn"] = true,
	["env_tonemap_controller"] = true,
	["env_fog_controller"] = true,
	["env_skypaint"] = true,
	["shadow_control"] = true,
	["env_sun"] = true,
	["predicted_viewmodel"] = true,
	["physgun_beam"] = true,
	["ambient_generic"] = true,
	["trigger_once"] = true,
	["trigger_multiple"] = true,
	["trigger_hurt"] = true,
	["info_ladder_dismount"] = true,
	["info_particle_system"] = true,
	["env_sprite"] = true,
	["env_fire"] = true,
	["env_soundscape"] = true,
	["env_smokestack"] = true,
	["light"] = true,
	["move_rope"] = true,
	["keyframe_rope"] = true,
	["env_soundscape_proxy"] = true,
	["gmod_hands"] = true,
	["env_lightglow"] = true,
	["point_spotlight"] = true,
	["spotlight_end"] = true,
	["beam"] = true,
	["info_target"] = true,
	["func_lod"] = true,
	["func_brush"] = true,
	["phys_bone_follower"] = true,
}

local physics_point_ent_classes = {
	["prop_physics"] = true,
	["prop_physics_multiplayer"] = true,
	["prop_ragdoll"] = true,
	["weapon_striderbuster"] = true,
	["item_item_crate"] = true,
	["func_breakable_surf"] = true,
	["func_breakable"] = true,
	["physics_cannister"] = true
}

local function MergeTargetsByID(tbl1, tbl2)
	for i,v in ipairs(tbl2) do
		tbl1[v:EntIndex()] = v
	end
end

local function Is_NPC(ent)
	return ent:IsNPC() or ent:IsNextBot() or ent.IsDrGEntity or ent.IsVJBaseSNPC
end

local function ProcessForcesList(ents_hits, tbl, pos, ang, ply)
	for i,v in pairs(ents_hits) do
		if pre_excluded_ent_classes[v:GetClass()] then ents_hits[i] = nil end
	end
	local ftime = 0.016 --approximate tick duration
	local BASEFORCE = 0
	local VECFORCE = Vector(0,0,0)
	if tbl.Continuous then
		BASEFORCE = tbl.BaseForce * ftime * 3.3333 --weird value to equalize how 600 cancels out gravity
		VECFORCE = tbl.AddedVectorForce * ftime * 3.3333
	else
		BASEFORCE = tbl.BaseForce
		VECFORCE = tbl.AddedVectorForce
	end
	for _,ent in pairs(ents_hits) do
		if ent:IsWeapon() or ent:GetClass() == "viewmodel" or ent:GetClass() == "func_physbox_multiplayer" then continue end
		if ent:GetPos():Distance(ply:GetPos()) < 300 then
			print(ent)
		end
		local phys_ent
		local is_player = ent:IsPlayer()
		local is_physics = (physics_point_ent_classes[ent:GetClass()] or string.find(ent:GetClass(),"item_") or string.find(ent:GetClass(),"ammo_") or (ent:IsWeapon() and not IsValid(ent:GetOwner())))
		local is_npc = Is_NPC(ent)

		if is_npc and not tbl.NPC then continue end
		if is_player and not (tbl.Players or ent == tbl:GetPlayerOwner()) then continue end
		if is_player and not tbl.AffectSelf and ent == tbl:GetPlayerOwner() then continue end
		if is_physics and not tbl.PhysicsProps then continue end
		if not is_npc and not is_player and not is_physics then
			if not tbl.PointEntities then continue end
		end

		local is_phys = true
		phys_ent = ent
		is_phys = false

		local oldvel

		if IsValid(phys_ent) then
			oldvel = phys_ent:GetVelocity()
		else
			oldvel = Vector(0,0,0)
		end


		local addvel = Vector(0,0,0)
		local add_angvel = Vector(0,0,0)

		local ent_center = ent:WorldSpaceCenter() or ent:GetPos()

		local dir = ent_center - pos --part
		local locus_pos = pos
		if tbl.Locus ~= nil then
			if tbl.Locus:IsValid() then
				locus_pos = tbl.Locus:GetWorldPosition()
			end
		end
		local dir2 = ent_center - locus_pos

		local dist_multiplier = 1
		local damping_dist_mult = 1
		local up_mult = 1
		local distance = (ent_center - pos):Length()
		local height_delta = pos.z + tbl.LevitationHeight - ent_center.z

		--what it do
		--if delta is -100 (ent is lower than the desired height), that means +100 adjustment direction
		--height decides how much to knee the force until it equalizes at 0
		--clamp the delta to the ratio levitation height

		if tbl.Levitation then
			up_mult = math.Clamp(height_delta / (5 + math.abs(tbl.LevitationHeight)),-1,1)
		end

		if tbl.BaseForceAngleMode == "Radial" then --radial on self
			addvel = dir:GetNormalized() * tbl.BaseForce
		elseif tbl.BaseForceAngleMode == "Locus" then --radial on locus
			addvel = dir2:GetNormalized() * tbl.BaseForce
		elseif tbl.BaseForceAngleMode == "Local" then --forward on self
			addvel = ang:Forward() * tbl.BaseForce
		end

		if tbl.VectorForceAngleMode == "Global" then --global
			addvel = addvel + tbl.AddedVectorForce
		elseif tbl.VectorForceAngleMode == "Local" then --local on self
			addvel = addvel
			+ang:Forward()*tbl.AddedVectorForce.x
			+ang:Right()*tbl.AddedVectorForce.y
			+ang:Up()*tbl.AddedVectorForce.z

		elseif tbl.VectorForceAngleMode == "Radial" then --relative to locus or self
			ang2 = dir:Angle()
			addvel = addvel
			+ang2:Forward()*tbl.AddedVectorForce.x
			+ang2:Right()*tbl.AddedVectorForce.y
			+ang2:Up()*tbl.AddedVectorForce.z
		elseif tbl.VectorForceAngleMode == "RadialNoPitch" then --relative to locus or self
			dir.z = 0
			ang2 = dir:Angle()
			addvel = addvel
			+ang2:Forward()*tbl.AddedVectorForce.x
			+ang2:Right()*tbl.AddedVectorForce.y
			+ang2:Up()*tbl.AddedVectorForce.z
		end

		--[[if tbl.TorqueMode == "Global" then
			add_angvel = tbl.Torque
		elseif tbl.TorqueMode == "Local" then
			add_angvel = ang:Forward()*tbl.Torque.x + ang:Right()*tbl.Torque.y + ang:Up()*tbl.Torque.z
		elseif tbl.TorqueMode == "TargetLocal" then
			add_angvel = tbl.Torque
		elseif tbl.TorqueMode == "Radial" then
			ang2 = dir:Angle()
			addvel = ang2:Forward()*tbl.Torque.x + ang2:Right()*tbl.Torque.y + ang2:Up()*tbl.Torque.z
		end]]

		local mass = 1
		if IsValid(phys_ent) then
			if phys_ent.GetMass then
				phys_ent:GetMass()
			end
		end
		if is_phys and tbl.AccountMass then
			if not is_npc then
				addvel = addvel * (1 / math.max(mass,0.1))
			else
				addvel = addvel
			end
			add_angvel = add_angvel * (1 / math.max(mass,0.1))
		end

		if tbl.Falloff then
			dist_multiplier = math.Clamp(1 - distance / math.max(tbl.Radius, tbl.Length),0,1)
		end
		if tbl.ReverseFalloff then
			dist_multiplier = 1 - math.Clamp(1 - distance / math.max(tbl.Radius, tbl.Length),0,1)
		end

		if tbl.DampingFalloff then
			damping_dist_mult = math.Clamp(1 - distance / math.max(tbl.Radius, tbl.Length),0,1)
		end
		if tbl.DampingReverseFalloff then
			damping_dist_mult = 1 - math.Clamp(1 - distance / math.max(tbl.Radius, tbl.Length),0,1)
		end
		damping_dist_mult = damping_dist_mult
		local final_damping = 1 - (tbl.Damping * damping_dist_mult)

		if tbl.Levitation then
			addvel.z = addvel.z * up_mult
		end

		addvel = addvel * dist_multiplier
		draw_force_line(ent:WorldSpaceCenter(), addvel)
		
	end
end

local function preview_process_ents(tbl)
	ply = tbl:GetPlayerOwner()
	local pos = tbl.pos
	local ang = tbl.ang

	if tbl.HitboxMode == "Sphere" then
		local ents_hits = ents.FindInSphere(pos, tbl.Radius)
		ProcessForcesList(ents_hits, tbl, pos, ang, ply)
	elseif tbl.HitboxMode == "Box" then
		local mins
		local maxs
		if tbl.HitboxMode == "Box" then
			mins = pos - Vector(tbl.Radius, tbl.Radius, tbl.Length)
			maxs = pos + Vector(tbl.Radius, tbl.Radius, tbl.Length)
		end

		local ents_hits = ents.FindInBox(mins, maxs)
		ProcessForcesList(ents_hits, tbl, pos, ang, ply)
	elseif tbl.HitboxMode == "Cylinder" then
		local ents_hits = {}
		if tbl.Length ~= 0 and tbl.Radius ~= 0 then
			local counter = 0
			MergeTargetsByID(ents_hits,ents.FindInSphere(pos, tbl.Radius))
			for i=0,1,1/(math.abs(tbl.Length/tbl.Radius)) do
				MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Length*i, tbl.Radius))
				if counter == 200 then break end
				counter = counter + 1
			end
			MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Length, tbl.Radius))
			--render.DrawWireframeSphere( self:GetWorldPosition() + self:GetWorldAngles():Forward()*(self.Length - 0.5*self.Radius), 0.5*self.Radius, 10, 10, Color( 255, 255, 255 ) )
		elseif tbl.Radius == 0 then MergeTargetsByID(ents_hits,ents.FindAlongRay(pos, pos + ang:Forward()*tbl.Length)) end
		ProcessForcesList(ents_hits, tbl, pos, ang, ply)
	elseif tbl.HitboxMode == "Cone" then
		local ents_hits = {}
		local steps
		steps = math.Clamp(4*math.ceil(tbl.Length / (tbl.Radius or 1)),1,50)
		for i = 1,0,-1/steps do
			MergeTargetsByID(ents_hits,ents.FindInSphere(pos + ang:Forward()*tbl.Length*i, i * tbl.Radius))
		end

		steps = math.Clamp(math.ceil(tbl.Length / (tbl.Radius or 1)),1,4)

		if tbl.Radius == 0 then MergeTargetsByID(ents_hits,ents.FindAlongRay(pos, pos + ang:Forward()*tbl.Length)) end
		ProcessForcesList(ents_hits, tbl, pos, ang, ply)
	elseif tbl.HitboxMode =="Ray" then
		local startpos = pos + Vector(0,0,0)
		local endpos = pos + ang:Forward()*tbl.Length
		ents_hits = ents.FindAlongRay(startpos, endpos)
		ProcessForcesList(ents_hits, tbl, pos, ang, ply)
	end
end

function PART:OnDraw()
	self.pos,self.ang = self:GetDrawPosition()
	if not self.Preview and not self.PreviewForces then pac.RemoveHook("PostDrawOpaqueRenderables", "pac_force_Draw"..self.UniqueID) end

	if self.Preview or self.PreviewForces then
		pac.AddHook("PostDrawOpaqueRenderables", "pac_force_Draw"..self.UniqueID, function()
			if self.PreviewForces then
				--recalculating forces every drawframe is cringe for other players
				if self:GetPlayerOwner() == pac.LocalPlayer then
					if self.NPC or self.Players or self.AffectSelf or self.PhysicsProps or self.PointEntities then
						preview_process_ents(self)
					end
				end
			end
			if not self.Preview then return end

			if self.HitboxMode == "Box" then
				local mins =  Vector(-self.Radius, -self.Radius, -self.Length)
				local maxs = Vector(self.Radius, self.Radius, self.Length)
				render.DrawWireframeBox( self:GetWorldPosition(), Angle(0,0,0), mins, maxs, Color( 255, 255, 255 ) )
			elseif self.HitboxMode == "Sphere" then
				render.DrawWireframeSphere( self:GetWorldPosition(), self.Radius, 10, 10, Color( 255, 255, 255 ) )
			elseif self.HitboxMode == "Cylinder" then
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
			elseif self.HitboxMode == "Cone" then
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
	end
end



function PART:OnThink()
	if self.Continuous and self.next_impulse < CurTime() then
		self:Impulse(true)
	end
end

function PART:Impulse(on)
	self.next_impulse = CurTime() + 0.05
	if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
	if not on and not self.Continuous then return end
	if not GetConVar("pac_sv_force"):GetBool() then return end
	if util.NetworkStringToID( "pac_request_force" ) == 0 then self:SetError("This part is deactivated on the server") return end
	pac.Blocked_Combat_Parts = pac.Blocked_Combat_Parts or {}
	if pac.Blocked_Combat_Parts then
		if pac.Blocked_Combat_Parts[self.ClassName] then return end
	end
	if not GetConVar("pac_sv_combat_enforce_netrate_monitor_serverside"):GetBool() then
		if not pac.CountNetMessage() then self:SetInfo("Went beyond the allowance") return end
	end

	local locus_pos = Vector(0,0,0)
	if self.Locus ~= nil then
		if self.Locus:IsValid() then
			locus_pos = self.Locus:GetWorldPosition()
		end
	else locus_pos = self:GetWorldPosition() end

	if self.BaseForce == 0 and not game.SinglePlayer() and self.Damping == 0 then
		if math.abs(self.AddedVectorForce.x) < 10 and math.abs(self.AddedVectorForce.y) < 10 and math.abs(self.AddedVectorForce.z) < 10 then
			if math.abs(self.Torque.x) < 10 and math.abs(self.Torque.y) < 10 and math.abs(self.Torque.z) < 10 then
				return
			end
		end
	end

	if not self.NPC and not self.Players and not self.AffectSelf and not self.PhysicsProps and not self.PointEntities then return end
	net.Start("pac_request_force", true)
	net.WriteVector(self:GetWorldPosition())
	net.WriteAngle(self:GetWorldAngles())
	net.WriteVector(locus_pos)
	net.WriteBool(on)

	net.WriteString(string.sub(self.UniqueID,1,12))
	net.WriteEntity(self:GetRootPart():GetOwner())

	net.WriteUInt(force_hitbox_ids[self.HitboxMode] or 0,4)
	net.WriteUInt(base_force_mode_ids[self.BaseForceAngleMode] or 0,3)
	net.WriteUInt(vect_force_mode_ids[self.VectorForceAngleMode] or 0,2)
	net.WriteUInt(ang_torque_mode_ids[self.TorqueMode] or 0,2)

	net.WriteInt(self.Length, 16)
	net.WriteInt(self.Radius, 16)

	net.WriteInt(self.BaseForce, 18)
	net.WriteVector(self.AddedVectorForce)
	net.WriteVector(self.Torque)
	net.WriteUInt(self.Damping*1000, 10)
	net.WriteInt(self.LevitationHeight,14)

	net.WriteBool(self.Continuous)
	net.WriteBool(self.AccountMass)
	net.WriteBool(self.Falloff)
	net.WriteBool(self.ReverseFalloff)
	net.WriteBool(self.DampingFalloff)
	net.WriteBool(self.DampingReverseFalloff)
	net.WriteBool(self.Levitation)
	net.WriteBool(self.AffectSelf)
	net.WriteBool(self.Players)
	net.WriteBool(self.PhysicsProps)
	net.WriteBool(self.PointEntities)
	net.WriteBool(self.NPC)
	net.SendToServer()
end



function PART:BuildCylinder(obj)
	local sides = 30
	local circle_tris = {}
	for i=1,sides,1 do
		local vert1 = {pos = Vector(0,          self.Radius*math.sin((i-1)*(2*math.pi / sides)),self.Radius*math.cos((i-1)*(2*math.pi / sides))), u = 0, v = 0 }
		local vert2 = {pos = Vector(0,          self.Radius*math.sin((i-0)*(2*math.pi / sides)),self.Radius*math.cos((i-0)*(2*math.pi / sides))), u = 0, v = 0 }
		local vert3 = {pos = Vector(self.Length,self.Radius*math.sin((i-1)*(2*math.pi / sides)),self.Radius*math.cos((i-1)*(2*math.pi / sides))), u = 0, v = 0 }
		local vert4 = {pos = Vector(self.Length,self.Radius*math.sin((i-0)*(2*math.pi / sides)),self.Radius*math.cos((i-0)*(2*math.pi / sides))), u = 0, v = 0 }

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

function PART:SetRadius(val)
	self.Radius = val
	local sv_dist = GetConVar("pac_sv_force_max_radius"):GetInt()
	if self.Radius > sv_dist then
		self:SetInfo("Your radius is beyond the server's maximum permitted! Server max is " .. sv_dist)
	else
		self:SetInfo(nil)
	end
end

function PART:SetLength(val)
	self.Length = val
	local sv_dist = GetConVar("pac_sv_force_max_length"):GetInt()
	if self.Length > sv_dist then
		self:SetInfo("Your length is beyond the server's maximum permitted! Server max is " .. sv_dist)
	else
		self:SetInfo(nil)
	end
end

function PART:SetBaseForce(val)
	self.BaseForce = val
	local sv_max = GetConVar("pac_sv_force_max_amount"):GetInt()
	if self.BaseForce > sv_max then
		self:SetInfo("Your base force is beyond the server's maximum permitted! Server max is " .. sv_max)
	else
		self:SetInfo(nil)
	end
end

BUILDER:Register()