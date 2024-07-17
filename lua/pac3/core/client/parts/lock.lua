local pac = pac
local Vector = Vector
local Angle = Angle
local NULL = NULL
local Matrix = Matrix

local physics_point_ent_classes = {
	["prop_physics"] = true,
	["prop_physics_multiplayer"] = true,
	["prop_physics_respawnable"] = true,
	["prop_ragdoll"] = true,
	["weapon_striderbuster"] = true,
	["item_item_crate"] = true,
	["func_breakable_surf"] = true,
	["func_breakable"] = true,
	["physics_cannister"] = true,
	["npc_satchel"] = true,
	["npc_grenade_frag"] = true,
}

local convar_lock = GetConVar("pac_sv_lock")
local convar_lock_grab = GetConVar("pac_sv_lock_grab")
local convar_lock_max_grab_radius = GetConVar("pac_sv_lock_max_grab_radius")
local convar_lock_teleport = GetConVar("pac_sv_lock_teleport")
local convar_combat_enforce_netrate = GetConVar("pac_sv_combat_enforce_netrate_monitor_serverside")

--sorcerous hack fix
if convar_lock == nil then timer.Simple(10, function() convar_lock = GetConVar("pac_sv_lock") end) end
if convar_lock_grab == nil then timer.Simple(10, function() convar_lock_grab = GetConVar("pac_sv_lock_grab") end) end
if convar_lock_teleport == nil then timer.Simple(10, function() convar_lock_teleport = GetConVar("pac_sv_lock_teleport") end) end
if convar_lock_max_grab_radius == nil then timer.Simple(10, function() convar_lock_max_grab_radius = GetConVar("pac_sv_lock_max_grab_radius") end) end
if convar_combat_enforce_netrate == nil then timer.Simple(10, function() convar_combat_enforce_netrate = GetConVar("pac_sv_combat_enforce_netrate_monitor_serverside") end) end


local BUILDER, PART = pac.PartTemplate("base_movable")

PART.ClassName = "lock"
PART.Group = "combat"
PART.Icon = "icon16/lock.png"


BUILDER:StartStorableVars()
	:SetPropertyGroup("Behaviour")
		:GetSet("Mode", "None", {enums = {["None"] = "None", ["Grab"] = "Grab", ["Teleport"] = "Teleport"}})
		:GetSet("OverrideAngles", true, {description = "Whether the part will rotate the entity alongside it, otherwise it changes just the position"})
		:GetSet("RelativeGrab", false)
		:GetSet("RestoreDelay", 1, {description = "Seconds until the entity's original angles before self.grabbing are re-applied"})
		:GetSet("NoCollide", true, {description = "Whether to disable collisions on the entity while grabbed."})

	:SetPropertyGroup("DetectionOrigin")
		:GetSet("Radius", 20)
		:GetSet("OffsetDownAmount", 0, {description = "Lowers the detect origin by some amount"})
		:GetSetPart("TargetPart")
		:GetSet("ContinuousSearch", false, {description = "Will search for entities until one is found. Otherwise only try once when part is shown."})
		:GetSet("Preview", false)

	:SetPropertyGroup("TeleportSafety")
		:GetSet("ClampDistance", false, {description = "Prevents the teleport from going too far (By Radius amount). For example, if you use hitpos bone on a pac model, it can act as a safety in case the raycast falls out of bounds."})
		:GetSet("SlopeSafety", false, {description = "Teleports a bit up in case you end up on a slope and get stuck."})

	:SetPropertyGroup("PlayerCameraOverride")
		:GetSet("OverrideEyeAngles", false, {description = "Whether the part will try to override players' eye angles. Requires OverrideAngles and user consent"})
		:GetSet("OverrideEyePosition", false, {description = "Whether the part will try to override players' view position to a selected base_movable part with a CalcView hook as well. Requires OverrideEyeAngles, OverrideAngles, a valid base_movable OverrideEyePositionPart and user consent"})
		:GetSetPart("OverrideEyePositionPart")
		:GetSet("DrawLocalPlayer", true, {description = "Whether the resulting calcview will draw the target player as in third person, otherwise hide the player"})

	:SetPropertyGroup("Targets")
		:GetSet("AffectPlayerOwner", false)
		:GetSet("Players", false)
		:GetSet("PhysicsProps", false)
		:GetSet("NPC", false)


