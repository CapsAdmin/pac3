pace.DeprecatedParts =
{
	woohoo = true,
	--command = true,
	balanim = true
}

pace.DeprecatedProperties =
{
	BodygroupState = true, -- we have a bodygroup part now
	Bodygroup = true, -- we have a bodygroup part now

	AngleVelocity = true, -- use proxies on angle offset instead!
	OriginFix = true, -- use position offset instead!
	OverallSize = true, -- use Size instead!
	BoneMergeAlternative = true, -- broken
	FollowBone = true, -- broken

	AnglePartMultiplier = true, -- useless
	AnglePartName = true, -- useless
	Description = true, -- useless

	-- not ready for deprecation yet
	--[[
	InputMultiplier = "proxy",
	InputDivider = "proxy",
	Function = "proxy",
	Input = "proxy",
	Axis = "proxy",
	Offset = "proxy",
	Min = "proxy",
	Max = "proxy",
	Pow = "proxy",
	]]
}

local basic_mode = CreateConVar("pac_show_deprecated", "0")

function pace.ToggleDeprecatedFeatures()
	RunConsoleCommand("pac_show_deprecated", basic_mode:GetBool() and "0" or "1")
	if pace.Editor and pace.Editor:IsValid() then
		pace.CloseEditor()
		timer.Simple(0.1, function()
			pace.OpenEditor()
		end)
	end
end

function pace.IsShowingDeprecatedFeatures()
	return basic_mode:GetBool()
end