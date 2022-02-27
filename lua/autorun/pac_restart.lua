AddCSLuaFile()

if SERVER then
	return
end

local sv_allowcslua = GetConVar('sv_allowcslua')
local prefer_local_version = CreateClientConVar("pac_restart_prefer_local_version", "0")

function _G.pac_ReloadParts()
	local pacLocal = _G.pac

	local _, dirs = file.Find("addons/*", "MOD")
	for _, dir in ipairs(dirs) do
		if file.Exists("addons/" .. dir .. "/lua/autorun/pac_editor_init.lua", "MOD") then
			pacLocal.Message("found PAC3 in garrysmod/addons/" .. dir)
			local old_include = _G.include

			local function include(path, ...)
				local new_path = path
				if not file.Exists("addons/" .. dir .. "/lua/" .. path, "MOD") then
					local src = debug.getinfo(2).source
					local lua_dir = src:sub(2):match("(.+/)")
					if lua_dir:StartWith("addons/" .. dir) then
						lua_dir = lua_dir:match("addons/.-/lua/(.+)")
					end
					new_path = lua_dir .. path
				end

				if file.Exists("addons/" .. dir .. "/lua/" .. new_path, "MOD") then
					local str = file.Read("addons/" .. dir .. "/lua/" .. new_path, "MOD")
					if str then
						local func = CompileString(str, "addons/" .. dir .. "/lua/" .. new_path)
						if isfunction(func) then
							local res = {pcall(func, ...)}

							if res[1] then
								return unpack(res, 2)
							end

							pacLocal.Message("pac_restart: pcall error: " .. res[2])
						else
							pacLocal.Message("pac_restart: compile string error: " .. func)
						end
					end
				end

				return old_include(path, ...)
			end

			_G.include = include
			local ok, err = pcall(function()
				pac.LoadParts()
			end)
			_G.include = old_include
			break
		end
	end
end

