local bones =
{
	["pelvis"] = "valvebiped.bip01_pelvis",
	["spine"] = "valvebiped.bip01_spine",
	["spine 2"] = "valvebiped.bip01_spine1",
	["spine 3"] = "valvebiped.bip01_spine2",
	["spine 4"] = "valvebiped.bip01_spine4",
	["neck"] = "valvebiped.bip01_neck1",
	["head"] = "valvebiped.bip01_head1",
	["right clavicle"] = "valvebiped.bip01_r_clavicle",
	["right upper arm"] = "valvebiped.bip01_r_upperarm",
	["right upperarm"] = "valvebiped.bip01_r_upperarm",
	["right forearm"] = "valvebiped.bip01_r_forearm",
	["right hand"] = "valvebiped.bip01_r_hand",
	["left clavicle"] = "valvebiped.bip01_l_clavicle",
	["left upper arm"] = "valvebiped.bip01_l_upperarm",
	["left upperarm"] = "valvebiped.bip01_l_upperarm",
	["left forearm"] = "valvebiped.bip01_l_forearm",
	["left hand"] = "valvebiped.bip01_l_hand",
	["right thigh"] = "valvebiped.bip01_r_thigh",
	["right calf"] = "valvebiped.bip01_r_calf",
	["right foot"] = "valvebiped.bip01_r_foot",
	["right toe"] = "valvebiped.bip01_r_toe0",
	["left thigh"] = "valvebiped.bip01_l_thigh",
	["left calf"] = "valvebiped.bip01_l_calf",
	["left foot"] = "valvebiped.bip01_l_foot",
	["left toe"] = "valvebiped.bip01_l_toe0",
}

local function translate_bone(bone)
	if bones[bone] then return bones[bone] end
	if not bone.lower then debug.Trace() return "" end
	bone = bone:lower()
	for key, val in pairs(bones) do
		if bone == val then
			return key
		end
	end

	return bone
end

