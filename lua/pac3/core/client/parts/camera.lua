local LerpAngle = LerpAngle

local PART = {}

PART.ClassName = "camera"
PART.Group = 'entity'
PART.Icon = 'icon16/camera.png'

pac.StartStorableVars()
	pac.GetSet(PART, "EyeAnglesLerp", 1)
	pac.GetSet(PART, "DrawViewModel", false)

	pac.GetSet(PART, "NearZ", -1)
	pac.GetSet(PART, "FarZ", -1)
	pac.GetSet(PART, "FOV", -1)
pac.EndStorableVars()

for i, ply in ipairs(player.GetAll()) do
	ply.pac_cameras = nil
end

function PART:Initialize()
	local owner = self:GetOwner(true)

	if owner ~= NULL then
		owner.pac_cameras = owner.pac_cameras or {}
		owner.pac_cameras[self] = self
	end

	self.AllowSetupPositionFrameSkip = false
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

pac.RegisterPart(PART)

local temp = {}

pac.AddHook("CalcView", "camera_part", function(ply, pos, ang, fov, nearz, farz)
	if not ply.pac_cameras then return end
	if ply:GetViewEntity() ~= ply then return end

	for _, part in pairs(ply.pac_cameras) do
		if part:IsValid() then
			if part:IsHidden() and part:IsEventHidden() then
				for i, event in ipairs(part:GetChildrenList()) do
					if event.ClassName == 'event' then
						event.AlwaysThink = true
						event:Think()
						part.draw_hidden = part.event_hidden
					end
				end
			end

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
