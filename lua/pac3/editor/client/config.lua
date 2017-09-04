-- automate me!

pace.PropertySheets = {
	orientation =
	{
		position = true,
		angles = true,
		positionoffset = true,
		angleoffset = true,
		size = true,
		scale = true,
		eyeangles = true,
		aimpartname = true,
		alternativescaling = true,
		bone = true,
		bonemerge = true,
		fov = true,
		nearz = true,
		farz = true,
		eyeangleslerp = true,
	},

	appearance =
	{
		drawviewmodel = true,
		brightness = true,
		alpha =  true,
		fullbright =  true,
		cellshade =  true,
		translucent =  true,
		color =  true,
		tintcolor =  true,
		invert =  true,
		doubleface =  true,
		texturefilter =  true,
		passes =  true,
		lightblend =  true,
		skin =  true,
		outline =  true,
		outlinecolor =  true,
		outlinealpha =  true,
		font =  true,
		startalpha =  true,
		endalpha =  true,
		startcolor =  true,
		stretch =  true,
		endcolor =  true,
		draworder = true,
		drawshadow = true,
		blurlength = true,
		blurspacing = true,
		useweaponcolor = true,
		useplayercolor = true,
		modelfallback = true,
		lodoverride = true,
		additive = true,
	},

	other =
	{
		ownerentity = true,
		draworder = true,
		showinfirstperson = true,
		duplicate = true,
	},

	event = {

	},

	entity = {
		behavior =
		{
			mutefootsteps = true,
			inversekinematics = true,
			animationrate = true,
			relativebones = true,
			fallapartondeath = true,
			deathragdollizeparent = true,
			hideragdollondeath = true,
			movespeed = true,
			weapon = true,
			playercollide = true,
		},
		movement =
		{
			runspeed = true,
			walkspeed = true,
			crouchspeed = true,
			sprintspeed = true,
		},
		appearance = {
			drawweapon = true,
			hideentity = true,
		}
	},

	proxy = {
		["easy setup"] =
		{
			min = true,
			max = true,
			offset = true,
			["function"] = true,
			input = true,
			inputdivider = true,
			inputmultiplier = true,
			pow = true,
			axis = true,
		},
		["behavior"] =
		{
			velocityroughness = true,
			resetvelocitiesonhide = true,
			zeroeyepitch = true,
			playerangles = true,
			additive = true,
		}
	},

	particles = {
		orientation =
		{
			position = true,
			angles = true,
			positionoffset = true,
			angleoffset = true,
			eyeangles = true,
			aimpartname = true,
			bone = true,
		},
		appearance = {
			color1 = true,
			color2 = true,
			material = true,
			startalpha = true,
			endalpha = true,
			randomcolour = true,
			translucent = true,
			draworder = true,
			["3d"] = true,
			drawmanual = true,
			doublesided = true,
			lighting = true,
		},
		rotation = {
			rolldelta = true,
			randomrollspeed = true,
			particleanglevelocity = true,
		},
		movement = {
			velocity = true,
			spread = true,
			gravity = true,
			bounce = true,
			collide = true,
			ownervelocitymultiplier = true,
			airresistance = true,
			sliding = true,
		},
	}
}

pace.PropertySheets.entity.orientation = pace.PropertySheets.orientation
pace.PropertySheets.entity.appearance = pace.PropertySheets.appearance

pace.PropertySheetPatterns = {
	material = {
		["phong"] = "phong",
		["env map"] = "envmap.+",
		["ambient occlusion"] = {"ambientocclusion", "halflambert"},
		["detail"] = "detail",
		["rimlight"] = "rimlight",
		["cloak"] = {"cloak", "refract"},
		["colors"] = "color",
		["textures"] = {"bumpmap", "basetexture", "envmap", "lightwarptexture"},
		["flesh"] = "flesh",
		["selfillum"] = "selfillum",
		["emissive"] = "emissive",
	},
	particles = {
		["stick"] = {"stick", "align"},
	}
}

pace.PartTree = {
	entity = {
		animation = true,
		gesture = true,
		holdtype = true,
		bone = true,
		poseparameter = true,
		submaterial = true,
		material = true,
		effect = true,
		bodygroup = true,
		camera = true,
	},

	model = {
		clip = true,
		halo = true,
		animation = true,
		physics = true,
		jiggle = true,
		bone = true,
		effect = true,
		material = true,
		submaterial = true,
		bodygroup = true,
	},

	modifiers = {
		animation = true,
		bodygroup = true,
		proxy = true,
		material = true,
		poseparameter = true,
		fog = true,
		clip = true,
	},

	effects = {
		decal = true,
		shake = true,
		light = true,
		sound = true,
		ogg = true,
		webaudio = true,
		sunbeams = true,
		effect = true,
		particles = true,
		trail = true,
		sprite = true,
		beam = true,
		text = true,
	},

	advanced = {
		script = true,
		command = true,
		projectile = true,
		custom_animation = true,
	},
}


