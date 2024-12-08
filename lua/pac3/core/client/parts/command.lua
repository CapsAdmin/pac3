local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "command"

PART.Group = "advanced"
PART.Icon = "icon16/application_xp_terminal.png"

BUILDER:StartStorableVars()

BUILDER:SetPropertyGroup("generic")
	BUILDER:GetSet("String", "", {editor_panel = "code_script"})
	BUILDER:GetSet("UseLua", false)
	BUILDER:GetSet("ExecuteOnWear", false)
	BUILDER:GetSet("ExecuteOnShow", true)
	BUILDER:GetSet("SafeGuard", false, {description = "Delays the execution by 1 frame to attempt to prevent false triggers due to events' runtime quirks"})

	--fading re-run mode
	BUILDER:SetPropertyGroup("dynamic mode")
	BUILDER:GetSet("DynamicMode", false, {description = "Dynamically assign an argument, adding the appended number to the string.\nWhen the appended number is changed, run the command again.\nFor example, it could be used with post processing fades. With pp_colormod 1, pp_colormod_color represents saturation multiplier. You could fade that to slowly fade to gray."})
	BUILDER:GetSet("AppendedNumber", 1, {description = "Argument to use. When it changes, the command will run again with the updated value."})

	--common alternate activations
	BUILDER:SetPropertyGroup("alternates")
	BUILDER:GetSet("OnHideString", "", {description = "An alternate command when the part is hidden. Governed by execute on show", editor_panel = "code_script"})
	BUILDER:GetSet("DelayedString", "", {description = "An alternate command after a delay. Governed by execute on show", editor_panel = "code_script"})
	BUILDER:GetSet("Delay", 1)

	--we might as well have a section for command events since they are so useful for logic, and often integrated with command parts
	--There should be a more convenient front-end for pac_event stuff and to fix the issue where people want to randomize their command (e.g. random attacks) when cs lua isn't allowed on some servers.
	BUILDER:SetPropertyGroup("pac_event")
	BUILDER:GetSet("CommandName", "", {description = "name of the pac_event to manage, or base name of the sequenced series.\n\nfor example, if you have commands hat1, hat2, hat3, and hat4:\n-the base name is hat\n-the minimum is 1\n-the maximum is 4"})
	BUILDER:GetSet("Action", "Default", {enums = {
		["Default: single-shot"] = "Default",
		["Default: On (1)"] = "On",
		["Default: Off (0)"] = "Off",
		["Default: Toggle (2)"] = "Toggle",
		["Sequence: forward"] = "Sequence+",
		["Sequence: back"] = "Sequence-",
		["Sequence: set"] = "SequenceSet",
		["Random"] = "Random",
		["Random (Sequence set)"] = "RandomSet",
	}, description = "The Default series corresponds to the normal pac_event command modes. Minimum and maximum don't apply.\nSequences run the sequence command pac_event_sequenced with the corresponding mode.\nRandom will select a random number to append to the base name and run the pac_event as a single-shot. This is intended to replace the lua randomizer method when sv_allowcslua is disabled."})
	BUILDER:GetSet("Minimum", 1, {description = "The defined minimum for the pac_event if it's for a numbered series.\nOr, when using the sequence set action, this will be used.", editor_onchange = function(self, val) return math.floor(val) end})
	BUILDER:GetSet("Maximum", 1, {description = "The defined maximum for the pac_event if it's for a numbered series.", editor_onchange = function(self, val) return math.floor(val) end})

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

function PART:SetMaximum(val)
	self.Maximum = val
	if self:GetPlayerOwner() == pac.LocalPlayer and self.CommandName ~= "" and self.Minimum ~= self.Maximum then
		self:GetPlayerOwner():ConCommand("pac_event_sequenced_force_set_bounds " .. self.CommandName .. " " .. self.Minimum .. " " .. self.Maximum)
	end
end

function PART:SetMinimum(val)
	self.Minimum = val
	if self:GetPlayerOwner() == pac.LocalPlayer and self.CommandName ~= "" and self.Minimum ~= self.Maximum then
		self:GetPlayerOwner():ConCommand("pac_event_sequenced_force_set_bounds " .. self.CommandName .. " " .. self.Minimum .. " " .. self.Maximum)
	end
end

