local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "holdtype"

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

local udata = {
	enums = function(part)
		if not part.GetSequenceList then return {} end -- ???

		local tbl = {}

		for k, v in pairs(part:GetSequenceList()) do
			tbl[v] = v
		end

		return tbl
	end
}

BUILDER:StartStorableVars()
	for name in pairs(act_mods) do
		BUILDER:GetSet(name, "", udata)
	end

	BUILDER:GetSet("Fallback", "", udata)
	BUILDER:GetSet("Noclip", "", udata)
	BUILDER:GetSet("Air", "", udata)
	BUILDER:GetSet("Sitting", "", udata)
	BUILDER:GetSet("AlternativeRate", false)
	BUILDER:GetSet("Override", false)
BUILDER:EndStorableVars()

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
	local ent = self:GetRootPart():GetOwner()
	if not ent:IsValid() then return end

	ent.pac_holdtype_alternative_animation_rate = self.AlternativeRate

	ent.pac_holdtypes = ent.pac_holdtypes or {}

	if self.Override then
		table.Empty(ent.pac_holdtypes)
	end

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

function PART:OnThink()
	local ent = self:GetRootPart():GetOwner()
	if not ent:IsValid() then return end

	if (ent:GetModel() ~= self.last_model or ent.pac_holdtypes ~= self.last_pac_holdtypes)  then
		self:UpdateActTable()
		self.last_model = ent:GetModel()
		self.last_pac_holdtypes = ent.pac_holdtypes
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
	local ent = self:GetRootPart():GetOwner()

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


BUILDER:Register()