
local consume = test.EventConsumer({
	"init",
	"hide",
	"parent group",
	"shown from rendering",
	"think",
	"draw",
	"hide",
	"remove",
})

function test.Run(done)
	do
		local PART = {}

		PART.FriendlyName = "test"
		PART.ClassName = "test"
		PART.Icon = 'icon16/cut.png'

		function PART:Initialize()
			consume("init")
		end

		function PART:OnShow(from_rendering)
			if from_rendering then
				consume("shown from rendering")
			end
		end

		function PART:OnDraw(owner, pos, ang)
			consume("draw")
			self:Remove()
		end

		function PART:OnThink()
			consume("think")
		end

		function PART:OnHide()
			consume("hide")
		end

		function PART:OnRemove()
			consume("remove")
			done()
		end

		function PART:OnParent(parent)
			consume("parent " .. tostring(parent.ClassName))
		end

		function PART:OnUnparent()
			consume("unparent")
		end

		pac.RegisterPart(PART)
	end

	local root = pac.CreatePart("group", LocalPlayer())
	local part = root:CreatePart("test")
end