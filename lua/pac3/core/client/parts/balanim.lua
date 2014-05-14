local PART = {}

PART.ClassName = "balanim"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "Animation", "")
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
	return pac.PrettifyName(("/".. self:GetAnimation()):match(".+/(.-)%.")) or "no anim"
end

function PART:Initialize()
	currentpath = ""
end

function PART:OnThink() 
	local function LoadBalAnim(str)
	    local thistable = util.JSONToTable(str)
		RegisterLuaAnimation("pac_"..tostring(self:GetUniqueID()),thistable)
	end
	if currentpath ~= self:GetAnimation() then --reregister animation when input path/url changes
		var = self:GetAnimation()
		if var and var:find("http") then
			http.Fetch(self:GetAnimation(), LoadBalAnim)
			currentpath = self:GetAnimation()
		else
		--[[if file.Exists(var,"GAME") then --data/animations/something.txt
				local animfile = file.Read(var)
				LoadBalAnim(animfile)
			else if file.Exists(var,"DATA") then --animations/something.txt
				local animfile = file.Read("data/"..var)
				LoadBalAnim(animfile)
			else if file.Exists("animations/"..var,"DATA") then --something.txt
				local animfile = file.Read("data/animations/"..var)
				LoadBalAnim(animfile)
			else if file.Exists("animations/"..var..".txt","DATA") then --something
				local animfile = file.Read("data/animations/"..var..".txt")
				LoadBalAnim(animfile)
			end]]
		end
	end
end

function PART:OnShow(owner, pos, ang)
	--play animation
	local owner = self:GetOwner()
	if owner and owner:IsValid() then
	  owner:SetLuaAnimation("pac_"..tostring(self:GetUniqueID()))
	end
end

function PART:OnHide()
	--stop animation
	local owner = self:GetOwner()
	if owner and owner:IsValid() then
	  owner:StopLuaAnimation("pac_"..tostring(self:GetUniqueID()))
	end
end

function PART:OnRemove() 
	local owner = self:GetOwner()
	if owner and owner:IsValid() then
	  owner:SetLuaAnimation("BlankAnim") --play BlankAnim so they don't get stuck
	end
	UnRegisterLuaAnimation("pac_"..tostring(self:GetUniqueID())) --unregister the anim
end

pac.RegisterPart(PART)
