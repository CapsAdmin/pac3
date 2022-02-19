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
	local owner = self:GetRootPart():GetOwner()
	if not owner:IsValid() then return end

	owner.pac_cameras = owner.pac_cameras or {}
	owner.pac_cameras[self] = self
end

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

pac.AddHook("CalcView", "camera_part", function(ply, pos, ang, fov, nearz, farz)
	if not ply.pac_cameras then return end
	if ply:GetViewEntity() ~= ply then return end

	for _, part in pairs(ply.pac_cameras) do
		if part:IsValid() then
			part:CalcShowHide()

			if not part:IsHidden() then
				pos, ang, fov, nearz, farz = part:CalcView(ply, pos, ang, fov, nearz, farz)
				temp.origin = pos
				temp.angles = ang
				temp.fov = fov
				temp.znear = nearz
				temp.zfar = farz
				temp.drawviewer = not part.DrawViewModel
				return temp
			end
		else
			ply.pac_cameras[part] = nil
		end
	end
end)
