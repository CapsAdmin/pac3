
local recorded = {}
local function record(what)
	table.insert(recorded, what)
end

do
	local PART = {}

	PART.FriendlyName = "test"
	PART.ClassName = "test"
	PART.Icon = 'icon16/cut.png'

	function PART:Initialize()
		record("init")
	end

	function PART:OnShow(from_rendering)
		if from_rendering then
			record("shown from rendering")
		end
	end

	function PART:OnDraw(owner, pos, ang)
		record("draw")
		self:Remove()
	end

	function PART:OnThink()
		record("think")
	end

	function PART:OnHide()
		record("hide")
	end

	function PART:OnRemove()
		record("remove")

		self.finished()
	end

	function PART:OnParent(parent)
		record("parent " .. tostring(parent.ClassName))
	end

	function PART:OnUnparent()
		record("unparent")
	end

	pac.RegisterPart(PART)
end

hook.Add("ShouldDrawLocalPlayer", "pac_test", function() return true end)

-- TODO: no timer.Simple
timer.Simple(0, function()
	local root = pac.CreatePart("group", LocalPlayer())

	local part = root:CreatePart("test")

	part.finished = function()
		-- could be subject to change
		local got = table.concat(recorded, ", ")
		local expected = "init, hide, parent group, show true, think, draw, hide, remove"
		if got ~= expected then
			print("== base part events don't match ==")
			print(got)
			print("~=")
			print(expected)
			print("== ==")
		end

		hook.Remove("ShouldDrawLocalPlayer", "pac_test")

		-- TODO: OnRemove is called multiple times
		part.finished = function() end
	end
end)