-- Standalone test for particle cache system
-- Run in console: lua_run_script include("pac3/test_particle_cache.lua")
-- Or just: lua_run include("pac3/test_particle_cache.lua")

local results = {}
local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		print("[PASS] " .. name)
	else
		print("[FAIL] " .. name .. ": " .. tostring(err))
		results[name] = err
	end
end

local function section(title)
	print("")
	print("=== " .. title .. " ===")
end

-----------------------------------------------------------
section("1. Dependencies")
-----------------------------------------------------------

test("pac.StringStream exists", function()
	assert(pac.StringStream, "pac.StringStream is nil")
	print("  pac.StringStream: " .. tostring(pac.StringStream))
end)

test("pac.pcfparser exists", function()
	assert(pac.pcfparser, "pac.pcfparser is nil")
	print("  pac.pcfparser.ReadEffectNames: " .. tostring(pac.pcfparser.ReadEffectNames))
end)

-----------------------------------------------------------
section("2. SQL Basics")
-----------------------------------------------------------

test("sql.Query works (SELECT 1)", function()
	local r = sql.Query("SELECT 1 AS v")
	assert(r ~= false, "sql.Query returned false: " .. tostring(sql.LastError()))
	assert(r and r[1] and r[1].v == 1, "unexpected result: " .. tostring(r))
	print("  result: " .. tostring(r[1].v))
end)

test("sql.SQLStr quoting", function()
	local s1 = sql.SQLStr("hello world")
	local s2 = sql.SQLStr("it's a test")
	print("  sql.SQLStr(\"hello world\") = " .. s1)
	print("  sql.SQLStr(\"it's a test\") = " .. s2)
	assert(s1 == "'hello world'", "basic string not quoted: " .. s1)
	assert(s2:find("'") ~= nil, "string with apostrophe not quoted: " .. s2)
end)

-----------------------------------------------------------
section("3. SQL Table Creation (without STRICT)")
-----------------------------------------------------------

test("DROP old test tables", function()
	sql.Query("DROP TABLE IF EXISTS test_pcf_names")
	sql.Query("DROP TABLE IF EXISTS test_pcf_pcfs")
end)

test("CREATE pcfs table (no STRICT)", function()
	local r = sql.Query("CREATE TABLE IF NOT EXISTS test_pcf_pcfs (" ..
		"pcfid INTEGER PRIMARY KEY AUTOINCREMENT, " ..
		"filename TEXT NOT NULL, " ..
		"filesize INTEGER NOT NULL, " ..
		"UNIQUE(filename, filesize)" ..
	")")
	if r == false then
		error("CREATE TABLE failed: " .. tostring(sql.LastError()))
	end
	print("  result: " .. tostring(r))
end)

test("CREATE names table (no STRICT)", function()
	local r = sql.Query("CREATE TABLE IF NOT EXISTS test_pcf_names (" ..
		"particleeffectname TEXT NOT NULL, " ..
		"pcfid INTEGER NOT NULL, " ..
		"UNIQUE(particleeffectname, pcfid)" ..
	")")
	if r == false then
		error("CREATE TABLE failed: " .. tostring(sql.LastError()))
	end
	print("  result: " .. tostring(r))
end)

-----------------------------------------------------------
section("4. SQL Table Creation (with STRICT)")
-----------------------------------------------------------

test("CREATE pcfs table (WITH STRICT)", function()
	local r = sql.Query("CREATE TABLE IF NOT EXISTS test_pcf_pcfs_strict (" ..
		"pcfid INTEGER PRIMARY KEY AUTOINCREMENT, " ..
		"filename TEXT NOT NULL, " ..
		"filesize INTEGER NOT NULL, " ..
		"UNIQUE(filename, filesize)" ..
	") STRICT;")
	if r == false then
		print("  STRICT not supported: " .. tostring(sql.LastError()))
		return false
	end
	print("  STRICT tables work! result: " .. tostring(r))
end)

test("CREATE names table (WITH STRICT)", function()
	local r = sql.Query("CREATE TABLE IF NOT EXISTS test_pcf_names_strict (" ..
		"particleeffectname TEXT NOT NULL, " ..
		"pcfid INTEGER NOT NULL, " ..
		"UNIQUE(particleeffectname, pcfid)" ..
	") STRICT;")
	if r == false then
		print("  STRICT not supported: " .. tostring(sql.LastError()))
		return false
	end
	print("  STRICT tables work! result: " .. tostring(r))
end)

-----------------------------------------------------------
section("5. SQL INSERT/SELECT")
-----------------------------------------------------------

test("INSERT into pcfs table", function()
	local r = sql.Query("INSERT INTO test_pcf_pcfs (filename, filesize) VALUES ('test.pcf', 12345)")
	if r == false then
		error("INSERT failed: " .. tostring(sql.LastError()))
	end
	print("  INSERT result: " .. tostring(r))
end)

