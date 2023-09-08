local FrameTime = FrameTime

local BUILDER, PART = pac.PartTemplate("base")

local AnimStack
AnimStack = {
	__index = {
		push = function(self, part)
			local stack = self.stack

			if #stack == 0 then
				-- Empty stack
				table.insert(stack, part)
			else
				-- Stop the current animation if it's not self
				local top = self:getTop()
				if top ~= part then
					if top then top:OnStackStop() end

					-- Remove self from stack to move to end and also prevent things from breaking because table.RemoveByValue() only removes the first instance
					table.RemoveByValue(stack, part)
					table.insert(stack, part)
				end
			end

			part:OnStackStart()
		end,
		pop = function(self, part)
			part:OnStackStop()
			local stack = self.stack

			-- Remove self from animation stack
			if table.RemoveByValue(stack, part) == #stack + 1 then
				-- This was the current animation so play the next in the stack
				local top = self:getTop()
				if top then top:OnStackStart() end
			end
		end,
		getTop = function(self)
			local stack = self.stack
			local top = stack[#stack]
			-- Remove invalid parts
			while top and not top:IsValid() do
				table.remove(stack)
				top = stack[#stack]
			end
			return top
		end
	},
	__call = function(meta)
		return setmetatable({
			stack = {}
		}, meta)
	end,
	get = function(ent)
		local animStack = ent.pac_animation_stack
		if not animStack then
			animStack = AnimStack()
			ent.pac_animation_stack = animStack
		end
		return animStack
	end
}
setmetatable(AnimStack, AnimStack)

PART.ClassName = "animation"
PART.ThinkTime = 0
PART.Groups = {'entity', 'model', 'modifiers'}
PART.Icon = 'icon16/eye.png'

PART.frame = 0

BUILDER
:StartStorableVars()
	:GetSet("Loop", true)
	:GetSet("PingPongLoop", false)
	:GetSet("SequenceName", "", {enums = function(part) local tbl = {} for k,v in pairs(part:GetSequenceList()) do tbl[v] = v end return tbl end})
	:GetSet("Rate", 1, {editor_sensitivity = 0.1})
	:GetSet("Offset", 0)
	:GetSet("Min", 0)
	:GetSet("Max", 1)
	:GetSet("WeaponHoldType", "none", {enums = function(part) return part.ValidHoldTypes end})
	:GetSet("OwnerCycle", false)
	:GetSet("InvertFrames", false)
	:GetSet("ResetOnHide", true)
:EndStorableVars()

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

function PART:GetSequenceList()
	local ent = self:GetOwner()

	if ent:IsValid() then
		return ent:GetSequenceList()
	end

	return {"none"}
end

PART.GetSequenceNameList = PART.GetSequenceList

function PART:OnStackStop()
	-- Move code from PART:OnHide() to here
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

-- Stop animation and remove from animation stack
function PART:OnHide()
	local ent = self:GetOwner()
	if not ent:IsValid() then return end
	AnimStack.get(ent):pop(self)
end

PART.random_seqname = ""

function PART:SetSequenceName(name)
	self.SequenceName = name
	self.random_seqname = table.Random(name:Split(";"))

	if not self:IsHidden() then
		self:OnShow()
	end
end

function PART:OnStackStart()
	-- Moved code from PART:OnShow() to here
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

-- Play animation and move to top of animation stack
function PART:OnShow()
	local ent = self:GetOwner()
	if not ent:IsValid() then return end
	AnimStack.get(ent):push(self)
end


function PART:OnThink()
	local ent = self:GetOwner()
	if not ent:IsPlayer() then
		self:OnUpdateAnimation(nil)
	end
end

function PART:OnUpdateAnimation(ply)
	if self:IsHiddenCached() then return end

	local ent = self:GetOwner()
	if not ent:IsValid() or not ent.pac_animation_stack or ent.pac_animation_stack.stack[#ent.pac_animation_stack.stack] ~= self then return end

	-- from UpdateAnimation hook
	if ply and ent ~= ply then return end

	if not self.random_seqname then return end

	local seq, duration = ent:LookupSequence(self.random_seqname)

	local count = ent:GetSequenceCount() or 0
	if seq < 0 or seq >= count then
		-- It's an invalid sequence. Don't bother
		return
	end

	if self.OwnerCycle then
		local owner = self:GetRootPart():GetOwner()

		if IsValid(owner) then
			ent:SetCycle(owner:GetCycle())
		end

		return
	end

	local min = self.Min
	local max = self.Max
	local maxmin = max - min

	if min == max then
		local cycle = min

		if pac.IsNumberValid(cycle) then
			ent:SetCycle(self.InvertFrames and (1 - cycle) or cycle)
		end
		return
	end

	local rate = (duration == 0) and 0 or (self.Rate / duration / math.abs(maxmin) * FrameTime())

	if self.PingPongLoop then
		if self.Loop then
			self.frame = (self.frame + rate) % 2
		else
			self.frame = math.max(math.min(self.frame + rate, 2), 0)
		end
		local cycle = min + math.abs(1 - (self.frame + 1 + self.Offset) % 2) * maxmin

		if pac.IsNumberValid(cycle) then
			ent:SetCycle(self.InvertFrames and (1 - cycle) or cycle)
		end
	else
		if self.Loop then
			self.frame = (self.frame + rate) % 2
		else
			self.frame = math.max(math.min(self.frame + rate, 1), 0)
		end
		local cycle = min + (self.frame + self.Offset) % 1 * maxmin

		if pac.IsNumberValid(cycle) then
			ent:SetCycle(self.InvertFrames and (1 - cycle) or cycle)
		end
	end
end

BUILDER:Register()
