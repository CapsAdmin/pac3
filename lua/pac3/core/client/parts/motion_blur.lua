local render_SetBlend = render.SetBlend
local table_insert = table.insert
local table_remove = table.remove

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "motion_blur"
PART.Group = 'modifiers'
PART.Icon = 'icon16/shape_ungroup.png'

BUILDER:StartStorableVars()
	:GetSet("Alpha", 0.5)
	:GetSet("BlurLength", 10)
	:GetSet("BlurSpacing", 0.1)
:EndStorableVars()


function PART:OnShow()
	if self.BlurLength > 0 then
		self.blur_history = {}
		self.blur_last_add = 0
		pac.drawing_motionblur_alpha = false
	end
end

function PART:DrawBlur(pos, ang)
	local parent = self:GetParent()
	if not parent:IsValid() then return end
	local ent = parent:GetOwner()

	if not parent.OnDraw then return end

	self.blur_history = self.blur_history or {}

	local blurSpacing = self.BlurSpacing

	if not self.blur_last_add or blurSpacing == 0 or self.blur_last_add < pac.RealTime then
		table_insert(self.blur_history, {pos, ang})
		self.blur_last_add = pac.RealTime + blurSpacing / 1000
	end

	local blurHistoryLength = #self.blur_history
	for i = 1, blurHistoryLength do
		pos, ang = self.blur_history[i][1], self.blur_history[i][2]

		local alpha = self.Alpha * (i / blurHistoryLength)
		render_SetBlend(alpha)

		pac.drawing_motionblur_alpha = alpha
		parent:OnDraw(ent, pos, ang)
		pac.drawing_motionblur_alpha = false

		if ent then
			ent:SetupBones()
		end
	end

	local maximumBlurHistoryLength = math.min(self.BlurLength, 20)
	while #self.blur_history >= maximumBlurHistoryLength do
		table_remove(self.blur_history, 1)
	end
end

function PART:OnDraw()
	if pac.drawing_motionblur_alpha then return end

	if self.BlurLength > 0 then
		local pos, ang = self:GetDrawPosition()

		self:DrawBlur(pos, ang)
	end
end

BUILDER:Register()
