pac.EffectsBlackList =
{
	"frozen_steam",
	"portal_rift_01",
	"explosion_silo",
	"citadel_shockwave_06",
	"citadel_shockwave",
	"choreo_launch_rocket_start",
	"choreo_launch_rocket_jet",
}

if not pac_loaded_particle_effects then
	pac_loaded_particle_effects = {}

	local files = file.Find("particles/*.pcf", "GAME")

	for i = 1, #files do
		local path = files[i]

		if not pac_loaded_particle_effects[path] and not pac.BlacklistedParticleSystems[path:lower()] then
			game.AddParticles("particles/" .. path)
		end

		pac_loaded_particle_effects[path] = true
	end

	pac.Message("Loaded total ", #files, " particle systems")
end

util.AddNetworkString("pac_effect_precached")
util.AddNetworkString("pac_request_precache")

function pac.PrecacheEffect(name)
	PrecacheParticleSystem(name)

	net.Start("pac_effect_precached")
	net.WriteString(name)
	net.Broadcast()
end

local queue = {}
net.Receive("pac_request_precache", function(len, pl)
	local name = net.ReadString()
	if table.HasValue(pac.EffectsBlackList, name) then return end

	-- Each player gets a 50 length queue
	local plqueue = queue[pl]
	if plqueue then
		if #plqueue < 50 then
			plqueue[#plqueue + 1] = name
		end
	else
		plqueue = {name}
		queue[pl] = plqueue

		local function processQueue()
			if plqueue[1] ~= nil then
				timer.Simple(0.5, processQueue)
				pac.PrecacheEffect(table.remove(plqueue, 1))
			else
				queue[pl] = nil
			end
		end

		processQueue()
	end
end)