function pacx.ConvertPAC2Config(data, name)
	local _out = {}

	local base = pac.CreatePart("group")
		base:SetName(name or "pac2 outfit")

	for key, data in pairs(data.parts) do
		if data.sprite.Enabled then
			local part = pac.CreatePart("sprite")
				part:SetParent(base)
				part.pac2_part = data
				part:SetName(data.name .. " sprite")

				part:SetBone(translate_bone(data.bone))

				part:SetColor(Vector(data.sprite.color.r, data.sprite.color.g, data.sprite.color.b))
				part:SetAlpha(data.sprite.color.a / 255)

				part:SetPosition(data.offset*1)
				part:SetAngles(data.angles*1)
				--part:SetAngleVelocity(Angle(data.anglevelocity.p, -data.anglevelocity.r, data.anglevelocity.y)*0.5)

				part:SetMaterial(data.sprite.material)
				part:SetSizeX(data.sprite.x)
				part:SetSizeY(data.sprite.y)
				part:SetEyeAngles(data.eyeangles)
				if data.weaponclass and data.weaponclass ~= "" then
					local part_ = pac.CreatePart("event")
					part_:SetName(part.Name .. " weapon class")
					part_:SetParent(part)
					part_:SetEvent("weapon_class")
					part_:SetOperator("find simple")
					part_:SetInvert(true)
					part_:SetArguments(data.weaponclass .. "@@" .. (data.hideweaponclass and "1" or "0"))
				end
		end

		if data.light.Enabled then
			local part = pac.CreatePart("light")
				part:SetParent(base)
				part.pac2_part = data
				part:SetName(data.name .. " light")

				part:SetBone(translate_bone(data.bone))

				part:SetColor(Vector(data.light.r, data.light.g, data.light.b))

				part:SetPosition(data.offset*1)
				part:SetAngles(data.angles*1)
				--part:SetAngleVelocity(Angle(data.anglevelocity.p, -data.anglevelocity.r, data.anglevelocity.y)*0.5)

				part:SetBrightness(data.light.Brightness)
				part:SetSize(data.light.Size)

				if data.weaponclass and data.weaponclass ~= "" then
					local part_ = pac.CreatePart("event")
					part_:SetName(part.Name .. " weapon class")
					part_:SetParent(part)
					part_:SetEvent("weapon_class")
					part_:SetOperator("find simple")
					part_:SetInvert(true)
					part_:SetArguments(data.weaponclass .. "@@" .. (data.hideweaponclass and "1" or "0"))
				end
		end

		if data.text.Enabled then
			local part = pac.CreatePart("text")
				part:SetParent(base)
				part.pac2_part = data
				part:SetName(data.name .. " text")

				part:SetBone(translate_bone(data.bone))

				part:SetColor(Vector(data.text.color.r, data.text.color.g, data.text.color.b))
				part:SetAlpha(data.text.color.a / 255)

				part:SetColor(Vector(data.text.outlinecolor.r, data.text.outlinecolor.g, data.text.outlinecolor.b))
				part:SetAlpha(data.text.outlinecolor.a / 255)

				part:SetPosition(data.offset*1)
				part:SetAngles(data.angles*1)
				--part:SetAngleVelocity(Angle(data.anglevelocity.p, -data.anglevelocity.r, data.anglevelocity.y)*0.5)

				part:SetOutline(data.text.outline)
				part:SetText(data.text.text)
				part:SetFont(data.text.font)
				part:SetSize(data.text.size)
				part:SetEyeAngles(data.eyeangles)
				if data.weaponclass and data.weaponclass ~= "" then
					local part_ = pac.CreatePart("event")
					part_:SetName(part.Name .. " weapon class")
					part_:SetParent(part)
					part_:SetEvent("weapon_class")
					part_:SetOperator("find simple")
					part_:SetInvert(true)
					part_:SetArguments(data.weaponclass .. "@@" .. (data.hideweaponclass and "1" or "0"))
				end
		end

		if data.trail.Enabled then
			local part = pac.CreatePart("trail")
				part:SetParent(base)
				part.pac2_part = data
				part:SetName(data.name .. " trail")
				part:SetBone(translate_bone(data.bone))

				part:SetPosition(data.offset*1)
				part:SetAngles(data.angles*1)
				--part:SetAngleVelocity(Angle(data.anglevelocity.p, -data.anglevelocity.r, data.anglevelocity.y)*0.5)

				part:SetStartSize(data.trail.startsize)

				part:SetStartColor(Vector(data.trail.color.r, data.trail.color.g, data.trail.color.b))
				part:SetEndColor(Vector(data.trail.color.r, data.trail.color.g, data.trail.color.b))

				part:SetStartAlpha(data.trail.color.a/255)
				part:SetEndAlpha(data.trail.color.a/255)

				part:SetSpacing(0)

				part:SetMaterial(data.trail.material)
				part:SetLength(data.trail.length)
				if data.weaponclass and data.weaponclass ~= "" then
					local part_ = pac.CreatePart("event")
					part_:SetName(part.Name .. " weapon class")
					part_:SetParent(part)
					part_:SetEvent("weapon_class")
					part_:SetOperator("find simple")
					part_:SetInvert(true)
					part_:SetArguments(data.weaponclass .. "@@" .. (data.hideweaponclass and "1" or "0"))
				end
		end

		if true or  data.color.a ~= 0 and data.size ~= 0 and data.scale ~= vector_origin or data.effect.Enabled then
			local part = pac.CreatePart("model")
				part:SetParent(base)
				part.pac2_part = data
				part:SetName(data.name .. " model")
				part:SetBone(translate_bone(data.bone))

				part:SetMaterial(data.material)

				part:SetColor(Vector(data.color.r, data.color.g, data.color.b))
				part:SetAlpha(data.color.a / 255)

				part:SetModel(data.model)
				part:SetSize(data.size)
				part:SetScale(data.scale*1)

				part:SetPosition(data.offset*1)
				part:SetAngles(data.angles*1)
				--part:SetAngleVelocity(Angle(data.anglevelocity.p, -data.anglevelocity.r, data.anglevelocity.y)*0.5)

				part:SetInvert(data.mirrored)
				part:SetFullbright(data.fullbright)
				part:SetEyeAngles(data.eyeangles)

				if data.effect.Enabled then
					local part2 = pac.CreatePart("effect")
					part2:SetName(data.name .. " effect")
					part2:SetParent(part)
					part2:SetBone(translate_bone(data.bone))

					part2:SetLoop(data.effect.loop)
					part2:SetRate(data.effect.rate)
					part2:SetEffect(data.effect.effect)
					if data.weaponclass and data.weaponclass ~= "" then
						local part_ = pac.CreatePart("event")
						part_:SetName(part2.Name .. " weapon class")
						part_:SetParent(part2)
						part_:SetEvent("weapon_class")
						part_:SetOperator("find simple")
						part_:SetInvert(true)
						part_:SetArguments(data.weaponclass .. "@@" .. (data.hideweaponclass and "1" or "0"))
					end
				end

				if data.clip.Enabled then
					local part2 = part:CreatePart("clip")
						part2:SetName(data.name .. " clip")
						if data.clip.bone and data.clip.bone ~= "" then
							part2:SetBone(data.clip.bone)
						end
						part2:SetParent(part)
						part2:SetPosition(data.clip.angles:Forward() * data.clip.distance)
						part2:SetAngles(data.clip.angles*-1)
				end

				if data.animation.Enabled then
					local part2 = part:CreatePart("animation")
						part2:SetParent(part)
						part2:SetName(data.name .. " animation")
						part2:SetSequenceName(data.animation.sequence or "")
						part2:SetRate(data.animation.rate)
						part2:SetMin(data.animation.min)
						part2:SetMax(data.animation.max)
						part2:SetOffset(data.animation.offset)
						part2:SetPingPongLoop(data.animation.loopmode)
					part:AddChild(part2)
				end

				if data.modelbones.Enabled then
					part:SetBoneMerge(data.modelbones.merge)
					part.pac2_modelbone = data.modelbones.redirectparent

					for key, bone in pairs(data.modelbones.bones) do
						bone.size = tonumber(bone.size)
						if
							bone.scale == Vector(1,1,1) and
							bone.angles == Vector(0,0,0) and
							bone.offset == Vector(0,0,0) and
							bone.size == 1
						then goto CONTINUE end

						local part2 = pac.CreatePart("bone")
							part2:SetName("model bone " .. part:GetName() .. " " .. key)
							part2:SetParent(part)
							part2:SetBone(part:GetEntity():GetBoneName(key))

							part2:SetScale(bone.scale*1)
							part2:SetAngles(bone.angles*1)
							part2:SetPosition(bone.offset*1)

							part2:SetSize(bone.size)
							::CONTINUE::
					end
				end

				if data.weaponclass and data.weaponclass ~= "" then
					local part_ = pac.CreatePart("event")
					part_:SetName(part.Name .. " weapon class")
					part_:SetParent(part)
					part_:SetEvent("weapon_class")
					part_:SetOperator("find simple")
					part_:SetInvert(true)
					part_:SetArguments(data.weaponclass .. "@@" .. (data.hideweaponclass and "1" or "0"))
				end
		end
	end

	local part = pac.CreatePart("entity")
		part:SetParent(base)
		part:SetName("player")

		part:SetColor(Vector(data.player_color.r, data.player_color.g, data.player_color.b))
		part:SetAlpha(data.player_color.a/255)
		part:SetMaterial(data.player_material)
		part:SetScale(data.overall_scale*1)
		part:SetDrawWeapon(data.drawwep)

	for bone, data in pairs(data.bones) do
		local part_ = pac.CreatePart("bone")
			part_:SetParent(part)
			part_:SetName(bone .. " bone")
			part_:SetBone(translate_bone(bone))
			part_:SetSize(tonumber(data.size))
			part_:SetScale(data.scale*1)
			part_:SetPosition(data.offset*1)
			part_:SetAngles(data.angles*1)
	end

	for key, part in pairs(pac.GetLocalParts()) do
		if part.pac2_part and part.pac2_part.parent and part.pac2_part.parent ~= "none" then
			for key, parent in pairs(pac.GetLocalParts()) do
				if parent:GetName() == (part.pac2_part.parent .. " model") then
					part:SetParent(parent)
					if parent.pac2_modelbone then
						part:SetBone(translate_bone(parent.pac2_modelbone))
					end
				end
			end
		end
	end

	-- hacks

	for key, part in pairs(pac.GetLocalParts()) do
		part:SetParent(part:GetParent())
	end

	return base
