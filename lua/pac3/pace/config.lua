pace.PartIcons =
{
	text = "icon16/text_align_center.png",
	bone = "widgets/bone_small.png",
	clip = "icon16/cut.png",
	light = "icon16/lightbulb.png",
	sprite = "icon16/layers.png",
	bone = "icon16/connect.png",
	effect = "icon16/wand.png",
	model = "icon16/shape_square.png",
	animation = "icon16/eye.png",
	holdtype = "icon16/user_edit.png",
	entity = "icon16/brick.png",
	group = "icon16/world.png",
	trail = "icon16/arrow_undo.png",
	event = "icon16/clock.png",
	sunbeams = "icon16/weather_sun.png",
	jiggle = "icon16/chart_line.png",
	sound = "icon16/sound.png",
	command = "icon16/application_xp_terminal.png",
	material = "icon16/paintcan.png",
	proxy = "icon16/calculator.png",
	particles = "icon16/water.png",
	woohoo = "icon16/webcam_delete.png",
	halo = "icon16/shading.png",
	poseparameter = "icon16/disconnect.png",
	fog = "icon16/weather_clouds.png",
	physics = "icon16/shape_handles.png",
	beam = "icon16/vector.png",
	projectile = "icon16/bomb.png",
	shake = "icon16/transmit.png",
}

pace.PropertyOrder =
{
	"Name",
	"Description",
	"Hide",
	"ParentName",
	"OwnerName",
	
	"Input",
	"Function",
	
	"AimPartName",
	
	"Bone",
	"VariableName",
	"Axis",
	"BoneMerge",
	"BoneMergeAlternative",
	"OverallSize",
	"Position",
	"Angles",
	"AngleVelocity",
	"ModifyAngles",
	"EyeAngles",
	"Size",
	"Scale",
	
	"OriginFix",
	"PositionOffset",
	"AngleOffset",
	
	"Model",
	"Bodygroup",
	"BodygroupState",
	"Material",	
	"TrailPath",
	"Color",
	"StartColor",
	"EndColor",
	"Brightness",
	"Alpha",
	"Fullbright",
	"CellShade",
	"StartAlpha",
	"EndAlpha",
	"Min",
	"Max",
	"Loop",
	"PingPongLoop",
		
	"BaseTexture",
	"BumpMap",
	
	"Phong",
	"PhongTint",
	"PhongBoost",
	"PhongFresnelRanges",
	"PhongExponentTexture",
	"PhongExponent",
	"PhongAlbedoTint",
	"PhongWarpTexture",
	
	"Rimlight",
	"RimlightBoost",
	"RimlightExponent",
		
	"EnvMap",
	"EnvMapMask",
	"EnvMapContrast",
	"EnvMapSaturation",
	"EnvMapTint",
	"EnvMapMode",
	
	"Detail",
	"DetailTint",
	"DetailScale",
	"DetailBlendMode",
	"DetailBlendFactor",
	
	"CloakPassEnabled",
	"CloakFactor",
	"RefractAmount",
	
	"AmbientOcclusion",
	"AmbientOcclusionTexture",
	"AmbientOcclusionColor",	
	
	"ConstrainSphere",
	"ConstrainX",
	"ConstrainY",
	"ConstrainZ",
	"ConstrainPitch",
	"ConstrainYaw",
	"ConstrainRoll",
}

pace.PropertyLimits = 
{
	Sequence = function(self, num)
		num = tonumber(num)
		return math.Round(math.min(num, -1))
	end,
	
	Skin = function(self, num)
		num = tonumber(num)
		return math.Round(math.max(num, 0))
	end,
	Bodygroup = function(self, num)
		num = tonumber(num)
		return math.Round(math.max(num, 0))
	end,
	BodygroupState = function(self, num)
		num = tonumber(num)
		return math.Round(math.max(num, 0))
	end,
	
	Size = function(self, num)
		self.sens = 0.25
		
		return num
	end,
	
	Strain = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1) * 0.999
	end,
	
	Style = function(self, num)
		num = tonumber(num)
		return math.Clamp(num, 0, 16)
	end,
	
	Alpha = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1)
	end,
	OutlineAlpha = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1)
	end,
	
	Rate = function(self, num)
		self.sens = 0.1
		num = tonumber(num)
		return num
	end,
	
	CellShade = function(self, num)
		self.sens = 0.1
		num = tonumber(num)
		return num
	end,
	
	CloakFactor = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1)
	end,
	
	DetailBlendMode = function(self, num)
		num = tonumber(num)
		return math.Round(math.max(num, 0))
	end,
	
	Volume = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1)
	end,	
	Pitch = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1)
	end,
}

pace.HiddenProperties =
{
	Arguments = true,
}

pace.HiddenPropertyKeys =
{
	EditorExpand = true,
	UniqueID = true,
	OwnerName = "group",
}

function pace.ShouldHideProperty(key)
	return key:find("UID")
end


function pace.TranslatePropertiesKey(key, obj)
	local key_ = key
	key = key:lower()
	
	if 
		key == "bone" or 
		key == "model" or
		key == "event" or
		key == "operator" or
		key == "arguments" or
		key == "ownername"
	then
		return key
	end

	if key == "weaponholdtype" and obj.ClassName == "animation" then
		return "weaponholdtype"
	end
	
	if key == "function" and obj.ClassName == "proxy" then
		return "proxyfunctions"
	end
	
	if key == "input" and obj.ClassName == "proxy" then
		return "proxyinputs"
	end	
	
	if key == "variablename" and obj.ClassName == "proxy" then
		return "proxyvars"
	end
	
	if key == "aimpartname" or key == "parentname" or key == "followpartname" or key == "anglepartname" or key == "endpointname" or key == "outfitpartname" then
		return "part"
	end
	
	if key == "sequence" or key == "sequencename" or (obj.ClassName == "holdtype" and (obj.ActMods[key_] or key == "fallback" or key == "noclip" or key == "air")) then
		return "sequence"
	end
	
	if key == "poseparameter" then
		return "poseparameter"
	end
	
	if key == "material" or key == "spritepath" or key == "trailpath" then
		return "material"
	end
	
	if obj.ClassName == "material" and obj.ShaderParams[key_] == "ITexture" then
		return "material"
	end
		
	if obj.ClassName == "material" and obj.ShaderParams[key_] == "Vector" and 
		(
			key ~= "phongfresnelranges" and
			key ~= "color2" and
			key ~= "color" and
			not key:find("tint")
		)
	then
		return "color"
	end

	if key:find("color") then
		return "color"
	end
end