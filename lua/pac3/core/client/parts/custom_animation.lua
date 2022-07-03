local animations = pac.animations

local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "custom_animation"

PART.Group = 'advanced'
PART.Icon = 'icon16/film.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("URL", "")
	BUILDER:GetSet("Data", "")
	BUILDER:GetSet("StopOnHide", true)
	BUILDER:GetSet("StopOtherAnimations", false)
	BUILDER:GetSet("AnimationType", "sequence", {enums = {
		gesture = "gesture",
		posture = "posture",
		sequence = "sequence",
		stance = "stance",
	}})
	BUILDER:GetSet("Interpolation", "cosine", {enums = {
		linear = "linear",
		cosine = "cosine",
		cubic = "cubic",
		none = "none",
	}})
	BUILDER:GetSet("Rate", 1)
	BUILDER:GetSet("BonePower", 1)
	BUILDER:GetSet("Offset", 0)
BUILDER:EndStorableVars()

function PART:GetNiceName()
	return pac.PrettifyName(("/".. self:GetURL()):match(".+/(.-)%.")) or "no anim"
end

function PART:GetAnimID()
	return "pac_anim_" .. (self:GetPlayerOwnerId() or "null") .. "_" .. self:GetUniqueID()
end

function PART:GetLuaAnimation()
	local owner = self:GetOwner()
	if owner:IsValid() and owner.pac_animations then
		return owner.pac_animations[self:GetAnimID()]
	end
end

function PART:SetRate(num)
	self.Rate = num
	local anim = self:GetLuaAnimation()
	if anim then
		anim.TimeScale = self.Rate
	end
end

function PART:SetBonePower(num)
	self.BonePower = num
	local anim = self:GetLuaAnimation()
	if anim then
		anim.Power = self.BonePower
	end
end

function PART:SetInterpolation(mode)
	self.Interpolation = mode
	local anim = self:GetLuaAnimation()
	if anim then
		anim.Interpolation = mode
	end
end

function PART:SetOffset(num)
	self.Offset = num
	local anim = self:GetLuaAnimation()
	if anim then
		anim.Offset = num
	end
end

function PART:SetURL(url)
	self.URL = url
	self:SetError()

	if url:find("http") then
		pac.HTTPGet(url, function(str)
			local tbl = util.JSONToTable(str)
			if not tbl then
				pac.Message("Animation failed to parse from ", url)
				self:SetError("Animation failed to parse from " .. url)
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
			if self:IsValid() and pac.LocalPlayer == self:GetPlayerOwner() and pace and pace.IsActive() then
				if pace and pace.current_part == self and not IsValid(pace.BusyWithProperties) then
					pace.MessagePrompt(err, "HTTP Request Failed for " .. url, "OK")
				else
					local msg = "HTTP Request failed for " .. url .. " - " .. err
					self:SetError(msg)
					pac.Message(Color(0, 255, 0), "[animation] ", Color(255, 255, 255), msg)
				end
			end
		end)
	end
end

function PART:SetData(str)
	self.Data = str
	if str then
		local tbl = util.JSONToTable(str)
		if tbl then

			if isnumber(tbl.Type) then
				animations.ConvertOldData(tbl)
				self:SetAnimationType(tbl.Type)
				self:SetInterpolation(tbl.Interpolation)
			end

			animations.RegisterAnimation(self:GetAnimID(), tbl)
		end
	end
end

function PART:OnShow(from_rendering)
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

BUILDER:Register()
