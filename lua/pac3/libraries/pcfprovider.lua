local pac = pac

local pcfprovider = {}

local initialized = false
local loadedPCFs = {}
local precachedNames = {}

local EffectsBlackList = pac.EffectsBlackList or {}

local function Query(...)
	local ok, res = pcall(sql.Query, ...)
	if not ok then return false end
	return res
end

local function QueryRow(...)
	local ok, res = pcall(sql.QueryRow, ...)
	if not ok then return nil end
	return res
end

local function IsBlacklisted(name)
	return EffectsBlackList[name] ~= nil
end

local function InitDB()
	local ok1 = Query("CREATE TABLE IF NOT EXISTS pac3_pcfcache_pcfs (" ..
		"pcfid INTEGER PRIMARY KEY AUTOINCREMENT, " ..
		"filename TEXT NOT NULL, " ..
		"filesize INTEGER NOT NULL, " ..
		"UNIQUE(filename, filesize)" ..
	");")

	local ok2 = Query("CREATE TABLE IF NOT EXISTS pac3_pcfcache_names (" ..
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

	local row = QueryRow(
		string.format("SELECT pcfid FROM pac3_pcfcache_pcfs WHERE filename = %s AND filesize = %d",
			qfilename, filesize)
	)
	if row then
		return row.pcfid
	end

	local ok = Query(
		string.format("INSERT INTO pac3_pcfcache_pcfs (filename, filesize) VALUES (%s, %d)",
			qfilename, filesize)
	)
	if ok == false then return nil end

	local row2 = QueryRow(
		string.format("SELECT pcfid FROM pac3_pcfcache_pcfs WHERE filename = %s AND filesize = %d",
			qfilename, filesize)
	)
	return row2 and row2.pcfid or nil
end

local function GetCachedNames(pcfid)
	local rows = Query(
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
	for name in pairs(effectNames) do
		Query(
			string.format("INSERT OR IGNORE INTO pac3_pcfcache_names (particleeffectname, pcfid) VALUES (%s, %d)",
				sql.SQLStr(name), pcfid)
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

	local files = file.Find("particles/*.pcf", "GAME") or {}
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
						if not IsBlacklisted(name) then
							allNames[name] = name
						end
					end
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
	if IsBlacklisted(name) then return false end

	local rows = Query(
		string.format("SELECT n.pcfid, p.filename FROM pac3_pcfcache_names n " ..
			"JOIN pac3_pcfcache_pcfs p ON n.pcfid = p.pcfid " ..
			"WHERE n.particleeffectname = %s", sql.SQLStr(name))
	)
	if not rows then return false end

	local loaded = false
	for _, row in ipairs(rows) do
		local filename = row.filename
		local fullpath = "particles/" .. filename

		if loadedPCFs[filename] ~= true then
			local ok, err = pcall(game.AddParticles, fullpath)
			loadedPCFs[filename] = ok and true or false

			if not ok then
				pac.Message(Color(255, 50, 50), string.format(
					"failed to load particle file %s: %s", filename, tostring(err)
				))
			end
		end

		if loadedPCFs[filename] then
			loaded = true
		end
	end

	if loaded and not precachedNames[effectName] then
		precachedNames[effectName] = true
		pcall(PrecacheParticleSystem, effectName)
	end

	return loaded
end

function pcfprovider.IsEffectLoaded(effectName)
	if not effectName or effectName == "" then return false end

	if IsBlacklisted(string.lower(effectName)) then return false end

	local rows = Query(
		string.format("SELECT p.filename FROM pac3_pcfcache_names n " ..
			"JOIN pac3_pcfcache_pcfs p ON n.pcfid = p.pcfid " ..
			"WHERE n.particleeffectname = %s", sql.SQLStr(string.lower(effectName)))
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
	Query("DROP TABLE IF EXISTS pac3_pcfcache_names")
	Query("DROP TABLE IF EXISTS pac3_pcfcache_pcfs")
	initialized = false
	loadedPCFs = {}
	precachedNames = {}
	pac.particle_list = {}
	pac.Message("particle cache cleared")
end

concommand.Add("pac_debug_pcf_reload", function()
	pcfprovider.ClearCache()
	pcfprovider.Initialize()
end)

return pcfprovider