local FrameTime = FrameTime


local PART = {}

PART.ClassName = "animation"
PART.NonPhysical = true
PART.ThinkTime = 0
PART.Groups = {'entity', 'model', 'modifiers'}
PART.Icon = 'icon16/eye.png'

PART.frame = 0

pac.StartStorableVars()
	pac.GetSet(PART, "Loop", true)
	pac.GetSet(PART, "PingPongLoop", false)
	pac.GetSet(PART, "SequenceName", "", {enums = function(part) local tbl = {} for k,v in pairs(part:GetSequenceList()) do tbl[v] = v end return tbl end})
	pac.GetSet(PART, "Rate", 1, {editor_sensitivity = 0.1})
	pac.GetSet(PART, "Offset", 0)
	pac.GetSet(PART, "Min", 0)
	pac.GetSet(PART, "Max", 1)
	pac.GetSet(PART, "WeaponHoldType", "none", {enums = function(part) return part.ValidHoldTypes end})
	pac.GetSet(PART, "OwnerCycle", false)
	pac.GetSet(PART, "InvertFrames", false)
	pac.GetSet(PART, "ResetOnHide", true)
pac.EndStorableVars()

local tonumber = tonumber

PART.ValidHoldTypes =
{
	pistol = ACT_HL2MP_IDLE_PISTOL,
	smg = ACT_HL2MP_IDLE_SMG1,
	grenade = ACT_HL2MP_IDLE_GRENADE,
	ar2 = ACT_HL2MP_IDLE_AR2,
	shotgun = ACT_HL2MP_IDLE_SHOTGUN,
	rpg = ACT_HL2MP_IDLE_RPG,
	physgun = ACT_HL2MP_IDLE_PHYSGUN,
	crossbow = ACT_HL2MP_IDLE_CROSSBOW,
	melee = ACT_HL2MP_IDLE_MELEE,
	slam = ACT_HL2MP_IDLE_SLAM,
	normal = ACT_HL2MP_IDLE,
	fist = ACT_HL2MP_IDLE_FIST,
	melee2 = ACT_HL2MP_IDLE_MELEE2,
	passive = ACT_HL2MP_IDLE_PASSIVE,
	knife = ACT_HL2MP_IDLE_KNIFE,
	duel = ACT_HL2MP_IDLE_DUEL,
	camera = ACT_HL2MP_IDLE_CAMERA,
	revolver = ACT_HL2MP_IDLE_REVOLVER,

	zombie = ACT_HL2MP_IDLE_ZOMBIE,
	magic = ACT_HL2MP_IDLE_MAGIC,
	meleeangry = ACT_HL2MP_IDLE_MELEE_ANGRY,
	angry = ACT_HL2MP_IDLE_ANGRY,
	suitcase = ACT_HL2MP_IDLE_SUITCASE,
	scared = ACT_HL2MP_IDLE_SCARED,
}

function PART:GetNiceName()
	local str = self:GetSequenceName()

	if str == "" and self:GetWeaponHoldType() ~= "none" then
		str = self:GetWeaponHoldType()
	end

	return pac.PrettifyName(str)
end

function PART:GetOwner()
	local parent = self:GetParent()

	if parent:IsValid() and parent.is_model_part and parent.Entity:IsValid() then
		return parent.Entity
	end

	return self.BaseClass.GetOwner(self)
end

function PART:GetSequenceList()
	local ent = self:GetOwner()

	if ent:IsValid() then
		return ent:GetSequenceList()
	end

	return {"none"}
end

PART.GetSequenceNameList = PART.GetSequenceList

function PART:OnHide()
	local ent = self:GetOwner()

	if ent:IsValid() then
		if not self:GetResetOnHide() then
			self.SequenceCycle = ent:GetCycle()
			self.storeFrame = self.frame
		else
			self.SequenceCycle = nil
			self.frame = 0
		end

		if ent.pac_animation_sequences then
			ent.pac_animation_sequences[self] = nil
		end

		if ent.pac_animation_holdtypes then
			ent.pac_animation_holdtypes[self] = nil
		end

		if not ent:IsPlayer() and self.prevSequence then
			ent:ResetSequence(self.prevSequence)
			self.prevSequence = nil
		end
	end
end

PART.random_seqname = ""

function PART:SetSequenceName(name)
	self.SequenceName = name
	self.random_seqname = table.Random(name:Split(";"))

	if not self:IsHidden() then
		self:OnShow()
	end
end

