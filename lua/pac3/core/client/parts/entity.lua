local PART = {}

PART.ClassName = "entity"	
PART.HideGizmo = true

function PART:Initialize()
	self.ClipPlanes = {}
	
	self.StorableVars = {}

	pac.StartStorableVars()
		pac.GetSet(self, "Name", "")
		pac.GetSet(self, "Description", "")
		pac.GetSet(self, "Hide", false)
		pac.GetSet(self, "ParentName", "")
		pac.GetSet(self, "Material", "")
		pac.GetSet(self, "Model", "")
		pac.GetSet(self, "Color", Vector(255, 255, 255))
		pac.GetSet(self, "Brightness", 1)
		pac.GetSet(self, "Alpha", 1)
		pac.GetSet(self, "Scale", Vector(1,1,1))
		pac.GetSet(self, "Size", 1)
		pac.GetSet(self, "OverallSize", 1)
		pac.GetSet(self, "HideEntity", false)
		pac.GetSet(self, "Invert", false)
		pac.GetSet(self, "DoubleFace", false)
		pac.GetSet(self, "DrawWeapon", true)
		pac.GetSet(self, "Fullbright", false)
		
		pac.GetSet(self, "RelativeBones", true)
			
		pac.GetSet(self, "Skin", 0)
		pac.GetSet(self, "Bodygroup", 0)
		pac.GetSet(self, "BodygroupState", 0)
		pac.GetSet(self, "DrawShadow", true)
	pac.EndStorableVars()
end

function PART:OnBuildBonePositions(ent)
	if self.OverallSize ~= 1 then
		for i = 0, ent:GetBoneCount() do
			local mat = ent:GetBoneMatrix(i)
			if mat then
				mat:Scale(Vector() * self.OverallSize)
				
				ent:SetBoneMatrix(i, mat)
			end
		end
	end
end

function PART:SetDrawShadow(b)
	self.DrawShadow = b

	local ent = self:GetOwner()
	if ent:IsValid() then
		ent:DrawShadow(b)
	end
end

function PART:SetDrawShadow(b)
	self.DrawShadow = b

	local ent = self:GetOwner()
	if ent:IsValid() then
		ent:DrawShadow(b)
	end
end

function PART:SetBodygroupState(var)
	var = var or 0

	self.BodygroupState = var
	
	local ent = self:GetOwner()
	timer.Simple(0, function() 
		if self:IsValid() and ent:IsValid() then
			ent:SetBodygroup(self.Bodygroup, var) 
		end
	end)		
end

function PART:SetBodygroup(var)
	var = var or 0

	self.Bodygroup = var
	
	local ent = self:GetOwner()
	timer.Simple(0, function() 
		if self:IsValid() and ent:IsValid() then
			ent:SetBodygroup(var, self.BodygroupState) 
		end
	end)		
end

function PART:SetSkin(var)
	var = var or 0

	self.Skin = var

	local ent = self:GetOwner()
	if ent:IsValid() then
		ent:SetSkin(var)
	end
end

function PART:AddClipPlane(part)
	return table.insert(self.ClipPlanes, part)
end

function PART:RemoveClipPlane(id)
	local part = self.ClipPlanes[id]
	if part then
		table.remove(self.ClipPlanes, id)
		part:Remove()
	end
end

local render_EnableClipping = render.EnableClipping 
local render_PushCustomClipPlane = render.PushCustomClipPlane
local LocalToWorld = LocalToWorld
local bclip 

function PART:StartClipping(owner)	
	bclip = nil
	
	if #self.ClipPlanes > 0 then
		bclip = render_EnableClipping(true)

		for key, clip in pairs(self.ClipPlanes) do
			if clip:IsValid() and not clip:IsHidden() then
				local pos, ang = clip:GetDrawPosition(owner)
				pos, ang = LocalToWorld(clip.Position, clip:CalcAngles(owner, clip.Angles), pos, ang or Angle(0))
				local normal = ang:Forward()
				render_PushCustomClipPlane(normal, normal:Dot(pos + normal))
			end
		end
	end
end

local render_PopCustomClipPlane = render.PopCustomClipPlane

function PART:EndClipping()
	if #self.ClipPlanes > 0 then
		for key, clip in pairs(self.ClipPlanes) do
			if not clip:IsValid() then
				self.ClipPlanes[key] = nil
			end
			if not clip:IsHidden() then
				render_PopCustomClipPlane()
			end
		end

		render_EnableClipping(bclip)
	end
end

function PART:UpdateScale(ent)
	ent = ent or self:GetOwner()
	if ent:IsValid() then		
		if VERSION >= 150 then 
			ent:SetIK(not self.RelativeBones) 
		end
		
		if self.OverallSize ~= 1 and not self.setup_overallscale then
			pac.HookBuildBone(ent)
			self.setup_overallscale = true
		end
		
		local scale = self.Scale * self.Size
		
		if scale ~= ent:GetModelScale() then
			ent:SetModelScale(scale)
		end
	end
