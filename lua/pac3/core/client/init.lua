pac = pac or {}

--include("libraries/profiler.lua")
include("libraries/luadata.lua")
include("libraries/class.lua")
include("libraries/null.lua")

include("libraries/urlmat.lua")
include("libraries/urlobj.lua")

-- no need to rematch the same pattern
pac.PatternCache = {{}}

function pac.LoadParts()
	local files
	
	if file.FindInLua then
		files = file.FindInLua("pac3/core/client/parts/*.lua")
	else
		files = file.Find("pac3/core/client/parts/*.lua", "LUA")
	end
	
	for _, name in pairs(files) do
		include("pac3/core/client/parts/" .. name)
	end
end

function pac.CheckParts()
	for key, part in pairs(pac.ActiveParts) do
		if not part:IsValid() then
			pac.ActiveParts[key] = nil
			pac.MakeNull(part)
		end
	end
end

function pac.RemoveAllPACEntities()
	for key, ent in pairs(ents.GetAll()) do
		if ent.pac_parts then
			pac.UnhookEntityRender(ent)
			--ent:Remove()
		end
		
		if ent.IsPACEntity then
			ent:Remove()
		end
	end
end

function pac.Panic()
	pac.RemoveAllParts()
	pac.RemoveAllPACEntities()
	pac.Parts = {}
end

include("util.lua")
include("parts.lua")

include("bones.lua")
include("hooks.lua")

include("online.lua")
include("wear.lua")
include("contraption.lua")

pac.LoadParts()

include("pac2_compat.lua")

function pac.StringFind(a, b, simple)
	if not a or not b then return end
	
	if simple then
		a = a:lower()
		b = b:lower()
	end
	
	local hash = a..b
	
	if pac.PatternCache[hash] ~= nil then
		return pac.PatternCache[hash]
	end
	
	if simple and a:find(b, nil, true) or not simple and a:find(b) then
		pac.PatternCache[hash] = true
		return true
	else
		pac.PatternCache[hash] = false
		return false
	end
end

function pac.HideWeapon(wep, hide)
	if hide then
		wep:SetNoDraw(true)
		wep.pac_wep_hiding = true
	else
		if wep.pac_wep_hiding then
			wep:SetNoDraw(false)
			wep.pac_wep_hiding = false
		end
	end
end

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
			
			if ent == LocalPlayer() then
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

-- this function adds the unique id of the owner to the part name to resolve name conflicts
-- hack??

function pac.HandlePartName(ply, name)
	if ply:IsPlayer() and ply ~= LocalPlayer() then
		return ply:UniqueID() .. " " .. name
	end
	
	if not ply:IsPlayer() and ply:IsValid() then	
		return pac.CallHook("HandlePartName", ply, name) or (ply:EntIndex() .. " " .. name)
	end

	return name
end

concommand.Add("pac_restart", function()
	if pac then pac.Panic() end
	
	local was_open
	
	if pace then 
		was_open = pace.Editor:IsValid() 
		pace.Panic() 
	end

	pac = {}
	pace = {}
	
	include("autorun/pac_init.lua")
	include("autorun/pace_init.lua")

	if was_open then 
		pace.OpenEditor() 
	end
	
	pace.LoadSession("autoload")
end)