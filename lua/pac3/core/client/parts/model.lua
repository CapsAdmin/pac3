local PART = {}

PART.ClassName = "model"
PART.ManualDraw = true

pac.StartStorableVars()
	pac.GetSet(PART, "BoneMerge", false)
	pac.GetSet(PART, "BoneMergeAlternative", false)
	pac.GetSet(PART, "Skin", 0)
	pac.GetSet(PART, "Fullbright", false)
	pac.GetSet(PART, "Invert", false)
	pac.GetSet(PART, "DoubleFace", false)
	pac.GetSet(PART, "Bodygroup", 0)
	pac.GetSet(PART, "BodygroupState", 0)
	pac.GetSet(PART, "Material", "")
	pac.GetSet(PART, "Color", Vector(255, 255, 255))
	pac.GetSet(PART, "Brightness", 1)
	pac.GetSet(PART, "CellShade", 0)
	pac.GetSet(PART, "Alpha", 1)
	pac.GetSet(PART, "Scale", Vector(1,1,1))
	pac.GetSet(PART, "Size", 1)
	pac.GetSet(PART, "OverallSize", 1)
	pac.GetSet(PART, "OriginFix", false)
	pac.GetSet(PART, "Model", "models/dav0r/hoverball.mdl")
	pac.GetSet(PART, "OwnerEntity", false)
pac.EndStorableVars()

function PART:SetOverallSize(num)
	if self.Entity:IsValid() then
		if num ~= 1 then
			pac.HookBuildBone(self.Entity)
			self.Entity.pac_part_ref = self
		else
			self.Entity.pac_part_ref = nil
		end
	end
	
	self.OverallSize = num
end

PART.Colorf = Vector(1,1,1)

pac.GetSet(PART, "Entity", NULL)

function PART:GetEntity()
	self.Entity = self.Entity:IsValid() and self.Entity or pac.CreateEntity(self:GetModel())
	return self.Entity
end

function PART:Initialize()
	self.ClipPlanes = {}
	
	self.Color = self.Color * 1
	self.Scale = self.Scale * 1
	
	self.Entity = self:GetEntity()
	self.Entity:SetNoDraw(true)
	--[[self.Entity:SetRenderMode(RENDERMODE_NONE)
	self.Entity:AddEffects(EF_NOINTERP)
	self.Entity:AddEffects(EF_NOSHADOW)
	self.Entity:AddEffects(EF_NODRAW)
	self.Entity:AddEffects(EF_NORECEIVESHADOW)
	self.Entity:AddEFlags(EFL_NO_THINK_FUNCTION)
	self.Entity:DrawShadow(false)
	self.Entity:DestroyShadow()]]
	self.Entity.PACPart = self
end

function PART:GetModelBones()
	local parent = self.RealParent
	if parent and parent.Entity:IsValid() then
		return pac.GetModelBones(parent.Entity)
	else
		return pac.GetModelBones(self:GetOwner())
	end
end

function PART:GetModelBonesSorted()
	local parent = self.RealParent
	if parent and IsValid(parent.Entity) then
		return pac.GetModelBonesSorted(parent.Entity)
	else
		return pac.GetModelBonesSorted(self:GetOwner())
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

function PART:OnAttach(owner)
	local ent = self:GetEntity()
	
	if ent:IsValid() and owner:IsValid() and owner ~= ent then
		ent:SetPos(owner:EyePos())
		ent:SetParent(owner)
		ent:SetOwner(owner)
		self.BoneIndex = nil
	end
end

function PART:OnParent(part)
	local ent = self:GetEntity()
	local owner = self:GetOwner()

	if part.ClassName == self.ClassName and part:GetEntity():IsValid() and owner ~= ent then
		ent:SetParent(self:GetParent():GetEntity())
		ent:SetOwner(self:GetParent():GetEntity())
	elseif owner ~= ent then
		ent:SetParent(owner)
		ent:SetOwner(owner)
	end	
end

function PART:OnUnParent()
	local ent = self:GetEntity()
	
	if ent:IsValid() and owner ~= ent then
		ent:SetParent(self:GetOwner())
		ent:SetOwner(self:GetOwner())
	end
