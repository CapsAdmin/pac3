
local recorded
local function record_event(what)
	table.insert(recorded, what)
end

do
	local PART = {}

	PART.FriendlyName = "test"
	PART.ClassName = "test"
	PART.Icon = 'icon16/cut.png'

	function PART:Initialize()
		record_event("init")
	end

	function PART:OnShow(from_rendering)
		record_event("show " .. tostring(from_rendering))
		print(self:GetOwner())
	end

	function PART:OnDraw(owner, pos, ang)
		record_event("draw")
		self:Remove()
	end

	function PART:OnThink()
		record_event("think")
	end

	function PART:OnHide()
		record_event("hide")
	end

	function PART:OnRemove()
		record_event("remove")

		self.finished(recorded)
	end

	function PART:OnParent(parent)
		record_event("parent " .. tostring(parent.ClassName))
	end

	function PART:OnUnparent()
		record_event("unparent")
	end

	pac.RegisterPart(PART)
end

recorded = {}

local root = pac.CreatePart("group", LocalPlayer())

local part = root:CreatePart("test")

part.finished = function(recorded)
	-- could be subject to change
	local events = table.concat(recorded, ", ")
	local expected = "init, hide, parent group, show true, think, draw, hide, remove"
	if events ~= expected then
		print(expected)
		print("~=")
		print(events)
		error("events don't match")
	end
end