BUILDER:EndStorableVars()

function PART:OnThink()
	if not convar_lock:GetBool() then return end
	if util.NetworkStringToID("pac_request_position_override_on_entity_grab") == 0 then self:SetError("This part is deactivated on the server") return end
	pac.Blocked_Combat_Parts = pac.Blocked_Combat_Parts or {}
	if pac.Blocked_Combat_Parts then
		if pac.Blocked_Combat_Parts[self.ClassName] then return end
	end

	if self.forcebreak then
		if self.next_allowed_grab < CurTime() then --we're able to resume
			if self.ContinuousSearch then
				self.forcebreak = false
			else
				--wait for the next showing to reset the search because we have self.resetcondition
			end
		else
			return
		end
	end

	if self.Mode == "Grab" then
		if not convar_lock_grab:GetBool() then return end
		if pac.Blocked_Combat_Parts then
			if pac.Blocked_Combat_Parts[self.ClassName] then
				return
			end
		end
		if self.ContinuousSearch and not self.grabbing then
			self:DecideTarget()
		end
		self:CheckEntValidity()
		if self.valid_ent then
			local final_ang = Angle(0, 0, 0)
			if self.OverrideAngles then --if overriding angles
				if self.is_first_time then
					self.default_ang = self.target_ent:GetAngles() --record the initial ent angles
				end
				if self.OverrideEyeAngles then self.default_ang.y = self:GetWorldAngles().y end --if we want to override players eye angles we will keep recording the yaw

			elseif not self.grabbing then
				self.default_ang = self.target_ent:GetAngles() --record the initial ent angles anyway
			end

			local relative_transform_matrix = Matrix()
			relative_transform_matrix:Identity()

			if self.RelativeGrab then
				if self.is_first_time then self:CalculateRelativeOffset() end
				relative_transform_matrix = self.relative_transform_matrix or Matrix():Identity()
			else
				relative_transform_matrix = Matrix()
				relative_transform_matrix:Identity()
			end

			local offset_matrix = Matrix()
			offset_matrix:Translate(self:GetWorldPosition())
			offset_matrix:Rotate(self:GetWorldAngles())
			offset_matrix:Mul(relative_transform_matrix)

			local relative_offset_pos = offset_matrix:GetTranslation()
			local relative_offset_ang = offset_matrix:GetAngles()

			local ply_owner = self:GetPlayerOwner()

			if pac.LocalPlayer == ply_owner then
				if not convar_combat_enforce_netrate:GetBool() then
					if not pac.CountNetMessage() then self:SetInfo("Went beyond the allowance") return end
				end
				net.Start("pac_request_position_override_on_entity_grab")
				net.WriteBool(self.is_first_time)
				net.WriteString(self.UniqueID)
				if self.RelativeGrab then
					net.WriteVector(relative_offset_pos)
					net.WriteAngle(relative_offset_ang)
				else
					net.WriteVector(self:GetWorldPosition())
					net.WriteAngle(self:GetWorldAngles())
				end
			end

			local try_override_eyeang = false
			if self.target_ent:IsPlayer() then
				if self.OverrideEyeAngles then try_override_eyeang = true end
			end
			if pac.LocalPlayer == ply_owner then
				net.WriteBool(self.OverrideAngles)
				net.WriteBool(try_override_eyeang)
				net.WriteBool(self.NoCollide)
				net.WriteEntity(self.target_ent)
				net.WriteEntity(self:GetRootPart():GetOwner())
				local can_calcview = false
				if self.OverrideEyePosition and IsValid(self.OverrideEyePositionPart) then
					if self.OverrideEyePositionPart.GetWorldAngles then
						can_calcview = true
					end
				end
				net.WriteBool(can_calcview)
				--print(IsValid(self.OverrideEyePositionPart), self.OverrideEyeAngles)
				if can_calcview then
					net.WriteVector(self.OverrideEyePositionPart:GetWorldPosition())
					net.WriteAngle(self.OverrideEyePositionPart:GetWorldAngles())
				else
					net.WriteVector(self:GetWorldPosition())
					net.WriteAngle(self:GetWorldAngles())
				end
				net.WriteBool(self.DrawLocalPlayer)
				net.SendToServer()
			end
			--print(self:GetRootPart():GetOwner())
			if self.Players and self.target_ent:IsPlayer() and self.OverrideAngles then
				local mat = Matrix()
				mat:Identity()

				if self.OverrideAngles then
					final_ang = self:GetWorldAngles()
				end
				if self.OverrideEyeAngles then
					final_ang = self:GetWorldAngles()
					--final_ang = Angle(0,180,0)
					--print("chose part ang")
				end
				if self.OverrideEyePosition and can_calcview then
					final_ang = self.OverrideEyePositionPart:GetWorldAngles()
					--print("chose alt part ang")
				end

				local eyeang = self.target_ent:EyeAngles()
				--print("eyeang", eyeang)
				eyeang.p = 0
				eyeang.y = eyeang.y
				eyeang.r = 0
				mat:Rotate(final_ang - eyeang) --this works
				--mat:Rotate(eyeang)
				--print("transform ang", final_ang)
				--print("part's angles", self:GetWorldAngles())
				--mat:Rotate(self:GetWorldAngles())

				self.target_ent:EnableMatrix("RenderMultiply", mat)
			end

			self.grabbing = true
			self.teleported = false
		end
	end
	--if self.is_first_time then print("lock " .. self.UniqueID .. "did its first clock") end
	self.is_first_time = false
