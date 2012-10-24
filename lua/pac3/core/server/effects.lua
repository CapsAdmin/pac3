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

function pac.PrecacheEffect(name)
	PrecacheParticleSystem(name)
	net.Start("pac_effect_precached")
		net.WriteString(name)
	net.Send()
end

net.Receive("pac_precache_effect", function()
	local name = net.ReadString()
	if not table.HasValue(pac.EffectsBlackList, name) then
		pac.PrecacheEffect(name)
	end
end)