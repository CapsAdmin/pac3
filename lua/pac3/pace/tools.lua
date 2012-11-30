local L = pace.LanguageString
pace.Tools = {}

function pace.AddTool(name, callback, ...)
	table.insert(pace.Tools, {name = name, callback = callback, suboptions = {...}})
end

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