end

do
	function PART:BreakLock(ent)
		self.forcebreak = true
		self.next_allowed_grab = CurTime() + 3
		if self.target_ent then self.target_ent.IsGrabbedID = nil end
		self.target_ent = nil
		self.grabbing = false
		pac.Message(Color(255, 50, 50), "lock break result:")
		MsgC(Color(0,255,255), "\t", self) MsgC(Color(200, 200, 200), " in your group ") MsgC(Color(0,255,255), self:GetRootPart(),"\n")
		MsgC(Color(200, 200, 200), "\tIt will now be in the forcebreak state until the next allowed grab, 3 seconds from now\nalso this entity can't be grabbed for 10 seconds.\n")
		if not self.ContinuousSearch then
			self.resetcondition = true
		end

		ent:SetGravity(1)

		ent.pac_recently_broken_free_from_lock = CurTime()
		ent:DisableMatrix("RenderMultiply")
	end
	net.Receive("pac_request_lock_break", function(len)
		--[[format:
			net.Start("pac_request_lock_break")
			net.WriteEntity(ply)	--the breaker
			net.WriteString("")		--the uid if applicable
			net.Send(ent)			--that's us! the locker
		]]
		local target_to_release = net.ReadEntity()
		local uid = net.ReadString()
		local reason = net.ReadString()
		pac.Message(Color(255, 255, 255), "------------ CEASE AND DESIST! / BREAK LOCK ------------")
		MsgC(Color(0,255,255), tostring(target_to_release)) MsgC(Color(255,50,50), " WANTS TO BREAK FREE!!\n")
		MsgC(Color(255,50,50), "reason:") MsgC(Color(0,255,255), reason .."\n")

		if uid ~= "" then --if a uid is provided
			MsgC(Color(255, 50, 50), "AND IT KNOWS YOUR UID! " .. uid .. "\n")
			local part = pac.GetPartFromUniqueID(pac.Hash(pac.LocalPlayer), uid)
			if part then
				if part.ClassName == "lock" then
					part:BreakLock(target_to_release)
				end
			end
		else
			MsgC(Color(200, 200, 200), "NOW! WE SEARCH YOUR LOCAL PARTS!\n")
			for i,part in pairs(pac.GetLocalParts()) do
				if part.ClassName == "lock" then
					if part.grabbing then
						if IsValid(part.target_ent) and part.target_ent == target_to_release then
							part:BreakLock(target_to_release)
						end
					end
				end
			end
		end

	end)

	net.Receive("pac_mark_grabbed_ent", function(len)

		local target_to_mark = net.ReadEntity()
		if not IsValid(target_to_mark) then return end
		if target_to_mark:EntIndex() == 0 then return end
		local successful_grab = net.ReadBool()
		local uid = net.ReadString()
		local part = pac.GetPartFromUniqueID(pac.Hash(pac.LocalPlayer), uid)
		--print(target_to_mark,"is grabbed by",uid)

		if not successful_grab then
			part:BreakLock(target_to_mark) --yes we will employ the aggressive lock break here
		else
			target_to_mark.IsGrabbed = successful_grab
			target_to_mark.IsGrabbedID = uid
			target_to_mark:SetGravity(0)
		end
	end)
