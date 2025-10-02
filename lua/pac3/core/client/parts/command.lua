local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "command"

PART.Group = "advanced"
PART.Icon = "icon16/application_xp_terminal.png"

PART.ImplementsDoubleClickSpecified = true

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
		if self:GetPlayerOwner() == pac.LocalPlayer and self.DynamicMode and not self:IsHidden() then
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

function PART:HandleErrors(result, mode)
	if isstring(result) then
		pac.Message(result)
		self.Error = "[" .. mode .. "] " .. result
		self.erroring_mode = mode
		self:SetError(result)
		if pace.ActiveSpecialPanel and pace.ActiveSpecialPanel.luapad then
			pace.ActiveSpecialPanel.special_title = self.Error 
		end
	elseif isfunction(result) then
		if pace.ActiveSpecialPanel and pace.ActiveSpecialPanel.luapad then
			if not self.Error then --good compile
				pace.ActiveSpecialPanel.special_title = "[" .. mode .. "] " .. "successfully compiled"
				self.Error = nil
				self:SetError()
			elseif (self.erroring_mode~= nil and self.erroring_mode ~= mode) then --good compile but already had an error from somewhere else (there are 3 script areas: main, onhide, delayed)
				pace.ActiveSpecialPanel.special_title = "successfully compiled, but another erroring script may remain at " .. self.erroring_mode
			else -- if we fixed our previous error from the same mode
				pace.ActiveSpecialPanel.special_title = "[" .. mode .. "] " .. "successfully compiled"
				self.Error = nil
				self:SetError()
			end
		end
	end
end

function PART:SetString(str)
	str = string.Trim(str,"\n")
	self.func = nil
	if self.UseLua and canRunLua() and self:GetPlayerOwner() == pac.LocalPlayer and str ~= "" then
		self.func = CompileString(str, "pac_event", false)
		self:HandleErrors(self.func, "Main string")
	end
	self.String = str
	if self.UseLua and not canRunLua() then
		self:SetError("clientside lua is disabled (sv_allowcslua 0)")
	end
end

function PART:SetOnHideString(str)
	str = string.Trim(str,"\n")
	self.onhide_func = nil
	if self.erroring_mode == "OnHide string" then self.erroring_mode = nil end
	if self.UseLua and canRunLua() and self:GetPlayerOwner() == pac.LocalPlayer and str ~= "" then
		self.onhide_func = CompileString(str, "pac_event", false)
		self:HandleErrors(self.onhide_func, "OnHide string")
	end
	self.OnHideString = str
	if self.UseLua and not canRunLua() then
		self:SetError("clientside lua is disabled (sv_allowcslua 0)")
	end
end

function PART:SetDelayedString(str)
	str = string.Trim(str,"\n")
	self.delayed_func = nil
	if self.erroring_mode == "Delayed string" then self.erroring_mode = nil end
	if self.UseLua and canRunLua() and self:GetPlayerOwner() == pac.LocalPlayer and str ~= "" then
		self.delayed_func = CompileString(str, "pac_event", false)
		self:HandleErrors(self.delayed_func, "Delayed string")
	end
	self.DelayedString = str
	if self.UseLua and not canRunLua() then
		self:SetError("clientside lua is disabled (sv_allowcslua 0)")
	end
end

function PART:Initialize()
	--yield for the compile until other vars are available (UseLua)
	timer.Simple(0, function()
		self:SetOnHideString(self:GetOnHideString())
		self:SetDelayedString(self:GetDelayedString())
	end)
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

local function try_lua_exec(self, func)
	if canRunLua() then
		if isstring(func) then return end
		local status, err = pcall(func)

		if not status then
			self:SetError(err)
			ErrorNoHalt(err .. "\n")
		end
	else
		local msg = "clientside lua is disabled (sv_allowcslua 0)"
		self:SetError(msg)
		pac.Message(tostring(self) .. " - ".. msg)
	end
end

function PART:Execute(commandstring)
	local ent = self:GetPlayerOwner()

	if ent == pac.LocalPlayer then
		if self.UseLua then
			if (self.func or self.onhide_func or self.delayed_func) then
				if commandstring == nil then --regular string
					try_lua_exec(self, self.func)
				else --other modes
					if ((commandstring == self.OnHideString) and self.onhide_func) then
						try_lua_exec(self, self.onhide_func)
					elseif ((commandstring == self.DelayedString) and self.delayed_func) then
						try_lua_exec(self, self.delayed_func)
					elseif ((commandstring == self.String) and self.func) then
						try_lua_exec(self, self.func)
					end
				end
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

PART.OnDoubleClickSpecified = PART.Execute

BUILDER:Register()
