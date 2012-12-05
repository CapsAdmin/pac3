local lib = 
{
	PI = math.pi,
	rand = math.random,
	randx = function(a,b)
		a = a or -1
		b = b or 1
		return math.Rand(a, b)
	end,
	
	abs = math.abs,
	acos = math.acos,
	asin = math.asin,
	atan = math.atan,
	atan2 = math.atan2,
	ceil = math.ceil,
	cos = math.cos,
	cosh = math.cosh,
	deg = math.deg,
	exp = math.exp,
	floor = math.floor,
	frexp = math.frexp,
	ldexp = math.ldexp,
	log = math.log,
	log10 = math.log10,
	max = math.max,
	min = math.min,
	rad = math.rad,
	sin = math.sin,
	sinh = math.sinh,
	sqrt = math.sqrt,
	tanh = math.tanh,
	tan = math.tan,
}
local allowed_chars = "%(%),%.^%+%-/%*%d%s=><%%"

do
	local str = "IN"
	for k in pairs(lib) do str = str .. k end
	allowed_chars = allowed_chars .. str
	allowed_chars = "[" .. allowed_chars .. "]"
end

local blacklist = {"do", "for", "repeat", "until", "function", "end"}

function compile_expression(str, extra_lib)		
	local illegal_chars = str:gsub(allowed_chars, "")
	if #illegal_chars ~= 0 then		
		return false, string.format("illegal characters used %q", illegal_chars)
	end
	
	for _, word in pairs(blacklist) do
		if str:find("[%p%s]" .. word) or str:find(word .. "[%p%s]") then
			return false, string.format("illegal characters used %q", word)
		end
	end
	
	if extra_lib then
		for k,v in pairs(extra_lib) do lib[k] = v end
	end
	
	lib.select = select
	str = "local IN = select(1, ...) return " .. str
	local func = CompileString(str, "pac_expression", false)
	if type(func) == "string" then
		print(func)	
	else
		setfenv(func, lib)
		return true, func
	end
end

pac.CompileExpression = compile_expression