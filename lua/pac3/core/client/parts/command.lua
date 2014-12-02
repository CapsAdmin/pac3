local PART = {}

PART.ClassName = "command"
PART.NonPhysical = true

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

function PART:SetUseLua(b)
	self.UseLua = b
	self:SetString(self:GetString())
end

function PART:SetString(str)
	if self.UseLua and self:GetPlayerOwner() == pac.LocalPlayer then
		self.func = CompileString(str, "pac_event")
	end	
	self.String = str
end

function PART:GetCode()
	return self.String
end

function PART:SetCode(str)
	self.String = str
end

function PART:ShouldHighlight(str)
	return _G[str] ~= nil
end

local sv_allowcslua = GetConVar("sv_allowcslua")
function PART:Execute()
	local ent = self:GetPlayerOwner()

	if ent == pac.LocalPlayer then
		if self.UseLua and self.func then
			if sv_allowcslua:GetBool() or pac.AllowClientsideLUA then
				local status, err = pcall(self.func)
				if not status then
					ErrorNoHalt(err .. "\n")
				end
			else
				ErrorNoHalt("[PAC] sv_allowcslua is 0\n")
			end
		else
			ent:ConCommand(self.String)
		end
	end
end

pac.RegisterPart(PART)