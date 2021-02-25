local utility = pac999.utility
local models = pac999.models

local BUILDER, META = pac999.entity.ComponentTemplate("model")

BUILDER:StartStorableVars()
	:GetSet("Material", (Material("phoenix_storms/concrete0")))
	:GetSet("Color", Vector(1,1,1))
	:GetSet("Alpha", 1)
	:GetSet("IgnoreZ", false)
	:GetSet("Model", "models/maxofs2d/cube_tool.mdl")
:EndStorableVars()

function META:Start()
	pac999_models = pac999_models or {}

	self.source_ent = ClientsideModel("error.mdl")
	table.insert(pac999_models, self.source_ent)
	self.source_ent:SetNoDraw(true)

	self.model_set = false
end

function META:Finish()
	SafeRemoveEntityDelayed(self.source_ent, 0)
end

function META:SetColor(val)
	if IsColor(val) then
		val = Vector(val.r, val.g, val.b) / 255
	end
	self.Color = val
end

local function blend(color, alpha, brightness)
	local r,g,b = 1,1,1
	local a = 1

	if color then
		r = color.x
		g = color.y
		b = color.z
	end

	if alpha then
		a = alpha
	end

	if brightness then
		r = r * brightness
		g = g * brightness
		b = b * brightness
	end

	return r,g,b,a
end

function META:Render3D()
	if not self.model_set then return end
	local ent = self.source_ent
	local world = self.entity.transform:GetMatrix()

	local m = world * Matrix()
	-- m:Translate(-self.entity.transform:GetCageCenter())
	ent:SetRenderOrigin(m:GetTranslation())

	m:SetTranslation(vector_origin)
	ent:EnableMatrix("RenderMultiply", m * self.entity.transform:GetScaleMatrix())
	ent:SetupBones()

	if self.IgnoreZ then
		cam.IgnoreZ(true)
	end

	local r,g,b,a =  blend(self.Color, self.Alpha, self.Brightness)

	if self.Material then
		render.MaterialOverride(self.Material)
	end

	if self.entity:HasComponent("input") and self.entity.input.Hovered then
		r = r * 4
		g = g * 4
		b = b * 4
	end

	render.SetBlend(a)
	render.SetColorModulation(r,g,b)

	ent:DrawModel()

	if self.Material then
		--render.MaterialOverride()
	end

	if self.IgnoreZ then
		cam.IgnoreZ(false)
	end
end

function META:SetModel(mdl)
	self.Model = mdl

	self.source_ent:SetModel(mdl)

	local data = pac999.models.GetMeshInfo(self.source_ent:GetModel())

	if self.entity.bounding_box then
		self.entity.bounding_box:SetMin(data.min)
		self.entity.bounding_box:SetMax(data.max)
		self.entity.bounding_box:SetAngleOffset(data.angle_offset)
	end

	self.model_set = true
end

BUILDER:Register()

hook.Add("PostDrawOpaqueRenderables", "pac_999", function()
	for _, obj in ipairs(pac999.entity.GetAllComponents("model")) do
		obj:Render3D()
	end
end)