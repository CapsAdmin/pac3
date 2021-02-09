
local check = test.EventConsumer({
	"shown from rendering",
	"event think",
	"event triggers hide",
	"hidden",
	"event triggers show",
	"shown from event",
})

function test.Run(done)
	local stage = nil

	do
		local PART = {}

		PART.FriendlyName = "test"
		PART.ClassName = "test"
		PART.Icon = 'icon16/cut.png'

		function PART:OnShow(from_rendering)
			if from_rendering then
				-- TODO: OnShow(true) triggers 2 times
				if stage == nil then
					-- 1

					check("shown from rendering")
					stage = "first event frame"
				end
			else
				if stage == "wait for trigger" then

					-- 5

					check("shown from event")
					self:GetRootPart():Remove()
				end
			end
		end

		function PART:OnHide()
			if stage == "hide from event" then

				-- 3

				check("hidden")
				stage = "show trigger"
			end
		end

		function PART:OnRemove()
			done()
		end

		pac.RegisterPart(PART)
	end

	do
		local event = pac.CreateEvent("test")

		function event:Think(event, ent, ...)

			if stage == "first event frame" then

				-- 2

				check("event think")
				stage = "hide trigger"


			elseif stage == "hide trigger" then


				-- 3

				check("event triggers hide")
				stage = "hide from event"

				return true -- hide
			elseif stage == "show trigger" then

				-- 4

				check("event triggers show")
				stage = "wait for trigger"


				return false -- show
			end
		end

		pac.RegisterEvent(event)
	end

	local root = pac.CreatePart("group", LocalPlayer())

	do
		local event = root:CreatePart("event")
		event:SetEvent("test")
		event:SetAffectChildrenOnly(true)
		event_part = event

		local child = event:CreatePart("test")
	end
end