function PART:OnShow()
	self.PlayingSequenceFrom = RealTime()
	local ent = self:GetOwner()

	if ent:IsValid() then
		self.prevSequence = ent:GetSequence()
		self.random_seqname = table.Random(self.SequenceName:Split(";"))

		if self.random_seqname ~= "" then
			local seq = ent:LookupSequence(self.random_seqname) or 0
			local count = ent:GetSequenceCount() or 0

			if seq < 0 or seq > count or count < 0 then
				return
			end

			ent.pac_animation_sequences = ent.pac_animation_sequences or {}
			ent.pac_animation_sequences[self] = ent.pac_animation_sequences[self] or {}

			local tbl = ent.pac_animation_sequences[self]

			tbl.part = self

			if seq ~= -1 then
				tbl.seq = seq
			else
				seq = tonumber(self.random_seqname) or -1

				if seq ~= -1 then
					tbl.seq = seq
				else
					ent.pac_animation_sequences[self] = nil
				end
			end

			if seq ~= -1  then
				ent:ResetSequence(seq)
				ent:SetSequence(seq)
				if not self:GetResetOnHide() then
					ent:ResetSequenceInfo()

					for i = 1, 10 do
						ent:FrameAdvance(1)
					end

					ent:ResetSequenceInfo()
				end
			end

		elseif ent:IsPlayer() then
			local t = self.WeaponHoldType
			t = t:lower()

			local index = self.ValidHoldTypes[t]

			ent.pac_animation_holdtypes = ent.pac_animation_holdtypes or {}

			if index == nil then
				ent.pac_animation_holdtypes[self] = nil
			else
				local params = {}
					params[ACT_MP_STAND_IDLE] = index + 0
					params[ACT_MP_WALK] = index + 1
					params[ACT_MP_RUN] = index + 2
					params[ACT_MP_CROUCH_IDLE] = index + 3
					params[ACT_MP_CROUCHWALK] = index + 4
					params[ACT_MP_ATTACK_STAND_PRIMARYFIRE] = index + 5
					params[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE] = index + 5
					params[ACT_MP_RELOAD_STAND] = index + 6
					params[ACT_MP_RELOAD_CROUCH] = index + 7
					params[ACT_MP_JUMP] = index + 8
					params[ACT_RANGE_ATTACK1] = index + 9
					params[ACT_MP_SWIM_IDLE] = index + 10
					params[ACT_MP_SWIM] = index + 11

				-- "normal" jump animation doesn't exist
				if t == "normal" then
					params[ACT_MP_JUMP] = ACT_HL2MP_JUMP_SLAM
				end

				-- these two aren't defined in ACTs for whatever reason
				if t == "knife" or t == "melee2" then
					params[ACT_MP_CROUCH_IDLE] = nil
				end

				params.part = self

				ent.pac_animation_holdtypes[self] = params
			end
		end

		if not self:GetResetOnHide() and self.SequenceCycle then
			ent:SetCycle(self.SequenceCycle)
			self.SequenceCycle = nil

			if self.storeFrame then
				self.frame = self.storeFrame
				self.storeFrame = nil
			end
		end
	end
end

function PART:OnThink()
	local ent = self:GetOwner()

	if ent:IsValid() then
		if not self.random_seqname then return end

		local seq = ent:LookupSequence(self.random_seqname) or 0

		local duration = 0
		local count = ent:GetSequenceCount() or 0
		if seq >= 0 and seq < count and count > 0 then
			duration = ent:SequenceDuration(seq)
		else
			-- It's an invalid sequence. Don't bother
			return
		end

		if self.OwnerCycle then
			local owner = self.BaseClass.GetOwner(self, true)

			if IsValid(owner) then
				ent:SetCycle(owner:GetCycle())
			end

			return
		end

		local rate = math.min(self.Rate * duration, 1)

		if seq ~= -1 then

			if rate == 0 then
				ent:SetCycle(self.Offset % 1)
				return
			end
		else
			seq = tonumber(self.random_seqname) or -1

			if seq ~= -1 then
				if rate == 0 then
					ent:SetCycle(self.Offset % 1)
					return
				end
			else
				return
			end
		end

		rate = rate / math.abs(self.Min - self.Max)
		rate = rate * FrameTime()

		local min = self.Min
		local max = self.Max

		if self.PingPongLoop then
			self.frame = self.frame + rate / 2
			local cycle = min + math.abs(math.Round((self.frame + self.Offset) * 0.5) - (self.frame + self.Offset) * 0.5) * 2 * (max - min)

			if pac.IsNumberValid(cycle) then
				ent:SetCycle(not self.InvertFrames and cycle or (1 - cycle))
			end
		else
			self.frame = self.frame + rate
			local cycle = min + ((self.frame + self.Offset) * 0.5) % 1 * (max - min)

			if pac.IsNumberValid(cycle) then
				ent:SetCycle(not self.InvertFrames and cycle or (1 - cycle))
			end
		end
	end
end

pac.RegisterPart(PART)