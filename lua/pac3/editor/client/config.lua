-- automate me!

pace.PropertySheets = {}
pace.PropertySheetPatterns = {}
pace.PartTree = {}

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

pace.PropertyOrder = {}
pace.PropertyLimits = {}

local temp = {}
for group, properties in pairs(pace.PropertySheets) do
	for k,v in pairs(properties) do
		temp[k] = group
	end
end

pace.ReversedPropertySheets = temp

function pace.ShouldHideProperty(key)
	local status = hook.Call('PACShouldHideProperty', nil, key)
	if status ~= nil then return status end
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