local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "command"

PART.Group = "advanced"
PART.Icon = "icon16/application_xp_terminal.png"

BUILDER:StartStorableVars()
	BUILDER:GetSet("String", "", {editor_panel = "string"})
	BUILDER:GetSet("UseLua", false)
	BUILDER:GetSet("ExecuteOnWear", false)
	BUILDER:GetSet("ExecuteOnShow", true)
BUILDER:EndStorableVars()

local sv_allowcslua = GetConVar("sv_allowcslua")
local function canRunLua()
	return sv_allowcslua:GetBool() or pac.AllowClientsideLUA
end

function PART:OnWorn()
	if self:GetExecuteOnWear() then
		self:Execute()
	end
end

function PART:OnShow(from_rendering)
	if not from_rendering and self:GetExecuteOnShow() then
		self:Execute()
	end
end

function PART:SetUseLua(b)
	self.UseLua = b
	self:SetString(self:GetString())
end

function PART:SetString(str)
	if self.UseLua and canRunLua() and self:GetPlayerOwner() == pac.LocalPlayer then
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

function PART:GetNiceName()
	if self.UseLua then
		return ("lua: " .. self.String)
	end
	return "command: " .. self.String
end

function PART:Execute()
	local ent = self:GetPlayerOwner()

	if ent == pac.LocalPlayer then
		if self.UseLua and self.func then
			if canRunLua() then
				local status, err = pcall(self.func)

				if not status then
					self:SetError(err)
					ErrorNoHalt(err .. "\n")
				end
			else
				local msg = "clientside lua is disabled (sv_allowcslua 0)"
				self:SetError(msg)
				pac.Message(tostring(self) .. " - ".. msg)
			end
		else
			if hook.Run("PACCanRunConsoleCommand", self.String) == false then return end
			if IsConCommandBlocked(self.String) then
				self:SetError("Concommand is blocked")
				return
			end
			ent:ConCommand(self.String)
		end
	end
end

BUILDER:Register()
