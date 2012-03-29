local PART = {}

PART.ClassName = "text"

pac.StartStorableVars()
	pac.GetSet(PART, "Text", "")
	pac.GetSet(PART, "Font", "default")
	pac.GetSet(PART, "Size", 1)
	pac.GetSet(PART, "Outline", 0)
	pac.GetSet(PART, "Color", Color(255, 255, 255, 255))
	pac.GetSet(PART, "OutlineColor", Color(255, 255, 255, 255))
pac.EndStorableVars()

function PART:PostDrawTranslucentRenderables(owner, pos, ang)
	if self.Text ~= "" then
		cam.Start3D(EyePos(), EyeAngles())
		cam.Start3D2D(pos, ang, self.Size)
			draw.SimpleTextOutlined(self.Text, self.Font, 0,0, self.Color, TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER, self.Outline, self.OutlineColor)
			render.CullMode(1) -- MATERIAL_CULLMODE_CW
			draw.SimpleTextOutlined(self.Text, self.Font, 0,0, self.Color, TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER, self.Outline, self.OutlineColor)
			render.CullMode(0) -- MATERIAL_CULLMODE_CCW
		cam.End3D2D()
		cam.End3D()
	end
end

function PART:OnRestore(data)
	self:SetMaterial(data.SpritePath)
end

function PART:SetText(str)
	self.Text = str
	self:SetTooltip(str)
end

pac.RegisterPart(PART)