function pac.PartToContraptionData(part, tbl)	
	tbl = tbl or {}
		
	if part.ClassName == "model" then
		local data = {}
		
		local c = part:GetColor()
		local a = part:GetAlpha() * 255
		data.clr = {c.r, c.g, c.b, a}
		data.ang = part.Entity:GetAngles()
		data.pos = part.Entity:GetPos()
		data.mat = part:GetMaterial()
		data.mdl = part:GetModel()
		data.skn = part:GetSkin()
			
		table.insert(tbl, data)
	end
	
	for key, part in pairs(part:GetChildren()) do
		if part.ClassName == "model" then
			pac.PartToContraptionData(part, tbl)
		end
	end
	
	return tbl
end