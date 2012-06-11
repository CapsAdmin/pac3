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
		pac.GetSet(self, "Material", "")
		pac.GetSet(self, "Color", Vector(255, 255, 255))
		pac.GetSet(self, "Brightness", 1)
		pac.GetSet(self, "Alpha", 1)
		pac.GetSet(self, "Scale", Vector(1,1,1))
		pac.GetSet(self, "Size", 1)
		pac.GetSet(self, "Model", "")
		pac.GetSet(self, "DrawWeapon", true)
	pac.EndStorableVars()
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

function PART:StartClipping(pos, ang)
	if #self.ClipPlanes > 0 then
		bclip = render.EnableClipping(true)

		for key, clip in pairs(self.ClipPlanes) do
			if clip:IsValid() then
				local pos, ang = LocalToWorld(clip.Position, clip:CalcAngleVelocity(clip.Angles), pos, ang)
				local normal = ang:Forward()
				render.PushCustomClipPlane(normal, normal:Dot(pos + normal))
			end
		end
	end
end

function PART:EndClipping()
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

function PART:UpdateScale(owner)	
	owner:InvalidateBoneCache()
	owner:SetModelScale(self.Scale * self.Size)
	owner:SetupBones()
	print(self.Scale, self.Size)
end

function PART:SetSize(var)
	self.Size = var
	self:UpdateScale(self:GetOwner())
end

function PART:SetScale(var)	
	self.Scale = var
	self:UpdateScale(self:GetOwner())
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


function PART:GetModel()
	local owner = self:GetOwner()

	if owner:IsValid() and (not self.Model or self.Model == "") then
		return owner:GetModel()
	end
	
	return self.Model
end

function PART:SetModel(path)
	local owner = self:GetOwner()
	
	if path == "" and owner.pac_original_model then
		owner:SetModel(owner.pac_original_model)
	end

	if owner:IsValid() then
		owner.pac_original_model = owner.pac_original_model or owner:GetModel()
		owner:SetModel(path)
	end
	
	self.Model = path
end

function PART:UpdateWeaponDraw(owner)
	local wep = owner.GetActiveWeapon and owner:GetActiveWeapon() or NULL
	
	if wep:IsWeapon() then
		pac.HideWeapon(wep, not self.DrawWeapon)
	end
end

function PART:UpdateColor(owner)
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

function PART:UpdateMaterial(owner)
	if self.Material ~= "" then
		if net then
			render.MaterialOverride(self.Materialm)
		else
			SetMaterialOverride(self.Materialm)
		end
	end
end

function PART:UpdateAll(owner)
	--self:UpdateScale(owner)
	self:UpdateMaterial(owner)
	self:UpdateColor(owner)
end

function PART:OnDetach(ent)
	if not ent:IsPlayer() then
		ent:SetNoDraw(false)
		if ent.pac_original_model then
			ent:SetModel(ent.pac_original_model)
		end
	end	
end

function PART:PreDraw(owner, pos, ang)
	if not owner:IsPlayer() then
		owner:SetNoDraw(true)
	end	

	self:StartClipping(pos, ang)
	
	self:UpdateAll(owner)	
end

function PART:OnDraw(owner, pos, ang)	
	if not owner:IsPlayer() then
		owner:DrawModel()
	end
	
	render.SetBlend(1)
	render.SetColorModulation(1,1,1)
	
	if net then
		render.MaterialOverride()
	else
		SetMaterialOverride(0)
	end

	self:EndClipping()
	self:UpdateWeaponDraw(owner)
end

pac.RegisterPart(PART)