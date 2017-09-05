-- automate me!

pace.PropertySheets = {}
pace.PropertySheetPatterns = {}
pace.PartTree = {}


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

pace.PropertyOrder = {}

pace.PropertyLimits =
{
	Sequence = function(self, num)
		num = tonumber(num)
		return math.Round(math.min(num, -1))
	end,


	BaseTextureAngle = function(self, num) self.sens = 0.25 return num end,
	BumpAngle = function(self, num) self.sens = 0.25 return num end,
	EnvMapMaskAngle = function(self, num) self.sens = 0.25 return num end,

	Size = function(self, num)
		self.sens = 0.25

		return num
	end,

	Alpha = function(self, num)
		self.sens = 0.25
		num = tonumber(num)
		return math.Clamp(num, 0, 1)
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