
local PREFIX = '[PAC3] '
local PREFIX_COLOR = Color(255, 255, 0)

local DEFAULT_TEXT_COLOR = Color(200, 200, 200)
local BOOLEAN_COLOR = Color(33, 83, 226)
local NUMBER_COLOR = Color(245, 199, 64)
local STEAMID_COLOR = Color(255, 255, 255)
local ENTITY_COLOR = Color(180, 232, 180)
local FUNCTION_COLOR = Color(62, 106, 255)
local TABLE_COLOR = Color(107, 200, 224)
local URL_COLOR = Color(174, 124, 192)

function pac.RepackMessage(strIn)
	local output = {}

	for line in string.gmatch(strIn, '([^ ]+)') do
		if #output ~= 0 then
			table.insert(output, ' ')
		end

		table.insert(output, line)
	end

	return output
end

local function FormatMessage(tabIn)
	local prevColor = DEFAULT_TEXT_COLOR
	local output = {prevColor}

	for i, val in ipairs(tabIn) do
		local valType = type(val)

		if valType == 'number' then
			table.insert(output, NUMBER_COLOR)
			table.insert(output, tostring(val))
			table.insert(output, prevColor)
		elseif valType == 'string' then
			if val:find('^https?://') then
				table.insert(output, URL_COLOR)
				table.insert(output, val)
				table.insert(output, prevColor)
			else
				table.insert(output, val)
			end
		elseif valType == 'Player' then
			if team then
				table.insert(output, team.GetColor(val:Team()) or ENTITY_COLOR)
			else
				table.insert(output, ENTITY_COLOR)
			end

			table.insert(output, val:Nick())

			if val.SteamName and val:SteamName() ~= val:Nick() then
				table.insert(output, ' (' .. val:SteamName() .. ')')
			end

			table.insert(output, '<')
			table.insert(output, val:SteamID())
			table.insert(output, '>')
			table.insert(output, prevColor)
		elseif valType == 'Entity' or valType == 'NPC' or valType == 'Vehicle' then
			table.insert(output, ENTITY_COLOR)
			table.insert(output, tostring(val))
			table.insert(output, prevColor)
		elseif valType == 'table' then
			if val.r and val.g and val.b then
				table.insert(output, val)
				prevColor = val
			else
				table.insert(output, TABLE_COLOR)
				table.insert(output, tostring(val))
				table.insert(output, prevColor)
			end
		elseif valType == 'function' then
			table.insert(output, FUNCTION_COLOR)
			table.insert(output, string.format('function - %p', val))
			table.insert(output, prevColor)
		elseif valType == 'boolean' then
			table.insert(output, BOOLEAN_COLOR)
			table.insert(output, tostring(val))
			table.insert(output, prevColor)
		else
			table.insert(output, tostring(val))
		end
	end

	return output
end

pac.FormatMessage = FormatMessage

function pac.Message(...)
	local formatted = FormatMessage({...})
	MsgC(PREFIX_COLOR, PREFIX, unpack(formatted))
	MsgC('\n')
	return formatted
end

function pac.dprint(fmt, ...)
	if not pac.debug then return end
	MsgN("\n")
	MsgN(">>>PAC3>>>")
	MsgN(fmt:format(...))
	if pac.debug_trace then
		MsgN("==TRACE==")
		debug.Trace()
		MsgN("==TRACE==")
	end
	MsgN("<<<PAC3<<<")
	MsgN("\n")
end
