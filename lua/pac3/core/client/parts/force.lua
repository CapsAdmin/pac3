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
		:GetSet("Preview",false)

	:SetPropertyGroup("BaseForces")
		:GetSet("BaseForce", 0)
		:GetSet("AddedVectorForce", Vector(0,0,0))
		:GetSet("Torque", Vector(0,0,0))
		:GetSet("BaseForceAngleMode","Radial",{enums = {["Radial"] = "Radial", ["Locus"] = "Locus", ["Local"] = "Local"}})
		:GetSet("VectorForceAngleMode", "Global", {enums = {["Global"] = "Global", ["Local"] = "Local", ["Radial"] = "Radial",  ["RadialNoPitch"] = "RadialNoPitch"}})
		:GetSet("TorqueMode", "TargetLocal", {enums = {["Global"] = "Global", ["TargetLocal"] = "TargetLocal", ["Local"] = "Local", ["Radial"] = "Radial"}})
		:GetSetPart("Locus", nil)

	:SetPropertyGroup("Behaviors")
		:GetSet("Continuous", true, {description = "If set to false, the force will be a single, stronger impulse"})
		:GetSet("AccountMass", false, {description = "Apply acceleration according to mass."})
		:GetSet("Falloff", false, {description = "Whether the force to apply should fade with distance"})
		:GetSet("ReverseFalloff", false, {description = "The reverse of the falloff means the force fades when getting closer."})
		:GetSet("Levitation", false, {description = "Tries to stabilize the force to levitate targets at a certain height relative to the part"})
		:GetSet("LevitationHeight", 0)

	:SetPropertyGroup("Damping")
		:GetSet("Damping", 0, {editor_clamp = {0,1}, editor_sensitivity = 0.1})
		:GetSet("DampingFalloff", false, {description = "Whether the damping should fade with distance"})
		:GetSet("DampingReverseFalloff", false, {description = "Whether the damping should fade with distance but reverse"})

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


function PART:OnDraw()
	self.pos,self.ang = self:GetDrawPosition()
	if not self.Preview then pac.RemoveHook("PostDrawOpaqueRenderables", "pac_force_Draw"..self.UniqueID) end

	if self.Preview then
		pac.AddHook("PostDrawOpaqueRenderables", "pac_force_Draw"..self.UniqueID, function()
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

	if self.BaseForce == 0 and not game.SinglePlayer() then
		if math.abs(self.AddedVectorForce.x) < 10 and math.abs(self.AddedVectorForce.y) < 10 and math.abs(self.AddedVectorForce.z) < 10 then
			if math.abs(self.Torque.x) < 10 and math.abs(self.Torque.y) < 10 and math.abs(self.Torque.z) < 10 then
				return
			end
		end
	end

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