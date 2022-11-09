local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "command"

PART.Group = 'advanced'
PART.Icon = 'icon16/application_xp_terminal.png'

BUILDER:StartStorableVars()
	BUILDER:GetSet("String", "", {editor_panel = "string"})
	BUILDER:GetSet("UseLua", false)
	BUILDER:GetSet("ExecuteOnWear", false)
	BUILDER:GetSet("ExecuteOnShow", true)
BUILDER:EndStorableVars()

function PART:OnWorn()
	if self:GetExecuteOnWear() then
		self:Execute()
	end
end

function PART:OnShow(from_rendering)
	if not from_rendering then
		if self:GetExecuteOnShow() then
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
					self:SetError(err)
					ErrorNoHalt(err .. "\n")
				end
			else
				local msg = "clientside lua is disabled (sv_allowcslua 0)"
				self:SetError(msg)
				pac.Message(tostring(self) .. ' - '.. msg)
			end
		else
			if hook.Run("PACCanRunConsoleCommand", self.String) == false then return end
			ent:ConCommand(self.String)
		end
	end
end

BUILDER:Register()
