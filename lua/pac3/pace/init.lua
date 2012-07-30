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
include("spawnmenu.lua")

pace.ActivePanels = pace.ActivePanels or {}
pace.Editor = NULL

function pace.OpenEditor()
	pace.SetLanguage()
	local editor = pace.CreatePanel("editor")
		editor:SetSize(220, ScrH())
		editor:MakePopup()
		editor.Close = function() 
			pace.CloseEditor()
		end
	pace.Editor = editor
	pace.Active = true
	
	if ctp and ctp.Disable then
		ctp:Disable()
	end
	
	RunConsoleCommand("pac_in_editor", 1)
	
	pace.Call("OpenEditor")
end

function pace.CloseEditor()
	if pace.Editor:IsValid() then
		pace.Call("CloseEditor") 
		pace.Editor:Remove() 
		pace.Active = false
	end
	
	RunConsoleCommand("pac_in_editor", 0)
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
	hook.Add("HUDPaint", "pac_InPAC3Editor", function()		
		for key, ply in pairs(player.GetAll()) do
			if ply ~= LocalPlayer() and ply:GetNWBool("in pac3 editor") then
				local pos_3d = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Head1"))
				local pos_2d = (pos_3d + Vector(0,0,10)):ToScreen()
				draw.DrawText("In PAC3 Editor", "ChatFont", pos_2d.x, pos_2d.y, Color(255,255,255,math.Clamp((pos_3d + Vector(0,0,10)):Distance(EyePos()) * -1 + 500, 0, 500)/500*255),1)
			end
		end
	end)
end

pace.RegisterPanels()