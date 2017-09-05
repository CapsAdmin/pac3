-- automate me!

pace.PropertySheets = {
	orientation =
	{
		aimpartname = true,
		alternativescaling = true,
		angleoffset = true,
		angles = true,
		bone = true,
		bonemerge = true,
		eyeangles = true,
		eyeangleslerp = true,
		farz = true,
		fov = true,
		nearz = true,
		position = true,
		positionoffset = true,
		scale = true,
		size = true,
	},

	appearance =
	{
		additive = true,
		alpha =  true,
		blurlength = true,
		blurspacing = true,
		brightness = true,
		cellshade =  true,
		color =  true,
		doubleface =  true,
		draworder = true,
		drawshadow = true,
		drawviewmodel = true,
		endalpha =  true,
		endcolor =  true,
		font =  true,
		fullbright =  true,
		invert =  true,
		lightblend =  true,
		lodoverride = true,
		modelfallback = true,
		outline =  true,
		outlinealpha =  true,
		outlinecolor =  true,
		passes =  true,
		skin =  true,
		startalpha =  true,
		startcolor =  true,
		stretch =  true,
		texturefilter =  true,
		tintcolor =  true,
		translucent =  true,
		useplayercolor = true,
		useweaponcolor = true,
	},

	other =
	{
		draworder = true,
		duplicate = true,
		ownerentity = true,
		showinfirstperson = true,
	},

	event = {

	},

	entity = {
		behavior =
		{
			animationrate = true,
			deathragdollizeparent = true,
			fallapartondeath = true,
			hideragdollondeath = true,
			inversekinematics = true,
			movespeed = true,
			mutefootsteps = true,
			playercollide = true,
			relativebones = true,
			weapon = true,
		},
		movement =
		{
			crouchspeed = true,
			runspeed = true,
			sprintspeed = true,
			walkspeed = true,
		},
		appearance = {
			drawweapon = true,
			hideentity = true,
		}
	},

	proxy = {
		["easy setup"] =
		{
			["function"] = true,
			axis = true,
			input = true,
			inputdivider = true,
			inputmultiplier = true,
			max = true,
			min = true,
			offset = true,
			pow = true,
		},
		["behavior"] =
		{
			additive = true,
			playerangles = true,
			resetvelocitiesonhide = true,
			velocityroughness = true,
			zeroeyepitch = true,
		}
	},

	particles = {
		orientation =
		{
			aimpartname = true,
			angleoffset = true,
			angles = true,
			bone = true,
			eyeangles = true,
			position = true,
			positionoffset = true,
		},
		appearance = {
			["3d"] = true,
			color1 = true,
			color2 = true,
			doublesided = true,
			drawmanual = true,
			draworder = true,
			endalpha = true,
			lighting = true,
			material = true,
			randomcolour = true,
			startalpha = true,
			translucent = true,
		},
		rotation = {
			particleanglevelocity = true,
			randomrollspeed = true,
			rolldelta = true,
		},
		movement = {
			airresistance = true,
			bounce = true,
			collide = true,
			gravity = true,
			ownervelocitymultiplier = true,
			sliding = true,
			spread = true,
			velocity = true,
		},
	}
}

pace.PropertySheets.entity.orientation = pace.PropertySheets.orientation
pace.PropertySheets.entity.appearance = pace.PropertySheets.appearance

pace.PropertySheetPatterns = {
	material = {
		["ambient occlusion"] = {"ambientocclusion", "halflambert"},
		["cloak"] = {"cloak", "refract"},
		["colors"] = "color",
		["detail"] = "detail",
		["emissive"] = "emissive",
		["env map"] = "envmap.+",
		["flesh"] = "flesh",
		["phong"] = "phong",
		["rimlight"] = "rimlight",
		["selfillum"] = "selfillum",
		["textures"] = {"bumpmap", "basetexture", "envmap", "lightwarptexture"},
	},
	particles = {
		["stick"] = {"stick", "align"},
	}
}

pace.MiscIcons = {
	about = "icon16/star.png",
	appearance = "icon16/paintcan.png",
	autoload = "icon16/transmit_go.png",
	chat = "icon16/comment.png",
	clear = "icon16/cross.png",
	clone = "icon16/page_copy.png",
	copy = "icon16/page_white_text.png",
	edit = "icon16/table_edit.png",
	exit = "icon16/cancel.png",
	font = "icon16/text_smallcaps.png",
	help = "icon16/help.png",
	info = "icon16/information.png",
	language = "icon16/user_comment.png",
	load = "icon16/folder.png",
	new = "icon16/add.png",
	orientation = "icon16/shape_handles.png",
	outfit = "icon16/group.png",
	paste = "icon16/paste_plain.png",
	replace = "icon16/arrow_refresh.png",
	revert = "icon16/table_delete.png",
	save = "icon16/disk.png",
	uniqueid = "icon16/vcard.png",
	url = "icon16/server_go.png",
	wear = "icon16/transmit.png",
}

pace.GroupsIcons = {
	effects = 'icon16/wand.png',
	model = 'icon16/shape_square.png',
	entity = 'icon16/brick.png',
	modifiers = 'icon16/disconnect.png',
	advanced = 'icon16/page_white_gear.png'
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
		key == "arguments" or
		key == "bodygroupname" or
		key == "bone" or
		key == "code" or
		key == "damagetype" or
		key == "effect" or
		key == "event" or
		key == "flex" or
		key == "material" or
		key == "model" or
		key == "operator" or
		key == "ownername" or
		key == "poseparameter" or
		key == "sequence" or
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
		key == "anglepartname" or
		key == "endpointname" or
		key == "followpartname" or
		key == "outfitpartname" or
		key == "parentname" or
		key == "pointaname" or
		key == "pointbname" or
		key == "pointcname" or
		key == "pointdname" or
		key == "targetpartname"
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

hook.Run("pac_EditorPostConfig")