end

function PART:SetOwnerEntity(b)
	local ent = self:GetOwner()
	if ent:IsValid() then
		if b then
			self.Entity = ent
			
			function ent.RenderOverride(ent)
				if self:IsValid() then
					if not self.HideEntity then 
						self:PreEntityDraw(ent, ent, ent:GetPos(), ent:GetAngles())
						ent:DrawModel()
						self:PostEntityDraw(ent, ent, ent:GetPos(), ent:GetAngles())
					end
				else
					ent.RenderOverride = nil
				end
			end
		else
			self.Entity = NULL
			
			ent.RenderOverride = nil
			ent:SetModelScale(Vector(1,1,1))
		end
	end
end

local render_EnableClipping = render.EnableClipping
local render_PushCustomClipPlane = render.PushCustomClipPlane
local render_CullMode = render.CullMode
local render_SetColorModulation = render.SetColorModulation
local render_SetBlend = render.SetBlend
local render_MaterialOverride = render.MaterialOverride or SetMaterialOverride
local render_SuppressEngineLighting = render.SuppressEngineLighting
local render_PopCustomClipPlane = render.PopCustomClipPlane
local LocalToWorld = LocalToWorld
local MATERIAL_CULLMODE_CW = MATERIAL_CULLMODE_CW

function PART:PreEntityDraw(owner, ent, pos, ang)	
	
	if not ent:IsPlayer() and pos and ang then
		if self.OriginFix and ent.pac3_center then			
			local pos, ang = LocalToWorld(
				ent.pac3_center * self.Scale * -self.Size, 
				Angle(0,0,0), 
				
				pos, 
				ang
			)
			ent:SetPos(pos)
			ent:SetAngles(ang)
		else		
			ent:SetPos(pos)
			ent:SetAngles(ang)
		end
	end
			
	ent:SetupBones()
	
	local bclip
	
	if #self.ClipPlanes > 0 then
		bclip = render_EnableClipping(true)

		for key, clip in pairs(self.ClipPlanes) do
			if clip:IsValid() and not clip:IsHidden() then
				local pos, ang = clip:GetBonePosition()
				pos, ang = LocalToWorld(clip.Position, clip:CalcAngles(owner, clip.Angles), pos, ang)
				local normal = ang:Forward()
				render_PushCustomClipPlane(normal, normal:Dot(pos + normal))
			end
		end
	end			
	if self.DoubleFace then
		render_CullMode(MATERIAL_CULLMODE_CW)
	else
		if self.Invert then
			render_CullMode(MATERIAL_CULLMODE_CW)
		end
	end

	if self.Colorf then 
		render_SetColorModulation(self.Colorf.r * self.Brightness, self.Colorf.g * self.Brightness, self.Colorf.b * self.Brightness) 
	end
	
	if self.Alpha then render_SetBlend(self.Alpha) end
	
	render_MaterialOverride(self.Materialm) 

	if self.Fullbright then
		render_SuppressEngineLighting(true) 
	end
	
end

local MATERIAL_CULLMODE_CCW = MATERIAL_CULLMODE_CCW
local WHITE = Material("models/debug/debugwhite")

function PART:PostEntityDraw(owner, ent, pos, ang)
		
	if self.DoubleFace then
		render_CullMode(MATERIAL_CULLMODE_CCW)
		self:DrawModel(ent, pos, ang)
	else
		if self.Invert then
			render_CullMode(MATERIAL_CULLMODE_CCW)
		end
	end
		
	if self.Fullbright then
		render_SuppressEngineLighting(false) 
	end
	
	if self.CellShade > 0 then
		render_CullMode(MATERIAL_CULLMODE_CW)
			ent:SetModelScale((self.Scale * self.Size) * (1 + self.CellShade))
				render_SetColorModulation(0,0,0)
					render_SuppressEngineLighting(true)
					render_MaterialOverride(WHITE)
						
						ent:SetupBones()
						self:DrawModel(ent, pos, ang)
						
					render_MaterialOverride()
					render_SuppressEngineLighting(false)
			ent:SetModelScale(self.Scale * self.Size)
		render_CullMode(MATERIAL_CULLMODE_CCW)
	end
	
	render_SetColorModulation(1,1,1)
	render_SetBlend(1)
	
	render_MaterialOverride()
	
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

