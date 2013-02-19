pac.OwnerNames =
{
	"self",
	"active vehicle",
	"active weapon",
}

local function find_ent(ent, str)
	return 
		pac.StringFind(ent:GetClass(), str) or 
		pac.StringFind(ent:GetClass(), str, true) or 
		
		(ent.GetName and pac.StringFind(ent:GetName(), str)) or 
		(ent.GetName and pac.StringFind(ent:GetName(), str, true)) or 
		
		pac.StringFind(ent:GetModel(), str) or 
		pac.StringFind(ent:GetModel(), str, true) 
end

local function check_owner(a, b)
	return a:GetOwner() == b or (not b.CPPIGetOwner or b:CPPIGetOwner() == a or b:CPPIGetOwner() == true)
end

function pac.CalcEntityCRC(ent)
	local pos = ent:GetPos()
	local ang = ent:GetAngles()
	local mdl = ent:GetModel():lower():gsub("\\", "/")
	local x,y,z = math.Round(pos.x/10)*10, math.Round(pos.y/10)*10, math.Round(pos.z/10)*10
	local p,_y,r = math.Round(ang.p/10)*10, math.Round(ang.y/10)*10, math.Round(ang.r/10)*10

	local crc = x .. y .. z .. p .. _y .. r .. mdl

	return util.CRC(crc)
end

function pac.HandleOwnerName(owner, name, ent, part)
	local idx = tonumber(name)
	if idx then
		local ent = Entity(idx)
		
		if ent:IsValid() then
			if owner:IsValid() and owner.GetViewModel and ent == owner:GetViewModel() then
				part:SetOwnerName("viewmodel")
				return	ent
			end
			
			if ent == pac.LocalPlayer then
				part:SetOwnerName("self")
				return ent
			end
		
			if ent.GetPersistent and ent:GetPersistent() then
				part:SetOwnerName("persist " .. pac.CalcEntityCRC(ent))
			end
		
			return ent
		end		
		return NULL
	end

	if name == "self" then
		return owner
	end
	
	if name == "active weapon" then
		return owner:IsValid() and owner.GetActiveWeapon and owner:GetActiveWeapon()
	end
	
	if name == "active vehicle" then
		return owner:IsValid() and owner.GetVehicle and owner:GetVehicle()
	end
	
	if name == "viewmodel" then
		return owner:IsValid() and owner.GetViewModel and owner:GetViewModel()
	end
	
	if name:find("persist ", nil, true) then
		local crc = name:match("persist (.+)")
		for key, ent in pairs(ents.GetAll()) do
			if ent.GetPersistent and ent:GetModel() and ent:GetPersistent() and crc == pac.CalcEntityCRC(ent) then
				return ent
			end
		end
	end
	
	if IsValid(ent) then
		if check_owner(ent, owner) and find_ent(ent, name) then
			return ent
		end
	end
	
	for key, ent in pairs(ents.GetAll()) do
		if ent:IsValid() and check_owner(ent, owner) and find_ent(ent, name) then
			return ent
		end
	end

	return NULL
end