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
		pac.GetSet(self, "Color", Vector(255, 255, 255))
		pac.GetSet(self, "Brightness", 1)
		pac.GetSet(self, "Alpha", 1)
		pac.GetSet(self, "Scale", Vector(1,1,1))
		pac.GetSet(self, "Size", 1)
		pac.GetSet(self, "OverallSize", 1)
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

function PART:StartClipping(pos, ang)
	if #self.ClipPlanes > 0 then
		local bclip = render.EnableClipping(true)

		for key, clip in pairs(self.ClipPlanes) do
			if clip:IsValid() then
				local pos, ang = LocalToWorld(clip.Position, clip:CalcAngles(clip.Angles), pos, ang)
				local normal = ang:Forward()
				render.PushCustomClipPlane(normal, normal:Dot(pos + normal))
			end
		end
		
		return bclip
	end
end

function PART:EndClipping(bclip)
	if #self.ClipPlanes > 0 then
		for key, clip in pairs(self.ClipPlanes) do
			if not clip:IsValid() then
				table.remove(key, self.ClipPlanes)
			end
			render.PopCustomClipPlane()
		end

		render.EnableClipping(bclip)
	end
end

function PART:UpdateScale(ent)
	ent = ent or self:GetOwner()
	if ent:IsValid() then		
		if net then 
			ent:SetIK(not self.RelativeBones) 
		end
		
		if self.OverallSize ~= 1 and not self.setup_overallscale then
			pac.HookBuildBone(ent)
			self.pac3_bonebuild_ref = ent
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
	self.Colorf = (Vector(var.r, var.g, var.b) / 255)
end

function PART:SetMaterial(var)
	var = var or ""

	self.Material = var
	
	if var ~= "" then
		self.Materialm = Material(var)
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

function PART:UpdateColor(ent)
	if 
		self.Brightness ~= 1 or
		self.Colorf.r == 1 or 
		self.Colorf.g == 1 or
		self.Colorf.b == 1
	then
		render.SetColorModulation(self.Colorf.r * self.Brightness, self.Colorf.g * self.Brightness, self.Colorf.b * self.Brightness)
	end
	if self.Alpha ~= 1 then 
		render.SetBlend(self.Alpha)
	end
end

function PART:UpdateMaterial(ent)
	if self.Material ~= "" then
		if net then
			render.MaterialOverride(self.Materialm)
		else
			SetMaterialOverride(self.Materialm)
		end
	end
end

function PART:UpdateAll(ent)
	self:UpdateMaterial(ent)
	self:UpdateColor(ent)
	self:UpdateScale(ent)
end

function PART:OnAttach(ent)
	if not ent:IsPlayer() then
		ent:SetNoDraw(true)
	end	
end

function PART:OnDetach(ent)
	if not ent:IsPlayer() then
		ent:SetNoDraw(false)
	end	
	
	ent:SetModelScale(Vector(1,1,1))
	ent:SetupBones()
end

local aaa = false

function PART:GetDrawPosition()
	local ent = self:GetOwner()

	if ent:IsValid() then
		return ent:GetPos()
	end
end

local bclip

function PART:PreDraw(ent, pos, ang)
	--bclip = self:StartClipping(pos, ang)
	
	self:UpdateAll(ent)

	if self.Invert then
		render.CullMode(MATERIAL_CULLMODE_CW)
	end

	if self.Fullbright then
		render.SuppressEngineLighting(true) 
	end
end

function PART:OnDraw(ent, pos, ang)	
	if ent:IsValid() and not ent:IsPlayer() then
		ent:DrawModel()
	end
	
	if self.Invert then
		render.CullMode(MATERIAL_CULLMODE_CCW)
	end
	
	if self.Fullbright then
		render.SuppressEngineLighting(false) 
	end
	
	render.SetBlend(1)
	render.SetColorModulation(1,1,1)
	
	if net then
		render.MaterialOverride()
	else
		SetMaterialOverride(0)
	end

	--if bclip ~= nil then 
		--self:EndClipping(bclip)
		--bclip = nil
	--end
end

pac.RegisterPart(PART)