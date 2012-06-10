local bones = 
{
	["pelvis"] = "ValveBiped.Bip01_Pelvis",
	["spine 1"] = "ValveBiped.Bip01_Spine",
	["spine 2"] = "ValveBiped.Bip01_Spine1",
	["spine 3"] = "ValveBiped.Bip01_Spine2",
	["spine 4"] = "ValveBiped.Bip01_Spine4",
	["neck"] = "ValveBiped.Bip01_Neck1",
	["head"] = "ValveBiped.Bip01_Head1",
	["right clavicle"] = "ValveBiped.Bip01_R_Clavicle",
	["right upper arm"] = "ValveBiped.Bip01_R_UpperArm",
	["right forearm"] = "ValveBiped.Bip01_R_Forearm",
	["right hand"] = "ValveBiped.Bip01_R_Hand",
	["left clavicle"] = "ValveBiped.Bip01_L_Clavicle",
	["left upper arm"] = "ValveBiped.Bip01_L_UpperArm",
	["left forearm"] = "ValveBiped.Bip01_L_Forearm",
	["left hand"] = "ValveBiped.Bip01_L_Hand",
	["right thigh"] = "ValveBiped.Bip01_R_Thigh",
	["right calf"] = "ValveBiped.Bip01_R_Calf",
	["right foot"] = "ValveBiped.Bip01_R_Foot",
	["right toe"] = "ValveBiped.Bip01_R_Toe0",
	["left thigh"] = "ValveBiped.Bip01_L_Thigh",
	["left calf"] = "ValveBiped.Bip01_L_Calf",
	["left foot"] = "ValveBiped.Bip01_L_Foot",
	["left toe"] = "ValveBiped.Bip01_L_Toe0",
}

local function translate_bone(part, bone, i)
	bone = bone and bone:lower()
	local bones = part:GetOwnerModelBones()
	if bones then
		for friendly, val in pairs(bones) do
			if val.real:lower() == bone or (i and val.i == i) then
				return friendly
			end
		end
	end
	
	return bone
end

