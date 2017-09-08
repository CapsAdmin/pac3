local PART = {}

PART.ClassName = "gesture"
PART.NonPhysical = true
PART.ThinkTime = 0
PART.Group = 'entity'
PART.Icon = 'icon16/thumb_up.png'

pac.StartStorableVars()
	pac.GetSet(PART, "Loop", false)
	pac.GetSet(PART, "GestureName", "", {editor_panel = "sequence"})
	pac.GetSet(PART, "SlotName", "attackreload", {enums = function(part) return part.ValidGestureSlots end})
	pac.GetSet(PART, "SlotWeight", 1)
pac.EndStorableVars()

PART.random_gestlist = {}

PART.ValidGestureSlots = {
	attackreload = GESTURE_SLOT_ATTACK_AND_RELOAD,
	grenade = GESTURE_SLOT_GRENADE,
	jump = GESTURE_SLOT_JUMP,
	swim = GESTURE_SLOT_SWIM,
	flinch = GESTURE_SLOT_FLINCH,
	vcd = GESTURE_SLOT_VCD,
	custom = GESTURE_SLOT_CUSTOM
}

function PART:GetOwner()
	return self.BaseClass.GetOwner(self)	-- until gesture functions for non-players
end

function PART:GetSequenceList()
	local ent = self:GetOwner()

	if ent:IsValid() then
		return ent:GetSequenceList()
	end
	return {"none"}
end

function PART:GetSlotID()
	return self.ValidGestureSlots[self.SlotName] or GESTURE_SLOT_CUSTOM
end

function PART:SetLoop(bool)
	self.Loop = bool

	if not self:IsHidden() then
		self:OnShow()
	end
end

function PART:SetGestureName(name)
	self.GestureName = name

	local list = name:Split(";")
	for k,v in next,list do
		if v:Trim() == "" then list[k] = nil end
	end

	self.random_gestlist = list

	if not self:IsHidden() then
		self:OnShow()
	end
end

function PART:SetSlotName(name)
	local ent = self:GetOwner()

	if ent:IsValid() and ent:IsPlayer() then		-- to stop gestures getting stuck
		for _, v in next,self.ValidGestureSlots do
			ent:AnimResetGestureSlot(v)
		end
	end

	self.SlotName = name

	if not self:IsHidden() then
		self:OnShow()
	end
end

function PART:SetSlotWeight(num)
	local ent = self:GetOwner()

	if ent:IsValid() and ent:IsPlayer() then
		ent:AnimSetGestureWeight(self:GetSlotID(), num)
	end

	self.SlotWeight = num
end

function PART:OnShow()
	local ent = self:GetOwner()

	if ent:IsValid() and ent:IsPlayer() then		-- function is for players only :(
		local gesture = self.random_gestlist and table.Random(self.random_gestlist) or self.GestureName
		local slot = self:GetSlotID()

		ent:AnimResetGestureSlot(slot)
		local act = ent:GetSequenceActivity(ent:LookupSequence(gesture))
		if act ~= 1 then
			ent:AnimRestartGesture(slot, act, not self.Loop)
		end
		ent:AnimSetGestureWeight(slot, self.SlotWeight or 1)
	end
end

function PART:OnHide()
	local ent = self:GetOwner()

	if ent:IsValid() and ent:IsPlayer() and self.Loop then
		ent:AnimResetGestureSlot(self:GetSlotID())
	end
end

PART.OnRemove = PART.OnHide

pac.RegisterPart(PART)