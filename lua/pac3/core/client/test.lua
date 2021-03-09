-- the order of tests is important, smoke test should always be first
local tests = {
	"smoke",
	"all_parts",
	"base_part",
	"events",
	"model_modifier",
	"size_modifier",
}

local COLOR_ERROR = Color(255,100,100)
local COLOR_WARNING = Color(255,150,50)
local COLOR_NORMAL = Color(255,255,255)
local COLOR_OK = Color(150,255,50)

-- see bottom of this file and test_suite_backdoor.lua on server for more info
local run_lua_on_server

local function msg_color(color, ...)
	local tbl = {}

	for i = 1, select("#", ...) do
		local val = select(i, ...)
		if IsColor(val) then
			tbl[i] = val
		else
			tbl[i] = tostring(val)
		end
	end

	table.insert(tbl, "\n")

	MsgC(color, unpack(tbl))
end

local function msg_error(...)
	msg_color(COLOR_ERROR, ...)
end

local function msg_warning(...)
	msg_color(COLOR_WARNING, ...)
end

local function msg_ok(...)
	msg_color(COLOR_OK, ...)
end

local function msg(...)
	msg_color(COLOR_NORMAL, ...)
end

local function start_test(name, done)
	local test = {}

	local function msg_error(...)
		test.error_called = true
		msg_color(COLOR_ERROR, ...)
	end

	local function msg_warning(...)
		test.warning_called = true
		msg_color(COLOR_WARNING, ...)
	end

	test.name = name
	test.time = os.clock() + 5

	test.RunLuaOnServer = function(code)
		local ret
		run_lua_on_server(code, function(...) ret = {...} end)
		while not ret do
			coroutine.yield()
		end
		return unpack(ret)
	end

	function test.SetTestTimeout(sec)
		test.time = os.clock() + sec
	end

	function test.Setup()
		hook.Add("ShouldDrawLocalPlayer", "pac_test", function() return true end)
	end

	function test.Teardown()
		hook.Remove("ShouldDrawLocalPlayer", "pac_test")
	end

	function test.Run(done) error("test.Run is not defined") end
	function test.Remove()
		hook.Remove("ShouldDrawLocalPlayer", "pac_test")
		hook.Remove("Think", "pac_test_coroutine")

		if test.done then return end

		if test.events_consume and test.events_consume_index then
			msg_error(test.name .. " finished before consuming event ", test.events_consume[test.events_consume_index], " at index ", test.events_consume_index)
		end

		test.co = nil

		test.Teardown()
		done(test)

		test.done = true
	end

	function test.equal(a, b)
		if a ~= b then
			msg_error("=============")
			msg_error("expected ", COLOR_NORMAL, tostring(a), COLOR_ERROR, " got ", COLOR_NORMAL, tostring(b), COLOR_ERROR, "!")
			msg(debug.traceback())
			msg_error("=============")
		end
	end

	function test.EventConsumer(events)
		test.events_consume = events
		test.events_consume_index = 1
		return function(got)
			if not test.events_consume_index then
				msg_error("tried to consume event when finished")
				msg(debug.traceback())
				return
			end

			local expected = events[test.events_consume_index]
			test.equal(expected, got)
			test.events_consume_index = test.events_consume_index + 1
			if not events[test.events_consume_index] then
				test.events_consume_index = nil
			end
		end
	end

	local env = {}
	env.test = test
	env.msg = msg
	env.msg_ok = msg_ok
	env.msg_error = msg_error
	env.msg_warning = msg_warning
	env.msg_color = msg_color
	env.yield = coroutine.yield

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

	test.co = coroutine.create(function()
		test.Run(test.Remove)
	end)

	local ok, err = coroutine.resume(test.co)

	if not ok then
		ErrorNoHalt(err)
		test.Remove()
	end

	hook.Add("Think", "pac_test_coroutine", function()
		if not test.co then return end

		local ok, err = coroutine.resume(test.co)

		if not ok and err ~= "cannot resume dead coroutine" then
			ErrorNoHalt(err)
			test.Remove()
		end
	end)

	if test.done then
		return
	end

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
		local which = args[2]

		pac.RemoveAllParts()

		local tests = table.Copy(tests)

		if which then
			tests = {which}
		end

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

local lua_server_run_callbacks = {}

function run_lua_on_server(code, cb)
	local id = util.CRC(code .. tostring(cb))
	lua_server_run_callbacks[id] = cb
	net.Start("pac3_test_sutie_backdoor")
		net.WriteString(id)
		net.WriteString(code)
	net.SendToServer()
end

net.Receive("pac3_test_sutie_backdoor_receive_results", function()
	local id = net.ReadString()
	local results = net.ReadTable()
	lua_server_run_callbacks[id](unpack(results))
	lua_server_run_callbacks[id] = nil
end)