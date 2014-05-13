local PART = {}
--testing webhook
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

function addquotes(str) return "\""..str.."\"" end

function UnRegisterLuaAnimation(sName)
	local Animations = GetLuaAnimations()
	Animations[sName] = nil
end

function PART:GetNiceName()
	return pac.PrettifyName(("/".. self:GetURL()):match(".+/(.-)%.")) or "no anim"
end

function PART:Initialize()
	currenturl = ""
end

function PART:OnThink() 
	--[[local function LoadBalAnim(str)
		local regstring="RegisterLuaAnimation("..addquotes(tostring(self:GetUniqueID()))..","..str..")"
		local registeranim = CompileString(regstring,"registeranim")
		animregenv = {RegisterLuaAnimation = RegisterLuaAnimation,} --create an environment where it's only possible to register animations
		setfenv(registeranim, animregenv) --force registeranim() to run in the limited environment
		pcall(registeranim) --run registeranim in the environment
	end]]
	local function LoadBalAnim(str) --this is so much better
	    t = pcall(util.JSONToTable, str)
		RegisterLuaAnimation(addquotes(tostring(self:GetUniqueID())),t)
	end
	--reregister animation when URL changes
	if currenturl ~= self:GetURL() then
		http.Fetch(self:GetURL(), LoadBalAnim)
		currenturl = self:GetURL()
	end

end

function PART:OnShow(owner, pos, ang)
	--play animation
	local owner = self:GetOwner()
	if owner and owner:IsValid() then
	  owner:SetLuaAnimation(tostring(self:GetUniqueID()))
	end
end

function PART:OnHide()
	--stop animation
	local owner = self:GetOwner()
	if owner and owner:IsValid() then
	  owner:StopLuaAnimation(tostring(self:GetUniqueID()))
	end
end

function PART:OnRemove() 
	local owner = self:GetOwner()
	if owner and owner:IsValid() then
	  owner:SetLuaAnimation("BlankAnim") --play BlankAnim so they don't get stuck
	end
	UnRegisterLuaAnimation(tostring(self:GetUniqueID())) --unregister the anim
end

pac.RegisterPart(PART)