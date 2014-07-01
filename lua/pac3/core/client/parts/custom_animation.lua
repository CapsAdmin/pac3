local PART = {}

PART.ClassName = "custom_animation"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
pac.EndStorableVars()

function PART:GetNiceName()
	return pac.PrettifyName(("/".. self:GetURL()):match(".+/(.-)%.")) or "no anim"
end

function PART:GetAnimID()
	return "pac_anim_" .. self:GetUniqueID()
end

function PART:SetURL(url)
		self.URL = url
		
		if url:find("http") then
			http.Fetch(url, function(str,len,hdr,code)
				if not str or code~=200 then 
					Msg"[PAC] Animation failed to load from "print(url)
					return
				end
				local tbl = util.JSONToTable(str)
				if not tbl then 
					Msg"[PAC] Animation failed to parse from "print(url)
					return
				end
				RegisterLuaAnimation(self:GetAnimID(), tbl)
			end, function() return end) --should do nothing on invalid/inaccessible URL
		end
end

function PART:OnShow(owner)
	--play animation
	local owner = self:GetOwner()
	--local parent = self:GetParent()
	
	if not GetLuaAnimations()[self:GetAnimID()] then
		self:SetURL(self:GetURL())
	end
	
	--[[if parent:IsValid() and parent.ClassName == "model" and parent.Entity:IsValid() then
		print("Trying to run anim on Entity "..tostring(parent.Entity:EntIndex()).."!")
		parent.Entity:SetLuaAnimation(self:GetAnimID())
	else]]if owner:IsValid() then
		owner:SetLuaAnimation(self:GetAnimID())
	end
end

function PART:OnHide()
	--stop animation
	local owner = self:GetOwner()
	--local parent = self:GetParent()
	
	--[[if parent:IsValid() and parent.ClassName == "model" and parent.Entity:IsValid() then
		if GetLuaAnimations()[self:GetAnimID()] then
			print("Trying to stop anim on Entity "..tostring(parent.Entity:EntIndex()).."!")
			parent.Entity:StopLuaAnimation(self:GetAnimID())
		end
		print("Trying to reset bones on Entity "..tostring(parent.Entity:EntIndex()).."!")
		parent.Entity:ResetBoneMatrix()
	else]]if owner:IsValid() then
		if GetLuaAnimations()[self:GetAnimID()] then
			owner:StopLuaAnimation(self:GetAnimID())
		end
		owner:ResetBoneMatrix()
	end
end

function PART:OnRemove() 
	local owner = self:GetOwner()

	if owner:IsValid() then
		owner:ResetBoneMatrix()
	end
	
	GetLuaAnimations()[self:GetAnimID()] = nil
end

pac.RegisterPart(PART)