function pac.ConvertPAC2Config(data, ent)
	local _out = {}
	
	local base = pac.CreatePart("group")
		base:SetName("pac2 outfit")
		base:SetOwner(ent)
		
	for bone, data in pairs(data.bones) do
		local part = base:CreatePart("bone")			
			part:SetName(bone)
			part:SetBone(translate_bone(part, bones[bone]))
			part:SetSize(data.size)
			part:SetScale(data.scale)
			part:SetPosition(data.offset)
			part:SetAngles(data.angles)
	end
	
	for key, data in pairs(data.parts)  do
		if data.sprite.Enabled then
			local part = base:CreatePart("sprite")			
				part:SetName(data.name)
								
				if data.parent ~= "none" then
					part:SetParentName(data.parent)
				end
								
				part:SetBone(translate_bone(part, bones[data.bone]))
				
				part:SetColor(Vector(data.sprite.color.r, data.sprite.color.g, data.sprite.color.b))
				part:SetAlpha(data.sprite.color.a / 255)
				
				part:SetMaterial(data.sprite.material)
				part:SetSizeX(data.sprite.x)
				part:SetSizeY(data.sprite.y)
				part:SetEyeAngles(data.eyeangles)
				if data.weaponclass ~= "" then 
					local part = part:CreatePart("event")
					part:SetEvent("weapon_class")
					part:SetArguments(data.weaponclass)
				end
		end
		
		if data.light.Enabled then
			local part = base:CreatePart("light")		
				part:SetName(data.name)
												
				if data.parent ~= "none" then
					part:SetParentName(data.parent)
				end
								
				part:SetBone(translate_bone(part, bones[data.bone]))
				
				part:SetColor(Vector(data.light.r, data.light.g, data.light.b))
				
				part:SetBrightness(data.light.Brightness)
				part:SetSize(data.light.Size)
				part:SetEyeAngles(data.eyeangles)
				if data.weaponclass ~= "" then 
					local part = part:CreatePart("event")
					part:SetEvent("weapon_class")
					part:SetArguments(data.weaponclass)
				end
		end
		
		if data.text.Enabled then
			local part = base:CreatePart("text")		
				part:SetName(data.name)
				
				if data.parent ~= "none" then
					part:SetParentName(data.parent)
				end			
				
				part:SetBone(translate_bone(part, bones[data.bone]))
				
				part:SetColor(Vector(data.text.color.r, data.text.color.g, data.text.color.b))
				part:SetAlpha(data.text.color.a / 255)
				
				part:SetColor(Vector(data.text.outlinecolor.r, data.text.outlinecolor.g, data.text.outlinecolor.b))
				part:SetAlpha(data.text.outlinecolor.a / 255)
				
				part:SetOutline(data.text.outline)
				part:SetText(data.text.text)
				part:SetFont(data.text.font)
				part:SetSize(data.text.size)
				part:SetEyeAngles(data.eyeangles)
				if data.weaponclass ~= "" then 
					local part = part:CreatePart("event")
					part:SetEvent("weapon_class")
					part:SetArguments(data.weaponclass)
				end
		end
		
		if data.trail.Enabled then
			local part = base:CreatePart("trail")
				part:SetName(data.name .. " " .. part.ClassName)
				
				part:SetStartSize(data.trail.startsize)
				part:SetColor(data.trail.color)
				part:SetMaterial(data.trail.material)
				part:SetLength(data.trail.length)		
				if data.weaponclass ~= "" then 
					local part = part:CreatePart("event")
					part:SetEvent("weapon_class")
					part:SetArguments(data.weaponclass)
				end				
		end
		
		if data.effect.Enabled then
			local part = base:CreatePart("effect")
				part:SetName(data.name .. " " .. part.ClassName)				
				
				part:SetLoop(data.effect.loop)
				part:SetRate(data.effect.rate)
				part:SetEffect(data.effect.effect)
				if data.weaponclass ~= "" then 
					local part = part:CreatePart("event")
					part:SetEvent("weapon_class")
					part:SetArguments(data.weaponclass)
				end
		end
		
		if data.color.a ~= 0 and data.size ~= 0 and data.scale ~= vector_origin then
			local part = base:CreatePart("model")
				part:SetName(data.name)
				
				if data.weaponclass ~= "" then 
					local part = part:CreatePart("event")
					part:SetEvent("weapon_class")
					part:SetArguments(data.weaponclass)
				end
				
				if data.parent ~= "none" then
					part:SetParentName(data.parent)
				end
				
				part:SetBone(translate_bone(part, bones[data.bone]))
				part:SetMaterial(data.material)
				
				part:SetColor(Vector(data.color.r, data.color.g, data.color.b))
				part:SetAlpha(data.color.a / 255)
				
				part:SetModel(data.model)
				part:SetSize(data.size)
				part:SetScale(data.scale)
				part:SetPosition(data.offset)
				part:SetAngles(data.angles)
				part:SetInvert(data.mirrored)
				part:SetFullbright(data.fullbright)
				part:SetEyeAngles(data.eyeangles)
				
				if data.clip.Enabled then
					local part2 = part:CreatePart("clip")
						part2:SetName(data.name .. " " .. part.ClassName)				
						
						part2:SetPosition(data.clip.angles:Forward() * data.clip.distance)
						part2:SetAngles(data.clip.angles)
				end
				
				if data.animation.Enabled then
					local part2 = part:CreatePart("animation")
						part2:SetName(data.name .. " " .. part.ClassName)				
						part2:SetSequence(data.animation.sequence)
						part2:SetRate(data.animation.rate)
						part2:SetMin(data.animation.min)
						part2:SetMax(data.animation.max)
						part2:SetOffset(data.animation.offset)
						part2:SetPingPongLoop(data.animation.loopmode)
					part:AddChild(part2)
				end
				
				if data.modelbones.Enabled then
					for key, bone in pairs(data.modelbones.bones) do
						if 
							bone.scale == Vector(1,1,1) and
							bone.angles == Vector(0,0,0) and
							bone.offset == Vector(0,0,0) and
							bone.size == "1"
						then continue end
						
						local part2 = part:CreatePart("bone")
							part2:SetBone(translate_bone(part2, nil, key))
							
							part2:SetScale(bone.scale)
							part2:SetAngles(bone.angles)
							part2:SetPosition(bone.offset)
							part2:SetSize(bone.size)
					end
				end
		end
	end
	
	local part = base:CreatePart("player")
		part:SetName("player mod")
		
		part:SetColor(Vector(data.player_color.r, data.player_color.g, data.player_color.b))
		part:SetAlpha(data.player_color.a)
		part:SetMaterial(data.player_material)
		part:SetScale(data.overall_scale)
		part:SetDrawWeapon(data.drawwep)
	
	timer.Simple(1, function()
		for key, part in pairs(pac.GetParts()) do
			if not part:HasParent() then
				part:SetParent(base)
			end
		end
	end)
	
	return base
end

concommand.Add("convert_pac2_config", function(ply, _, args)
	pac.Panic()
	pac.ConvertPAC2Config(glon.decode(file.Read("pac2_outfits/"..args[1].."/"..args[2].."/outfit.txt")), LocalPlayer())
end)