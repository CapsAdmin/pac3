-- the order of tests is important, smoke test should always be first
local tests = {
	"smoke",
	"base_part",
	"events",
}

local function msg_color(color, ...)
	local str = {}
	for i = 1, select("#", ...) do
		str[i] = select(i, ...)
	end

	MsgC(color, table.concat(str), "\n")
end

local function msg_error(...)
	msg_color(Color(255,50,50), ...)
end

local function msg_warning(...)
	msg_color(Color(255,150,50), ...)
end

local function msg_ok(...)
	msg_color(Color(150,255,50), ...)
end

local function msg(...)
	msg_color(Color(255,255,255), ...)
end


local function CheckOrdered(events)
	return function(got)
		local expected = table.remove(events, 1)
		if expected ~= got then
			msg_error("=============\n")
			msg_error(" expected " .. expected .. " got " .. got .. "\n")
			msg(debug.traceback())
			msg_error("=============\n")
		end
	end, events
end

local function start_test(name, done)
	local test = {}

	test.name = name
	test.time = os.clock() + 5

	function test.Setup() end
	function test.Teardown() end
	function test.Run(done) error("test.Run is not defined") end
	function test.Remove()
		if not test then return end

		test.Teardown()
		done(test)

		-- so that if done was called the same frame, start_test returns nil
		test = nil
	end

	test.CheckOrdered = CheckOrdered

	local function msg_error(...)
		test.error_called = true
		msg_color(Color(255,50,50), ...)
	end

	local function msg_warning(...)
		test.warning_called = true
		msg_color(Color(255,150,50), ...)
	end

	local env = {}
	env.test = test
	env.msg = msg
	env.msg_ok = msg_ok
	env.msg_error = msg_error
	env.msg_warning = msg_warning
	env.msg_color = msg_color

	local func = CompileFile("pac3/core/client/tests/"..name..".lua")

	if not func then
		return
	end

	setfenv(func, setmetatable({}, {
		__index = function(_, key)
			if env[key] then
				return env[key]
			end
			return rawget(_G, key)
		end,
	}))

	func()

	test.Setup()
	test.Run(test.Remove)

	return test
end

concommand.Add("pac_test", function(ply, _, args)
	local what = args[1]

	if not what then
		msg_warning("this command is intended for developers to test that pac works after changing the code")
		msg_warning("it will remove all parts before starting the test")
		msg_warning("if you really want to run this command, run 'pac_test client'")
		return
	end

	if what == "client" then
		pac.RemoveAllParts()

		local tests = table.Copy(tests)

		local current_test = nil

		hook.Add("Think", "pac_tests", function()
			if current_test then
				if current_test.time < os.clock() then
					msg_error("test ", current_test.name, " timed out")
					if current_test.Timeout then
						local ok, err = pcall(current_test.Timeout)
						if not ok then
							msg_error(err)
						end
					end
					current_test.Remove()
					current_test = nil
				end
				return
			end

			local name = table.remove(tests, 1)
			if not name then
				msg("finished testing")
				hook.Remove("Think", "pac_tests")
				return
			end

			msg("running test " .. name)

			current_test = start_test(name, function(test)
				if not test.warning_called and not test.error_called then
					msg_ok(name, " - OK")
				end
				current_test = nil
			end)
		end)
	end
end)