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
	if VERSION >= 150 then
		net.Start("pac_effect_precached")
			net.WriteString(name)
		net.Send()
	else
		umsg.Start("pac_effect_precached")
			umsg.String(name)
		umsg.End()
	-- compat hack
	if PAC then
	  if PAC.EffectsBlackList and table.HasValue(PAC.EffectsBlackList, effect) then return end
		umsg.Start("PAC Effect Precached")
		  umsg.String(name)
		umsg.End()
	  end
	 end
end

if VERSION >= 150 then
	net.Receive("pac_precache_effect", function()
		local name = net.ReadString()
		if not table.HasValue(pac.EffectsBlackList, name) then
			pac.PrecacheEffect(name)
		end
	end)
else
	concommand.Add("pac_precache_effect", function(ply, _, args)
		local name = args[1]
		if not table.HasValue(pac.EffectsBlackList, name) then
			pac.dprint("%s precached effect %s", tostring(ply), name)
			pac.PrecacheEffect(name)
		end
	end)
end