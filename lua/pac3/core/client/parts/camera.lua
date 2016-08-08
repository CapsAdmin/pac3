local PART = {}

PART.ClassName = "camera"

pac.StartStorableVars()
	pac.GetSet(PART, "EyeAnglesLerp", 1)
	pac.GetSet(PART, "DrawViewModel", false)

	pac.GetSet(PART, "NearZ", -1)
	pac.GetSet(PART, "FarZ", -1)
	pac.GetSet(PART, "FOV", -1)
pac.EndStorableVars()

function PART:Initialize()
	local owner = self:GetOwner(true)
	owner.pac_cameras = owner.pac_cameras or {}
	owner.pac_cameras[self] = self
end

function PART:CalcView(ply, pos, eyeang, fov, nearz, farz)
	local pos, ang = self:GetDrawPosition(nil, true)

	ang = LerpAngle(self.EyeAnglesLerp, ang,eyeang)

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

function pac.CalcView(ply, pos, ang, fov, nearz, farz)
	if not ply.pac_cameras then return end

	for _, self in pairs(ply.pac_cameras) do
		if self:IsValid() then
			if not self:IsHidden() then
				local pos, ang, fov, nearz, farz = self:CalcView(ply, pos, ang, fov, nearz, farz)
				temp.origin =  pos
				temp.angles =  ang
				temp.fov =  fov
				temp.znear =  nearz
				temp.zfar =  farz
				temp.drawviewer =  not self.DrawViewModel
				return temp
			end
		else
			ply.pac_cameras[self] = nil
		end
	end
end

pac.AddHook("CalcView")