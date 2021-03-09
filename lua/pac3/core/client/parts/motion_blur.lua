local render_SetBlend = render.SetBlend
local table_insert = table.insert
local table_remove = table.remove

local PART = {}

PART.ClassName = "motion_blur"
PART.Group = 'modifiers'
PART.Icon = 'icon16/shape_ungroup.png'

pac.StartStorableVars()
	pac.GetSet(PART, "Alpha", 0.5)
	pac.GetSet(PART, "BlurLength", 10)
	pac.GetSet(PART, "BlurSpacing", 0.1)
pac.EndStorableVars()


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
	local ent = parent.GetEntity and parent:GetEntity():IsValid() and parent:GetEntity()

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
		parent:OnDraw(parent:GetOwner(), pos, ang)
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

function PART:OnDraw(ent, pos, ang)
	if pac.drawing_motionblur_alpha then return end

	if self.BlurLength > 0 then
		self:DrawBlur(pos, ang)
	end
end

pac.RegisterPart(PART)