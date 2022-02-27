--[[
	luadata by CapsAdmin (fuck copyright, do what you want with this)

	-- encodes table to string
		string 	luadata.Encode(tbl)

	-- decodes string to table
	-- it will throw an error if there's a syntax error in the table
		table 	luadata.Decode(str)

	-- writes the table to file ( it's just "file.Write(path, luadata.Encode(str))" )
		nil 	luadata.WriteFile(path, tbl)
		table 	luadata.ReadFile(path)

	-- returns a string of how the variable is typically initialized
		string  luadata.ToString(var)

	-- will let you add your own tostring function for a custom type
	-- if you have made a custom data object, you can do this "mymatrix.LuaDataType = "Matrix33""
	-- and it will make luadata.Type return that instead
		nil		luadata.SetModifier(type, callback)

]]

--- luajit bytecode firewall --
local opcode_checker
do
	local bcnames

	local jit = jit or require("jit")
	local ver = jit and jit.version_num or 0

	-- what are these magic versions?
	if ver >= 20000 and ver <= 20009 then
		bcnames = "ISLT  ISGE  ISLE  ISGT  ISEQV ISNEV ISEQS ISNES ISEQN ISNEN ISEQP ISNEP ISTC  ISFC  IST   ISF   MOV   NOT   UNM   LEN   ADDVN SUBVN MULVN DIVVN MODVN ADDNV SUBNV MULNV DIVNV MODNV ADDVV SUBVV MULVV DIVVV MODVV POW   CAT   KSTR  KCDATAKSHORTKNUM  KPRI  KNIL  UGET  USETV USETS USETN USETP UCLO  FNEW  TNEW  TDUP  GGET  GSET  TGETV TGETS TGETB TSETV TSETS TSETB TSETM CALLM CALL  CALLMTCALLT ITERC ITERN VARG  ISNEXTRETM  RET   RET0  RET1  FORI  JFORI FORL  IFORL JFORL ITERL IITERLJITERLLOOP  ILOOP JLOOP JMP   FUNCF IFUNCFJFUNCFFUNCV IFUNCVJFUNCVFUNCC FUNCCW"
	elseif ver==20100 then -- LuaJIT 2.1.0-beta3
		bcnames = "ISLT  ISGE  ISLE  ISGT  ISEQV ISNEV ISEQS ISNES ISEQN ISNEN ISEQP ISNEP ISTC  ISFC  IST   ISF   ISTYPEISNUM MOV   NOT   UNM   LEN   ADDVN SUBVN MULVN DIVVN MODVN ADDNV SUBNV MULNV DIVNV MODNV ADDVV SUBVV MULVV DIVVV MODVV POW   CAT   KSTR  KCDATAKSHORTKNUM  KPRI  KNIL  UGET  USETV USETS USETN USETP UCLO  FNEW  TNEW  TDUP  GGET  GSET  TGETV TGETS TGETB TGETR TSETV TSETS TSETB TSETM TSETR CALLM CALL  CALLMTCALLT ITERC ITERN VARG  ISNEXTRETM  RET   RET0  RET1  FORI  JFORI FORL  IFORL JFORL ITERL IITERLJITERLLOOP  ILOOP JLOOP JMP   FUNCF IFUNCFJFUNCFFUNCV IFUNCVJFUNCVFUNCC FUNCCW"
	end

	local jutil = jit.util
	if not jutil then
		local ok, _jutil = pcall(require,'jit.util')
		if not ok then
			bcnames = nil
		else
			jutil = _jutil
		end
	end

	if not bcnames then
		if not jutil then
			print("[luadata] Verifier could not be loaded. luadata may cause infinite loops.")
		else
			ErrorNoHalt"LUADATA SECURITY WARNING: Unable to load verifier, update me!\n"
		end
		opcode_checker = function() return function() return true end end
	else
		local band =  bit.band

		local opcodes = {}

		--extract opcode names
		for str in bcnames:gmatch "......" do
			str = str:gsub("%s", "")
			table.insert(opcodes, str)
		end

		local function getopnum(opname)
			for k, v in next, opcodes do
				if v == opname then
					return k
				end

			end

			error("not found: " .. opname)
		end


		local function getop(func, pc)
			local ins = jutil.funcbc(func, pc)
			return ins and (band(ins, 0xff)+1)
		end


		opcode_checker = function(white)

			local opwhite = {}
			for i=0,#opcodes do table.insert(opwhite, false) end


			local function iswhitelisted(opnum)
				local ret = opwhite[opnum]
				if ret == nil then
					error("opcode not found " .. opnum)
				end

				return ret
			end

			local function add_whitelist(num)
				if opwhite[num] == nil then
					error "invalid opcode num"
				end

				opwhite[num] = true
			end

			for line in white:gmatch '[^\r\n]+' do

				local opstr_towhite = line:match '[%w]+'

				if opstr_towhite and opstr_towhite:len() > 0 then
					local whiteopnum = getopnum(opstr_towhite)
					add_whitelist(whiteopnum)
					assert(iswhitelisted(whiteopnum))
				end

			end


			local function checker_function(func,max_opcodes)
				max_opcodes = max_opcodes or math.huge
				for i = 1, max_opcodes do
					local ret = getop(func, i)
					if not ret then
						return true
					end

					if not iswhitelisted(ret) then
						--error("non-whitelisted: " .. )
						return false,"non-whitelisted: "..opcodes[ret]
					end

				end
				return false,"checked max_opcodes"
			end

			return checker_function
		end

	end

end


local whitelist = [[TNEW
TDUP

TSETV
TSETS
TSETB
TSETM

KSTR
KCDATA
KSHORT
KNUM
KPRI
KNIL

UNM

GGET
CALL
RET1]]

local is_func_ok = opcode_checker(whitelist)

-------------------------------






local luadata = {}
local s = luadata
luadata.is_func_ok = is_func_ok

luadata.EscapeSequences = {
	[("\a"):byte()] = [[\a]],
	[("\b"):byte()] = [[\b]],
	[("\f"):byte()] = [[\f]],
	[("\t"):byte()] = [[\t]],
	[("\r"):byte()] = [[\r]],
	[("\v"):byte()] = [[\v]],
}

local tab = 0

luadata.Types = {
	["number"] = function(var)
		return ("%s"):format(var)
	end,
	["string"] = function(var)
		return ("%q"):format(var)
	end,
	["boolean"] = function(var)
		return ("%s"):format(var and "true" or "false")
	end,
	["Vector"] = function(var)
		return ("Vector(%s, %s, %s)"):format(var.x, var.y, var.z)
	end,
	["Angle"] = function(var)
		return ("Angle(%s, %s, %s)"):format(var.p, var.y, var.r)
	end,
	["table"] = function(var)
		if
			isnumber(var.r) and
			isnumber(var.g) and
			isnumber(var.b) and
			isnumber(var.a)
		then
			return ("Color(%s, %s, %s, %s)"):format(var.r, var.g, var.b, var.a)
		end

		tab = tab + 1
		local str = luadata.Encode(var, true)
		tab = tab - 1
		return str
	end,
}

function luadata.SetModifier(type, callback)
	luadata.Types[type] = callback
end

function luadata.Type(var)
	local t

	if IsEntity(var) then
		if var:IsValid() then
			t = "Entity"
		else
			t = "NULL"
		end
	else
		t = type(var)
	end

	if t == "table" then
		if var.LuaDataType then
			t = var.LuaDataType
		end
	end

	return t
end

function luadata.ToString(var)
	local func = s.Types[s.Type(var)]
	return func and func(var)
end

function luadata.Encode(tbl, __brackets)
	if luadata.Hushed then return end

	local str = __brackets and "{\n" or ""

	for key, value in pairs(tbl) do
		value = s.ToString(value)
		key = s.ToString(key)

		if key and value and key ~= "__index" then
			str = str .. ("\t"):rep(tab) ..  ("[%s] = %s,\n"):format(key, value)
		end
	end

	str = str .. ("\t"):rep(tab-1) .. (__brackets and "}" or "")

	return str
end

local env = {
	Vector=Vector,
	Angle=Angle,
	Color=Color,
	--Entity=Entity,
}

-- TODO: Bytecode analysis for bad loop and string functions?
function luadata.Decode(str,nojail)
	local func = CompileString(string.format("return { %s }",str), "luadata_decode", false)

	if isstring(func) then
		--ErrorNoHalt("Luadata decode syntax: "..tostring(func):gsub("^luadata_decode","")..'\n')

		return nil,func
	end

	if not nojail then
		setfenv(func,env)
	elseif istable(nojail) then
		setfenv(func,nojail)
	elseif isfunction(nojail) then
		nojail( func )
	end


	local ok,err = is_func_ok( func )
	if not ok or err then
		err = err or "invalid opcodes detected"
		--ErrorNoHalt("Luadata opcode: "..tostring(err):gsub("^luadata_decode","")..'\n')

		return nil,err
	end

	local ok, err = xpcall(func,debug.traceback)

	if not ok then
		--ErrorNoHalt("Luadata decode: "..tostring(err):gsub("^luadata_decode","")..'\n')

		return nil,err
	end

	if isfunction(nojail) then
		nojail( func, err )
	end

	return err
end

do -- file extension
	function luadata.WriteFile(path, tbl)
		if tbl==nil or false --[[empty table!?]] then
			if file.Exists(path,'DATA') then
				file.Delete(path,'DATA')
				return true
			end
			return false,"file does not exist"
		end
		local encoded = luadata.Encode(tbl)
		file.Write(path, encoded)
		--if not file.Exists(path,'DATA') then return false,"could not write" end
		return encoded
	end

	function luadata.ReadFile(path,location,noinvalid)
		local file = file.Read(path,location or 'DATA')
		if not file then
			if noinvalid then return end
			return false,"invalid file"
		end
		return luadata.Decode(file)
	end
end

return luadata
