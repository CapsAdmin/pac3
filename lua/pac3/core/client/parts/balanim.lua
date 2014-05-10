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
	local function LoadBalAnim(str) --this function is called by http.Fetch below. str should contain the tInfo for the animation
		local regstring="RegisterLuaAnimation("..addquotes(tostring(self:GetUniqueID()))..","..str..")"
		local registeranim = CompileString(regstring,"registeranim") --if you can make this work better be my guest
		registeranim()
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
	local setstring="Entity("..owner:EntIndex().."):SetLuaAnimation("..addquotes(tostring(self:GetUniqueID()))..")"
	local setanim = CompileString(setstring,"setanim")
	setanim()
end

function PART:OnHide()
	--stop animation
	local owner = self:GetOwner()
	local stopstring="Entity("..owner:EntIndex().."):StopLuaAnimation("..addquotes(tostring(self:GetUniqueID()))..")"
	local stopanim = CompileString(stopstring,"stopanim")
	stopanim()
end

function PART:OnRemove() 
	local owner = self:GetOwner()
	local setstring="Entity("..owner:EntIndex().."):SetLuaAnimation("..addquotes("BlankAnim")..")"
	local setanim = CompileString(setstring,"setanim")
	setanim() --play BlankAnim so they don't get stuck
	UnRegisterLuaAnimation(tostring(self:GetUniqueID())) --unregister the anim
end

pac.RegisterPart(PART)