end

local glon = {}

do
	local decode_types
	decode_types = {
		-- \2\6omg\1\6omgavalue\1\1
		[2	] = function(reader, rtabs) -- table
			local t, c, pos = {}, reader:Next()
			rtabs[#rtabs+1] = t
			local stage = false
			local key
			while true do
				c, pos = reader:Peek()
				if c == "\1" then
					if stage then
						error(string.format("Expected value to match key at %s! (Got EO Table)",
							pos))
					else
						reader:Next()
						return t
					end
				else
					if stage then
						t[key] = Read(reader, rtabs)
					else
						key = Read(reader, rtabs)
					end
					stage = not stage
				end
			end
		end,
		[3	] = function(reader, rtabs) -- array
			local t, i, c, pos = {}, 1, reader:Next()
			rtabs[#rtabs+1] = t
			while true do
				c, pos = reader:Peek()
				if c == "\1" then
					reader:Next()
					return t
				else
					t[i] = Read(reader, rtabs)
					i = i+1
				end
			end
		end,
		[4	] = function(reader) -- false boolean
			reader:Next()
			return false
		end,
		[5	] = function(reader) -- true boolean
			reader:Next()
			return true
		end,
		[6	] = function(reader) -- number
			local s, c, pos, e = "", reader:Next()
			while true do
				c = reader:Next()
				if not c then
					error(string.format("Expected \1 to end number at %s! (Got EOF!)",
						pos))
				elseif c == "\1" then
					break
				else
					s = s..c
				end
			end
			if s == "" then s = "0" end
			local n = tonumber(s)
			if not n then
				error(string.format("Invalid number at %s! (%q)",
					pos, s))
			end
			return n
		end,
		[7	] = function(reader) -- string
			local s, c, pos, e = "", reader:Next()
			while true do
				c = reader:Next()
				if not c then
					error(string.format("Expected unescaped \1 to end string at position %s! (Got EOF)",
						pos))
				elseif e then
					if c == "\3" then
						s = s.."\0"
					else
						s = s..c
					end
					e = false
				elseif c == "\2" then
					e = true
				elseif c == "\1" then
					s = string.gsub(s, "\4", "\"") -- unescape quotes
					return s
				else
					s = s..c
				end
			end
		end,
		[8	] = function(reader) -- Vector
			local x = decode_types[6](reader)
			reader:StepBack()
			local y = decode_types[6](reader)
			reader:StepBack()
			local z = decode_types[6](reader)
			return Vector(x, y, z)
		end,
		[9	] = function(reader) -- Angle
			local p = decode_types[6](reader)
			reader:StepBack()
			local y = decode_types[6](reader)
			reader:StepBack()
			local r = decode_types[6](reader)
			return Angle(p, y, r)
		end,
		[13	] = function(reader) -- ConVar
			return GetConVar(decode_types[7](reader))
		end,
		[15 ] = function(reader) -- Color
			local r = decode_types[6](reader)
			reader:StepBack()
			local g = decode_types[6](reader)
			reader:StepBack()
			local b = decode_types[6](reader)
			reader:StepBack()
			local a = decode_types[6](reader)
			return Color(r, g, b, a)
		end,
		[253] = function(reader) -- -math.huge
			reader:Next()
			return -math.huge
		end,
		[254] = function(reader) -- math.huge
			reader:Next()
			return math.huge
		end,
		[255] = function(reader, rtabs) -- Reference
			return rtabs[decode_types[6](reader) - 1]
		end,
	}
	function Read(reader, rtabs)
		local t, pos = reader:Peek()
		if not t then
			error(string.format("Expected type ID at %s! (Got EOF)",
				pos))
		else
			local dt = decode_types[string.byte(t)]
			if not dt then
				error(string.format("Unknown type ID, %s!",
					string.byte(t)))
			else
				return dt(reader, rtabs or {0})
			end
		end
	end
	local reader_meta = {}
	reader_meta.__index = reader_meta
	function reader_meta:Next()
		self.i = self.i+1
		self.c = string.sub(self.s, self.i, self.i)
		if self.c == "" then self.c = nil end
		self.p = string.sub(self.s, self.i+1, self.i+1)
		if self.p == "" then self.p = nil end
		return self.c, self.i
	end
	function reader_meta:StepBack()
		self.i = self.i-1
		self.c = string.sub(self.s, self.i, self.i)
		if self.c == "" then self.c = nil end
		self.p = string.sub(self.s, self.i+1, self.i+1)
		if self.p == "" then self.p = nil end
		return self.c, self.i
	end
	function reader_meta:Peek()
		return self.p, self.i+1
	end
	function glon.decode(data)
		if type(data) == "nil" then
			return nil
		elseif type(data) ~= "string" then
			error(string.format("Expected string to decode! (Got type %s)",
				type(data)
			))
		elseif data:len() == 0 then
			return nil
		end


		return Read(setmetatable({
			s = data,
			i = 0,
			c = string.sub(data, 0, 0),
			p = string.sub(data, 1, 1),
		}, reader_meta), {})
	end
end

concommand.Add("pac_convert_pac2_outfits", function()
	if not file.IsDir("pac2_outfits", "DATA") then
		pac.Message("garrysmod/data/pac2_outfits/ does not exist")
		return
	end

	local folders = select(2, file.Find("pac2_outfits/*", "DATA"))

	if #folders == 0 then
		pac.Message("garrysmod/data/pac2_outfits/ is empty")
		return
	end

	for _, uniqueid in ipairs(folders) do
		local owner_nick = file.Read("pac2_outfits/" .. uniqueid .. "/__owner.txt", "DATA")

		if not owner_nick then
			owner_nick = LocalPlayer():Nick()
			pac.Message("garrysmod/data/pac2_outfits/" .. uniqueid .. "/__owner.txt does not exist (it contains the player nickname) defaulting to " .. owner_nick)
		end

		local folders = select(2, file.Find("pac2_outfits/" .. uniqueid .. "/*", "DATA"))

		if #folders == 0 then
			pac.Message("garrysmod/data/pac2_outfits/" .. uniqueid .. "/ is empty")
			return
		end

		for _, folder_name in ipairs(folders) do
			local name = file.Read("pac2_outfits/" .. uniqueid .. "/" .. folder_name .. "/name.txt", "DATA")
			local data = file.Read("pac2_outfits/" .. uniqueid .. "/" .. folder_name .. "/outfit.txt", "DATA")

			if not name then
				pac.Message("garrysmod/data/pac2_outfits/" .. uniqueid .. "/" .. folder_name .. "/name.txt does not exist. defaulting to: " .. folder_name)
			end

			if data then
				pace.ClearParts()

				local ok, res = pcall(function() pacx.ConvertPAC2Config(glon.decode(data), name) end)
				if ok then
					file.CreateDir("pac3/pac2_outfits/")
					file.CreateDir("pac3/pac2_outfits/" .. uniqueid .. "/")

					pace.SaveParts("pac2_outfits/" .. uniqueid .. "/" .. folder_name)
				else
					pac.Message("garrysmod/data/pac2_outfits/" .. uniqueid .. "/" .. folder_name .. "(" .. name .. ") failed to convert : " .. res)
				end
			else
				pac.Message("garrysmod/data/pac2_outfits/" .. uniqueid .. "/" .. folder_name .. "/data.txt does not exist. this file contains the outfit data")
			end
		end
	end

	pace.ClearParts()

	pac.Message("pac2 outfits are stored under pac > load > pac2_outfits in the editor")
	pac.Message("you may need to restart the editor to see them")
end)
