local lib = {
	PI = math.pi,
	rand = math.random,
	randx = function(a, b)
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
	sgn = function(n) return n>0 and 1 or n<0 and -1 or 0 end,

	clamp = math.Clamp,
	round = math.Round,
}

local blacklist = {
    "function";
    "for"; "break";
    "while"; "do";
    "repeat"; "until";
}

-- convert blacklist items into patterns to match
for k, item in pairs(blacklist) do
    -- uses more efficient / conclusive frontier pattern syntax
    -- frontier matches transition into and out of sets
    -- in this case, matching transition into letters and then out of letters (to match whole words and not partials)
    blacklist[k] = ("%%f[%%a](%s)%%f[%%A]"):format(item)
end

local function_intro = "local IN = (...); "

local function_formats = {
    function_intro .. "return %s";
    function_intro .. "%s"; -- allows <code>return</code> semantics
}

local function TryCompile(code, identifier)
    local result = CompileString(code, identifier, false)
    
    return not isstring(result), result
end

local function CompileStringAdvanced(code, identifier)
    local success, func = false, nil
    
    for _, structure in pairs(function_formats) do
        success, func = TryCompile(structure:format(code), identifier)
        
        if success then break end
    end
    
    return success, func
end

local function readonlyError()
    error("Not allowed to assign to globals", 2)
end

local function makeReadonly(t)
    return setmetatable(
        {}, 
        {
            __index = t,
            __newindex = readonlyError,
            __metatable = "This metatable is locked."
        }
    )
end

local function copyInto(t1, t2)
    for k,v in pairs(t1) do t2[k] = v end
end

local function checkBlacklist(code)
    local str
    
    for _, word in pairs(blacklist) do
        str = code:match(word)
        
		if str then
			return str
		end
	end
    
    return nil
end

local function compile_expression(str, extra_lib)
    local illegalWord = checkBlacklist(str)
    
	if illegalWord then
        return false, string.format("illegal characters used %q", illegalWord)
    end

	local success, func = CompileStringAdvanced(str, "pac_expression")

	if success then
        local functions = {}

        copyInto(lib, functions)

        if extra_lib then
            copyInto(extra_lib, functions)
        end

        functions.select = select
        
        setfenv(
            func, 
            makeReadonly(functions)
        )
        
		return true, func
	end
    
    return false, func
end

return compile_expression