function _G.pac_Restart()
	PAC_MDL_SALT = PAC_MDL_SALT + 1

	local editor_was_open
	local prev_parts = {}
	local pacLocal = _G.pac
	local selected_part_uid
	local model_browser_opened

	if pace then
		if pace.Editor and pace.Editor:IsValid() then
			editor_was_open = true
			if pace.current_part and pace.current_part:IsValid() then
				selected_part_uid = pace.current_part:GetUniqueID()
			end

			for key, part in pairs(pac.GetLocalParts()) do
				if not part:HasParent() and part:GetShowInEditor() then
					local ok, err = pcall(function()
						table.insert(prev_parts, part:ToTable())
					end)
					if not ok then print(err) end
				end
			end
		end

		if pace.model_browser and pace.model_browser:IsValid() and pace.model_browser:IsVisible() then
			model_browser_opened = true
			pace.model_browser:Remove()
		end
	end

	if pac and pac.Disable then
		pacLocal.Message("removing all traces of pac3 from lua")
		pac.Disable()
		pac.Panic()

		if pace and pace.Editor then
			editor_was_open = pace.Editor:IsValid()
			pace.Panic()
		end

		for _, ent in pairs(ents.GetAll()) do
			for k in pairs(ent:GetTable()) do
				if k:sub(0, 4) == "pac_" then
					ent[k] = nil
				end
			end
		end

		for hook_name, hooks in pairs(hook.GetTable()) do
			for id, func in pairs(hooks) do
				if isstring(id) and (id:StartWith("pace_") or id:StartWith("pac_") or id:StartWith("pac3_") or id:StartWith("pacx_")) then
					hook.Remove(hook_name, id)
				end
			end
		end

		timer.Remove("pac_gc")
		timer.Remove("pac_render_times")
		timer.Remove("urlobj_download_queue")

		_G.pac = nil
		_G.pace = nil
		_G.pacx = nil

		collectgarbage()
	end

	_G.PAC_RESTART = true

	if not prefer_local_version:GetBool() then
		pacLocal.Message("pac_restart: not reloading from local version")

		for _, path in ipairs((file.Find("autorun/pac*", "LUA"))) do
			if path:EndsWith("_init.lua") and path ~= "pac_init.lua" then
				include("autorun/" .. path)
			end
		end

	elseif sv_allowcslua:GetBool() or LocalPlayer():IsSuperAdmin() then
		local loadingHit = false

		if sv_allowcslua:GetBool() then
			pacLocal.Message("pac_restart: sv_allowcslua is on, looking for PAC3 addon..")
		end

		if LocalPlayer():IsSuperAdmin() then
			pacLocal.Message("pac_restart: LocalPlayer() is superadmin, looking for PAC3 addon..")
		end

		local _, dirs = file.Find("addons/*", "MOD")
		for _, dir in ipairs(dirs) do
			if file.Exists("addons/" .. dir .. "/lua/autorun/pac_editor_init.lua", "MOD") then
				pacLocal.Message("found PAC3 in garrysmod/addons/" .. dir)
				local old_include = _G.include

				local function include(path, ...)
					local new_path = path
					if not file.Exists("addons/" .. dir .. "/lua/" .. path, "MOD") then
						local src = debug.getinfo(2).source
						local lua_dir = src:sub(2):match("(.+/)")
						if lua_dir:StartWith("addons/" .. dir) then
							lua_dir = lua_dir:match("addons/.-/lua/(.+)")
						end
						new_path = lua_dir .. path
					end

					if file.Exists("addons/" .. dir .. "/lua/" .. new_path, "MOD") then
						local str = file.Read("addons/" .. dir .. "/lua/" .. new_path, "MOD")
						if str then
							local func = CompileString(str, "addons/" .. dir .. "/lua/" .. new_path)
							if isfunction(func) then
								local res = {pcall(func, ...)}

								if res[1] then
									return unpack(res, 2)
								end

								pacLocal.Message("pac_restart: pcall error: " .. res[2])
							else
								pacLocal.Message("pac_restart: compile string error: " .. func)
							end
						end
					end

					pacLocal.Message("pac_restart: couldn't include " .. new_path .. " reverting to normal include")

					return old_include(path, ...)
				end

				_G.include = include

				for _, path in ipairs((file.Find("autorun/pac_*", "LUA"))) do
					if path:EndsWith("_init.lua") and path ~= "pac_init.lua" then
						pacLocal.Message("pac_restart: including autorun/" .. path .. "...")

						local ok, err = pcall(function()
							include("autorun/" .. path)
						end)

						if not ok then
							pacLocal.Message("pac_restart: error when reloading pac " .. err)
						end
					end
				end

				_G.include = old_include

				loadingHit = true
				break
			end
		end


		if not loadingHit then
			pacLocal.Message("sv_allowcslua is not enabled or unable to find PAC3 in addons/, loading PAC3 again from server lua")

			for _, path in ipairs((file.Find("autorun/pac*", "LUA"))) do
				if path:EndsWith("_init.lua") and path ~= "pac_init.lua" then
					include("autorun/" .. path)
				end
			end
		end
	end

	_G.PAC_RESTART = nil

	if editor_was_open then
		pace.OpenEditor()
	end

	pac.Enable()

	if prev_parts[1] then
		pace.LoadPartsFromTable(prev_parts, true)
	end

	pacLocal.Message("pac_restart: done")

	if selected_part_uid then
		local part = pac.GetPartFromUniqueID(pac.Hash(pac.LocalPlayer), selected_part_uid)

		if part and part:IsValid() then
			pace.Call("PartSelected", part)
		end
	end

	if model_browser_opened then
		RunConsoleCommand("pac_asset_browser")
	end

	local msg = "*•.¸♥¸.•* IF YOU ARE USING PAC_RESTART TO FIX A BUG IT WOULD BE NICE IF YOU COULD ALSO REPORT THE BUG *•.¸♥¸.•*"
	local words = msg:Split(" ")
	for i2 = 1, 40 do
		for i, word in ipairs(words) do
			local f = i / #words
			MsgC(HSVToColor(Lerp(f, 0, 360), 0.6, 1), word, " ")
		end
		MsgN("")
	end
	MsgC(Color(79,155,245), "https://github.com/CapsAdmin/pac3/issues", "\n")
	MsgC(Color(79,155,245), "https://discord.com/invite/utpR3gJ", "\n")
	MsgC(Color(79,155,245), "https://steamcommunity.com/sharedfiles/filedetails/?id=104691717", "\n")
	MsgC(Color(79,155,245), "https://steamcommunity.com/id/eliashogstvedt", "\n")
end

concommand.Add("pac_restart", _G.pac_Restart)