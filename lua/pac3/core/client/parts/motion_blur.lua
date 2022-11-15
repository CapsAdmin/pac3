local render_SetBlend = render.SetBlend
local table_insert = table.insert
local table_remove = table.remove

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "motion_blur"
PART.Group = 'modifiers'
PART.Icon = 'icon16/shape_ungroup.png'

BUILDER:StartStorableVars()
	:GetSet("Bone", "none")
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

		local bones = {}
		local i = 1
		for id = 0, ent:GetBoneCount() - 1 do
			local mat = ent:GetBoneMatrix(id)
			if mat then
				bones[i] = {id = id, matrix = mat}
				i = i + 1
			end
		end

		table_insert(self.blur_history, {pos, ang, ent:GetCycle(), bones})
		self.blur_last_add = pac.RealTime + blurSpacing / 1000
	end

	local prev_cycle = ent:GetCycle()

	local blurHistoryLength = #self.blur_history
	for i = 1, blurHistoryLength do
		local pos, ang, cycle, bones = self.blur_history[i][1], self.blur_history[i][2], self.blur_history[i][3], self.blur_history[i][4]

		local alpha = self.Alpha * (i / blurHistoryLength)
		render_SetBlend(alpha)

		if ent then
			ent:SetCycle(cycle)

			for _, data in ipairs(bones) do
				pcall(ent.SetBoneMatrix, ent, data.id, data.matrix)
			end
		end

		pac.drawing_motionblur_alpha = alpha
		parent:OnDraw(ent, pos, ang)
		pac.drawing_motionblur_alpha = false

		if ent then
			pac.SetupBones(ent)
		end
	end

	ent:SetCycle(prev_cycle)

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
