pac.OwnerNames = {
	"self",
	"viewmodel",
	"hands",
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

local function calc_entity_crc(ent)
	local pos = ent:GetPos()
	local ang = ent:GetAngles()
	local mdl = ent:GetModel():lower():gsub("\\", "/")
	local x, y, z = math.Round(pos.x / 10) * 10, math.Round(pos.y / 10) * 10, math.Round(pos.z / 10) * 10
	local p, _y, r = math.Round(ang.p / 10) * 10, math.Round(ang.y / 10) * 10, math.Round(ang.r / 10) * 10

	local crc = x .. y .. z .. p .. _y .. r .. mdl

	return pac.Hash(crc)
end

SafeRemoveEntity(pac.WorldEntity)

pac.WorldEntity = NULL

function pac.GetWorldEntity()
	if not pac.WorldEntity:IsValid() then
		local ent = pac.CreateEntity("models/error.mdl")

		ent:SetPos(Vector(0,0,0))

		-- go away ugh
		ent:SetModelScale(0,0)

		ent.IsPACWorldEntity = true

		pac.WorldEntity = ent
	end

	return pac.WorldEntity
end

function pac.HandleOwnerName(owner, name, ent, part, check_func)
	local idx = tonumber(name)

	if idx then
		ent = Entity(idx)

		if ent:IsValid() then
			if owner:IsValid() and owner.GetViewModel and ent == owner:GetViewModel() then
				part:SetOwnerName("viewmodel")
				return ent
			end

			if owner:IsValid() and owner.GetHands and ent == owner:GetHands() then
				part:SetOwnerName("hands")
				return ent
			end

			if ent == pac.LocalPlayer then
				part:SetOwnerName("self")
				return ent
			end

			if ent.GetPersistent and ent:GetPersistent() then
				part:SetOwnerName("persist " .. calc_entity_crc(ent))
			end

			return ent
		end

		return pac.GetWorldEntity()
	end

	if name == "world" or name == "worldspawn" then
		return pac.GetWorldEntity()
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

		if name == "hands" and owner == pac.LocalPlayer and pac.LocalHands:IsValid() then
			return pac.LocalHands
		end

		if name == "hands" and owner.GetHands then
			return owner:GetHands()
		end

		if name == "viewmodel" and owner.GetViewModel then
			return owner:GetViewModel()
		end

		if IsValid(ent) and (not check_func or check_func(ent)) and check_owner(ent, owner) and find_ent(ent, name) then
			return ent
		end

		for _, val in pairs(ents.GetAll()) do
			if val:IsValid() and (not check_func or check_func(val)) and check_owner(val, owner) and find_ent(val, name) then
				return val
			end
		end
	end

	if name:find("persist ", nil, true) then
		local crc = name:match("persist (.+)")
		for _, val in pairs(ents.GetAll()) do
			if val.GetPersistent and val:GetModel() and val:GetPersistent() and crc == calc_entity_crc(val) then
				return val
			end
		end
	end

	return NULL
end
