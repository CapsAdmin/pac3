pac.ServerModifiers = {}

function pac.AddServerModifier(id, func)
	pac.ServerModifiers[id] = func
end

function pac.GetServerModifiers()
	return pac.ServerModifiers
end

function pac.HandleModifiers(data, owner)
	for key, func in pairs(pac.GetServerModifiers()) do
		func(data, owner)
	end
end

pac.ModifiersPath = "pac3/core/shared/modifiers/"

function pac.LoadModifiers()
	local files = file.Find(pac.ModifiersPath .. "*", "LUA")
	
	for key, val in pairs(files) do
		local name = val:match("(.-)%.")
		
		if SERVER then
			CreateConVar("pac_modifier_" .. name, 1, bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE))
		end
		
		if CLIENT then
			CreateClientConVar("pac_modifier_" .. name, 1, true, true)
		end
		
		include(pac.ModifiersPath .. val)
	end
end

pac.LoadModifiers()