local render_SetMaterial = render.SetMaterial

function PART:OnDraw(owner, pos, ang)
	local ent = self.Entity
	
	if ent:IsValid() then
		self:CheckBoneMerge()
	
		self:PreEntityDraw(owner, ent, pos, ang)
		
		self:DrawModel(ent, pos, ang)
		
		self:PostEntityDraw(owner, ent, pos, ang)
	else
		timer.Simple(0, function()
			self.Entity = pac.CreateEntity(self.Model)
			self.Entity:SetNoDraw(true)
			self.Entity.PACPart = self
		end)
	end
end

function PART:DrawModel(ent, pos, ang)
	if self.wavefront_mesh then
		local matrix = Matrix()
		
		if VERSION >= 150 then
			matrix:SetAngles(ang)
		else
			matrix:SetAngle(ang)
		end
		matrix:SetTranslation(pos)
		matrix:Scale(self.Scale * self.Size)
		
		cam.PushModelMatrix(matrix)
			if self.Materialm then 
				render_SetMaterial(self.Materialm)	
			end
			self.wavefront_mesh:Draw()
		cam.PopModelMatrix()
		
		ent:SetModelScale(Vector(0,0,0))
		ent:DrawModel()
		self.wavefront_mesh_hack = true
	else
		if self.wavefront_mesh_hack then
			ent:SetModelScale(self.Scale)
			self.wavefront_mesh_hack = false
		end
		ent:DrawModel()
	end
end

function PART:SetModel(var)
	self.Entity = self:GetEntity()

	if var and var:find("http") and pac.urlobj then
		var = var:gsub("https://", "http://")
		local skip_cache = var:sub(1,1) == "_"
		
		if skip_cache then
			var = var:sub(2)
		end	
		
		pac.urlobj.GetObjFromURL(var, function(mesh, err)
			if not self:IsValid() then return end
			self.Entity = self:GetEntity()
			
			if not mesh and err then
				self.Entity:SetModel("error.mdl")
				self.wavefront_mesh = nil
				return
			end
		
			self.wavefront_mesh = mesh
			self.Entity.pac_bones = nil
			
			if not self.Materialm then
				self.Materialm = Material("error")
			end
			
			-- temp
			self.Entity:SetRenderBounds(Vector()*-300, Vector()*300)	
		end, true, skip_cache)
		
		self.Model = var
		return
	end
	
	self.wavefront_mesh = nil
	
	self.Model = var
	self.Entity.pac_bones = nil
	self.Entity:SetModel(var)
	
	local min, max = self.Entity:GetRenderBounds()
	self.Entity.pac3_center = (min + max) * 0.5
end

function PART:SetScale(var)
	var = var or Vector(1,1,1)

	self.Scale = var
	self.Entity:SetModelScale(self.Scale * self.Size)
end

function PART:SetSize(var)
	var = var or 1

	self.Size = var
	self.Entity:SetModelScale(self.Scale * self.Size)
end

function PART:SetColor(var)
	var = var or Vector()

	self.Color = var
	self.Colorf = (Vector(var.r, var.g, var.b) / 255)
end

function PART:SetMaterial(var)
	var = var or ""
	
	if not pac.HandleUrlMat(self, var) then
		if var ~= "" then
			self.Materialm = Material(var)
			self:CallEvent("material_changed")
		end
	end
	
	self.Material = var
end

function PART:SetBodygroupState(var)
	var = var or 0

	self.BodygroupState = var
	timer.Simple(0, function() 
		if self:IsValid() and self.Entity:IsValid() then
			self.Entity:SetBodygroup(self.Bodygroup, var) 
		end
	end)		
end

function PART:SetBodygroup(var)
	var = var or 0

	self.Bodygroup = var
	timer.Simple(0, function() 
		if self:IsValid() and self.Entity:IsValid() then
			self.Entity:SetBodygroup(var, self.BodygroupState) 
		end
	end)		
