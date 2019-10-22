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

	for key, file_name in pairs(files) do
		if not pac_loaded_particle_effects[file_name] and not pac.BlacklistedParticleSystems[file_name:lower()] then
			game.AddParticles("particles/" .. file_name)
		end

		pac_loaded_particle_effects[file_name] = true
	end

	pac.Message('Loaded total ', #files, ' particle systems')
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
		if #plqueue<50 then plqueue[#plqueue+1] = name end
	else
		plqueue = {name}
		queue[pl] = plqueue
		local function processQueue()
			if #plqueue == 0 then
				queue[pl] = nil
			else
				timer.Simple(0.5, processQueue)
				pac.PrecacheEffect(table.remove(plqueue,1))
			end
		end
		processQueue()
	end
end)
