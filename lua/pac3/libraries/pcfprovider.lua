local pac = pac

local pcfprovider = {}

local initialized = false
local pcfCache = {}
local loadedPCFs = {}

local function InitDB()
	local ok1 = sql.Query("CREATE TABLE IF NOT EXISTS pac3_pcfcache_pcfs (" ..
		"pcfid INTEGER PRIMARY KEY AUTOINCREMENT, " ..
		"filename TEXT NOT NULL, " ..
		"filesize INTEGER NOT NULL, " ..
		"UNIQUE(filename, filesize)" ..
	");")

	local ok2 = sql.Query("CREATE TABLE IF NOT EXISTS pac3_pcfcache_names (" ..
		"particleeffectname TEXT NOT NULL, " ..
		"pcfid INTEGER NOT NULL REFERENCES pac3_pcfcache_pcfs(pcfid), " ..
		"UNIQUE(particleeffectname, pcfid)" ..
	");")

	if ok1 == false or ok2 == false then
		pac.Message(Color(255, 50, 50), "pcfprovider: failed to create SQL tables: " .. tostring(sql.LastError()))
		return false
	end

	return true
end

local function GetOrCreatePCFEntry(filename, filesize)
	local qfilename = sql.SQLStr(filename)

	local row = sql.QueryRow(
		string.format("SELECT pcfid FROM pac3_pcfcache_pcfs WHERE filename = %s AND filesize = %d",
			qfilename, filesize)
	)
	if row then
		return row.pcfid
	end

	local ok = sql.Query(
		string.format("INSERT INTO pac3_pcfcache_pcfs (filename, filesize) VALUES (%s, %d)",
			qfilename, filesize)
	)
	if ok == false then return nil end

	local row2 = sql.QueryRow(
		string.format("SELECT pcfid FROM pac3_pcfcache_pcfs WHERE filename = %s AND filesize = %d",
			qfilename, filesize)
	)
	return row2 and row2.pcfid or nil
end

local function GetCachedNames(pcfid)
	local rows = sql.Query(
		string.format("SELECT particleeffectname FROM pac3_pcfcache_names WHERE pcfid = %d", pcfid)
	)
	if not rows then return {} end

	local names = {}
	for _, row in ipairs(rows) do
		names[row.particleeffectname] = true
	end
	return names
end

local function StoreNames(pcfid, effectNames)
	for canonicalName in pairs(effectNames) do
		sql.Query(
			string.format("INSERT OR IGNORE INTO pac3_pcfcache_names (particleeffectname, pcfid) VALUES (%s, %d)",
				sql.SQLStr(canonicalName), pcfid)
		)
	end
end

function pcfprovider.Initialize()
	if initialized then return end
	initialized = true

	if not InitDB() then
		pac.particle_list = {}
		return
	end

	local t0 = SysTime()

	local files = file.Find("particles/*.pcf", "GAME")
	local allNames = {}
	local parsed = 0
	local cached = 0

	for _, filename in ipairs(files) do
		if not pac.BlacklistedParticleSystems[filename:lower()] then
			local filesize = file.Size("particles/" .. filename, "GAME")
			if filesize and filesize > 0 then
				local pcfid = GetOrCreatePCFEntry(filename, filesize)
				if pcfid then
					local names = GetCachedNames(pcfid)
					if table.Count(names) == 0 then
						local ok, effectNames = pcall(pac.pcfparser.ReadEffectNames, "particles/" .. filename)
						if ok and table.Count(effectNames) > 0 then
							StoreNames(pcfid, effectNames)
							names = effectNames
						end
						parsed = parsed + 1
					else
						cached = cached + 1
					end

					for name in pairs(names) do
						allNames[name] = name
					end

					pcfCache[filename] = names
				end
			end
		end
	end

	pac.particle_list = allNames

	local elapsed = math.Round((SysTime() - t0) * 1000, 1)
	pac.Message(string.format(
		"particle cache built in %dms (%d effects from %d files, %d parsed, %d cached)",
		elapsed, table.Count(allNames), #files, parsed, cached
	))
end

function pcfprovider.GetParticleList()
	return pac.particle_list or {}
end

function pcfprovider.LoadEffect(effectName)
	if not effectName or effectName == "" then return false end

	local name = string.lower(effectName)
	local rows = sql.Query(
		string.format("SELECT n.pcfid, p.filename FROM pac3_pcfcache_names n " ..
			"JOIN pac3_pcfcache_pcfs p ON n.pcfid = p.pcfid " ..
			"WHERE n.particleeffectname = %s", sql.SQLStr(name))
	)
	if not rows then return false end

	for _, row in ipairs(rows) do
		local filename = row.filename
		if not loadedPCFs[filename] then
			local fullpath = "particles/" .. filename
			pac.Message("game.AddParticles: " .. fullpath)
			local ok, err = pcall(game.AddParticles, fullpath)
			if ok then
				loadedPCFs[filename] = true
				pac_loaded_particle_effects[filename] = true
			else
				pac.Message(Color(255, 50, 50), string.format(
					"failed to load particle file %s: %s", filename, tostring(err)
				))
			end
		end
	end

	return true
end

function pcfprovider.IsEffectLoaded(effectName)
	if not effectName or effectName == "" then return false end

	local name = string.lower(effectName)
	local rows = sql.Query(
		string.format("SELECT p.filename FROM pac3_pcfcache_names n " ..
			"JOIN pac3_pcfcache_pcfs p ON n.pcfid = p.pcfid " ..
			"WHERE n.particleeffectname = %s", sql.SQLStr(name))
	)
	if not rows then return false end

	for _, row in ipairs(rows) do
		if loadedPCFs[row.filename] then
			return true
		end
	end

	return false
end

function pcfprovider.ClearCache()
	sql.Query("DROP TABLE IF EXISTS pac3_pcfcache_names")
	sql.Query("DROP TABLE IF EXISTS pac3_pcfcache_pcfs")
	initialized = false
	pcfCache = {}
	loadedPCFs = {}
	pac.particle_list = {}
	pac.Message("particle cache cleared")
end

concommand.Add("pac_debug_pcf_reload", function()
	pcfprovider.ClearCache()
	pcfprovider.Initialize()
end)

return pcfprovider
