local pcfprovider = {}

local FRAME_BUDGET = 0.002

local effect_files = {}
local effect_list = {}
local loaded_files = {}
local precached = {}
local indexed = false

local function index_file(file_name)
	if pac.BlacklistedParticleSystems[file_name:lower()] then return end

	local ok, names = pcall(pac.pcfparser.ReadEffectNames, "particles/" .. file_name)

	if not ok then
		pac.Message(Color(255, 50, 50), "unable to parse particle file ", file_name, ": ", names)
		return
	end

	for lower_name, name in pairs(names) do
		effect_files[lower_name] = file_name

		if not pac.EffectsBlackList[lower_name] then
			effect_list[name] = name
		end
	end
end

local step_index = coroutine.wrap(function()
	local deadline = SysTime() + FRAME_BUDGET

	for _, file_name in ipairs(file.Find("particles/*.pcf", "GAME")) do
		index_file(file_name)

		if SysTime() > deadline then
			coroutine.yield(false)
			deadline = SysTime() + FRAME_BUDGET
		end
	end

	indexed = true

	return true
end)

function pcfprovider.IsIndexed()
	return indexed
end

function pcfprovider.GetParticleList()
	return effect_list
end

function pcfprovider.LoadEffect(name)
	if not indexed then return false end
	if not name or name == "" then return false end

	local lower_name = name:lower()
	if pac.EffectsBlackList[lower_name] then return false end

	local file_name = effect_files[lower_name]

	if file_name and not loaded_files[file_name] then
		loaded_files[file_name] = true
		game.AddParticles("particles/" .. file_name)
	end

	if not precached[lower_name] then
		precached[lower_name] = true
		PrecacheParticleSystem(lower_name)
	end

	return true
end

pac.AddHook("Think", "pcfprovider_index", function()
	if step_index() then
		pac.RemoveHook("Think", "pcfprovider_index")
	end
end)

return pcfprovider