test("INSERT duplicate (UNIQUE constraint)", function()
	local r = sql.Query("INSERT INTO test_pcf_pcfs (filename, filesize) VALUES ('test.pcf', 12345)")
	local err = sql.LastError()
	print("  INSERT duplicate result: " .. tostring(r) .. " | error: " .. tostring(err))
	-- Should return false (constraint violation), not crash
end)

test("SELECT by filename", function()
	local r = sql.QueryRow(
		string.format("SELECT pcfid FROM test_pcf_pcfs WHERE filename = %s AND filesize = %d",
			sql.SQLStr("test.pcf"), 12345)
	)
	assert(r and r.pcfid, "SELECT failed: " .. tostring(sql.LastError()))
	print("  pcfid = " .. tostring(r.pcfid))
end)

test("INSERT into names table", function()
	local r = sql.Query("INSERT INTO test_pcf_names (particleeffectname, pcfid) VALUES ('my_effect', 1)")
	if r == false then
		error("INSERT failed: " .. tostring(sql.LastError()))
	end
	print("  INSERT result: " .. tostring(r))
end)

test("SELECT names with JOIN", function()
	local r = sql.Query(
		"SELECT n.particleeffectname, p.filename FROM test_pcf_names n " ..
		"JOIN test_pcf_pcfs p ON n.pcfid = p.pcfid " ..
		"WHERE n.particleeffectname = " .. sql.SQLStr("my_effect")
	)
	assert(r and r[1], "JOIN query failed: " .. tostring(sql.LastError()))
	print("  filename=" .. r[1].filename .. " name=" .. r[1].particleeffectname)
end)

test("INSERT OR IGNORE", function()
	local r = sql.Query("INSERT OR IGNORE INTO test_pcf_names (particleeffectname, pcfid) VALUES ('my_effect', 1)")
	if r == false then
		error("INSERT OR IGNORE failed: " .. tostring(sql.LastError()))
	end
	print("  result: " .. tostring(r))
end)

-----------------------------------------------------------
section("6. File System")
-----------------------------------------------------------

local pcfFiles = {}