end

function PART:SetRadius(val)
	self.Radius = val
	local sv_dist = convar_lock_max_grab_radius:GetInt()
	if self.Radius > sv_dist then
		self:SetInfo("Your radius is beyond the server's maximum permitted! Server max is " .. sv_dist)
	else
		self:SetInfo(nil)
	end
end

function PART:OnShow()
	if util.NetworkStringToID("pac_request_position_override_on_entity_grab") == 0 then self:SetError("This part is deactivated on the server") return end
	local origin_part
	self.is_first_time = true
	if self.resetting_condition or self.forcebreak then
		if self.next_allowed_grab < CurTime() then
			self.forcebreak = false
			self.resetting_condition = false
		end
	end
	local hookID = "pace_draw_lockpart_preview" .. self.UniqueID
	pac.AddHook("PostDrawOpaqueRenderables", hookID, function()
		if not IsValid(self) then pac.RemoveHook("PostDrawOpaqueRenderables", hookID) return end
		if self.TargetPart:IsValid() then
			origin_part = self.TargetPart
		else
			origin_part = self
		end
		if origin_part == nil or not self.Preview or pac.LocalPlayer ~= self:GetPlayerOwner() then return end
		local sv_dist = GetConVar("pac_sv_lock_max_grab_radius"):GetInt()

		render.DrawLine(origin_part:GetWorldPosition(),origin_part:GetWorldPosition() + Vector(0,0,-self.OffsetDownAmount),Color(255,255,255))

		if self.Radius < sv_dist then
			self:SetInfo(nil)
			render.DrawWireframeSphere(origin_part:GetWorldPosition() + Vector(0,0,-self.OffsetDownAmount), sv_dist, 30, 30, Color(50,50,150),true)
			render.DrawWireframeSphere(origin_part:GetWorldPosition() + Vector(0,0,-self.OffsetDownAmount), self.Radius, 30, 30, Color(255,255,255),true)
		else
			self:SetInfo("Your radius is beyond the server max! Active max is " .. sv_dist)
			render.DrawWireframeSphere(origin_part:GetWorldPosition() + Vector(0,0,-self.OffsetDownAmount), sv_dist, 30, 30, Color(0,255,255),true)
			render.DrawWireframeSphere(origin_part:GetWorldPosition() + Vector(0,0,-self.OffsetDownAmount), self.Radius, 30, 30, Color(100,100,100),true)
		end

	end)
	if self.Mode == "Teleport" then
		if not GetConVar('pac_sv_lock_teleport'):GetBool() or pac.Blocked_Combat_Parts[self.ClassName] then return end
		if pace.still_loading_wearing then return end
		self.target_ent = nil

		local ang_yaw_only = self:GetWorldAngles()
		ang_yaw_only.p = 0
		ang_yaw_only.r = 0
		if pac.LocalPlayer == self:GetPlayerOwner() then

			local teleport_pos_final = self:GetWorldPosition()

			if self.ClampDistance then
				local ply_pos = self:GetPlayerOwner():GetPos()
				local pos = self:GetWorldPosition()

				if pos:Distance(ply_pos) > self.Radius then
					local clamped_pos = ply_pos + (pos - ply_pos):GetNormalized()*self.Radius
					teleport_pos_final = clamped_pos
				end
			end
			if self.SlopeSafety then teleport_pos_final = teleport_pos_final + Vector(0,0,30) end
			if not GetConVar("pac_sv_combat_enforce_netrate_monitor_serverside"):GetBool() then
				if not pac.CountNetMessage() then self:SetInfo("Went beyond the allowance") return end
			end
			timer.Simple(0, function()
				if self:IsHidden() or self:IsDrawHidden() then return end
				net.Start("pac_request_position_override_on_entity_teleport")
				net.WriteString(self.UniqueID)
				net.WriteVector(teleport_pos_final)
				net.WriteAngle(ang_yaw_only)
				net.WriteBool(self.OverrideAngles)
				net.SendToServer()
			end)

		end
		self.grabbing = false
	elseif self.Mode == "Grab" then
		self:DecideTarget()
		self:CheckEntValidity()
	end
