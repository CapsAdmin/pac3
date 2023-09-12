local LerpAngle = LerpAngle

local BUILDER, PART = pac.PartTemplate("base_movable")

PART.ClassName = "camera"
PART.Group = 'entity'
PART.Icon = 'icon16/camera.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("EyeAnglesLerp", 1)
	BUILDER:GetSet("DrawViewModel", false)

	BUILDER:GetSet("NearZ", -1)
	BUILDER:GetSet("FarZ", -1)
	BUILDER:GetSet("FOV", -1)
BUILDER:EndStorableVars()

for i, ply in ipairs(player.GetAll()) do
	ply.pac_cameras = nil
end

function PART:OnShow()
	local owner = self:GetPlayerOwner()
	if not owner:IsValid() then return end
	self.inactive = false

	owner.pac_cameras = owner.pac_cameras or {}
	owner.pac_cameras[self] = self

	--the policy is that a shown camera takes priority over all others
	for _, part in pairs(owner.pac_cameras) do
		if part ~= self then
			part.priority = false
		end
	end
	self.priority = true
	timer.Simple(0.02, function()
		self.priority = true
	end)
end

function PART:OnHide()
	local owner = self:GetPlayerOwner()
	if not owner:IsValid() then return end

	owner.pac_cameras = owner.pac_cameras or {}

	--this camera cedes priority to others that may be active
	for _, part in pairs(owner.pac_cameras) do
		if part ~= self and not part:IsHidden() then
			part.priority = true
		end
	end
	self.inactive = true
	self.priority = false
	owner.pac_cameras[self] = nil
end

--[[function PART:OnHide()
	--only stop the part if explicitly set to hidden.
	if not self.Hide and not self:IsHidden() then return end
end]]

function PART:CalcView(_, _, eyeang, fov, nearz, farz)
	local pos, ang = self:GetDrawPosition(nil, true)

	ang = LerpAngle(self.EyeAnglesLerp, ang, eyeang)

	if self.NearZ > 0 then
		nearz = self.NearZ
	end

	if self.FarZ > 0 then
		farz = self.FarZ
	end

	if self.FOV > 0 then
		fov = self.FOV
	end

	return pos, ang, fov, nearz, farz
end

BUILDER:Register()


local temp = {}
local remaining_camera = false
local remaining_camera_time_buffer = CurTime()

local function CheckCamerasAgain(ply)
	local cams = ply.pac_cameras or {}
	local fpos, fang, ffov, fnearz, ffarz

	for _, part in pairs(cams) do
		if (not part.inactive or part.priority) and not part:IsHidden() then
			return true
		end
	end
end

local function RebuildCameras(ply)
	ply.pac_cameras = {}
	for _,part in pairs(pac.GetLocalParts()) do
		if part:IsValid() then
			if part.ClassName == "camera" and (not part.inactive or not part:IsHidden() or part.priority) then
				if part:GetPlayerOwner() == ply then
					ply.pac_cameras[part] = part
				end
			end
		end
	end
end

pac.AddHook("CalcView", "camera_part", function(ply, pos, ang, fov, nearz, farz)

	local fpos, fang, ffov, fnearz, ffarz
	local warning_state = not ply.pac_cameras
	if not warning_state then warning_state = table.IsEmpty(ply.pac_cameras) end
	if ply:GetViewEntity() ~= ply then return end

	remaining_camera = false
	remaining_camera_time_buffer = remaining_camera_time_buffer or CurTime()
	if warning_state then
		RebuildCameras(ply)
	else
		for _, part in pairs(ply.pac_cameras) do
			if part.ClassName ~= "camera" then
				ply.pac_cameras[part] = nil
			end

			if part.ClassName == "camera" and part:IsValid() then
				if not part:IsHidden() then
					remaining_camera = true
					remaining_camera_time_buffer = CurTime() + 0.1
				end

				part:CalcShowHide()
				if not part.inactive then
					--calculate values ahead of the return, used as a fallback just in case
					fpos, fang, ffov, fnearz, ffarz = part:CalcView(ply, pos, ang, fov, nearz, farz)
					temp.origin = fpos
					temp.angles = fang
					temp.fov = ffov
					temp.znear = fnearz
					temp.zfar = ffarz
					temp.drawviewer = false
					
					if not part:IsHidden() and not part.inactive and part.priority then
						temp.drawviewer = not part.DrawViewModel
						return temp
					end
				end
			else
				ply.pac_cameras[part] = nil
			end
		end
	end

	if remaining_camera or CurTime() < remaining_camera_time_buffer then
		return temp
	end

	--final fallback, just give us any valid pac camera to preserve the view! priority will be handled elsewhere
	if CheckCamerasAgain(ply) then
		return temp
	else
		return
	end

	return
	--only time to return to first person is if all camera parts are hidden AFTER we pass the buffer time filter
	--until we make reversible first person a thing, letting some non-drawable parts think, this is the best solution I could come up with
end)
