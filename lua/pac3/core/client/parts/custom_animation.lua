local PART = {}

PART.ClassName = "custom_animation"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
	pac.GetSet(PART, "StopOnHide", true)
pac.EndStorableVars()

function PART:GetNiceName()
	return pac.PrettifyName(("/".. self:GetURL()):match(".+/(.-)%.")) or "no anim"
end

function PART:GetAnimID()
	return "pac_anim_" .. self:GetUniqueID()
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
				RegisterLuaAnimation(self:GetAnimID(), tbl)
			end, function(code) Msg"[PAC] Animation failed to load from "print(url,code) end) --should do nothing on invalid/inaccessible URL
		end
end

function PART:OnShow(owner)
	--play animation
	local owner = self:GetOwner()

	if not GetLuaAnimations()[self:GetAnimID()] then
		self:SetURL(self:GetURL())
	end

	if owner:IsValid() then
		if not self:GetStopOnHide() then
			if GetLuaAnimations()[self:GetAnimID()] then
				owner:StopLuaAnimation(self:GetAnimID())
			end
		end
		owner:SetLuaAnimation(self:GetAnimID())
	end
end

function PART:OnHide()
	--stop animation
	local owner = self:GetOwner()

	if owner:IsValid() and self:GetStopOnHide() then
		if GetLuaAnimations()[self:GetAnimID()] then
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

	GetLuaAnimations()[self:GetAnimID()] = nil
end

pac.RegisterPart(PART)