end

function PART:OnHide()
	pac.RemoveHook("PostDrawOpaqueRenderables", "pace_draw_lockpart_preview"..self.UniqueID)
	self.teleported = false
	self.grabbing = false
	if self.target_ent == nil then return
	else self.target_ent.IsGrabbed = false self.target_ent.IsGrabbedID = nil end
	if util.NetworkStringToID( "pac_request_position_override_on_entity_grab" ) == 0 then self:SetError("This part is deactivated on the server") return end
	self:reset_ent_ang()
end

function PART:reset_ent_ang()
	if self.target_ent == nil then return end
	local reset_ent = self.target_ent

	if reset_ent:IsValid() then
		timer.Simple(math.min(self.RestoreDelay,5), function()
			if pac.LocalPlayer == self:GetPlayerOwner() then
				if not GetConVar("pac_sv_combat_enforce_netrate_monitor_serverside"):GetBool() then
					if not pac.CountNetMessage() then self:SetInfo("Went beyond the allowance") return end
				end
				net.Start("pac_request_angle_reset_on_entity")
				net.WriteAngle(Angle(0,0,0))
				net.WriteFloat(self.RestoreDelay)
				net.WriteEntity(reset_ent)
				net.WriteEntity(self:GetPlayerOwner())
				net.SendToServer()
			end
			if self.Players and reset_ent:IsPlayer() then
				reset_ent:DisableMatrix("RenderMultiply")
			end
		end)
	end
end

function PART:OnRemove()
end