pace.MiscIcons = {
	copy = "icon16/page_white_text.png",
	uniqueid = "icon16/vcard.png",
	paste = "icon16/paste_plain.png",
	clone = "icon16/page_copy.png",
	new = "icon16/add.png",
	autoload = "icon16/transmit_go.png",
	url = "icon16/server_go.png",
	outfit = "icon16/group.png",
	clear = "icon16/cross.png",
	language = "icon16/user_comment.png",
	font = "icon16/text_smallcaps.png",
	load = "icon16/folder.png",
	save = "icon16/disk.png",
	exit = "icon16/cancel.png",
	wear = "icon16/transmit.png",
	help = "icon16/help.png",
	info = "icon16/information.png",
	edit = "icon16/table_edit.png",
	revert = "icon16/table_delete.png",
	about = "icon16/star.png",
	appearance = "icon16/paintcan.png",
	orientation = "icon16/shape_handles.png",
	chat = "icon16/comment.png",
	replace = "icon16/arrow_refresh.png",
}
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
	ogg = "icon16/music.png",
	webaudio = "icon16/sound_add.png",
	script = "icon16/page_white_gear.png",
	info = "icon16/help.png",
	bodygroup = "icon16/user.png",
	camera = "icon16/camera.png",
	custom_animation = "icon16/film.png",
	gesture = "icon16/thumb_up.png",
	decal = "icon16/paintbrush.png",
}

pace.PartIcons.effects = pace.PartIcons.effect
pace.PartIcons.advanced = pace.PartIcons.script
pace.PartIcons.modifiers = pace.PartIcons.poseparameter

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
	"SubMaterialId",
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

	SubMaterialId = function(self, num)

		num = tonumber(num) or 0

		local ent = self:GetOwner(self.RootOwner)

		local maxnum = 16

		return math.floor(math.Clamp(num, 0, maxnum))
	end,

	Bodygroup = function(self, num)
		num = tonumber(num)
		return math.Round(math.max(num, 0))
	end,
	BodygroupState = function(self, num)
		num = tonumber(num)
		return math.Round(math.max(num, 0))
	end,

	BaseTextureAngle = function(self, num) self.sens = 0.25 return num end,
	BumpAngle = function(self, num) self.sens = 0.25 return num end,
	EnvMapMaskAngle = function(self, num) self.sens = 0.25 return num end,

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
		return num
	end,
	Pitch = function(self, num)
		self.sens = 0.125
		num = tonumber(num)
		return num
	end,
	RandomPitch = function(self, num)
		self.sens = 0.125
		num = tonumber(num)
		return num
	end,
	MinPitch = function(self, num)
		self.sens = 0.125
		num = tonumber(num)
		return num
	end,
	MaxPitch = function(self, num)
		self.sens = 0.125
		num = tonumber(num)
		return num
	end,
	EchoDelay = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return num
	end,
	EchoFeedback = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1)
	end,
	FilterFraction = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1)
	end,
	FilterType = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Round(math.Clamp(num, 0, 2))
	end,
	PlayCount = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Round(math.max(num, 0))
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

local temp = {}
for group, properties in pairs(pace.PropertySheets) do
	for k,v in pairs(properties) do
		temp[k] = group
	end
end

pace.ReversedPropertySheets = temp

function pace.ShouldHideProperty(key)
	return key:find("UID")
end

function pace.TranslatePropertiesKey(key, obj)
	local key_ = key
	key = key:lower()

	if obj.ClassName == "entity" and (key == "positionoffset" or key == "angleoffset") then
		return ""
	end

	if (
		obj.ClassName == "effect" or
		obj.ClassName == "bone"
		)
		and key == "translucent" then
		return ""
	end

	if key == "string" and obj.ClassName == "command" then
		return key
	end

	if
		key == "damagetype" or
		key == "bone" or
		key == "model" or
		key == "event" or
		key == "operator" or
		key == "arguments" or
		key == "ownername" or
		key == "poseparameter" or
		key == "material" or
		key == "sequence" or
		key == "flex" or
		key == "bodygroupname" or
		key == "effect" or
		key == "code" or
		key == "sound"
	then
		return key
	end

	if key == "weaponholdtype" and obj.ClassName == "animation" then
		return "weaponholdtype"
	end

	if key == "slotname" and obj.ClassName == "gesture" then
		return "gestureslot"
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

	if key == "aimpartname" then
		return "aimpartname"
	end

	if key == "attractmode" then
		return "attract_mode"
	end

	if key == "animationtype" and obj.ClassName == "custom_animation" then
		return "custom_animation_type"
	end

	if
		key == "parentname" or
		key == "followpartname" or
		key == "anglepartname" or
		key == "endpointname" or
		key == "pointaname" or
		key == "pointbname" or
		key == "pointcname" or
		key == "pointdname" or
		key == "targetpartname" or
		key == "outfitpartname"
	then
		return "part"
	end

	if
		key == "sequencename" or
		key == "gesturename" or
		(
			obj.ClassName == "holdtype" and
			(
				obj.ActMods[key_] or
				key == "fallback" or
				key == "noclip" or
				key == "sitting" or
				key == "air"
			)
		)
	then
		return "sequence"
	end

	if key == "spritepath" or key == "trailpath" then
		return "material"
	end

	if obj.ClassName == "material" and obj.ShaderParams[key_] == "ITexture" then
		return "textures"
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

	if key:find("color") and not key:find("use") and isvector(obj[key_]) then
		return "color"
	end

	return obj and obj.TranslatePropertiesKey and obj:TranslatePropertiesKey(key)
end

function pace.GetIconFromClassName(class_name)
	return pace.PartIcons[class_name] or "icon16/plugin.png"
end

hook.Run("pac_EditorPostConfig")