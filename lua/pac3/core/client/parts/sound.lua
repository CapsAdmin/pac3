local PART = {}

PART.ClassName = "sound"

pac.StartStorableVars()
	pac.GetSet(PART, "Sound", "")
	pac.GetSet(PART, "Volume", 100)
	pac.GetSet(PART, "MinPitch", 100)
	pac.GetSet(PART, "MaxPitch", 100)
pac.EndStorableVars()

function PART:Initialize()
	self:PlaySound()
end

function PART:OnRemove()
	self:StopSound()
end

function PART:OnShow()
	self:PlaySound()
end

function PART:OnHide()
	self:StopSound()
end

function PART:PlaySound()
	local ent = self:GetOwner()

	if ent:IsValid() then
		local snd = self.Sound:gsub(
			"(%[%d-,%d-%])", 
			function(minmax) 
				local min, max = minmax:match("%[(%d-),(%d-)%]")
				if max < min then
					max = min
				end
				return math.random(min, max) 
			end
		)
		
		ent:EmitSound(snd, self.Volume, math.random(self.MinPitch, self.MaxPitch))
	end
end

function PART:StopSound()
	local ent = self:GetOwner()

	if ent:IsValid() and ent.IsPACEntity then
		ent:StopSound(self.Sound)
	end
end

pac.RegisterPart(PART)