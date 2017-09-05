local PART = {}

PART.ClassName = "holdtype"
PART.NonPhysical = true
PART.ThinkTime = 0
PART.Group = 'entity'
PART.Icon = 'icon16/user_edit.png'

local act_mods =
{
	"ACT_MP_STAND_IDLE",
	"ACT_MP_WALK",
	"ACT_MP_RUN",
	"ACT_MP_CROUCH_IDLE",
	"ACT_MP_CROUCHWALK",
	"ACT_MP_ATTACK_STAND_PRIMARYFIRE",
	"ACT_MP_ATTACK_CROUCH_PRIMARYFIRE",
	"ACT_MP_RELOAD_STAND",
	"ACT_MP_RELOAD_CROUCH",
	"ACT_MP_JUMP",
	"ACT_LAND",
	"ACT_RANGE_ATTACK1",
	"ACT_MP_SWIM_IDLE",
	"ACT_MP_SWIM",
}

do
	local temp = {}

	for _, act in pairs(act_mods) do

		local key = act
		key = "_" .. key
		key = key:gsub("ACT_MP_", "")
		key = key :lower()
		key = key:gsub("_(.)", function(char)
			return char:upper()
		end)

		temp[key] = _G[act]
	end

	-- ew
	if temp.Crouchwalk then
		temp.CrouchWalk = temp.Crouchwalk
		temp.Crouchwalk = nil
	end

	act_mods = temp
end

PART.ActMods = act_mods

pac.StartStorableVars()
	for name in pairs(act_mods) do
		pac.GetSet(PART, name, "")
	end

	pac.GetSet(PART, "Fallback", "")
	pac.GetSet(PART, "Noclip", "")
	pac.GetSet(PART, "Air", "")
	pac.GetSet(PART, "Sitting", "")
	pac.GetSet(PART, "AlternativeRate", false)
pac.EndStorableVars()

for name in pairs(act_mods) do
	PART["Set" .. name] = function(self, str)
		self[name] = str

		if not self:IsHidden() then
			self:UpdateActTable()
		end
	end
end

function PART:SetFallback(str)
	self.Fallback = str
	if not self:IsHidden() then
		self:UpdateActTable()
	end
end

function PART:UpdateActTable()
	local ent = self:GetOwner(true)

	if ent:IsValid() then

		ent.pac_holdtype_alternative_animation_rate = self.AlternativeRate

		ent.pac_holdtypes = ent.pac_holdtypes or {}
		ent.pac_holdtypes[self] = ent.pac_holdtypes[self] or {}

		local acts = ent.pac_holdtypes[self]

		for name, act in pairs(act_mods) do
			acts[act] = ent:GetSequenceActivity(ent:LookupSequence(self[name]))
		end

		-- custom acts
		acts.fallback = ent:GetSequenceActivity(ent:LookupSequence(self.Fallback))
		acts.noclip = ent:GetSequenceActivity(ent:LookupSequence(self.Noclip))
		acts.air = ent:GetSequenceActivity(ent:LookupSequence(self.Air))
		acts.sitting = ent:GetSequenceActivity(ent:LookupSequence(self.Sitting))

		acts.part = self
	end
end

function PART:GetSequenceList()
	local ent = self:GetOwner()

	if ent:IsValid() then
		return ent:GetSequenceList()
	end
	return {"none"}
end

function PART:OnHide()
	local ent = self:GetOwner(true)

	if ent:IsValid() then
		if ent.pac_holdtypes then
			ent.pac_holdtypes[self] = nil
		end

		ent.pac_holdtype_alternative_animation_rate = nil
	end
end

function PART:OnShow()
	self:UpdateActTable()
end


pac.RegisterPart(PART)