function PART:DecideTarget()

	local RADIUS = math.Clamp(self.Radius,0,GetConVar("pac_sv_lock_max_grab_radius"):GetInt())
	local ents_candidates = {}
	local chosen_ent = nil
	local target_part = self.TargetPart
	local origin

	if self.TargetPart and (self.TargetPart):IsValid() then
		origin = (self.TargetPart):GetWorldPosition()
	else
		origin = self:GetWorldPosition()
	end
	origin:Add(Vector(0,0,-self.OffsetDownAmount))

	for i, ent_candidate in ipairs(ents.GetAll()) do

		if IsValid(ent_candidate) then
			local check_further = true
			if ent_candidate.pac_recently_broken_free_from_lock then
				if ent_candidate.pac_recently_broken_free_from_lock + 10 > CurTime() then
					check_further = false
				end
			else check_further = true end

			if check_further then
				if ent_candidate:GetPos():Distance( origin ) < RADIUS then
					if self.Players and ent_candidate:IsPlayer() then
						--we don't want to grab ourselves
						if (ent_candidate ~= self:GetRootPart():GetOwner()) or (self.AffectPlayerOwner and ent_candidate == self:GetPlayerOwner()) then
							if not (not self.AffectPlayerOwner and ent_candidate == self:GetPlayerOwner()) then
								chosen_ent = ent_candidate
								table.insert(ents_candidates, ent_candidate)
							end
						elseif (self:GetPlayerOwner() ~= ent_candidate) then --if it's another player, good
							chosen_ent = ent_candidate
							table.insert(ents_candidates, ent_candidate)
						end
					elseif self.PhysicsProps and (physics_point_ent_classes[ent_candidate:GetClass()] or string.find(ent_candidate:GetClass(),"item_") or string.find(ent_candidate:GetClass(),"ammo_")) then
						chosen_ent = ent_candidate
						table.insert(ents_candidates, ent_candidate)
					elseif self.NPC and (ent_candidate:IsNPC() or ent_candidate:IsNextBot() or ent_candidate.IsDrGEntity or ent_candidate.IsVJBaseSNPC) then
						chosen_ent = ent_candidate
						table.insert(ents_candidates, ent_candidate)
					end
				end
			end
		end
	end
	local closest_distance = math.huge

	--sort for the closest
	for i,ent_candidate in ipairs(ents_candidates) do
		local test_distance = (ent_candidate:GetPos()):Distance( self:GetWorldPosition())
		if (test_distance < closest_distance) then
			closest_distance = test_distance
			chosen_ent = ent_candidate
		end
	end

	if chosen_ent ~= nil then
		self.target_ent = chosen_ent
		if pac.LocalPlayer == self:GetPlayerOwner() then
			print("selected ", chosen_ent, "dist ", (chosen_ent:GetPos()):Distance( self:GetWorldPosition() ))
		end
		self.valid_ent = true
	else
		self.target_ent = nil
		self.valid_ent = false
	end
end



function PART:CheckEntValidity()

	if self.target_ent == nil then
		self.valid_ent = false
	elseif self.target_ent:EntIndex() == 0 then
		self.valid_ent = false
	elseif IsValid(self.target_ent) then
		self.valid_ent = true
	end
	if self.target_ent ~= nil then
		if self.target_ent.IsGrabbedID and self.target_ent.IsGrabbedID ~= self.UniqueID then self.valid_ent = false end
	end
	if not self.valid_ent then self.target_ent = nil end
	--print("ent check:",self.valid_ent)
end

function PART:CalculateRelativeOffset()
	if self.target_ent == nil or not IsValid(self.target_ent) then self.relative_transform_matrix = Matrix() return end
	self.relative_transform_matrix = Matrix()
	self.relative_transform_matrix:Rotate(self.target_ent:GetAngles() - self:GetWorldAngles())
	self.relative_transform_matrix:Translate(self.target_ent:GetPos() - self:GetWorldPosition())
	--print("ang delta!", self.target_ent:GetAngles() - self:GetWorldAngles())
end

function PART:Initialize()
	self.default_ang = Angle(0,0,0)
	if not GetConVar('pac_sv_lock_grab'):GetBool() then
		if not GetConVar('pac_sv_lock_teleport'):GetBool() then
			self:SetWarning("lock part grabs and teleports are disabled on this server!")
		else
			self:SetWarning("lock part grabs are disabled on this server!")
		end
	end
	if not GetConVar('pac_sv_lock_teleport'):GetBool() then
		if not GetConVar('pac_sv_lock_grab'):GetBool() then
			self:SetWarning("lock part grabs and teleports are disabled on this server!")
		else
			self:SetWarning("lock part teleports are disabled on this server!")
		end
	end
	if not GetConVar('pac_sv_lock'):GetBool() then self:SetError("lock parts are disabled on this server!") end
end


BUILDER:Register()