end

function PART:SetSkin(var)
	var = var or 0

	self.Skin = var
	self.Entity:SetSkin(var)
end

function PART:OnRemove()
	if not self.OwnerEntity then
		SafeRemoveEntity(self.Entity)
	end
end


function PART:CheckBoneMerge()
	local ent = self.Entity
	if ent:IsValid() and not ent:IsPlayer() then
			
		if ent:GetParent():IsValid() then
			if self.BoneMergeAlternative then	
				pac.HookBuildBone(ent)
				ent.pac_part_ref = self
			end
			
			if self.BoneMerge and not self.BoneMergeAlternative then
				if not ent:IsEffectActive(EF_BONEMERGE) then
					ent:AddEffects(EF_BONEMERGE)
				end
			else
				if ent:IsEffectActive(EF_BONEMERGE) then
					ent:RemoveEffects(EF_BONEMERGE)
				end
			end
		else	
			local owner = self:GetOwner()
			if owner:IsValid() and owner ~= ent then
				ent:SetParent(owner)
				ent:SetOwner(owner)
			end
		end		
	end
end

local bad_bones = 
{
	["ValveBiped.Bip01_L_Finger0"] = true,
	["ValveBiped.Bip01_L_Finger01"] = true,
	["ValveBiped.Bip01_L_Finger02"] = true, 

	["ValveBiped.Bip01_L_Finger1"] = true,
	["ValveBiped.Bip01_L_Finger11"] = true, 
	["ValveBiped.Bip01_L_Finger12"] = true,

	["ValveBiped.Bip01_L_Finger2"] = true,
	["ValveBiped.Bip01_L_Finger21"] = true,
	["ValveBiped.Bip01_L_Finger22"] = true,


	["ValveBiped.Bip01_R_Finger0"] = true,
	["ValveBiped.Bip01_R_Finger01"] = true,
	["ValveBiped.Bip01_R_Finger02"] = true,

	["ValveBiped.Bip01_R_Finger1"] = true,
	["ValveBiped.Bip01_R_Finger11"] = true,
	["ValveBiped.Bip01_R_Finger12"] = true,

	["ValveBiped.Bip01_R_Finger2"] = true,
	["ValveBiped.Bip01_R_Finger21"] = true,
	["ValveBiped.Bip01_R_Finger22"] = true,
}

function PART:OnBuildBonePositions(ent)
	local owner = self:GetOwner()
	if owner == ent then return end
	
	if self.BoneMergeAlternative then
		local ent_bones = pac.GetModelBones(ent)
		local owner_bones = pac.GetModelBones(owner)
		
		if ent_bones and owner_bones then
			for friendly, ent_bone in pairs(ent_bones) do
				local owner_bone = owner_bones[friendly]
				
				if owner_bone and not bad_bones[owner_bone.real] then				
					local pos, ang = owner:GetBonePosition(owner_bone.real ~= "ValveBiped.Bip01_Head1" and owner_bone.parent_i or owner_bone.i)
					if pos ~= owner:GetPos() and pos ~= owner:EyePos() then

						if owner_bone.real == "ValveBiped.Bip01_Neck1" then
							pos = vector_origin
						end
						
						if owner_bone.real == "ValveBiped.Bip01_Head1" then	
							local wpos, wang = owner:GetBonePosition(owner_bone.parent_i)							
							local pos, ang = WorldToLocal(pos, ang, wpos, wang)

							local pos2 = ent:GetBonePosition(ent_bone.parent_i)	

							ent:SetBonePosition(ent_bone.i, pos, ang)
							continue
						end
		
						ent:SetBonePosition(ent_bone.parent_i or ent_bone.i, pos, ang)
					end
				end
			end
		end
	end
	
	if self.OverallSize ~= 1 then
		for i = 0, ent:GetBoneCount() do
			local mat = ent:GetBoneMatrix(i)
			if mat then
				mat:Scale(Vector()*self.OverallSize)
				ent:SetBoneMatrix(i, mat)
			end
		end
	end
end

pac.RegisterPart(PART)