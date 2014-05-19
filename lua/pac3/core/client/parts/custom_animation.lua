local PART = {}

PART.ClassName = "custom_animation"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
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
			http.Fetch(url, function(str)
				RegisterLuaAnimation(self:GetAnimID(), util.JSONToTable(str))
			end, function() return end) --should do nothing on invalid/inaccessible URL
		end
end

function PART:OnShow(owner)
	--play animation
	local owner = self:GetOwner()
	
	if not GetLuaAnimations()[self:GetAnimID()] then
		self:SetURL(self:GetURL())
	elseif owner:IsValid() then
		owner:SetLuaAnimation(self:GetAnimID())
	end
end

function PART:OnHide()
	--stop animation
	local owner = self:GetOwner()
	
	if owner:IsValid() and GetLuaAnimations()[self:GetAnimID()] then
		owner:StopLuaAnimation(self:GetAnimID())
		owner:ResetBoneMatrix()
	elseif owner:IsValid() then --if, somehow, the owner is valid but the animation is not, their bones should still be reset
		owner:ResetBoneMatrix()
	end
end

function PART:OnRemove() 
	local owner = self:GetOwner()

	if owner:IsValid() then
		owner:ResetBoneMatrix()
	end
	
	GetLuaAnimations()[self:GetAnimID()] = nil
end

pac.RegisterPart(PART)
