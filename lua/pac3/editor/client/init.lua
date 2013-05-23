include("autorun/pac_init.lua")

pace = pace or {}

include("language.lua")

include("wear.lua")

include("select.lua")
include("view.lua")
include("config.lua")
include("parts.lua")
include("saved_parts.lua")
include("logic.lua")
include("undo.lua")
include("fonts.lua")
include("basic_mode.lua")
include("deprecated_features.lua")
include("settings.lua")
include("shortcuts.lua")
include("menu_bar.lua")

include("mctrl.lua")
include("screenvec.lua")

include("panels.lua")
include("tools.lua")
include("spawnmenu.lua")
include("wiki.lua")
include("examples.lua")

pace.ActivePanels = pace.ActivePanels or {}
pace.Editor = NULL

function pace.OpenEditor()
	if hook.Call("PrePACEditorOpen", GAMEMODE, LocalPlayer()) == false then return end
	
	pac.Enable()
	
	pace.RefreshFiles()
	
	pace.SetLanguage()
	
	local editor = pace.CreatePanel("editor")
		editor:SetSize(240, ScrH())
		editor:MakePopup()
		editor.Close = function() 
			editor:OnRemove()
			pace.CloseEditor()
		end
	pace.Editor = editor
	pace.Active = true
	
	if ctp and ctp.Disable then
		ctp:Disable()
	end
	
	RunConsoleCommand("pac_in_editor", "1")
	
	pace.DisableExternalHooks()
	
	pace.Call("OpenEditor")
end

function pace.CloseEditor()
	pace.RestoreExternalHooks()

	if pace.Editor:IsValid() then
		pace.Editor:OnRemove()
		pace.Editor:Remove() 
		pace.Active = false
		pace.Call("CloseEditor") 
	end
	
	RunConsoleCommand("pac_in_editor", "0")
end

hook.Add("pac_Disable", "pac_editor_disable", function()
	pace.CloseEditor()
end)

function pace.RefreshFiles()
	pace.CachedFiles = nil

	if pace.Editor:IsValid() then
		pace.Editor:MakeBar()
	end
			
	if pace.SpawnlistBrowser:IsValid() then
		pace.SpawnlistBrowser:PopulateFromClient()
	end
end


function pace.Panic()
	pace.CloseEditor()
	for key, pnl in pairs(pace.ActivePanels) do
		if pnl:IsValid() then
			pnl:Remove()
			table.remove(pace.ActivePanels, key)
		end
	end
end

do -- forcing hooks
	pace.ExternalHooks = 
	{
		"CalcView",
		"ShouldDrawLocalPlayer",
	}

	function pace.DisableExternalHooks()
		for _, event in pairs(pace.ExternalHooks) do
			local hooks = hook.GetTable()[event]

			if hooks then
				pace.OldHooks = pace.OldHooks or {}
				pace.OldHooks[event] = pace.OldHooks[event] or {}
				pace.OldHooks[event] = table.Copy(hooks)

				for name in pairs(hooks) do
					if name:sub(1, 4) ~= "pac_" then
						hook.Remove(event, name)
					end
				end
			end
		end
	end

	function pace.RestoreExternalHooks()
		if pace.OldHooks then
			for event, hooks in pairs(pace.OldHooks) do
				for name, func in pairs(hooks) do
					if name:sub(1, 4) ~= "pac_" then
						hook.Add(event, name, func)
					end
				end
			end
		end
		
		pace.OldHooks = nil
	end
end

function pace.IsActive()
	return pace.Active == true
end

concommand.Add("pac_editor", function()
	pace.Panic()
	timer.Simple(0.1, function() pace.OpenEditor() end)
end)

function pace.Call(str, ...)
	if pace["On" .. str] then
		if hook.Run("pace_On" .. str, ...) ~= false then
			pace["On" .. str](...)
		end
	else
		ErrorNoHalt("missing function pace.On" .. str .. "!\n")
	end
end

hook.Add("HUDPaint", "pac_InPAC3Editor", function()		
	for key, ply in pairs(player.GetAll()) do
		if ply ~= LocalPlayer() and ply:GetNWBool("in pac3 editor") then
			local id = ply:LookupBone("ValveBiped.Bip01_Head1")
			local pos_3d = id and ply:GetBonePosition(id) or ply:EyePos()
			local pos_2d = (pos_3d + Vector(0,0,10)):ToScreen()
			draw.DrawText("In PAC3 Editor", "ChatFont", pos_2d.x, pos_2d.y, Color(255,255,255,math.Clamp((pos_3d + Vector(0,0,10)):Distance(EyePos()) * -1 + 500, 0, 500)/500*255),1)
		end
	end
end)

pace.RegisterPanels()