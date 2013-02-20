local PART = {}

PART.ClassName = "animation"
PART.NonPhysical = true
PART.ThinkTime = 0

PART.frame = 0

pac.StartStorableVars()		
	pac.GetSet(PART, "Loop", true)
	pac.GetSet(PART, "PingPongLoop", false)
	pac.GetSet(PART, "SequenceName", "")
	pac.GetSet(PART, "Rate", 1)
	pac.GetSet(PART, "Offset", 0)
	pac.GetSet(PART, "Min", 0)
	pac.GetSet(PART, "Max", 1)
	pac.GetSet(PART, "WeaponHoldType", "none")
pac.EndStorableVars()
 
function PART:GetOwner()
	local parent = self:GetParent()
	
	if parent:IsValid() then		
		if parent.ClassName == "model" and parent.Entity:IsValid() then
			return parent.Entity
		end
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

function PART:OnHide()
	local ent = self:GetOwner()
		
	if ent:IsValid() then
		ent.pac_sequence = nil
		ent.pac_holdtype = nil
		ent.pac_pose_param = nil
	end
	
	self.last_holdtype = nil
end

function PART:OnShow()
	self.last_holdtype = nil
end

PART.OnRemove = PART.OnHide

local tonumber = tonumber

local ActIndex = 
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

PART.ValidHoldTypes = ActIndex

local function math_isvalid(num) 
	return
		num and
		num ~= inf and
		num ~= ninf and
		(num >= 0 or num <= 0)
end

function PART:OnThink()
	if self:IsHidden() then return end
	
	local ent = self:GetOwner()

	if ent:IsValid() then
		if ent:IsPlayer() then
			local t = self.WeaponHoldType
			t = t:lower()
			
			if t ~= self.last_holdtype then			
				local index = ActIndex[t]
				
				if index == nil then
					ent.pac_holdtype = nil
				else
					local params = {}
						params[ACT_MP_STAND_IDLE] = index
						params[ACT_MP_WALK] = index+1
						params[ACT_MP_RUN] = index+2
						params[ACT_MP_CROUCH_IDLE] = index+3
						params[ACT_MP_CROUCHWALK] = index+4
						params[ACT_MP_ATTACK_STAND_PRIMARYFIRE]	= index+5
						params[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE] = index+5
						params[ACT_MP_RELOAD_STAND ] = index+6
						params[ACT_MP_RELOAD_CROUCH ] = index+6
						params[ACT_MP_JUMP] = index+7
						params[ACT_RANGE_ATTACK1] = index+8
						params[ACT_MP_SWIM_IDLE] = index+8
						params[ACT_MP_SWIM] = index+9
					
					-- "normal" jump animation doesn't exist
					if t == "normal" then
						params[ACT_MP_JUMP] = ACT_HL2MP_JUMP_SLAM
					end
					
					-- these two aren't defined in ACTs for whatever reason
					if t == "knife" or t == "melee2" then
						params[ACT_MP_CROUCH_IDLE] = nil
					end
					
					ent.pac_holdtype = params
					
					self.last_holdtype = t
				end
			end
		end
	
		local seq = ent:LookupSequence(self.SequenceName)
		local rate = math.min((self.Rate * (ent:SequenceDuration(seq) or 0)), 1)
				
		if seq ~= -1 then
			ent:SetSequence(seq)
			ent.pac_sequence = seq
			
			if rate == 0 then
				ent:SetCycle(self.Offset)
				return
			end
		else
			seq = tonumber(self.SequenceName) or -1
			
			if seq ~= -1 then
				ent:SetSequence(seq)
				ent.pac_sequence = seq
				if rate == 0 then
					ent:SetCycle(self.Offset)
					return
				end			
			else
				ent.pac_sequence = nil
				return
			end
		end
		
		rate = rate / math.abs(self.Min - self.Max)
		rate = rate * FrameTime()
		
		local min = self.Min
		local max = self.Max
		
		if self.PingPongLoop then
			self.frame = self.frame + rate / 2
			local cycle = min + math.abs(math.Round((self.frame + self.Offset)*0.5) - (self.frame + self.Offset)*0.5)*2 * (max - min)
			if not math_isvalid(cycle) then print(self.frame, self.Offset, min, max) return end
			ent:SetCycle(cycle)
		else
			self.frame = self.frame + rate
			local cycle = min + ((self.frame + self.Offset)*0.5)%1 * (max - min)
			if not math_isvalid(cycle) then print(self.frame, self.Offset, min, max) return end
			ent:SetCycle(cycle)
		end
	end
end

hook.Add("TranslateActivity", "pac_holdtype", function(ply, act)
	if IsEntity(ply) and ply:IsValid() and ply.pac_holdtype and ply.pac_holdtype[act] then
		return ply.pac_holdtype[act]
	end
end)

hook.Add("CalcMainActivity", "pac_player_animations", function(ply, act) 
	if IsEntity(ply) and ply:IsValid() and ply.pac_sequence then
		return ply.pac_sequence, ply.pac_sequence
	end
end)
	
pac.RegisterPart(PART)