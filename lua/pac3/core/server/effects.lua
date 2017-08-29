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

pac.loaded_particle_effects = pac.loaded_particle_effects or {}

for key, file_name in pairs(file.Find("particles/*.pcf", "GAME")) do
	if not pac.loaded_particle_effects[file_name] then
		game.AddParticles("particles/" .. file_name)
	end
	pac.loaded_particle_effects[file_name] = true
end

util.AddNetworkString("pac_effect_precached")
util.AddNetworkString("pac_request_precache")

function pac.PrecacheEffect(name)
	PrecacheParticleSystem(name)
	net.Start("pac_effect_precached")
	net.WriteString(name)
	net.Broadcast()
end

net.Receive("pac_request_precache", function()
	local name = net.ReadString()
	if not table.HasValue(pac.EffectsBlackList, name) then
		pac.PrecacheEffect(name)
	end
end)