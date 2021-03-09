include("util.lua")

include("footsteps_fix.lua")
include("http.lua")
include("movement.lua")
include("entity_mutator.lua")

pac.StringStream = include("pac3/libraries/string_stream.lua")

CreateConVar("pac_sv_draw_distance", 0, CLIENT and FCVAR_REPLICATED or bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE))
CreateConVar("pac_sv_hide_outfit_on_death", 0, CLIENT and FCVAR_REPLICATED or bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE))

do
	local tohash = {
		-- Crash
		'weapon_unusual_isotope.pcf',

		-- Invalid
		'blood_fx.pcf',
		'boomer_fx.pcf',
		'charger_fx.pcf',
		'default.pcf',
		'electrical_fx.pcf',
		'environmental_fx.pcf',
		'fire_01l4d.pcf',
		'fire_fx.pcf',
		'fire_infected_fx.pcf',
		'firework_crate_fx.pcf',
		'fireworks_fx.pcf',
		'footstep_fx.pcf',
		'gen_dest_fx.pcf',
		'hunter_fx.pcf',
		'infected_fx.pcf',
		'insect_fx.pcf',
		'item_fx.pcf',
		'locator_fx.pcf',
		'military_artillery_impacts.pcf',
		'rain_fx.pcf',
		'rain_storm_fx.pcf',
		'rope_fx.pcf',
		'screen_fx.pcf',
		'smoker_fx.pcf',
		'speechbubbles.pcf',
		'spitter_fx.pcf',
		'steam_fx.pcf',
		'steamworks.pcf',
		'survivor_fx.pcf',
		'tank_fx.pcf',
		'tanker_explosion.pcf',
		'test_collision.pcf',
		'test_distancealpha.pcf',
		'ui_fx.pcf',
		'vehicle_fx.pcf',
		'water_fx.pcf',
		'weapon_fx.pcf',
		'witch_fx.pcf'
	}

	pac.BlacklistedParticleSystems = {}

	for i, val in ipairs(tohash) do
		pac.BlacklistedParticleSystems[val] = true
	end
end
