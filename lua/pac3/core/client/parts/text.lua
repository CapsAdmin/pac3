local PART = {}

PART.ClassName = "text"

pac.StartStorableVars()
	pac.GetSet(PART, "Text", "")
	pac.GetSet(PART, "Font", "default")
	pac.GetSet(PART, "Size", 1)
	pac.GetSet(PART, "Outline", 0)
	pac.GetSet(PART, "Color", Vector(255, 255, 255))
	pac.GetSet(PART, "Alpha", 1)
	pac.GetSet(PART, "OutlineColor", Vector(255, 255, 255))
	pac.GetSet(PART, "OutlineAlpha", 1)
pac.EndStorableVars()

function PART:SetColor(v)
	self.ColorC = self.ColorC or Color(255, 255, 255, 255)
	
	self.ColorC.r = v.r
	self.ColorC.g = v.g
	self.ColorC.b = v.b
end

function PART:SetAlpha(n)
	self.ColorC = self.ColorC or Color(255, 255, 255, 255)
	self.ColorC.a = n * 255
end

function PART:SetOutlineColor(v)
	self.ColorC = self.ColorC or Color(255, 255, 255, 255)
	
	self.ColorC.r = v.r
	self.ColorC.g = v.g
	self.ColorC.b = v.b
end

function PART:SetOutlineAlpha(n)
	self.ColorC = self.ColorC or Color(255, 255, 255, 255)
	self.ColorC.a = n * 255
end


function PART:OnDraw(owner, pos, ang)
	if self.Text ~= "" then
		cam.Start3D(EyePos(), EyeAngles())
			cam.Start3D2D(pos, ang, self.Size)
				
			draw.SimpleTextOutlined(self.Text, self.Font, 0,0, self.ColorC, TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER, self.Outline, self.OutlineColorC)
			render.CullMode(1) -- MATERIAL_CULLMODE_CW
			
			draw.SimpleTextOutlined(self.Text, self.Font, 0,0, self.ColorC, TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER, self.Outline, self.OutlineColorC)
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
end

pac.RegisterPart(PART)