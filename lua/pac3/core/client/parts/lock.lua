include("pac3/extra/shared/net_combat.lua")
--pac3/extra/shared/net_combat.lua



local target_ent = nil
local pac = pac
local Vector = Vector
local Angle = Angle
local NULL = NULL
local Matrix = Matrix

local BUILDER, PART = pac.PartTemplate("base_movable")

PART.ClassName = "lock"
PART.Group = 'advanced'
PART.Icon = 'icon16/lock.png'


BUILDER:StartStorableVars()
	:SetPropertyGroup("Behaviour")
		:GetSet("Mode", "None", {enums = {["None"] = "None", ["Grab"] = "Grab", ["Teleport"] = "Teleport"}})
		:GetSet("OverrideAngles", true, {description = "Whether the part will rotate the entity alongside it, otherwise it changes just the position"})
		:GetSet("RelativeGrab", false)
		:GetSet("RestoreDelay", 1, {description = "Seconds until the entity's original angles before grabbing are re-applied"})

	:SetPropertyGroup("DetectionOrigin")
		:GetSet("Radius", 20)
		:GetSet("RadiusOffsetDown", false, {description = "Lowers the detect origin by the radius distance"})
		:GetSetPart("TargetPart")
		:GetSet("ContinuousSearch", false, {description = "Will search for entities until one is found. Otherwise only try once when part is shown."})
		:GetSet("Preview", false)

	:SetPropertyGroup("PlayerCameraOverride")
		:GetSet("OverrideEyeAngles", true, {description = "Whether the part will try to override players' eye angles. Requires OverrideAngles and user consent"})
		:GetSetPart("OverrideEyePositionPart")

	:SetPropertyGroup("Targets")
		:GetSet("Players", false)
		:GetSet("PhysicsProps", false)
		:GetSet("NPC", false)

BUILDER:EndStorableVars()

local valid_ent = false
local grabbing = false
local last_request_time = SysTime()
local last_entsearch =  SysTime()
local default_ang = Angle(0,0,0)

local forcebreak = false
local next_allowed_grab = SysTime()