end

function PART:SetSize(var)
	self.Size = var
	self:UpdateScale()
end

function PART:SetScale(var)	
	self.Scale = var
	self:UpdateScale()
end

PART.Colorf = Vector(1,1,1)

function PART:SetColor(var)
	var = var or Vector(255, 255, 255)

	self.Color = var
	self.Colorf = Vector(var.r, var.g, var.b) / 255
	
	self.Colorc = self.Colorc or Color(var.r, var.g, var.b, self.Alpha)
	self.Colorc.r = var.r
	self.Colorc.g = var.g
	self.Colorc.b = var.b
end

function PART:SetAlpha(var)
	self.Alpha = var
	
	self.Colorc = self.Colorc or Color(self.Color.r, self.Color.g, self.Color.b, self.Alpha)
	self.Colorc.a = var
end

function PART:SetMaterial(var)
	var = var or ""

	if pac.urlmat and var:find("http") then
		var = var:gsub("https://", "http://")
		var = var:match("http[s]-://.+/.-%.%a+")
		if var then
			pac.urlmat.GetMaterialFromURL(var, function(mat)
				if self:IsValid() then
					self.Materialm = mat
					self:CallEvent("material_changed")
				end
			end)
			self.Material = var
			return
		end
	end	
	
	self.Material = var
	
	if var ~= "" then
		self.Materialm = Material(var)
		self:CallEvent("material_changed")
	end
end

function PART:SetRelativeBones(b)
	self.RelativeBones = b
	local ent = self:GetOwner()
	if ent:IsValid() then
		self:UpdateScale(ent)
	end
end

function PART:SetDrawWeapon(b)
	self.DrawWeapon = b
	self:UpdateWeaponDraw(self:GetOwner())
end

function PART:UpdateWeaponDraw(ent)
	local wep = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
	
	if wep:IsWeapon() then
		pac.HideWeapon(wep, not self.DrawWeapon)
	end
end

local render_CullMode = render.CullMode
local render_SuppressEngineLighting = render.SuppressEngineLighting
local render_SetBlend = render.SetBlend
local render_SetColorModulation = render.SetColorModulation
local render_MaterialOverride = render.MaterialOverride or SetMaterialOverride

function PART:UpdateColor(ent)

	render_SetColorModulation(self.Colorf.r * self.Brightness, self.Colorf.g * self.Brightness, self.Colorf.b * self.Brightness)
	render_SetBlend(self.Alpha)
	
	if self.Colorc then
		if VERSION >= 150 then 
			ent:SetColor(self.Colorc)
		else
			ent:SetColor(unpack(self.Colorc))
		end
	end
end

function PART:UpdateMaterial(ent)
	if self.Material ~= "" then
		render_MaterialOverride(self.Materialm)
	end
end

function PART:UpdateAll(ent)
	self:UpdateColor(ent)
	self:UpdateMaterial(ent)
	self:UpdateScale(ent)
end

function PART:OnAttach(ent)
	if ent:IsValid() then

		if ent:IsPlayer() and ent == LocalPlayer() then
			RunConsoleCommand("cl_playermodel", self.Model)
		else
			ent:SetModel(self.Model)
		end
	
		function ent.RenderOverride(ent)
			if self:IsValid() then
				if not self.HideEntity then 
					self:PreEntityDraw(ent)
					ent:DrawModel()
					self:PostEntityDraw(ent)
				end
			else
				ent.RenderOverride = nil
			end
		end
	end	
end

function PART:OnDetach(ent)
	if ent:IsValid() then
		ent.RenderOverride = nil
		
		ent:SetModelScale(Vector(1,1,1))
		
		local weps = ent.GetWeapons and ent:GetWeapons()
		
		if weps then
			for key, wep in pairs(weps) do
				pac.HideWeapon(wep, false)
			end
		end
	end
end

local aaa = false

function PART:GetDrawPosition()
	local ent = self:GetOwner()

	if ent:IsValid() then
		return ent:GetPos()
	end
end

function PART:PreEntityDraw(ent)
	self:UpdateWeaponDraw(ent)
	self:StartClipping(ent)
	
	self:UpdateAll(ent)

	if self.Invert then
		render_CullMode(1) -- MATERIAL_CULLMODE_CW
	end

	if self.Fullbright then
		render_SuppressEngineLighting(true) 
	end
end

function PART:PostEntityDraw(ent)	
	
	if self.Invert then
		render_CullMode(0) -- MATERIAL_CULLMODE_CCW
	end
	
	if self.Fullbright then
		render_SuppressEngineLighting(false) 
	end
	
	render_SetBlend(1)
	render_SetColorModulation(1,1,1)
	
	render_MaterialOverride()

	self:EndClipping(bclip)
end

pac.RegisterPart(PART)