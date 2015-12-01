local PART = {}

PART.ClassName = "submaterial"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "Material", "")
	pac.GetSet(PART, "SubMaterialId", 0)
	pac.GetSet(PART, "RootOwner", false)
pac.EndStorableVars()

function PART:TranslatePropertiesKey(key)
	if key and key:lower() == "submaterialid" then
		return "submaterialid"
	end
end

function PART:GetSubMaterialIdList()
	local out = {}
	
	local ent = self:GetOwner(self.RootOwner)
	
	if ent:IsValid() and ent.GetMaterials and #ent:GetMaterials() > 0 then
		out = ent:GetMaterials()
	end
	
	return out
end

function PART:UpdateSubMaterialId(id, material)
	local ent = self:GetOwner(self.RootOwner)
	--print("UpdateSubMaterialId",ent,id,material)
	
	if ent:IsValid() and ent.GetMaterials then	
		ent.pac_submaterials = ent.pac_submaterials or {}
		
		id = id or self.SubMaterialId
		local mat = self.Materialm
		if not material and self.Material and self.Material~="" and mat and not mat:IsError() then
			
			mat = mat:GetName()
			
			local has_slash = mat:find("/",1,true)
			--if has_slash then
			--	--print("\tSlash on self.Materialm?",mat)
			--end
			material = has_slash and mat or '!'..mat
		end
			
		material = material or self.Material or ""
			
		--print("\t Now: ",ent,id,material)
		
		if type(id) == "number" and id > 0 then -- and ent:GetMaterials()[id] then
			ent.pac_submaterials[id] = material
			ent:SetSubMaterial(id-1, material)
			--print("\t -> APPLY: ",ent,id-1,material)
		end
	end
end

function PART:SetSubMaterialId(num)
	self:UpdateSubMaterialId(self.SubMaterialId,"")

	self.SubMaterialId = num
	self:UpdateSubMaterialId()
end



function PART:FixMaterial()
	local mat = self.Materialm
	
	if not mat then return end
	
	local shader = mat:GetShader()
	
	if shader == "UnlitGeneric" then
		--print("=== FixMaterial ===")
		
		local tex_path = mat:GetString("$basetexture")
		
		if tex_path then		
			local params = {}
			
			params["$basetexture"] = tex_path
			params["$vertexcolor"] = 1
			params["$additive"] = 1
			
			self.Materialm = CreateMaterial(pac.uid"pac_fixmat_", "VertexLitGeneric", params)
		end		
	end
end

function PART:UrlTextHandler()
	return function(...)
		return self:Handleurltex(...)
	end
end

function PART:Handleurltex(mat,tex)
	
	if not mat or mat:IsError() or tex:IsError() then self.Materialm=nil return end
	
	self.Materialm = mat
	self:CallEvent("material_changed")
	
	self:UpdateSubMaterialId()
	
end

function PART:SetMaterial(var)
	var = var or ""
	
	if not pac.Handleurltex(self, var,self:UrlTextHandler()) then
		if var == "" then
			self.Materialm = nil
		else			
			self.Materialm = pac.Material(var, self)
			--print("pac.Material IsError",self.Materialm:IsError(),self.Materialm:GetName(),self.Materialm:GetShader())
			self:FixMaterial()
			self:CallEvent("material_changed")
		end
	end
		
	self.Material = var
	
	self:UpdateSubMaterialId()
end

function PART:OnShow()
	local ent = self:GetOwner(self.RootOwner)
	
	if ent:IsValid() then
		self:UpdateSubMaterialId()
	end
end

function PART:OnHide(force)
	if self.DefaultOnHide or force then
		self:UpdateSubMaterialId(nil, "")
	end
end

function PART:OnRemove()
	--print("OnRemove",self:GetOwner())
	self:OnHide(true)
end



function PART:OnUnParent(part)
	if not part:IsValid() then return end
	self:OnHide(true)
end

function PART:Clear()
	--print("CLEAR",self:GetOwner())
	self:RemoveChildren()
	self:UpdateSubMaterialId(nil, "")
end

pac.RegisterPart(PART)

hook.Add("pac_EditorPostConfig","submaterial",function()
	pace.PartTree.entity.submaterial = true
	pace.PartIcons.submaterial = "icon16/picture_edit.png"
end)
