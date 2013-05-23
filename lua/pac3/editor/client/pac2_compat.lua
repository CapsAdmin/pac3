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

function pac.ConvertPAC2Config(data, ent)
	local _out = {}
	
	local base = pac.CreatePart("group")
		base:SetName("pac2 outfit")
		
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
				part:SetAngleVelocity(Angle(data.anglevelocity.p, -data.anglevelocity.r, data.anglevelocity.y)*0.5)
				
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
				part:SetAngleVelocity(Angle(data.anglevelocity.p, -data.anglevelocity.r, data.anglevelocity.y)*0.5)
				
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
				part:SetAngleVelocity(Angle(data.anglevelocity.p, -data.anglevelocity.r, data.anglevelocity.y)*0.5)
				
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
				part:SetAngleVelocity(Angle(data.anglevelocity.p, -data.anglevelocity.r, data.anglevelocity.y)*0.5)
				
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
				part:SetOriginFix(data.originfix)
				
				part:SetMaterial(data.material)
				
				part:SetColor(Vector(data.color.r, data.color.g, data.color.b))
				part:SetAlpha(data.color.a / 255)
				
				part:SetModel(data.model)
				part:SetSize(data.size)
				part:SetScale(data.scale*1)
				
				part:SetPosition(data.offset*1)
				part:SetAngles(data.angles*1)
				part:SetAngleVelocity(Angle(data.anglevelocity.p, -data.anglevelocity.r, data.anglevelocity.y)*0.5)
				
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
						part2:SetSequenceName(data.animation.sequence)
						part2:SetRate(data.animation.rate)
						part2:SetMin(data.animation.min)
						part2:SetMax(data.animation.max)
						part2:SetOffset(data.animation.offset)
						part2:SetPingPongLoop(data.animation.loopmode)
					part:AddChild(part2)
				end
				
				if data.modelbones.Enabled then
					part:SetOverallSize(tonumber(data.modelbones.overallsize))
					part:SetBoneMerge(data.modelbones.merge)
					part.pac2_modelbone = data.modelbones.redirectparent
					
					for key, bone in pairs(data.modelbones.bones) do
						bone.size = tonumber(bone.size)
						if 
							bone.scale == Vector(1,1,1) and
							bone.angles == Vector(0,0,0) and
							bone.offset == Vector(0,0,0) and
							bone.size == 1
						then continue end
						
						local part2 = pac.CreatePart("bone")
							part2:SetName("model bone " .. part:GetName() .. " " .. key)
							part2:SetParent(part)
							part2:SetBone(part:GetEntity():GetBoneName(key))
							
							part2:SetScale(bone.scale*1)
							part2:SetAngles(bone.angles*1)
							part2:SetPosition(bone.offset*1)
							
							part2:SetSize(bone.size)
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
	
	for key, part in pairs(pac.GetParts(true)) do
		if part.pac2_part and part.pac2_part.parent and part.pac2_part.parent ~= "none" then
			for key, parent in pairs(pac.GetParts(true)) do
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
	
	for key, part in pairs(pac.GetParts(true)) do
		part:SetParent(part:GetParent())
	end

	return base
end

concommand.Add("pac_convert_pac2_config", function(ply, _, args)
	if not ply.GetPACConfig then return end
	pac.Panic()
	pac.ConvertPAC2Config(ply:GetPACConfig(), pac.LocalPlayer)
end)