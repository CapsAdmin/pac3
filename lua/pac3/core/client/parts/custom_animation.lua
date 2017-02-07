local PART = {}

PART.ClassName = "custom_animation"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
	pac.GetSet(PART, "Data", "")
	pac.GetSet(PART, "StopOnHide", true)
	pac.GetSet(PART, "StopOtherAnimations", false)
	pac.GetSet(PART, "AnimationType", "sequence")
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
	if owner:IsValid() and owner.LuaAnimations then
		local anim = owner.LuaAnimations[self:GetAnimID()]
		if anim then
			anim.TimeScale = self.Rate
		end
	end
end

function PART:SetBonePower(num)
	self.BonePower = num
	local owner = self:GetOwner()
	if owner:IsValid() and owner.LuaAnimations then
		local anim = owner.LuaAnimations[self:GetAnimID()]
		if anim then
			anim.Power = self.BonePower
		end
	end
end

function PART:SetOffset(num)
	self.Offset = num
	local owner = self:GetOwner()
	if owner:IsValid() and owner.LuaAnimations then
		local anim = owner.LuaAnimations[self:GetAnimID()]
		if anim then
			anim.Offset = num
		end
	end
end

function PART:SetURL(url)
	self.URL = url

	if url:find("http") then
		url = pac.FixupURL(url)

		http.Fetch(url, function(str,len,hdr,code)
			if not str or code~=200 then
				Msg"[PAC] Animation failed to load from "print(url,code)
				return
			end
			local tbl = util.JSONToTable(str)
			if not tbl then
				Msg"[PAC] Animation failed to parse from "print(url)
				return
			end

			if tbl.Type then
				if tbl.Type == boneanimlib.TYPE_GESTURE then
					self:SetAnimationType("gesture")
				elseif tbl.Type == boneanimlib.TYPE_POSTURE then
					self:SetAnimationType("posture")
				elseif tbl.Type == boneanimlib.TYPE_STANCE then
					self:SetAnimationType("stance")
				elseif tbl.Type == boneanimlib.TYPE_SEQUENCE then
					self:SetAnimationType("sequence")
				end
			end

			boneanimlib.RegisterLuaAnimation(self:GetAnimID(), tbl)

			if pace and pace.timeline.IsActive() and pace.timeline.animation_part == self then
				pace.timeline.Load(tbl)
			end
		end, function(code)
			Msg"[PAC] Animation failed to load from "print(url,code)
		end) --should do nothing on invalid/inaccessible URL
	end
end

function PART:SetData(str)
	self.Data = str
	if str then
		local tbl = util.JSONToTable(str)
		if tbl then
			boneanimlib.RegisterLuaAnimation(self:GetAnimID(), tbl)
		end
	end
end

function PART:OnShow(owner)
	--play animation
	local owner = self:GetOwner()

	if not boneanimlib.GetLuaAnimations()[self:GetAnimID()] then
		self:SetURL(self:GetURL())
	end

	if owner:IsValid() then
		if not self:GetStopOnHide() then
			if boneanimlib.GetLuaAnimations()[self:GetAnimID()] then
				owner:StopLuaAnimation(self:GetAnimID())
			end
		end
		owner:SetLuaAnimation(self:GetAnimID())
		self:SetOffset(self:GetOffset())
		self:SetRate(self:GetRate())
		self:SetBonePower(self:GetBonePower())
		if self.StopOtherAnimations then
			for id in pairs(owner.LuaAnimations) do
				if id ~= self:GetAnimID() then
					owner:StopLuaAnimation(id)
				end
			end
		end
	end
end

function PART:OnHide()
	--stop animation
	local owner = self:GetOwner()

	if owner:IsValid() and self:GetStopOnHide() then
		if boneanimlib.GetLuaAnimations()[self:GetAnimID()] then
			owner:StopLuaAnimation(self:GetAnimID())
		end
		owner:ResetBoneMatrix()
	end
end

function PART:OnRemove()
	local owner = self:GetOwner()

	if owner:IsValid() then
		owner:StopLuaAnimation(self:GetAnimID())
		owner:ResetBoneMatrix()
	end

	boneanimlib.GetLuaAnimations()[self:GetAnimID()] = nil
end

pac.RegisterPart(PART)