function PART:OnThink()
	
	if SysTime() > next_allowed_grab then
		forcebreak = false
	elseif forcebreak then
		valid_ent = false
		self:reset_ent_ang()
		target_ent = nil
		return
	end

	self:GetWorldPosition()
	self:GetWorldAngles()
	if self.Mode == "Grab" then
		if not valid_ent and self.ContinuousSearch then --no hit and can search = search more and try the move later
			self:DecideTarget()
			self:CheckEntValidity()
			return
		elseif not valid_ent and not self.ContinuousSearch then --if initial think failed to find and can't search = stop
			--print("end of the line. ", not valid_ent, not self.ContinuousSearch, not valid_ent and not self.ContinuousSearch)
			return
		end
	end
	--good hit and can search = search more and try the move later
	self:CheckEntValidity()

	--self:DecideTarget()
	if self.Mode == "Grab" then
		if self.OverrideAngles then
			default_ang = self.target_ent:GetAngles()
			if self.OverrideEyeAngles then default_ang.y = self:GetWorldAngles().y end
		end
		if not grabbing and not self.OverrideAngles then default_ang = self.target_ent:GetAngles() end

		local relative_transform_matrix = self.relative_transform_matrix or Matrix():Identity()
		if not self.RelativeGrab then
			relative_transform_matrix = Matrix()
			relative_transform_matrix:Identity()
		end

		local offset_matrix = Matrix()
		offset_matrix:Translate(self:GetWorldPosition())
		offset_matrix:Rotate(self:GetWorldAngles())
		offset_matrix:Mul(relative_transform_matrix)

		local relative_offset_pos = offset_matrix:GetTranslation()
		local relative_offset_ang = offset_matrix:GetAngles()

		if LocalPlayer() == self:GetPlayerOwner() then
			net.Start("pac_request_position_override_on_entity")
			if self.RelativeGrab then
				net.WriteVector(relative_offset_pos)
				net.WriteAngle(relative_offset_ang)
			else
				net.WriteVector(self:GetWorldPosition())
				net.WriteAngle(self:GetWorldAngles())
			end
		end

		local can_rotate = self.OverrideAngles
		if self.target_ent:IsPlayer() then can_rotate = false end
		if LocalPlayer() == self:GetPlayerOwner() then
			net.WriteBool(can_rotate)
			net.WriteEntity(self.target_ent)
			net.WriteEntity(self:GetRootPart():GetOwner())
			net.SendToServer()
		end
		--print(self:GetRootPart():GetOwner())

		if self.Players and self.target_ent:IsPlayer() and self.OverrideAngles then
			
			local mat = Matrix()
			mat:Identity()
			mat:Rotate(Angle(0,0,0))
			mat:Rotate(self:GetWorldAngles())
			--mat:Rotate(Angle(self:GetWorldAngles().p,self:GetWorldAngles().y,self:GetWorldAngles().r))
			self.target_ent:EnableMatrix("RenderMultiply", mat)
			if self.OverrideEyeAngles then
				--self.target_ent:SetEyeAngles(Angle(self:GetWorldAngles().p,default_ang.y,default_ang.r))
			end
			if self.OverrideEyePositionPart then
				--[[if self.OverrideEyePositionPart:IsValid() then
					self.target_ent:SetCurrentViewOffset(self.OverrideEyePositionPart:GetWorldPosition() - self:GetWorldPosition())
				end]]
			end
			--if self.OverrideEyeAngles then self.target_ent:SetEyeAngles(self:GetWorldAngles()) end
		end
		
		last_request_time = SysTime()
		grabbing = true
		teleported = false
	elseif self.Mode == "Teleport" and not teleported then

		self.target_ent = nil
		
		local ang_yaw_only = self:GetWorldAngles()
		ang_yaw_only.p = 0
		ang_yaw_only.r = 0
		if LocalPlayer() == self:GetPlayerOwner() then
			net.Start("pac_request_position_override_on_entity")
			net.WriteVector(self:GetWorldPosition())
			net.WriteAngle(ang_yaw_only)
			net.WriteBool(self.OverrideAngles)
			net.WriteEntity(self:GetPlayerOwner())
			net.WriteEntity(self:GetPlayerOwner())
			net.SendToServer()
		end
		self:GetPlayerOwner():SetAngles( ang_yaw_only )

		teleported = true
		grabbing = false
	end

	if CLIENT then
		net.Receive("pac_request_lock_break", function(len)
			local target_to_release = net.ReadEntity()
			print("YOU'RE HOLDING " .. tostring(self.target_ent))
			pac.Message(Color(255, 50, 50), tostring(target_to_release) .. " WANTS TO BREAK FREE!!")
			if self.target_ent == target_to_release then
				forcebreak = true
				next_allowed_grab = SysTime() + 3
			end
		end)
	end
end



function PART:OnShow()
	local targ = self.TargetPart or self
	if self.Preview then 
		hook.Add("PostDrawOpaqueRenderables", "pace_draw_lockpart_preview", function()
			if self.RadiusOffsetDown then
				render.DrawLine(targ:GetWorldPosition(),targ:GetWorldPosition() + Vector(0,0,-self.Radius),Color(255,255,255))
				render.DrawWireframeSphere(targ:GetWorldPosition() + Vector(0,0,-self.Radius), self.Radius, 30, 30, Color(255,255,255),true)
			else render.DrawWireframeSphere(targ:GetWorldPosition(), self.Radius, 30, 30, Color(255,255,255),true) end
		end)
	end
	self.target_ent = nil
	--self.relative_transform_matrix = Matrix():Identity()
	self:DecideTarget()
	self:CheckEntValidity()
	--self:CalculateRelativeOffset()
end

