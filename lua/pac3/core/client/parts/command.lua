local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "command"

PART.Group = 'advanced'
PART.Icon = 'icon16/application_xp_terminal.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("String", "", {editor_panel = "string"})
	BUILDER:GetSet("UseLua", false)
	BUILDER:GetSet("ExectueOnWear", false)
	BUILDER:GetSet("ExectueOnShow", true)
BUILDER:EndStorableVars()

function PART:Initialize()
	if self:GetExectueOnWear() then
		self:Execute()
	end
end

function PART:OnShow(from_rendering)
	if not from_rendering then
		if self:GetExectueOnShow() then
			self:Execute()
		end
	end
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
				pac.Message(tostring(self) .. ' - sv_allowcslua is 0')
			end
		else
			ent:ConCommand(self.String)
		end
	end
end

BUILDER:Register()