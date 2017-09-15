RENDER_ENTS = RENDER_ENTS or {}
for i,v in pairs(RENDER_ENTS) do if v:IsValid() then v:Remove() end end
table.Empty(RENDER_ENTS)

for k, v in pairs(hook.GetTable()) do
	for k2,v2 in pairs(v) do
		if k2 == "render_ents" then
			hook.Remove(k, k2)
		end
	end
end

local function is_entity_visible(self)
	if self.last_visible then
		return self.last_visible > 0
	end

	self.render_ents_pixvis = self.render_ents_pixvis or util.GetPixelVisibleHandle()
	local vis = util.PixelVisible(self:GetPos(), self:BoundingRadius() * 2, self.render_ents_pixvis)

	self.last_visible = vis

	return vis > 0
end

local function create_ent(mdl, rendergroup, parent)
	local ent = ClientsideModel(mdl, rendergroup)
	table.insert(RENDER_ENTS, ent)

	ent:Spawn()
	ent:SetLOD(0)

	ent.parent = parent
	ent.root_parent = parent.root_parent or parent
	ent.bone = 0
	ent.parent.matrix = ent.parent.matrix or Matrix()
	ent.matrix = Matrix() * ent.parent.matrix

	function ent:CheckVisibility()
		if is_entity_visible(self.root_parent) then
			self.draw_me = true
			return true
		end

		self.draw_me = false
		return false
	end

	function ent:UpdateMatrix()
		self:EnableMatrix("RenderMultiply", self.matrix)
	end

	function ent:GetPosAng()
		-- if we don't call this function mat will return nil (?)
		self.parent:GetBonePosition(self.bone)
		local mat = self.parent:GetBoneMatrix(self.bone)

		if mat then
			mat = mat * ent.matrix
			return mat:GetTranslation(), mat:GetAngles()
		end

		return self.parent:GetPos(), self.parent:GetAngles()
	end

	return ent
end

local ENT = LocalPlayer()
local max = 1500

for i = 1, 200 do
	local parent = ENT
	for i = 1, math.random(1, 20) do
		local ent = create_ent("models/props_junk/PopCan01a.mdl", RENDERGROUP_OPAQUE, parent)
		ent.bone = math.random(1, parent:GetBoneCount())
		ent.matrix:Translate(VectorRand()*5)
		ent.matrix:Rotate(VectorRand():Angle())
		ent:UpdateMatrix()
		parent = ent

		if #RENDER_ENTS == max then break end
	end

	if #RENDER_ENTS == max then break end
end

ENT.render_ents_RenderOverride = ENT.render_ents_RenderOverride or function(self) self:DrawModel()  end

function ENT:RenderOverride()
	self:render_ents_RenderOverride()

	for i, ent in ipairs(RENDER_ENTS) do
		if ent:CheckVisibility() then
			local pos, ang = ent:GetPosAng()
			ent:SetPos(pos)
			ent:SetAngles(ang)
			ent:InvalidateBoneCache()
		end
	end
end

hook.Add("PostRender", "render_ents", function()
	for i, ent in ipairs(RENDER_ENTS) do
		ent.root_parent.last_visible = nil
		ent:SetNoDraw(not ent.draw_me)
	end
end)