function PART:OnHide()
	hook.Remove("PostDrawOpaqueRenderables", "pace_draw_lockpart_preview")
	teleported = false
	grabbing = false
	if self.target_ent == nil then return end
	timer.Simple(math.min(self.RestoreDelay,5), function()
		if self.target_ent == nil then return end
		self:reset_ent_ang()
	end)
end

function PART:reset_ent_ang()
	if self.target_ent:IsValid() then
		--if self.target_ent:GetClass() == "prop_physics" then return end
		if LocalPlayer() == self:GetPlayerOwner() then
			net.Start("pac_request_angle_reset_on_entity")
			net.WriteAngle(Angle(0,0,0))
			net.WriteFloat(self.RestoreDelay)
			net.WriteEntity(self.target_ent)
			net.WriteEntity(self:GetPlayerOwner())
			net.SendToServer()
		end
		if self.Players then
			self.target_ent:DisableMatrix("RenderMultiply")
		end
	end
end

function PART:OnRemove()
end

function PART:DecideTarget()
	--print("search")
	local ents = ents.GetAll()
	local ents_candidates = {}
	local chosen_ent = nil
	local target_part = self.TargetPart
	--filter entities
	for i, ent_candidate in ipairs(ents) do
		--print(ent_candidate:GetClass())
		if ent_candidate:IsValid() then
			local origin

			if self.TargetPart and (self.TargetPart):IsValid() then
				origin = (self.TargetPart):GetWorldPosition()
			else
				origin = self:GetWorldPosition()
			end

			if self.RadiusOffsetDown then origin:Add(Vector(0,0,-self.Radius)) end

			if ent_candidate:GetPos():Distance( origin ) < self.Radius then
				if self.Players and ent_candidate:IsPlayer() then
					--we don't want to grab ourselves
					if (self:GetPlayerOwner() ~= self:GetRootPart():GetOwner()) then
						chosen_ent = ent_candidate
						table.insert(ents_candidates, ent_candidate)
					elseif (self:GetPlayerOwner() ~= ent_candidate) then --if it's another player, good
						chosen_ent = ent_candidate
						table.insert(ents_candidates, ent_candidate)
					end
				elseif self.PhysicsProps and (ent_candidate:GetClass() == "prop_physics" or ent_candidate:GetClass() == "prop_ragdoll") then
					chosen_ent = ent_candidate
					table.insert(ents_candidates, ent_candidate)
				elseif self.NPC and ent_candidate:IsNPC() then
					chosen_ent = ent_candidate
					table.insert(ents_candidates, ent_candidate)
				end
			end
		end
	end
	local closest_distance = math.huge

	--sort for the closest
	for i,ent_candidate in ipairs(ents_candidates) do
		--print("trying", ent_candidate, ent_candidate:GetClass(), (ent_candidate:GetPos()):Distance( self:GetWorldPosition()), " from part")
		local test_distance = (ent_candidate:GetPos()):Distance( self:GetWorldPosition())
		if (test_distance < closest_distance) then
			closest_distance = test_distance
			chosen_ent = ent_candidate
		end
	end
	
	if chosen_ent ~= nil then
		self.target_ent = chosen_ent
		print("selected ", chosen_ent, "dist ", (chosen_ent:GetPos()):Distance( self:GetWorldPosition() ))
		valid_ent = true
	else
		self.target_ent = nil
		valid_ent = false
	end
end

function PART:CheckEntValidity()
	
	if self.target_ent == nil then
		valid_ent = false
	elseif self.target_ent:EntIndex() == 0 then
		valid_ent = false
	elseif self.target_ent:IsValid() then
		valid_ent = true
	end
end

function PART:CalculateRelativeOffset()
	if self.target_ent == nil then self.relative_transform_matrix = Matrix() return end
	self.relative_transform_matrix = Matrix()
	self.relative_transform_matrix:Rotate(self.target_ent:GetAngles() - self:GetWorldAngles())
	self.relative_transform_matrix:Translate(self.target_ent:GetPos() - self:GetWorldPosition())
	print("ang delta!", self.target_ent:GetAngles() - self:GetWorldAngles())
end

BUILDER:Register()