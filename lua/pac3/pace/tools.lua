local L = pace.LanguageString
pace.Tools = {}

function pace.AddTool(name, callback, ...)
	table.insert(pace.Tools, {name = name, callback = callback, suboptions = {...}})
end

pace.AddTool(L"scale this and children", function(part, suboption)
	Derma_StringRequest(L"scale", L"input the scale multiplier (does not work well with bones)", "1", function(scale)
		scale = tonumber(scale)
		
		if scale and part:IsValid() then
			if part.SetPosition then 
				part:SetPosition(part:GetPosition() * scale)
			end 
					
			if part.SetSize then 
				part:SetSize(part:GetSize() * scale) 
			end 
					
			for _, part in pairs(part:GetChildren()) do 
				if part.SetPosition then 
					part:SetPosition(part:GetPosition() * scale)
				end 
						
				if part.SetSize then 
					part:SetSize(part:GetSize() * scale) 
				end 
			end		
		end			
	end)
end)

pace.AddTool(L"show only with active weapon", function(part, suboption)
	local event = part:CreatePart("event")
	local owner = part:GetOwner(true)
	if owner.GetActiveWeapon and owner:GetActiveWeapon():IsValid() then
		local class_name = owner:GetActiveWeapon():GetClass()
	
		event:SetName(class_name .. " ws")
		event:SetEvent("weapon_class")
		event:SetOperator("equal")
		event:SetInvert(true)
		event:SetRootOwner(true)
			
		event:ParseArguments(class_name, suboption == 1)
	end
end, L"hide weapon", L"show weapon")


