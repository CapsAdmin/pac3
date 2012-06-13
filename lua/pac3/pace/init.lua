include("autorun/pac_init.lua")

pace = pace or {}

include("language.lua")

include("select.lua")
include("view.lua")
include("config.lua")
include("logic.lua")
include("undo.lua")

include("mctrl.lua")
include("screenvec.lua")

include("panels.lua")

pace.ActivePanels = pace.ActivePanels or {}

function pace.OpenEditor()
	local editor = pace.CreatePanel("editor")
		editor:SetSize(220, ScrH())
		editor:Dock(LEFT)
		editor:MakePopup()
		editor.Close = function() 
			pace.Call("CloseEditor") 
			editor:Remove() 
			pace.Active = false
		end
	pace.Editor = editor
	pace.Active = true
	
	pace.Call("OpenEditor")
end

function pace.IsActive()
	return pace.Active == true
end

concommand.Add("pac_editor", function()
	pace.Panic()
	----include("autorun/pac_init.lua")
	--include("autorun/pace_init.lua")
	timer.Simple(0.1, function() pace.OpenEditor() end)
end)

function pace.Call(str, ...)
	if pace["On" .. str] then
		pace["On" .. str](...)
	else
		ErrorNoHalt("missing function pace.On" .. str .. "!\n")
	end
end

function pace.Panic()
	for key, pnl in pairs(pace.ActivePanels) do
		if pnl:IsValid() then
			pnl:Remove()
			table.remove(pace.ActivePanels, key)
		end
	end
end

do -- preview

	local last_inpreview = false

	local RunConsoleCommand = RunConsoleCommand
	local GetAllPlayers = player.GetAll
	local Color = Color
	local DrawText = draw.DrawText

	local position_3D
	local position

	hook.Add("HUDPaint", "pac_InPAC3Editor", function()
		if pace.IsActive() and pace.IsActive() ~= last_inpreview then
			RunConsoleCommand("pac_in_editor", 1)
			last_inpreview = pace.IsActive()
			if ctp and ctp.Disable then
				ctp:Disable()
			end
		elseif not pace.IsActive() and pace.IsActive() ~= last_inpreview then
			RunConsoleCommand("pac_in_editor", 0)
			last_inpreview = pace.IsActive()
		end
		for key, ply in pairs(GetAllPlayers()) do
			if ply ~= LocalPlayer() and ply:GetNWBool("in pac3 editor") then
				position_3D = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Head1"))
				position = (position_3D + Vector(0,0,10)):ToScreen()
				DrawText("In PAC3 Editor", "ChatFont", position.x, position.y, Color(255,255,255,Clamp((position_3D + Vector(0,0,10)):Distance(EyePos()) * -1 + 500, 0, 500)/500*255),1)
			end
		end
	end)
end

pace.RegisterPanels()