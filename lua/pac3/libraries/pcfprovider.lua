local pcfprovider = {}

local FRAME_BUDGET = 0.002

local effect_files = {}
local effect_list = {}
local loaded_files = {}
local precached = {}
local pending_files
local pending_index = 1
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

function pcfprovider.StepIndex(budget)
	if indexed then return true end

	pending_files = pending_files or file.Find("particles/*.pcf", "GAME")

	local deadline = budget and SysTime() + budget

	while pending_index <= #pending_files do
		index_file(pending_files[pending_index])
		pending_index = pending_index + 1

		if deadline and SysTime() > deadline then return false end
	end

	indexed = true
	pending_files = nil

	return true
end

function pcfprovider.IsIndexed()
	return indexed
end

function pcfprovider.GetParticleList()
	pcfprovider.StepIndex()
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
		PrecacheParticleSystem(name)
	end

	return true
end

pac.AddHook("Think", "pcfprovider_index", function()
	if pcfprovider.StepIndex(FRAME_BUDGET) then
		pac.RemoveHook("Think", "pcfprovider_index")
	end
end)

return pcfprovider
