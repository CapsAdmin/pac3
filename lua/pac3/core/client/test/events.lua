local stage
local recorded = {}
local function record(what)
	table.insert(recorded, what)
end
do
	local PART = {}

	PART.FriendlyName = "test"
	PART.ClassName = "test"
	PART.Icon = 'icon16/cut.png'

	function PART:OnShow(from_rendering)
		if from_rendering then

			-- 1

			record("shown from rendering")
			stage = "first event frame"
		else
			if stage == "wait for trigger" then

				-- 5

				record("shown from event")
				self:Remove()
			end
		end
	end

	function PART:OnHide()
		if stage == "hide from event" then

			-- 3

			record("hidden")
			stage = "show trigger"
		end
	end

	function PART:OnRemove()
		self.finished()
	end

	pac.RegisterPart(PART)
end

do
	local event = pac.CreateEvent("test")

	function event:Think(event, ent, ...)

		if stage == "first event frame" then

			-- 2

			record("event think")
			stage = "hide trigger"


		elseif stage == "hide trigger" then


			-- 3

			record("event triggers hide")
			stage = "hide from event"

			return true -- hide
		elseif stage == "show trigger" then

			-- 4

			record("event triggers show")
			stage = "wait for trigger"


			return false -- show
		end
	end

	pac.RegisterEvent(event)
end

hook.Add("ShouldDrawLocalPlayer", "pac_test", function() return true end)

-- TODO: no timer.Simple
timer.Simple(0, function()
	local root = pac.CreatePart("group", LocalPlayer())

	do
		local event = root:CreatePart("event")
		event:SetEvent("test")
		event:SetAffectChildrenOnly(true)
		event_part = event

		do
			local child = event:CreatePart("test")
			child.finished = function()
				local got = table.concat(recorded, ", ")
				local expected = "shown from rendering, event think, event triggers hide, hidden, event triggers show, shown from event"
				if got ~= expected then
					print("== events don't match ==")
					print(got)
					print("~=")
					print(expected)
					print("== ==")
				end
				hook.Remove("ShouldDrawLocalPlayer", "pac_test")

				-- TODO: OnRemove is called multiple times
				child.finished = function() end

				root:Remove()
			end
		end
	end
end)