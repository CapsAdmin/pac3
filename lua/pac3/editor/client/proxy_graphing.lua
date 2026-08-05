local tracked_proxy

local ease_aliases = {}
for ease,f in pairs(math.ease) do
	if string.find(ease,"In") or string.find(ease,"Out") then
		ease_aliases[ease] = ease
		ease_aliases["ease"..ease] = ease
		ease_aliases["ease_"..ease] = ease
	end
end
do -- grapher - line chart
	local current_runtime_data = {
		output_bounds = {0, 10},
		step = 0,
		scroll = false,
		input_bounds = {-10,10},
	}
	local sampled_data = {}
	local mouse_hovering = false
	local relative_mx = 0
	local relative_my = 0
	local graph_w = 0
	local graph_h = 0
	local graph_x_variable = "time()"
	local graph_x_variable_current_real_value = 0
	local active_output_variable = ""
	local active_expression = ""
	local last_active_expression = ""
	local mouse_crossing = {0,0}
	local asymptotes = {}
	local asymptotes_mids = {}
	local y_crossings = {}
	local graph_axis = "x"
	local graph_title = ""
	local graph_y_value_max = 0
	local graph_y_value_min = 0
	local x_btn, y_btn, z_btn

	local saved_vgui_values = {
		step = 0,
		max_x = 10,
		min_x = -1,
		max_y = 10,
		min_y = -10,
		asymptote = 100,
	}

	local drawn_points = 0
	local drawn_points_failures = 0
	local point_check_bypass = false
	local points_cache = {}
	local sorted_points_cache = {}
	local throttle_limit = 2000
	local throttle_burst_limit = 150
	local throttle = true
	--sequential, recursive, random
	local recursion_level = 0
	local plan_steps = 60
	local current_plan_batch = 1
	local planned_samples = {}
	local graph_following_x = false
	local extended_bounds = {0,0}

	local recording_mode = false


	local function DataCoversDisplayRange(data, min, max)
		if not data then return false end
		if not data[1] then return false end
		if data[1][1] > min then return false end
		if data[#data][1] < max then return false end
		return true
	end
	local function CacheDataCoversDisplayRange(min, max)
		if not sorted_points_cache then return false end
		if sorted_points_cache[1][1] > min then return false end
		if sorted_points_cache[#sorted_points_cache][1] < max then return false end
		return true
	end

	local function PlanOutSamplePoints(override_range, inserting_mode)
		runtime_data = current_runtime_data
		planned_samples = {}

		local bounds = runtime_data.input_bounds
		local bounds2 = {bounds[1],bounds[2]}
		local step = math.max(runtime_data.step, (bounds[2] - bounds[1]) / 500)

		--if throttle then step = 3*step end

		local split = 1
		local min = bounds[1]
		local max = bounds[2]
		bounds2[1] = min - 2*(max - min)
		bounds2[2] = max + 2*(max - min)
		extended_bounds = bounds2
		--end
		local resume = bounds2[1]
		local input_x = bounds2[1]

		if not throttle and override_range then
			min = override_range[1]
			max = override_range[2]
		end

		for i=1,plan_steps,1 do
			if throttle then input_x = resume else bounds2 = {min, max} end
			planned_samples[split] = {}
			local i2 = 0
			while ((input_x < bounds2[2]) and (i2 < throttle_burst_limit)) do --until max sample or throttle
				i2 = i2 + 1
				if i2 > throttle_burst_limit then
					continue
				end
				table.insert(planned_samples[split],input_x)
				input_x = input_x + step
				resume = input_x
			end
			split = split+1
		end
	end

	local function reset_points_cache(deep_reset)
		if not deep_reset then
			for x_val,y_val in pairs(points_cache) do
				if x_val > extended_bounds[1] and x_val < extended_bounds[2] then
					points_cache[x_val] = nil
				end
			end
			current_plan_batch = 1
			sampled_data = nil
			planned_samples = {}
			return
		end
		current_plan_batch = 1
		sampled_data = nil
		planned_samples = {}
		points_cache = {}
	end

	local last_post_compile_time = 0
	local function SampleData(part, variable_x, runtime_data, inserting_mode)
		local str = part.Expression
		--build expression from easy setup
		if str == "" then str = 
			part.Min .. " + (" .. part.Max .. " - " .. part.Min .. ") * (" ..
			"(" .. part.Function .. "(((" .. part.Input .. "()/" .. part.InputDivider .. ") + " .. part.Offset .. ") * " ..
			part.InputMultiplier .. ") + 1) / 2) ^" .. part.Pow
		end

		active_expression = str
		local step = runtime_data.step
		local bounds = runtime_data.input_bounds
		local points = {}
		if inserting_mode then points = points_cache end

		if active_expression ~= last_active_expression then
			reset_points_cache(true)
			PlanOutSamplePoints()
		end

		last_active_expression = str

		if not planned_samples then PlanOutSamplePoints() end
		if table.IsEmpty(planned_samples) then PlanOutSamplePoints() end

		local stime = SysTime()
		local ok, func = pac.CompileExpression(part.Expression, part.lib)
		if not ok then return {} end --it aint gonna give us anything

		local input_x = bounds[1]
		local j = 0 -- loop counter
		local i = bounds[1] --min sample

		--main sampling
		if current_plan_batch < plan_steps or recording_mode then
			--while input_x < bounds[2] do --until max sample
			local nils
			local x_same = false 
			local y_same = false
			local z_same = false 

			local prev_x
			local prev_y
			local prev_z
			if not recording_mode then
				for i,X in ipairs(planned_samples[current_plan_batch]) do
					--may be slightly randomized
					local compute_input_x = X
					if j > throttle_limit then break end

					local substituted_func = string.Replace(str,variable_x,compute_input_x)
					if graph_x_variable == "timeex()" and not recording_mode then
						part.timeex_override = compute_input_x
						if pac.StringFind(str, "time()") then
							substituted_func = string.Replace(substituted_func, "time()", "(" .. part.timeex_override .. ")")
						end
					end
					
					local ok2, res = pac.CompileExpression(substituted_func, part.lib)
					if ok2 then
						local value = 0
						local ok3, x,y,z = part:RunExpression(res)
						local val = 0
						if graph_axis == "x" then
							val = x or 0
						elseif graph_axis == "y" then
							val = y or 0
						elseif graph_axis == "z" then
							val = z or 0
						end
						if not x or not y or not z then
							nils = nils or {}
							if x == nil then
								nils.x =  true
							end
							if y == nil then
								nils.y = true
							end
							if z == nil then
								nils.z = true
							end
						end
						if isvector(val) then
							value = val.x or 0
						elseif isnumber(val) then
							value = val
						end
						table.insert(points, {compute_input_x, value})
						points_cache[compute_input_x] = value
						
						graph_y_value_min = math.min(value, graph_y_value_min)
						graph_y_value_max = math.max(value, graph_y_value_max)
					end
					input_x = math.Clamp(input_x + step,runtime_data.input_bounds[1],runtime_data.input_bounds[2])
					j = j + 1
					i = i + 1
				end
			else
				local compute_input_x = graph_x_variable_current_real_value
				local substituted_func = string.Replace(str,variable_x,compute_input_x)

				local ok2, res = pac.CompileExpression(substituted_func, part.lib)
				if ok2 then
					local value = 0
					local ok3, x,y,z = part:RunExpression(res)
					local val = 0
					if graph_axis == "x" then
						val = x or 0
					elseif graph_axis == "y" then
						val = y or 0
					elseif graph_axis == "z" then
						val = z or 0
					end
					if not x or not y or not z then
						nils = nils or {}
						if x == nil then
							nils.x =  true
						end
						if y == nil then
							nils.y = true
						end
						if z == nil then
							nils.z = true
						end
					end
					if isvector(val) then
						value = val.x or 0
					elseif isnumber(val) then
						value = val
					end
					table.insert(points, {compute_input_x, value})
					points_cache[compute_input_x] = value
					
					graph_y_value_min = math.min(value, graph_y_value_min)
					graph_y_value_max = math.max(value, graph_y_value_max)
				end
				input_x = math.Clamp(input_x + step,runtime_data.input_bounds[1],runtime_data.input_bounds[2])
				j = j + 1
				i = i + 1
			end
			
			if nils then
				runtime_data.nils = nils
			end
			current_plan_batch = current_plan_batch + 1
		end

		--final iteration
		local substituted_func = string.Replace(str,variable_x,input_x)
		local ok2, res = pac.CompileExpression(string.Replace(str,variable_x,input_x), part.lib)
		if ok2 then
			local value = 0
			local ok3, x,y,z = part:RunExpression(res)
			local val = 0
			if graph_axis == "x" then
				val = x or 0
			elseif graph_axis == "y" then
				val = y or 0
			elseif graph_axis == "z" then
				val = z or 0
			end
			if isvector(val) then
				value = val.x
			elseif isnumber(x) then
				value = val
			end
			table.insert(points, {input_x, value})
		end
		local current_post_compile_time = SysTime() - stime
		if mouse_hovering then
			input_x = Lerp(relative_mx / graph_w, runtime_data.input_bounds[1], runtime_data.input_bounds[2])
			
			local substituted_func = string.Replace(str,variable_x,input_x)
			local ok2, res = pac.CompileExpression(string.Replace(str,variable_x,input_x), part.lib)
			if ok2 then
				local value = 0
				local ok3, x,y,z = part:RunExpression(res)
				--[[if isvector(x) then
					--z = x.z
					--y = x.y
					--x = x.x
					value = x.x
				else]]
				if isnumber(x) then
					value = x
				end
				pace.FlashNotification("crossing = " .. input_x .. ", " .. value, 0.1)
			end
		end

		local unsorted_points = {}
		for x_val,y_val in pairs(points_cache) do
			if x_val > extended_bounds[1] and x_val < extended_bounds[2] then
				table.insert(unsorted_points, {x_val,y_val})
			end
		end
		table.sort(unsorted_points, function(a,b) return a[1] < b[1] end)
		for i=1, #unsorted_points - 1 do
			local a = unsorted_points[i]
			local b = unsorted_points[i+1]
			a[3] = (b[2] - a[2]) / (b[1] - a[1])
		end
		points = unsorted_points --sorted points
		sorted_points_cache = unsorted_points

		sampled_data = points
		y_crossings = {}
		local asymptote_slope = math.abs(pace.proxygraph_properties.panels["asymptote"]:GetValue())
		local domain = runtime_data.input_bounds[2] - runtime_data.input_bounds[1]
		local codomain = runtime_data.output_bounds[2] - runtime_data.output_bounds[1]
		local asymptote_check =
			string.find(active_expression,"/",0,true) or string.find(active_expression,"%",0,true) or string.find(active_expression,"tan",0,true)
			or string.find(active_expression,"floor",0,true) or string.find(active_expression,"ceil",0,true)
			or string.find(active_expression,"if_else",0,true) or string.find(active_expression,"if_event",0,true)
			or string.find(active_expression,"number_operator_alternative",0,true) or string.find(active_expression,"event_alternative",0,true)
		local asymptote_continuous_range_min = 0
		local asymptote_continuous_range_max = 0
		asymptotes = {}
		asymptotes_mids = {}
		for i,point in ipairs(points) do
			local slope = 0
			if points[i-1] then
				slope = (domain / codomain) * math.abs(points[i-1][3])
				--slope = (domain / codomain) * math.abs((points[i][2] - points[i-1][2]) / (points[i][1] - points[i-1][1]))
			end
			if point[2] ~= point[2] then -- NaN check?
				asymptotes[i] = true
			elseif math.abs(point[2]) > 3218311697140 then
				--idk I just grabbed a random gajillion value I got from a near-zero divide (floating point error made it not exactly 0)
				asymptotes[i] = true
			elseif (slope > asymptote_slope) and asymptote_check then
				asymptotes[i] = true
			else
				asymptotes[i] = false
			end
			if asymptotes[i] then
				if asymptote_continuous_range_min == 0 then
					asymptote_continuous_range_min = i
				end
			else
				if asymptotes[i-1] then
					asymptote_continuous_range_max = i - 1
					asymptotes_mids[math.floor((asymptote_continuous_range_max + asymptote_continuous_range_min) / 2)] = true
				end
				asymptote_continuous_range_max = 0
				asymptote_continuous_range_min = 0
			end
		end
		part.timeex_override = nil
		return points
	end

	local function AddMorePoints(data, min, max)
		local added_data = {}
		local range = max - min
		local compile_x = min
		local part = tracked_proxy
		local i = 0

		local input_bounds = {
			math.Round(pace.proxygraph_properties.panels["min_x"]:GetValue(),4),
			math.Round(pace.proxygraph_properties.panels["max_x"]:GetValue(),4)
		}
		--input_bounds = {CurTime() - 10, CurTime() + 10}
		local steps = pace.proxygraph_properties.panels["step"]:GetValue()
		if steps == 0 then
			steps = (input_bounds[2] - input_bounds[1]) / 500
		end

		while compile_x < max do
			if i > 50 then break end
			--may be slightly randomized
			local compute_input_x = compile_x

			local substituted_func = string.Replace(active_expression,graph_x_variable,compute_input_x)
			if graph_x_variable == "timeex()" and not recording_mode then
				part.timeex_override = compute_input_x
				if pac.StringFind(str, "time()") then
					substituted_func = string.Replace(substituted_func, "time()", "(" .. part.timeex_override .. ")")
				end
			end
			
			local ok2, res = pac.CompileExpression(substituted_func, part.lib)
			if ok2 then
				local value = 0
				local ok3, x,y,z = part:RunExpression(res)
				local val = 0
				if graph_axis == "x" then
					val = x or 0
				elseif graph_axis == "y" then
					val = y or 0
				elseif graph_axis == "z" then
					val = z or 0
				end
				if not x or not y or not z then
					nils = nils or {}
					if x == nil then
						nils.x =  true
					end
					if y == nil then
						nils.y = true
					end
					if z == nil then
						nils.z = true
					end
				end
				if isvector(val) then
					value = val.x or 0
				elseif isnumber(val) then
					value = val
				end
				added_data[compute_input_x] = value
				--points_cache[compute_input_x] = value
				
				graph_y_value_min = math.min(value, graph_y_value_min)
				graph_y_value_max = math.max(value, graph_y_value_max)
			end

			i = i + 1
			compile_x = compile_x + steps
		end
		for x,y in pairs(added_data) do
			points_cache[x] = y
		end
	end

	local function locate_y_in_graph(input_x, input_data)
		for i=1, #input_data, 1 do
			if input_data[i] and input_data[i+1] then
				if (input_data[i][1] < input_x) and (input_data[i+1][1] > input_x) then
					return input_data[i][2]
				end
			end
		end
	end

	local function is_asymptote()
		
	end

	local function find_asymptote_edges()
		
	end

	--drawing operation
	local function DrawGraph(x,y,w,h, runtime_data, input_data, resolution)
		if IsValid(pace.proxygraph_properties_controller) then
			pace.proxygraph_properties_controller:SetPos(x+w,y)
		end

		do
			local key = string.sub(graph_x_variable,1,#graph_x_variable-2)
			local ok, func = pac.CompileExpression(graph_x_variable, tracked_proxy.lib)
			if not tracked_proxy:IsHidden() and ok then
				local ok3, x,y,z = tracked_proxy:RunExpression(func)
				if ok3 then
					graph_x_variable_current_real_value = x
				end
			end
		end

		if tracked_proxy.feedback then
			if tracked_proxy.feedback[1] then
				x_btn:SetText("x : " .. math.Round(tracked_proxy.feedback[1],3) or "<nil>")
			else
				x_btn:SetText("x : <nil>")
			end
			if tracked_proxy.feedback[2] then
				y_btn:SetText("y : " .. math.Round(tracked_proxy.feedback[2],3) or "<nil>")
			else
				y_btn:SetText("y : <nil>")
			end
			if tracked_proxy.feedback[3] then
				z_btn:SetText("z : " .. math.Round(tracked_proxy.feedback[3],3) or "<nil>")
			else
				z_btn:SetText("z : <nil>")
			end
		end

		if not tracked_proxy:IsHidden() and not recording_mode and not DataCoversDisplayRange(input_data, runtime_data.input_bounds[1], runtime_data.input_bounds[2]) then
			throttle = false
			local delta = math.abs(runtime_data.input_bounds[2] - runtime_data.input_bounds[1])
			PlanOutSamplePoints({runtime_data.input_bounds[1] - 0.5*delta, runtime_data.input_bounds[2] + 0.5*delta})
			--PlanOutSamplePoints({runtime_data.input_bounds[1], runtime_data.input_bounds[2]})
			throttle = true
			local points = {}
			local input_x = runtime_data.input_bounds[1]
			local step = (runtime_data.input_bounds[2] - runtime_data.input_bounds[1]) / 500
			for i,X in ipairs(planned_samples[1]) do
				if points_cache[math.Round(X,1)] then
					table.insert(points, {X, points_cache[X]})
					input_x = math.Round(math.Clamp(input_x + step,runtime_data.input_bounds[1],runtime_data.input_bounds[2]),1)
					continue
				end
				--may be slightly randomized
				local compute_input_x = X

				local substituted_func = string.Replace(active_expression,graph_x_variable,compute_input_x)
				if graph_x_variable == "timeex()" and not recording_mode then
					tracked_proxy.timeex_override = compute_input_x
					if pac.StringFind(active_expression, "time()") then
						substituted_func = string.Replace(substituted_func, "time()", "(" .. tracked_proxy.timeex_override .. ")")
					end
				end
				
				--print("\t"..substituted_func)
				local ok2, res = pac.CompileExpression(substituted_func, tracked_proxy.lib)
				--pace.FlashNotification("compiling data...", 1)
				if ok2 then
					local value = 0
					local ok3, x,y,z = tracked_proxy:RunExpression(res)
					local val = 0
					if graph_axis == "x" then
						val = x or 0
					elseif graph_axis == "y" then
						val = y or 0
					elseif graph_axis == "z" then
						val = z or 0
					end
					if isvector(val) then
						value = val.x or 0
					elseif isnumber(x) then
						value = val
					end
					table.insert(points, {compute_input_x, value})
					points_cache[compute_input_x] = value
					
					graph_y_value_min = math.min(value, graph_y_value_min)
					graph_y_value_max = math.max(value, graph_y_value_max)
				end
				input_x = math.Round(math.Clamp(input_x + step,runtime_data.input_bounds[1],runtime_data.input_bounds[2]),1)
			end
			table.sort(points, function(a,b) return a[1] < b[1] end)
			input_data = points
		end

		if recording_mode and graph_following_x then
			local points = {}
			for x_val,y_val in pairs(points_cache) do
				if x_val < runtime_data.input_bounds[1] or x_val > runtime_data.input_bounds[2] then
					points_cache[x_val] = nil
				else
					table.insert(points, {x_val, y_val})
				end
			end
			table.sort(points, function(a,b) return a[1] < b[1] end)
			input_data = points
		end

		--[[if graph_following_x then
			runtime_data.input_bounds[1] = pace.proxygraph_properties.panels["min_x"]:GetValue()
			runtime_data.input_bounds[2] = pace.proxygraph_properties.panels["max_x"]:GetValue()
		end]]

		if mouse_hovering then
			local part = tracked_proxy
			local input_x = Lerp(relative_mx / graph_w, runtime_data.input_bounds[1], runtime_data.input_bounds[2])
			local value = locate_y_in_graph(input_x, input_data) or 0
			pace.FlashNotification("crossing = " .. input_x .. ", " .. value, 0.1)
			mouse_crossing = {input_x, value}

			--[[local substituted_func = string.Replace(active_expression,graph_x_variable,input_x)
			--print("\t"..substituted_func)
			local ok2, res = pac.CompileExpression(substituted_func, part.lib)
			if ok2 then
				local value = 0
				local ok3, x,y,z = part:RunExpression(res)
				if isvector(x) then
					--z = x.z
					--y = x.y
					--x = x.x
					value = x.x
				elseif isnumber(x) then
					value = x
				end
				
			end]]
		end

		local base_y = y
		y = y + 0.5*h

		surface.SetDrawColor(255,255,255,40) --white canvas
		surface.DrawRect(x,y-0.5*h,w + 20,h)

		surface.SetDrawColor(0,0,0)

		local x1 = x
		local y1 = y
		local x2 = runtime_data.input_bounds[1]
		local y2 = runtime_data.output_bounds[2]
		local y_stretch = h / (runtime_data.output_bounds[2] - runtime_data.output_bounds[1])
		local x_stretch = w / (runtime_data.input_bounds[2] - runtime_data.input_bounds[1])

		local main_x_y = math.floor(math.Remap(0,
			runtime_data.output_bounds[1],runtime_data.output_bounds[2],
			y+0.5*h, y - 0.5*h
		))
		local main_y_x = math.floor(math.Remap(0,
			runtime_data.input_bounds[1],runtime_data.input_bounds[2],
			x, x+w
		))

		local min_x_x = math.Remap(runtime_data.input_bounds[1],
			runtime_data.input_bounds[1],runtime_data.input_bounds[2],
			x, x+w)
		local max_x_x = math.Remap(runtime_data.input_bounds[2],
			runtime_data.input_bounds[1],runtime_data.input_bounds[2],
			x, x+w)
		local min_y_y = math.Remap(runtime_data.output_bounds[1],
			runtime_data.output_bounds[1],runtime_data.output_bounds[2],
			y+0.5*h, y - 0.5*h
		)
		local max_y_y = math.Remap(runtime_data.output_bounds[2],
			runtime_data.output_bounds[1],runtime_data.output_bounds[2],
			y+0.5*h, y - 0.5*h
		)

		local function project_coords(in_x,in_y)
			return
				math.Remap(in_x or 0,
					runtime_data.input_bounds[1],runtime_data.input_bounds[2],
					min_x_x, max_x_x
				),
				math.Remap(in_y or 0,
					runtime_data.output_bounds[1],runtime_data.output_bounds[2],
					min_y_y, max_y_y
				)
		end

		do -- abscissa and ordinate lines (x=0, y=0)
			if main_y_x > x then
				surface.DrawLine(
					main_y_x,
					y-0.5*h,
					main_y_x,
					y+0.5*h
				) -- main Y
				surface.DrawLine(
					main_y_x - 1,
					y-0.5*h,
					main_y_x - 1,
					y+0.5*h
				) -- main Y thickness
			end
			if main_x_y > y - 0.5*h and main_x_y < y + 0.5*h then
				surface.DrawLine(
					x,
					main_x_y,
					x+w,
					main_x_y
				) -- main X
				surface.DrawLine(
					x,
					main_x_y - 1,
					x+w,
					main_x_y - 1
				) -- main X thickness
			end
		end
		

		--indentations
		local indentation_fractions = {
			--1,-0.875,-0.75,-0.625,-0.5,-0.375,-0.25,-0.125,
			0,0.125,0.25,0.375,0.5,0.625,0.75,0.875,1
		}
		surface.SetFont("DebugOverlay")
		surface.SetTextColor(255,255,255)

		surface.SetTextPos(x + w + 24,math.Clamp(main_x_y,base_y,base_y+h))
		surface.DrawText("x axis : " .. graph_x_variable .. " = " .. (graph_x_variable_current_real_value or 0))

		surface.SetTextPos(main_y_x,y - 0.5*h - 24)
		surface.DrawText("y axis : " .. active_output_variable)

		for i,v in ipairs(indentation_fractions) do
			local y_lerp = Lerp(v,runtime_data.output_bounds[1],runtime_data.output_bounds[2])
			surface.SetTextPos(
				x + 4,
				math.Clamp(
					math.Remap(y_lerp,
						runtime_data.output_bounds[1],runtime_data.output_bounds[2],
						y + 0.5*h, y - 0.5*h
					),
					base_y,base_y+h
				)
			)
			surface.DrawText(math.Round(y_lerp,3))

			surface.SetDrawColor(100,100,100)
			--surface.DrawLine(x, y - y_stretch*y_lerp, x + w, y - y_stretch*y_lerp)
			--[[for i=0,1,0.02 do
				if i%0.04 == 0 then
					surface.DrawLine(x + i*w,y,x + (i+1)*w,y)
				end
			end]]
			local x_lerp = math.Remap(v,0,1,runtime_data.input_bounds[1],runtime_data.input_bounds[2])
			surface.SetTextPos(
				main_y_x + x_stretch*x_lerp,
				math.Clamp(main_x_y + 12,base_y,base_y+h)
			)
			surface.DrawText(x_lerp)
			--[[for i=0,1,0.02 do
				if i%0.04 == 0 then
					surface.DrawLine(x + i*w,y,x + (i+1)*w,y)
				end
			end]]
		end

		local p1 = input_data[1] or {0,0}
		x1, y1 = project_coords(p1[1],p1[2])
		--PrintTable(input_data)
		local previous_labeled_datapoint
		drawn_points = 0
		for i=1,#input_data-1,1 do
			point = input_data[i]
			--surface.SetDrawColor(0,0,0)
			x2, y2 = project_coords(point[1],point[2])
			--y2 = math.Remap(point[2],runtime_data.output_bounds[1],runtime_data.output_bounds[2],y+0.5*h,y-0.5*h) --y - point[2] * y_stretch
			--x2 = math.Remap(point[1],runtime_data.input_bounds[1],runtime_data.input_bounds[2],x,x+w) --x + point[1] * x_stretch

			local c_y2 = math.Clamp(y2,y-0.5*h,y+0.5*h)
			y2 = c_y2

			if x2 < x + w and x2 > x then
				if asymptotes_mids[i] and input_data[i-1] then --asymptotes
					surface.SetDrawColor(100,100,100)
					x2 = project_coords((input_data[i-1][1] + input_data[i][1])/2,0)
					local y_pos = y + 0.5*h
					while y_pos > y - 0.5*h do
						surface.DrawLine(x2,y_pos,x2,y_pos - 3)
						y_pos = y_pos - 6
					end
				else --normal data points
					if 2*CurTime()%1<0.5 then
						surface.SetDrawColor(255,0,0)
					else
						surface.SetDrawColor(0,0,0)
					end
					if i % 16 == 1 and previous_labeled_datapoint ~= point[2] then
						surface.SetTextPos(project_coords(point[1],point[2]))
						surface.DrawText("{" .. math.Round(point[1],2) .. ", " .. math.Round(point[2],2) .. "}")
						previous_labeled_datapoint = point[2]
					end
					
					surface.DrawLine(x1,y1,x2,y2)
			
					surface.DrawLine(x1-0.5,y1-0.5,x2-0.5,y2-0.5)
					surface.DrawLine(x1+0.5,y1-0.5,x2+0.5,y2-0.5)
					surface.DrawLine(x1+0.5,y1+0.5,x2+0.5,y2+0.5)
					surface.DrawLine(x1+0.5,y1-0.5,x2+0.5,y2-0.5)
					surface.DrawLine(x1-0.2,y1-0.2,x2-0.2,y2-0.2)
					surface.DrawLine(x1+0.2,y1-0.2,x2+0.2,y2-0.2)
					surface.DrawLine(x1+0.2,y1+0.2,x2+0.2,y2+0.2)
					surface.DrawLine(x1+0.2,y1-0.2,x2+0.2,y2-0.2)
				end
				drawn_points = drawn_points + 1
			end
			
			y1 = y2
			x1 = x2
		end

		if graph_x_variable_current_real_value and tracked_proxy then
			--if (not tracked_proxy:IsHidden()) --[[and graph_x_variable == "timeex()"]] then
				local x1, x2 = project_coords(graph_x_variable_current_real_value,0)
				surface.SetDrawColor(0,150,255)
				surface.DrawLine(x1,base_y,x1,base_y + h)
			--end
		end

		if mouse_hovering then
			do
				surface.SetDrawColor(100,100,100)
				local mx, my = project_coords(mouse_crossing[1],mouse_crossing[2])
				surface.DrawLine(mx,y-0.5*h,mx,y+0.5*h)
				surface.DrawLine(x,my,x+w,my)
				surface.SetTextPos(mx,my)
				surface.DrawText("{" .. math.Round(mouse_crossing[1],2) .. ", " .. math.Round(mouse_crossing[2],2) .. "}")
			end
		end
		surface.SetDrawColor(100,100,100)
		local tw, th = surface.GetTextSize(graph_title)
		surface.SetTextPos(x + w/2 - tw/2, base_y + 20)
		surface.DrawText(graph_title)
		tracked_proxy.timeex_override = nil
		--pace.FlashNotification("pts = " .. drawn_points .. " " .. #input_data, 0.2)
		if drawn_points == 0 then drawn_points_failures = drawn_points_failures + 1 else drawn_points_failures = 0 end
		local min,max = math.huge, -math.huge
		for x,y in pairs(points_cache) do
			--clean up
			if x < runtime_data.input_bounds[1] - 300 then
				points_cache[x] = nil
				continue
			end
			if x > runtime_data.input_bounds[2] + 300 then
				points_cache[x] = nil
				continue
			end
			min = math.min(min, x)
			max = math.max(max, x)
		end

		if not recording_mode then
			if max - 50 < runtime_data.input_bounds[2] then
				AddMorePoints(points_cache, max, runtime_data.input_bounds[2] + 300)
				pace.FlashNotification(">> compiling data...", 0.5)
			end
			if min + 50 > runtime_data.input_bounds[1] then
				AddMorePoints(points_cache, runtime_data.input_bounds[1] - 300, min)
				pace.FlashNotification("<< compiling data...", 0.5)
			end
		end

		if drawn_points_failures > 50 then
			reset_points_cache()
			PlanOutSamplePoints()
			drawn_points_failures = 0
		end
	end

	if pace and IsValid(pace.proxygraph_properties) then
		pace.proxygraph_properties:Remove()
		pace.proxygraph_properties = nil
		pace.performance_tracked_part = nil
		if IsValid(pace.proxygraph_properties_controller) then
			pace.proxygraph_properties_controller:Remove()
			pace.proxygraph_properties_controller = nil
		end
	end

	local non_variable_funcs = {
		ezfade = true,
		ezfade_4pt = true,
		lerp = true,
		sin = true,
		nsin = true,
		nsin2 = true,
		cos = true,
		ncos = true,
		ncos2 = true,
		tan = true,
	}
	for ease,kw in pairs(ease_aliases) do
		non_variable_funcs[ease] = true
	end

	local closed = true

	local function graph_main()
		if pace.request_proxy_stats ~= "graph" then return end
		if not pace.IsActive() then pace.performance_tracked_part = nil tracked_proxy = nil return end
		if pace.performance_tracked_part then
			tracked_proxy = pace.performance_tracked_part
		end
		if isbool(pace.performance_tracked_part) then
			tracked_proxy = nil
			frame_data = {}
			return
		end
		if not tracked_proxy then return end
		active_output_variable = tracked_proxy.VariableName

		if not IsValid(pace.proxygraph_properties) then
			pace.OpenProxyGrapher()
		end

		if IsValid(tracked_proxy.pace_tree_node) then
			if not pace.proxygraph_properties then return end
			if not pace.proxygraph_properties.panels then return end
			local x,y = tracked_proxy.pace_tree_node:LocalToScreen(0,0)
			x = pace.Editor:GetX() + pace.Editor:GetWide() + 10
			graph_w = 1000
			if x + graph_w + 250 > ScrW() then
				graph_w = ScrW() - x - 250
			end
			graph_h = 500
			
			local input_bounds = {
				math.Round(pace.proxygraph_properties.panels["min_x"]:GetValue(),4),
				math.Round(pace.proxygraph_properties.panels["max_x"]:GetValue(),4)
			}
			--input_bounds = {CurTime() - 10, CurTime() + 10}
			local steps = pace.proxygraph_properties.panels["step"]:GetValue()
			if steps == 0 then
				steps = (input_bounds[2] - input_bounds[1]) / 500
			end
			local runtime_data = {
				output_bounds = {
					math.Round(pace.proxygraph_properties.panels["min_y"]:GetValue(),4),
					math.Round(pace.proxygraph_properties.panels["max_y"]:GetValue(),4)
				},
				step = steps,
				--ppp = 1,--points per pixel
				scroll = false,
				input_bounds = input_bounds,
			}

			local mx, my = input.GetCursorPos()
			relative_mx = mx - x
			relative_my = -(my - y - 0.5*graph_h)
			--pace.FlashNotification("relative mouse position: " .. relative_mx .. ", " .. relative_my)
			mouse_hovering = 
				mx > x and
				mx < x + graph_w and
				my > y - graph_h and
				my < y + graph_h

			graph_x_variable = pace.proxygraph_properties.panels["variable_name"]:GetValue()
			if tracked_proxy.Expression == "" then --override by easy setup
				graph_x_variable = tracked_proxy.Input.."()"
			end
			current_runtime_data = runtime_data
			if (recording_mode and tracked_proxy:IsHidden()) then
				pace.reset_proxygraph = true
			end
			if pace.reset_proxygraph then points_cache = {} pace.reset_proxygraph = nil end
			local input_data = SampleData(tracked_proxy, graph_x_variable, runtime_data)

			if runtime_data.nils then
				if runtime_data.nils.x and graph_axis == "x" then graph_axis = "y" graph_title = "nil output on x, switched to y" end
				if runtime_data.nils.y and graph_axis == "y" then graph_axis = "z" graph_title = "nil output on y, switched to z" end
				if runtime_data.nils.z and graph_axis == "z" then graph_axis = "x" graph_title = "nil output on z, switched to x" end
			end

			DrawGraph(x,y,graph_w,graph_h,runtime_data,input_data)

		end
	end

	function pace.OpenProxyGrapher(part)
		pace.CloseProxyGrapher()
		pace.request_proxy_stats = "graph"
		tracked_proxy = part or pace.current_part
		if tracked_proxy.ClassName ~= "proxy" then return end
		pac.AddHook("HUDPaint", "proxy_draw_graph", graph_main)

		graph_following_x = false
		pace.proxygraph_properties = vgui.Create("DFrame")

		throttle_limit = 2000
		throttle_burst_limit = 100
		recursion_level = 0
		plan_steps = 60
		throttle = false
		timer.Simple(0.5, function() throttle = true end)


		pnl = pace.proxygraph_properties
		pnl:SetTitle("navigation")
		pnl:SetSize(400,400)
		pnl:SetPos(ScrW()-400,ScrH()-500)
		x_btn = vgui.Create("DButton", pnl)
		x_btn:SetSize(380/3,20) x_btn:SetPos(10 + (0 * 380/3),30)
		x_btn:SetText("x")
		y_btn = vgui.Create("DButton", pnl)
		y_btn:SetSize(380/3,20) y_btn:SetPos(10 + (1 * 380/3),30)
		y_btn:SetText("y")
		z_btn = vgui.Create("DButton", pnl)
		z_btn:SetSize(380/3,20) z_btn:SetPos(10 + (2 * 380/3),30)
		z_btn:SetText("z")

		function x_btn:DoClick()
			graph_y_value_max = 0
			graph_y_value_min = 0
			graph_axis = "x"
			reset_points_cache()
		end
		function y_btn:DoClick()
			graph_y_value_max = 0
			graph_y_value_min = 0
			graph_axis = "y"
			reset_points_cache()
		end
		function z_btn:DoClick()
			graph_y_value_max = 0
			graph_y_value_min = 0
			graph_axis = "z"
			reset_points_cache()
		end

		local properties_pnl = pace.CreatePanel("properties",pnl)
		properties_pnl:SetSize(380,440) properties_pnl:SetPos(10,50)
		
		local min_x_slider = pace.CreatePanel("properties_number")
			properties_pnl:AddKeyValue("MinX",min_x_slider)
			min_x_slider:SetValue(-10)
			min_x_slider:PostInit()
		local max_x_slider = pace.CreatePanel("properties_number")
			properties_pnl:AddKeyValue("MaxX",max_x_slider)
			max_x_slider:SetValue(10)
			max_x_slider:PostInit()
		local min_y_slider = pace.CreatePanel("properties_number")
			properties_pnl:AddKeyValue("MinY",min_y_slider)
			min_y_slider:SetValue(-10)
			min_y_slider:PostInit()
		local max_y_slider = pace.CreatePanel("properties_number")
			properties_pnl:AddKeyValue("MaxY",max_y_slider)
			max_y_slider:SetValue(10)
			max_y_slider:PostInit()
		local variable_name_pnl = pace.CreatePanel("properties_string", main_panel)
			properties_pnl:AddKeyValue("GraphVariable", variable_name_pnl, nil, nil,
				{description = "Which function (or expression) is used as the graph's main x (abscissa) baseline\nFunctions with arguments like property and part_distance should be written out manually e.g. property(\"Size\",\"x\").\nIdeally you should stick to primitive variables instead of processing functions.\nMost of the time it will be time() or timeex()."}
			)
			function variable_name_pnl:EditText()
				local oldText = self:GetText()
				self:SetText("")

				local pnl = vgui.Create("DTextEntry")
				self.editing = pnl
				pnl:SetFont(pace.CurrentFont)
				pnl:SetDrawBackground(false)
				pnl:SetDrawBorder(false)
				pnl:SetText(self:EncodeEdit(self.original_str or ""))
				pnl:SetKeyboardInputEnabled(true)
				pnl:SetDrawLanguageID(false)
				pnl:RequestFocus()
				pnl:SelectAllOnFocus(true)

				pnl.OnTextChanged = function() oldText = pnl:GetText() end

				local hookID = tostring({})
				local textEntry = pnl
				local delay = os.clock() + 0.1

				pac.AddHook('Think', hookID, function(code)
					if not IsValid(self) or not IsValid(textEntry) then return pac.RemoveHook('Think', hookID) end
					if textEntry:IsHovered() or self:IsHovered() then return end
					if delay > os.clock() then return end
					if not input.IsMouseDown(MOUSE_LEFT) and not input.IsKeyDown(KEY_ESCAPE) then return end
					pac.RemoveHook('Think', hookID)
					self.editing = false
					pace.BusyWithProperties = NULL
					textEntry:Remove()
					self:SetText(oldText)
					pnl:OnEnter()
				end)

				--local x,y = pnl:GetPos()
				--pnl:SetPos(x+3,y-4)
				--pnl:Dock(FILL)
				local x, y = self:LocalToScreen()
				local inset_x = self:GetTextInset()
				pnl:SetPos(x+5 + inset_x, y)
				pnl:SetSize(self:GetSize())
				pnl:SetWide(ScrW())
				pnl:MakePopup()

				pnl.OnEnter = function()
					pace.BusyWithProperties = NULL
					self.editing = false

					pnl:Remove()
					self:SetText(pnl:GetText())
					self:SetValue(pnl:GetText())
				end

				local old = pnl.Paint
				pnl.Paint = function(...)
					if not self:IsValid() then pnl:Remove() return end

					surface.SetFont(pnl:GetFont())
					local w = surface.GetTextSize(pnl:GetText()) + 6

					surface.DrawRect(0, 0, w, pnl:GetTall())
					surface.SetDrawColor(self:GetSkin().Colours.Properties.Border)
					surface.DrawOutlinedRect(0, 0, w, pnl:GetTall())

					pnl:SetWide(w)

					old(...)
				end

				pace.BusyWithProperties = pnl
			end
			if tracked_proxy.Expression == "" then
				variable_name_pnl:SetValue(tracked_proxy.Input.."()")
			else
				local variables = tracked_proxy:GetActiveFunctions()
				local timeex_derived_func = table.HasValue(variables, "ezfade") or table.HasValue(variables, "ezfade_4pt")
					or table.HasValue(variables, "drift") or table.HasValue(variables, "random_drift") or table.HasValue(variables, "sample_and_hold") or table.HasValue(variables, "samplehold")

				--first priority is timeex, contained within timeex or ezfade
				if table.HasValue(variables, "timeex") then
					variable_name_pnl:SetValue("timeex()")
				elseif timeex_derived_func then
					variable_name_pnl:SetValue("timeex()")
				elseif table.HasValue(variables, "time") then
					variable_name_pnl:SetValue("time()")
				else 
					variable_name_pnl:SetValue("time()")
				end

				if table.HasValue(variables, "drift") or table.HasValue(variables, "random_drift") or table.HasValue(variables, "sample_and_hold") or table.HasValue(variables, "samplehold") then
					recording_mode = true
				end
			end
		
		local variable_name_list_c = pace.CreatePanel("properties_container")
			properties_pnl:AddKeyValue("Variables", variable_name_list_c)
			local variables = tracked_proxy:GetActiveFunctions()
			table.insert(variables, 1, "timeex")
			for i,kw in ipairs(variables) do
				if ease_aliases[kw] then continue end
				if kw == "timeex" and i ~= 1 then continue end
				local btn = vgui.Create("Button")
				btn:SetText("Set") btn:SetSize(variable_name_list_c:GetWide(), variable_name_list_c:GetTall())
				properties_pnl:AddKeyValue(kw, btn)
				function btn:DoClick()
					variable_name_pnl:SetValue(kw.."()")
				end
			end
		local step_slider = pace.CreatePanel("properties_number")
			properties_pnl:AddKeyValue("StepPerSample",step_slider, nil, nil,
				{description = "Real interval between sampled points.\nlower values = more resolution\n0 means samples on a per-pixel basis"}
			)
			step_slider:SetValue(0.1)
			step_slider:PostInit()
		local asymptote_slider = pace.CreatePanel("properties_number")
			properties_pnl:AddKeyValue("AsymptoteThreshold",asymptote_slider, nil, nil,
				{description = "Slope limit to consider as an asymptote.\nIt's relative to the graph's proportions, not in real values."}
			)
			asymptote_slider:SetValue(100)
			asymptote_slider:PostInit()

		--if true then
			step_slider:SetValue(saved_vgui_values["step"])
			max_x_slider:SetValue(saved_vgui_values["max_x"])
			min_x_slider:SetValue(saved_vgui_values["min_x"])
			max_y_slider:SetValue(saved_vgui_values["max_y"])
			min_y_slider:SetValue(saved_vgui_values["min_y"])
			asymptote_slider:SetValue(saved_vgui_values["asymptote"])

			saved_vgui_values = {
				step = step_slider:GetValue(),
				max_x = max_x_slider:GetValue(),
				min_x = min_x_slider:GetValue(),
				max_y = max_y_slider:GetValue(),
				min_y = min_y_slider:GetValue(),
				asymptote = asymptote_slider:GetValue(),
			}
		--end
		pace.proxygraph_properties.panels = {
			step = step_slider,
			max_x = max_x_slider,
			min_x = min_x_slider,
			max_y = max_y_slider,
			min_y = min_y_slider,
			variable_name = variable_name_pnl,
			asymptote = asymptote_slider,
		}

		local max_x_target = max_x_slider:GetValue()
		local min_x_target = min_x_slider:GetValue()
		local max_y_target = max_y_slider:GetValue()
		local min_y_target = min_y_slider:GetValue()
		local move = false
		local editing = false

		local hookID = "proxy_graph_main_panel"
		pac.AddHook("Think", hookID, function()
			if not IsValid(pnl) then pac.RemoveHook("Think", hookID) return end
			if not IsValid(max_x_slider) then pac.RemoveHook("Think", hookID) return end
			if not pace.IsActive() then pnl:Close() pac.RemoveHook("Think", hookID) return end
			local max_x_getvalue = max_x_slider:GetValue()
			local min_x_getvalue = min_x_slider:GetValue()
			local max_y_getvalue = max_y_slider:GetValue()
			local min_y_getvalue = min_y_slider:GetValue()

			if move and not editing then
				if max_x_target ~= max_x_getvalue then
					max_x_slider:SetValue(Lerp(0.1,max_x_getvalue,max_x_target))
				end
				if min_x_target ~= min_x_getvalue then
					min_x_slider:SetValue(Lerp(0.1,min_x_getvalue,min_x_target))
				end
				if max_y_target ~= max_y_getvalue then
					max_y_slider:SetValue(Lerp(0.1,max_y_getvalue,max_y_target))
				end
				if min_y_target ~= min_y_getvalue then
					min_y_slider:SetValue(Lerp(0.1,min_y_getvalue,min_y_target))
				end
				return
			end
			
			if pnl:IsHovered() or pnl:IsChildHovered() then
				move = false
				max_x_target = max_x_getvalue
				min_x_target = min_x_getvalue
				max_y_target = max_y_getvalue
				min_y_target = min_y_getvalue
				editing = true
			else
				editing = false
			end
		end)

		function pnl:OnClose()
			pace.performance_tracked_part = nil
			tracked_proxy = nil
			if IsValid(pace.proxygraph_properties_controller) then
				pace.proxygraph_properties_controller:Remove()
			end
		end

		pace.proxygraph_properties_controller = vgui.Create("DFrame")
		pace.proxygraph_properties_controller:SetSize(240,80)
		pnl2 = vgui.Create("DPanel",pace.proxygraph_properties_controller)
		pnl2:SetSize(240,80) pnl2:SetPos(0,20) pace.proxygraph_properties_controller:SetTitle("sampling")

		local x_bck = vgui.Create("DButton", pnl2)
			x_bck:SetText("<<<") x_bck:SetSize(40, 20) x_bck:SetPos(0,0)
			function x_bck:DoClick()
				move = true
				local span = max_x_target - min_x_target
				if input.IsKeyDown(KEY_LSHIFT) then
					span = 2 * span
				elseif input.IsKeyDown(KEY_LALT) then
					span = 0.5 * span
				end
				max_x_target = max_x_target - 0.5*span
				min_x_target = min_x_target - 0.5*span
				--reset_points_cache()
				--timer.Simple(2, reset_points_cache)
			end
		local x_fwd = vgui.Create("DButton", pnl2)
			x_fwd:SetText(">>>") x_fwd:SetSize(40, 20) x_fwd:SetPos(40,0)
			function x_fwd:DoClick()
				move = true
				local span = max_x_target - min_x_target
				if input.IsKeyDown(KEY_LSHIFT) then
					span = 2 * span
				elseif input.IsKeyDown(KEY_LALT) then
					span = 0.5 * span
				end
				max_x_target = max_x_target + 0.5*span
				min_x_target = min_x_target + 0.5*span
				--reset_points_cache()
				--timer.Simple(2, reset_points_cache)
			end
		local x_2x = vgui.Create("DButton", pnl2)
			x_2x:SetText("x*2") x_2x:SetSize(40, 20) x_2x:SetPos(80,0)
			function x_2x:DoClick()
				move = true
				max_x_target = max_x_target * 2
				min_x_target = min_x_target * 2
				timer.Simple(2, reset_points_cache)
			end
		local x_05x = vgui.Create("DButton", pnl2)
			x_05x:SetText("x/2") x_05x:SetSize(40, 20) x_05x:SetPos(120,0)
			function x_05x:DoClick()
				move = true
				max_x_target = max_x_target * 0.5
				min_x_target = min_x_target * 0.5
				--timer.Simple(2, reset_points_cache)
			end
		local x_positive = vgui.Create("DButton", pnl2)
			x_positive:SetText("[0,x]") x_positive:SetSize(40, 20) x_positive:SetPos(160,0)
			function x_positive:DoClick()
				move = true
				min_x_target = 0
				--timer.Simple(2, reset_points_cache)
			end
		local follow_x = vgui.Create("DButton", pnl2)
			follow_x:SetTooltip("toggle follow mode")
			follow_x:SetText("FLW") follow_x:SetSize(40, 20) follow_x:SetPos(200,0)
			function follow_x:DoClick()
				move = true
				if self.held then
					self.held = false
					graph_following_x = false
					local span = max_x_target - min_x_target
					graph_x_variable_current_real_value = graph_x_variable_current_real_value or 0
					max_x_slider:SetValue(graph_x_variable_current_real_value + 0.5*span)
					min_x_slider:SetValue(graph_x_variable_current_real_value - 0.5*span)
					max_x_target = graph_x_variable_current_real_value + 0.5*span
					min_x_target = graph_x_variable_current_real_value - 0.5*span
					move = false
				else
					self.held = true
					graph_following_x = true
				end
			end
			local oldthink = follow_x.Think
			function follow_x:Think()
				oldthink(self)
				if not IsValid(max_x_slider) then return end


				if self.held then
					if not graph_x_variable_current_real_value then return end
					if not move then return end

					if tracked_proxy:IsHidden() then
						graph_x_variable_current_real_value = 0
					end

					local span = max_x_target - min_x_target
					max_x_slider:SetValue(math.Round(graph_x_variable_current_real_value + 0.5*span,3))
					min_x_slider:SetValue(math.Round(graph_x_variable_current_real_value - 0.5*span,3))
				end
			end

		local y_bck = vgui.Create("DButton", pnl2)
			y_bck:SetText("↑↑↑") y_bck:SetSize(40, 20) y_bck:SetPos(0,20)
			function y_bck:DoClick()
				move = true
				local span = max_y_target - min_y_target
				if input.IsKeyDown(KEY_LSHIFT) then
					span = 2 * span
				elseif input.IsKeyDown(KEY_LALT) then
					span = 0.5 * span
				end
				max_y_target = max_y_target - 0.5*span
				min_y_target = min_y_target - 0.5*span
			end
		local y_fwd = vgui.Create("DButton", pnl2)
			y_fwd:SetText("↓↓↓") y_fwd:SetSize(40, 20) y_fwd:SetPos(40,20)
			function y_fwd:DoClick()
				move = true
				local span = max_y_target - min_y_target
				if input.IsKeyDown(KEY_LSHIFT) then
					span = 2 * span
				elseif input.IsKeyDown(KEY_LALT) then
					span = 0.5 * span
				end
				max_y_target = max_y_target + 0.5*span
				min_y_target = min_y_target + 0.5*span
			end
		local y_2x = vgui.Create("DButton", pnl2)
			y_2x:SetText("y*2") y_2x:SetSize(40, 20) y_2x:SetPos(80,20)
			function y_2x:DoClick()
				move = true
				max_y_target = max_y_target * 2
				min_y_target = min_y_target * 2
			end
		local y_05x = vgui.Create("DButton", pnl2)
			y_05x:SetText("y/2") y_05x:SetSize(40, 20) y_05x:SetPos(120,20)
			function y_05x:DoClick()
				move = true
				max_y_target = max_y_target * 0.5
				min_y_target = min_y_target * 0.5
			end
		local y_positive = vgui.Create("DButton", pnl2)
			y_positive:SetText("[0,y]") y_positive:SetSize(40, 20) y_positive:SetPos(160,20)
			function y_positive:DoClick()
				move = true
				min_y_target = 0
			end
		local follow_y = vgui.Create("DButton", pnl2)
			follow_x:SetTooltip("toggle y-follow mode (fit data to graph vertically)")
			follow_y:SetText("fit") follow_y:SetSize(40, 20) follow_y:SetPos(200,20)
			function follow_y:DoClick()
				move = true
				if self.held then
					self.held = false
				else
					self.held = true
				end
			end
			local oldthink = follow_y.Think
			function follow_y:Think()
				oldthink(self)
				if self.held then
					move = true
					if not graph_x_variable_current_real_value then return end
					max_y_target = math.Round(graph_y_value_max,2)
					min_y_target = math.Round(graph_y_value_min,2)
				end
			end

		local origin_btn = vgui.Create("DButton", pnl2)
			origin_btn:SetText("{0,0}") origin_btn:SetSize(40, 20) origin_btn:SetPos(0,40)
			function origin_btn:DoClick()
				move = true
				local span_x = max_x_target - min_x_target
				local span_y = max_y_target - min_y_target
				max_x_target = 0.5*span_x
				min_x_target = -0.5*span_x
				max_y_target = 0.5*span_y
				min_y_target = -0.5*span_y
			end

		local reset_btn = vgui.Create("DButton", pnl2)
			reset_btn:SetText("reset") reset_btn:SetSize(40, 20) reset_btn:SetPos(40,40)
			function reset_btn:DoClick()
				reset_points_cache()
				move = false
				editing = false
				max_x_slider:SetValue(math.Round(max_x_slider:GetValue(),1))
				min_x_slider:SetValue(math.Round(min_x_slider:GetValue(),1))
				max_y_slider:SetValue(math.Round(max_y_slider:GetValue(),0))
				min_y_slider:SetValue(math.Round(min_y_slider:GetValue(),0))
			end

		local rec_btn = vgui.Create("DButton", pnl2)
			rec_btn:SetTooltip("toggle between recording mode and prediction mode")
			rec_btn:SetText("REC") rec_btn:SetSize(40, 20) rec_btn:SetPos(80,40)
			function rec_btn:DoClick()
				recording_mode = not recording_mode
				if recording_mode then pace.FlashNotification("switched to real-time recording mode") else pace.FlashNotification("switched to prediction mode") end
			end

		local btn_close = vgui.Create("DButton", pnl2)
			btn_close:SetText("close") btn_close:SetSize(60, 20) btn_close:SetPos(180,40)
			function btn_close:DoClick()
				pace.CloseProxyGrapher()
			end

		--hack fix to update the expression when it's an easy setup
		if tracked_proxy.Expression == "" then
			tracked_proxy:SetExpression(" ")
			timer.Simple(0, function()
				tracked_proxy:SetExpression("")
			end)
		end
	end

	function pace.CloseProxyGrapher()
		if IsValid(pace.proxygraph_properties) then pace.proxygraph_properties:Remove() end
		if IsValid(pace.proxygraph_properties_controller) then pace.proxygraph_properties_controller:Remove() end
		pace.proxygraph_properties = nil
		pace.proxygraph_properties_controller = nil
		pace.performance_tracked_part = nil
		tracked_proxy = nil
		pace.request_proxy_stats = nil
		pac.RemoveHook("HUDPaint", "proxy_draw_graph")
	end
end