function PART:SetAppendedNumber(val)
	if self.AppendedNumber ~= val then
		self.AppendedNumber = val
		if self:GetPlayerOwner() == pac.LocalPlayer and self.DynamicMode then
			self:Execute()
		end
	end
	self.AppendedNumber = val
end

function PART:OnShow(from_rendering)
	if not from_rendering and self:GetExecuteOnShow() then
		if pace.still_loading_wearing then return end
		
		if self.SafeGuard then
			timer.Simple(0,function()
				if self.Hide or self:IsHidden() then return end
				self:Execute()
			end)
		else
			self:Execute()
		end

		if self.DelayedString ~= "" then
			timer.Simple(self.Delay, function()
				self:Execute(self.DelayedString)
			end)
		end
	end
end

function PART:OnHide()
	if self.ExecuteOnShow and self.OnHideString ~= "" then
		self:Execute(self.OnHideString)
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
	if self.String == "" and self.CommandName ~= "" then
		if self.Action == "Default" then
			return "pac_event " .. self.CommandName
		elseif self.Action == "On" then
			return "pac_event " .. self.CommandName .. " 1"
		elseif self.Action == "Off" then
			return "pac_event " .. self.CommandName .. " 0"
		elseif self.Action == "Toggle" then
			return "pac_event " .. self.CommandName .. " 2"
		elseif self.Action == "Sequence+" then
			return "pac_event_sequenced " .. self.CommandName .. " +"
		elseif self.Action == "Sequence-" then
			return "pac_event_sequenced " .. self.CommandName .. " -"
		elseif self.Action == "SequenceSet" then
			return "pac_event_sequenced " .. self.CommandName .. " set " .. self.Minimum .. "[bounds:" .. self.Minimum .. ", " .. self.Maximum .."]"
		elseif self.Action == "Random" then
			return "pac_event " .. self.CommandName .. " <random:" .. self.Minimum .. ", " .. self.Maximum .. ">"
		elseif self.Action == "RandomSet" then
			return "pac_event_sequenced " .. self.CommandName .. " set " .. "<random:" .. self.Minimum .. "," .. self.Maximum .. ">"
		end
	end
	return "command: " .. self.String
end

function PART:Execute(commandstring)
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
			if self.String == "" and self.CommandName ~= "" then
				--[[
					["Default: single-shot"] = "Default",
					["Default: On (1)"] = "On",
					["Default: Off (0)"] = "Off",
					["Default: Toggle (2)"] = "Toggle",
					["Sequence: forward"] = "Sequence+",
					["Sequence: back"] = "Sequence-",
					["Sequence: set"] = "SequenceSet",
					["Random"] = "Random",
					["Random"] = "RandomSet",
				]]
				if self.Action == "Default" then
					ent:ConCommand("pac_event " .. self.CommandName)
				elseif self.Action == "On" then
					ent:ConCommand("pac_event " .. self.CommandName .. " 1")
				elseif self.Action == "Off" then
					ent:ConCommand("pac_event " .. self.CommandName .. " 0")
				elseif self.Action == "Toggle" then
					ent:ConCommand("pac_event " .. self.CommandName .. " 2")
				elseif self.Action == "Sequence+" then
					ent:ConCommand("pac_event_sequenced " .. self.CommandName .. " +")
				elseif self.Action == "Sequence-" then
					ent:ConCommand("pac_event_sequenced " .. self.CommandName .. " -")
				elseif self.Action == "SequenceSet" then
					ent:ConCommand("pac_event_sequenced " .. self.CommandName .. " set " .. self.Minimum)
				elseif self.Action == "Random" then
					local randnum = math.floor(math.Rand(self.Minimum, self.Maximum + 1))
					ent:ConCommand("pac_event " .. self.CommandName .. randnum)
				elseif self.Action == "RandomSet" then
					local randnum = math.floor(math.Rand(self.Minimum, self.Maximum + 1))
					ent:ConCommand("pac_event_sequenced " .. self.CommandName .. " set " .. randnum)
				end
				return
			end

			if self.DynamicMode then
				ent:ConCommand(self.String .. " " .. self.AppendedNumber)
				return
			end
			ent:ConCommand(commandstring or self.String)
		end
	end
end

BUILDER:Register()
