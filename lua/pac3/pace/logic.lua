pace.current_part = pac.NULL
pace.properties = NULL
pace.tree = NULL

local L = pace.LanguageString

function pace.PopulateProperties(part)
	if pace.properties:IsValid() then
		pace.properties:Populate(part)
	end
end

function pace.OnDraw()
	pace.mctrl.HUDPaint()
end

hook.Add("InitPostEntity", "pace_autoload_session", function()	
	timer.Simple(5, function()
		pace.LoadSession("autoload")
		timer.Simple(3, function()
		-- give pac some time to solve bones and parents
			for key, part in pairs(pac.GetParts(true)) do
				if not part:HasParent() then
					pac.SendPartToServer(part)
				end
			end
		end)
	end)
end)

function pace.OnOpenEditor()
	pace.SetViewPos(LocalPlayer():EyePos())
	pace.SetViewAngles(LocalPlayer():EyeAngles())
	pace.EnableView(true)
	
	pace.TrySelectPart()
	
	pace.ResetView()
end

function pace.TrySelectPart()
	local part
	
	for k,v in pairs(pac.GetParts(true)) do
		if v.UniqueID == pace.current_part_uid then
			part = v
		end
	end
	
	if part then
		pace.Call("PartSelected", part)
	elseif table.Count(pac.GetParts(true)) == 0 then
		pace.Call("CreatePart", "group", L"my outfit", L"add parts to me!")
	else
		pace.Call("PartSelected", select(2, next(pac.GetParts(true))))
	end
end