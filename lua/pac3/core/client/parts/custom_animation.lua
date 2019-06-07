local animations = pac.animations

local PART = {}

PART.ClassName = "custom_animation"
PART.NonPhysical = true
PART.Group = 'advanced'
PART.Icon = 'icon16/film.png'

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
	pac.GetSet(PART, "Data", "")
	pac.GetSet(PART, "StopOnHide", true)
	pac.GetSet(PART, "StopOtherAnimations", false)
	pac.GetSet(PART, "AnimationType", "sequence", {enums = {
		gesture = "gesture",
		posture = "posture",
		sequence = "sequence",
		stance = "stance",
	}})
	pac.GetSet(PART, "Interpolation", "cosine", {enums = {
		linear = "linear",
		cosine = "cosine",
		cubic = "cubic",
		none = "none",
	}})
	pac.GetSet(PART, "Rate", 1)
	pac.GetSet(PART, "BonePower", 1)
	pac.GetSet(PART, "Offset", 0)
pac.EndStorableVars()

function PART:GetNiceName()
	return pac.PrettifyName(("/".. self:GetURL()):match(".+/(.-)%.")) or "no anim"
end

function PART:GetAnimID()
	return "pac_anim_" .. (self:GetPlayerOwner():IsValid() and self:GetPlayerOwner():UniqueID() or "") .. self:GetUniqueID()
end

function PART:SetRate(num)
	self.Rate = num
	local owner = self:GetOwner()
	if owner:IsValid() and owner.pac_animations then
		local anim = owner.pac_animations[self:GetAnimID()]
		if anim then
			anim.TimeScale = self.Rate
		end
	end
end

function PART:SetBonePower(num)
	self.BonePower = num
	local owner = self:GetOwner()
	if owner:IsValid() and owner.pac_animations then
		local anim = owner.pac_animations[self:GetAnimID()]
		if anim then
			anim.Power = self.BonePower
		end
	end
end

function PART:SetInterpolation(mode)
	self.Interpolation = mode
	local owner = self:GetOwner()
	if owner:IsValid() and owner.pac_animations then
		local anim = owner.pac_animations[self:GetAnimID()]
		if anim then
			anim.Interpolation = mode
		end
	end
end

function PART:SetOffset(num)
	self.Offset = num
	local owner = self:GetOwner()
	if owner:IsValid() and owner.pac_animations then
		local anim = owner.pac_animations[self:GetAnimID()]
		if anim then
			anim.Offset = num
		end
	end
end

function PART:SetURL(url)
	self.URL = url

	if url:find("http") then
		pac.HTTPGet(url, function(str)
			local tbl = util.JSONToTable(str)
			if not tbl then
				pac.Message("Animation failed to parse from ", url)
				return
			end

			animations.ConvertOldData(tbl)

			self:SetAnimationType(tbl.Type)
			self:SetInterpolation(tbl.Interpolation)

			animations.RegisterAnimation(self:GetAnimID(), tbl)

			if pace and pace.timeline.IsActive() and pace.timeline.animation_part == self then
				pace.timeline.Load(tbl)
			end
		end,
		function(err)
			if self:IsValid() and LocalPlayer() == self:GetPlayerOwner() and pace and pace.IsActive() then
				Derma_Message("HTTP Request Failed for "..url,err,"OK")
			end
		end)
	end
end

function PART:SetData(str)
	self.Data = str
	if str then
		local tbl = util.JSONToTable(str)
		if tbl then
			animations.RegisterAnimation(self:GetAnimID(), tbl)
		end
	end
end

function PART:OnShow(owner)
	--play animation
	local owner = self:GetOwner()

	if not animations.GetRegisteredAnimations()[self:GetAnimID()] then
		self:SetURL(self:GetURL())
	end

	if owner:IsValid() then
		if not self:GetStopOnHide() then
			if animations.GetRegisteredAnimations()[self:GetAnimID()] then
				animations.StopEntityAnimation(owner, self:GetAnimID())
			end
		end
		animations.SetEntityAnimation(owner, self:GetAnimID())
		self:SetOffset(self:GetOffset())
		self:SetRate(self:GetRate())
		self:SetBonePower(self:GetBonePower())
		self:SetInterpolation(self:GetInterpolation())
		if self.StopOtherAnimations and owner.pac_animations then
			for id in pairs(owner.pac_animations) do
				if id ~= self:GetAnimID() then
					animations.StopEntityAnimation(owner, id)
				end
			end
		end
	end
end

function PART:OnHide()
	--stop animation
	local owner = self:GetOwner()

	if owner:IsValid() and self:GetStopOnHide() then
		if animations.GetRegisteredAnimations()[self:GetAnimID()] then
			animations.StopEntityAnimation(owner, self:GetAnimID())
		end
		animations.ResetEntityBoneMatrix(owner)
	end
end

function PART:OnRemove()
	local owner = self:GetOwner()

	if owner:IsValid() then
		animations.StopEntityAnimation(owner, self:GetAnimID())
		animations.ResetEntityBoneMatrix(owner)
	end

	animations.GetRegisteredAnimations()[self:GetAnimID()] = nil
end

pac.RegisterPart(PART)
