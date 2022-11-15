pace.current_part = NULL
pace.properties = NULL
pace.tree = NULL

local L = pace.LanguageString
local alreadyInCall

function pace.PopulateProperties(part)
	if pace.properties:IsValid() then
		pace.properties:Populate(part:GetProperties())
		for k,v in pairs(pace.extra_populates) do
			v.func(v.pnl)
		end
		pace.extra_populates = {}

		pace.Editor:InvalidateLayout()
	end
end

function pace.OnDraw()
	if not pace.editing_viewmodel and not pace.editing_hands then
		pace.mctrl.HUDPaint()
	end
end

local function post_draw_view_model()
	if alreadyInCall then return end

	if pace.editing_viewmodel and not pace.editing_hands then
		cam.Start2D()

		alreadyInCall = true
		pace.mctrl.HUDPaint()
		alreadyInCall = false

		cam.End2D()
	end
end

local function post_draw_player_hands()
	if alreadyInCall then return end

	if not pace.editing_viewmodel and pace.editing_hands then
		cam.Start2D()

		alreadyInCall = true
		pace.mctrl.HUDPaint()
		alreadyInCall = false

		cam.End2D()
	end
end

function pace.OnOpenEditor()
	alreadyInCall = false
	pace.SetViewPos(pac.LocalPlayer:EyePos())
	pace.SetViewAngles(pac.LocalPlayer:EyeAngles())
	pace.EnableView(true)

	if table.Count(pac.GetLocalParts()) == 0 then
		pace.Call("CreatePart", "group", L"my outfit")
	end

	pace.TrySelectPart()

	pace.ResetView()

	pac.AddHook("PostDrawPlayerHands", "pace_viewmodel_edit", post_draw_player_hands)
	pac.AddHook("PostDrawViewModel", "pace_viewmodel_edit", post_draw_view_model)
end

function pace.OnCloseEditor()
	pace.EnableView(false)
	pace.StopSelect()
	pace.SafeRemoveSpecialPanel()

	pac.RemoveHook("PostDrawViewModel", "pace_viewmodel_edit")
	pac.RemoveHook("PostDrawPlayerHands", "pace_viewmodel_edit")
end

function pace.TrySelectPart()
	local part = select(2, next(pac.GetLocalParts()))

	local found = pac.GetPartFromUniqueID(pac.Hash(pac.LocalPlayer), pace.current_part_uid)

	if found:IsValid() and found:GetPlayerOwner() == part:GetPlayerOwner() then
		part = found
	end

	if part then
		pace.Call("PartSelected", part)
	end
end