test("file.Find particles/*.pcf", function()
	local files = file.Find("particles/*.pcf", "GAME")
	assert(files, "file.Find returned nil")
	print("  found " .. #files .. " PCF files")
	for i = 1, math.min(5, #files) do
		print("    " .. files[i])
	end
	if #files > 5 then
		print("    ... and " .. (#files - 5) .. " more")
	end
	pcfFiles = files
end)

test("file.Size on first PCF", function()
	assert(#pcfFiles > 0, "no PCF files found to test")
	local name = pcfFiles[1]
	local size = file.Size("particles/" .. name, "GAME")
	print("  particles/" .. name .. " -> size=" .. tostring(size))
	assert(size and size > 0, "file.Size returned nil or 0 for " .. name)
end)

test("file.Open + Read first PCF", function()
	assert(#pcfFiles > 0, "no PCF files found to test")
	local name = pcfFiles[1]
	local f = file.Open("particles/" .. name, "rb", "GAME")
	assert(f, "file.Open returned nil for " .. name)
	local data = f:Read()
	f:Close()
	assert(data, "Read() returned nil")
	print("  read " .. #data .. " bytes from " .. name)
	-- Show first 128 bytes as hex
	local hex = {}
	for i = 1, math.min(128, #data) do
		hex[i] = string.format("%02x", string.byte(data, i))
	end
	print("  header hex: " .. table.concat(hex, " "))
	-- Look for DMX header
	local str = data:sub(1, 256)
	if str:find("dmx encoding", 1, true) then
		print("  found 'dmx encoding' header")
	else
		print("  WARNING: no 'dmx encoding' header found in first 256 bytes")
	end
end)

-----------------------------------------------------------
section("7. Parser on Real PCF Files")
-----------------------------------------------------------

test("pac.pcfparser.ReadEffectNames on first 3 PCFs", function()
	assert(#pcfFiles > 0, "no PCF files found to test")
	local count = math.min(3, #pcfFiles)
	for i = 1, count do
		local name = pcfFiles[i]
		local t0 = SysTime()
		local ok, names = pcall(pac.pcfparser.ReadEffectNames, "particles/" .. name)
		local elapsed = math.Round((SysTime() - t0) * 1000, 2)
		if ok then
			local n = 0
			for _ in pairs(names) do n = n + 1 end
			print("  " .. name .. " -> " .. n .. " effects (" .. elapsed .. "ms)")
			-- Print first few names
			local shown = 0
			for lower, canonical in pairs(names) do
				print("    " .. lower .. " = " .. canonical)
				shown = shown + 1
				if shown >= 5 then break end
			end
		else
			print("  " .. name .. " -> ERROR: " .. tostring(names))
		end
	end
end)

test("Parser on ALL non-blacklisted PCFs (summary)", function()
	local blacklist = pac.BlacklistedParticleSystems or {}
	local total = 0
	local totalEffects = 0
	local totalErrors = 0
	local t0 = SysTime()

	for _, name in ipairs(pcfFiles) do
		if not blacklist[name:lower()] then
			total = total + 1
			local ok, names = pcall(pac.pcfparser.ReadEffectNames, "particles/" .. name)
			if ok then
				local n = 0
				for _ in pairs(names) do n = n + 1 end
				totalEffects = totalEffects + n
				if n == 0 then
					print("  [NO EFFECTS] " .. name)
				end
			else
				totalErrors = totalErrors + 1
				print("  [ERROR] " .. name .. ": " .. tostring(names))
			end
		end
	end

	local elapsed = math.Round((SysTime() - t0) * 1000, 1)
	print("  scanned " .. total .. " files in " .. elapsed .. "ms")
	print("  found " .. totalEffects .. " total effect names")
	print("  errors: " .. totalErrors)
end)

-----------------------------------------------------------
section("8. Integration: Full Pipeline (SQL + Parser)")
-----------------------------------------------------------

test("Drop and recreate clean tables for integration test", function()
	sql.Query("DROP TABLE IF EXISTS test_integ_names")
	sql.Query("DROP TABLE IF EXISTS test_integ_pcfs")
	sql.Query("CREATE TABLE IF NOT EXISTS test_integ_pcfs (" ..
		"pcfid INTEGER PRIMARY KEY AUTOINCREMENT, " ..
		"filename TEXT NOT NULL, " ..
		"filesize INTEGER NOT NULL, " ..
		"UNIQUE(filename, filesize)" ..
	")")
	sql.Query("CREATE TABLE IF NOT EXISTS test_integ_names (" ..
		"particleeffectname TEXT NOT NULL, " ..
		"pcfid INTEGER NOT NULL, " ..
		"UNIQUE(particleeffectname, pcfid)" ..
	")")
end)

test("Parse first PCF and store in SQL", function()
	assert(#pcfFiles > 0, "no PCF files")
	local name = pcfFiles[1]
	local size = file.Size("particles/" .. name, "GAME")
	assert(size and size > 0, "file.Size failed")

	-- Insert PCF row
	local qname = sql.SQLStr(name)
	local r = sql.Query(string.format(
		"INSERT INTO test_integ_pcfs (filename, filesize) VALUES (%s, %d)", qname, size))
	if r == false then
		error("INSERT pcf failed: " .. tostring(sql.LastError()))
	end

	-- Get pcfid
	local row = sql.QueryRow(string.format(
		"SELECT pcfid FROM test_integ_pcfs WHERE filename = %s AND filesize = %d", qname, size))
	assert(row and row.pcfid, "SELECT pcfid failed: " .. tostring(sql.LastError()))
	local pcfid = row.pcfid
	print("  pcfid=" .. pcfid .. " for " .. name)

	-- Parse
	local ok, names = pcall(pac.pcfparser.ReadEffectNames, "particles/" .. name)
	assert(ok, "parser error: " .. tostring(names))
	local n = 0
	for _ in pairs(names) do n = n + 1 end
	print("  parsed " .. n .. " effect names")

	-- Store names
	local stored = 0
	for canonicalName in pairs(names) do
		local nr = sql.Query(string.format(
			"INSERT OR IGNORE INTO test_integ_names (particleeffectname, pcfid) VALUES (%s, %d)",
			sql.SQLStr(canonicalName), pcfid))
		if nr == false then
			print("  INSERT name failed for " .. canonicalName .. ": " .. tostring(sql.LastError()))
		else
			stored = stored + 1
		end
	end
	print("  stored " .. stored .. " names in SQL")

	-- Read back
	local cached = sql.Query(
		"SELECT particleeffectname FROM test_integ_names WHERE pcfid = " .. pcfid)
	assert(cached, "SELECT cached names failed: " .. tostring(sql.LastError()))
	print("  read back " .. #cached .. " names from SQL")
end)

-----------------------------------------------------------
section("Cleanup")
-----------------------------------------------------------

sql.Query("DROP TABLE IF EXISTS test_pcf_names")
sql.Query("DROP TABLE IF EXISTS test_pcf_names_strict")
sql.Query("DROP TABLE IF EXISTS test_pcf_pcfs")
sql.Query("DROP TABLE IF EXISTS test_pcf_pcfs_strict")
sql.Query("DROP TABLE IF EXISTS test_integ_names")
sql.Query("DROP TABLE IF EXISTS test_integ_pcfs")
print("  test tables dropped")

-----------------------------------------------------------
section("Summary")
-----------------------------------------------------------

local failCount = 0
for name, err in pairs(results) do
	failCount = failCount + 1
	print("  FAILED: " .. name .. " -> " .. err)
end

if failCount == 0 then
	print("  All tests passed!")
else
	print("  " .. failCount .. " test(s) failed")
end
