pacx.SpawnedMapEntities = pacx.SpawnedMapEntities or {}

local VEC0 = Vector(0, 0, 0)
local ANG0 = Angle(0, 0, 0)
local VEC1 = Vector(1, 1, 1)

local function tocolor(v, a) return Color(v.x, v.y, v.z, a) end

local function has_clip(part)
	for key, part in pairs(part.children) do
		if part.self.ClassName == "clip" then
			return true
		end
	end

	return false
end

local function set_pos(ent, data, parent)
	local ppos = Vector()
	local pang = Angle()

	if parent:IsValid() then
		ppos = parent:GetPos()
		pang = parent:GetAngles()
	end

	local pos, ang = LocalToWorld((data.Position or VEC0)+ (data.PositionOffset or VEC0), (data.Angles or ANG0) + (data.AngleOffset or ANG0), ppos, pang)

	ent:SetPos(pos)
	ent:SetAngles(ang)
end

local spawn_handlers = {
	model = function(part, parent)
		if
			(not part.self.Alpha or part.self.Alpha ~= 0) and
			(not part.self.Size or part.self.Size ~= 0) and
			(not part.self.Scale or part.self.Scale ~= VEC0)
		then
			SafeRemoveEntity(pacx.SpawnedMapEntities[part.self.UniqueID])

				local ent = ents.Create("prop_dynamic")

				local data = part.self

				ent:SetModel(data.Model or "models/dav0r/hoverball.mdl")

				local c = data.Color

				if c and data.Brightness then
					c = c * data.Brightness
				end

				if data.Color then ent:SetColor(tocolor(c, (data.Alpha or 1) * 255)) end
				if data.Skin then ent:SetSkin(data.Skin) end
				if data.Material then ent:SetMaterial(data.Material) end
				if data.Size then ent:SetModelScale(data.Size, 0) end
				ent:PhysicsInit(SOLID_VPHYSICS)

				set_pos(ent, part.self, parent)

				ent:Spawn()

			pacx.SpawnedMapEntities[part.self.UniqueID] = ent

			return ent
		end
	end,

	light = function(part, parent)

		SafeRemoveEntity(pacx.SpawnedMapEntities[part.self.UniqueID])

			local ent = ents.Create("light_dynamic")

			local data = part.self

			local c = data.Color

			ent:SetKeyValue("_light", ("%i %i %i 255"):format(c and c.x or 255, c and c.y or 255, c and c.z or 255))
			ent:SetKeyValue("brightness", (data.Brightness or 1) * 8)
			if data.Size then ent:SetKeyValue("distance", data.Size) end
			if data.Style then ent:SetKeyValue("style", data.Style) end

			set_pos(ent, part.self, parent)

			ent:Spawn()
			ent:Activate()

		pacx.SpawnedMapEntities[part.self.UniqueID] = ent

	end,

	effect = function(part, parent)
		if parent:IsValid() and part.data.Effect then
			ParticleEffectAttach(part.data.Effect, PATTACH_ABSORIGIN_FOLLOW, parent, 0)
		end
	end,
}

local function try_spawn(part, parent)

	local func = spawn_handlers[part.self.ClassName]

	if func then
		return func(part, parent)
	else
		pac.Message(part.self.ClassName)
	end

	return NULL
end

local function parse_part_data(part, parent)
	parent = try_spawn(part, parent)

	for key, part in pairs(part.children) do
		parse_part_data(part, parent)
	end
end

function pacx.SpawnMapOutfit(data)
	if data.self then
		data = {data}
	end

	for key, part in pairs(data) do
		parse_part_data(part, NULL)
	end
end

concommand.Add("pac_spawn_map", function(ply, _, args)
	if not ply:IsAdmin() then return end

	for k,v in pairs(pacx.SpawnedMapEntities) do
		SafeRemoveEntity(v)
	end

	pacx.SpawnedMapEntities = {}

	local data = file.Read("pac3/" .. args[1] .. ".txt", "DATA")

	if data then
		data = CompileString("return {" .. data .. "}", "luadata", true)

		if type(data) == "function" then
			pacx.SpawnMapOutfit(data())
		else
			pac.Message(data)
		end
	else
		pac.Message(data)
	end
end)