local PART = {}

PART.ClassName = "command"

pac.StartStorableVars()
	pac.GetSet(PART, "String", "")
	pac.GetSet(PART, "UseLua", false)
pac.EndStorableVars()

function PART:Initialize()
	self:Execute()
end

function PART:OnShow()
	self:Execute()
end

function PART:SetString(str)
	if self.UseLua and self:GetPlayerOwner() == LocalPlayer() then
		self.func = CompileString(str, "pac_event")
	end	
	self.String = str
end

function PART:Execute()
	local ent = self:GetPlayerOwner()

	if ent == LocalPlayer() then
		if self.UseLua and self.func then
			local status, err = pcall(self.func)
			if not status then
				ErrorNoHalt(err .. "\n")
			end
		else
			ent:ConCommand(self.String)
		end
	end
end

pac.RegisterPart(PART)