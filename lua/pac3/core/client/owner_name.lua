pac.OwnerNames =
{
	"self",
	"viewmodel",
	"active vehicle",
	"active weapon",
	"world",
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

local function check_outfits(ent, part)
	return not ent.pac_outfits-- or not ent.pac_outfits[part.UniqueID]
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

SafeRemoveEntity(pac.WorldEntity)

pac.WorldEntity = NULL

function pac.HandleOwnerName(owner, name, ent, part, check_func)
	local idx = tonumber(name)

	if idx then
		local ent = Entity(idx)

		if ent:IsValid() then
			if owner:IsValid() and owner.GetViewModel and ent == owner:GetViewModel() then
				part:SetOwnerName("viewmodel")
				return ent
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

	if name == "world" or (pac.WorldEntity:IsValid() and ent == pac.WorldEntity) then
		if not pac.WorldEntity:IsValid() then
			local ent = pac.CreateEntity("error.mdl")

			ent:SetPos(Vector(0,0,0))

			-- go away ugh
			ent:SetModelScale(0,0)

			ent.IsPACWorldEntity = true

			pac.WorldEntity = ent
		end

		return pac.WorldEntity
	end

	if name == "self" then
		return owner
	end

	if owner:IsValid() then
		if name == "active weapon" and owner.GetActiveWeapon and owner:GetActiveWeapon():IsValid() then
			return owner:GetActiveWeapon()
		end

		if name == "active vehicle" and owner.GetVehicle and owner:GetVehicle():IsValid() then
			return owner:GetVehicle()
		end

		if name == "viewmodel" and owner.GetViewModel then
			return owner:GetViewModel()
		end
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
		if (not check_func or check_func(ent)) and check_owner(ent, owner) and find_ent(ent, name) then
			return ent
		end
	end

	for key, ent in pairs(ents.GetAll()) do
		if ent:IsValid() and (not check_func or check_func(ent)) and check_owner(ent, owner) and find_ent(ent, name) then
			return ent
		end
	end

	return NULL
end