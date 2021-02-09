
local check = test.EventConsumer({
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
			check("init")
		end

		function PART:OnShow(from_rendering)
			if from_rendering then
				check("shown from rendering")
			end
		end

		function PART:OnDraw(owner, pos, ang)
			check("draw")
			self:Remove()
		end

		function PART:OnThink()
			check("think")
		end

		function PART:OnHide()
			check("hide")
		end

		function PART:OnRemove()
			check("remove")
			done()
		end

		function PART:OnParent(parent)
			check("parent " .. tostring(parent.ClassName))
		end

		function PART:OnUnparent()
			check("unparent")
		end

		pac.RegisterPart(PART)
	end

	local root = pac.CreatePart("group", LocalPlayer())
	local part = root:CreatePart("test")
end