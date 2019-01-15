pace.current_part = pac.NULL
pace.properties = NULL
pace.tree = NULL

local L = pace.LanguageString

function pace.PopulateProperties(part)
	if pace.properties:IsValid() then
		pace.properties:Populate(part)
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

pac.AddHook("PostDrawViewModel", "pace_viewmodel_edit", function()
	if alreadyInCall then return end

	if pace.editing_viewmodel and not pace.editing_hands then
		cam.Start2D()

		alreadyInCall = true
		pace.mctrl.HUDPaint()
		alreadyInCall = false

		cam.End2D()
	end
end)

pac.AddHook("PostDrawPlayerHands", "pace_viewmodel_edit", function()
	if alreadyInCall then return end

	if not pace.editing_viewmodel and pace.editing_hands then
		cam.Start2D()

		alreadyInCall = true
		pace.mctrl.HUDPaint()
		alreadyInCall = false

		cam.End2D()
	end
end)

function pace.OnOpenEditor()
	alreadyInCall = false
	pace.SetViewPos(LocalPlayer():EyePos())
	pace.SetViewAngles(LocalPlayer():EyeAngles())
	pace.EnableView(true)

	if table.Count(pac.GetLocalParts()) == 0 then
		pace.Call("CreatePart", "group", L"my outfit")
	end

	pace.TrySelectPart()

	pace.ResetView()
end

function pace.OnCloseEditor()
	pace.EnableView(false)
	pace.StopSelect()
	pace.SafeRemoveSpecialPanel()
end

function pace.TrySelectPart()
	local part = select(2, next(pac.GetLocalParts()))

	local found = pac.GetPartFromUniqueID(pac.LocalPlayer:UniqueID(), pace.current_part_uid)

	if found:IsValid() and found:GetPlayerOwner() == part:GetPlayerOwner() then
		part = found
	end

	if part then
		pace.Call("PartSelected", part)
	end
end

local pac_onuse_only = CreateClientConVar('pac_onuse_only', '0', true, false, 'Enable "on +use only" mode. Within this mode, outfits are not being actually "loaded" until you hover over player and press your use button')
local MAX_DIST = 270

local function PlayerBindPress(ply, bind, isPressed)
	if bind ~= "use" and bind ~= "+use" then return end
	if bind ~= "+use" and isPressed then return end
	if not pac_onuse_only:GetBool() then return end
	local eyes, aim = ply:EyePos(), ply:GetAimVector()

	local tr = util.TraceLine({
		start = eyes,
		endpos = eyes + aim * MAX_DIST,
		filter = ply
	})

	-- if not tr.Hit or not tr.Entity:IsValid() or not tr.Entity:IsPlayer() then return end
	if not tr.Hit or not tr.Entity:IsValid() then return end

	local ply2 = tr.Entity
	if not ply2.pac_onuse_only or not ply2.pac_onuse_only_check then return end
	ply2.pac_onuse_only_check = false
	pac.ToggleIgnoreEntity(ply2, false, "pac_onuse_only")
end

local lastDisplayLabel = 0

surface.CreateFont("pac_onuse_only_hint", {
	font = "Roboto",
	size = ScreenScale(16),
	weight = 600,
})

local function HUDPaint(ply, bind, isPressed)
	if not pac_onuse_only:GetBool() then return end
	local ply = LocalPlayer()
	local eyes, aim = ply:EyePos(), ply:GetAimVector()

	local tr = util.TraceLine({
		start = eyes,
		endpos = eyes + aim * MAX_DIST,
		filter = ply
	})

	if tr.Hit and tr.Entity:IsValid() and tr.Entity.pac_onuse_only and tr.Entity.pac_onuse_only_check then
		lastDisplayLabel = RealTime() + 1
	end

	if lastDisplayLabel < RealTime() then return end

	local alpha = (lastDisplayLabel - RealTime()) / 3
	draw.DrawText(L"Press +use to reveal PAC3 outfit", "pac_onuse_only_hint", ScrW() / 2, ScrH() * 0.3, Color(255, 255, 255, alpha * 255), TEXT_ALIGN_CENTER)
end

hook.Add("PlayerBindPress", "pac_onuse_only", PlayerBindPress)
hook.Add("HUDPaint", "pac_onuse_only", HUDPaint)
