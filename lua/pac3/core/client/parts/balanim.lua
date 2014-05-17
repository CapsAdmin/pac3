local PART = {}

PART.ClassName = "balanim"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
pac.EndStorableVars()

RegisterLuaAnimation('BlankAnim', {
	FrameData = {
		{
			BoneInfo = {
			},
			FrameRate = 1
		}
	},
	Type = TYPE_GESTURE
})

function UnRegisterLuaAnimation(sName)
	local Animations = GetLuaAnimations()
	Animations[sName] = nil
end

function PART:GetNiceName()
	return pac.PrettifyName(("/".. self:GetURL()):match(".+/(.-)%.")) or "no anim"
end

function PART:Initialize()
--	currentpath = ""
end

function PART:OnThink() 
-- nothing to do here
end

function PART:SetURL(url)
	self.URL = url
	local function LoadBalAnim(str)
	    local thistable = util.JSONToTable(str)
		RegisterLuaAnimation("pac_"..tostring(self:GetUniqueID()),thistable)
	end
	if url and url:find("http") then
		http.Fetch(self:GetURL(), LoadBalAnim)
	end
end

function PART:OnShow(owner, pos, ang)
	--play animation
	local owner = self:GetOwner()
	local Animations = GetLuaAnimations()
	if not Animations["pac_"..tostring(self:GetUniqueID())] then
		self:SetURL(self:GetURL()) --I don't like this but it isn't /bad/ per se
	end
	if owner and owner:IsValid() and Animations["pac_"..tostring(self:GetUniqueID())] then
		owner:SetLuaAnimation("pac_"..tostring(self:GetUniqueID()))
	end
end

function PART:OnHide()
	--stop animation
	local owner = self:GetOwner()
	local Animations = GetLuaAnimations()
	if owner and owner:IsValid() and Animations["pac_"..tostring(self:GetUniqueID())] then
		owner:StopLuaAnimation("pac_"..tostring(self:GetUniqueID()))
	end
	if owner and owner:IsValid() then
		owner:ResetBoneMatrix()
	end
end

function PART:OnRemove() 
	local owner = self:GetOwner()
	local Animations = GetLuaAnimations()
	if owner and owner:IsValid() then
		owner:ResetBoneMatrix()
	end
	if Animations["pac_"..tostring(self:GetUniqueID())] then
		UnRegisterLuaAnimation("pac_"..tostring(self:GetUniqueID())) --unregister the anim
	end
end

pac.RegisterPart(PART)
