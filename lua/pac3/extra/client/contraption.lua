local L = pace.LanguageString

pace.AddTool(L"spawn as props", function(part)
	local data = pacx.PartToContraptionData(part)
	net.Start("pac_to_contraption")
		net.WriteTable(data)
	net.SendToServer()
end)

function pacx.PartToContraptionData(part, tbl)
	tbl = tbl or {}

	if part.is_model_part then
		local data = {}

		local color = part:GetColor()
		local alpha = part:GetAlpha()

		if part.ProperColorRange then
			data.clr = Color(color.r * 255, color.g * 255, color.b * 255, alpha * 255)
		else
			data.clr = Color(color.r, color.g, color.b, alpha * 255)
		end

		data.ang = part:GetOwner():GetAngles()
		data.pos = part:GetOwner():GetPos()
		data.mat = part:GetMaterial()
		data.mdl = part:GetModel()
		data.skn = part:GetSkin()

		local size = part:GetSize()
		data.scale = part:GetScale()*size

		data.id = part.UniqueID

		table.insert(tbl, data)
	end

	for key, part in ipairs(part:GetChildren()) do
		if part.is_model_part then
			pacx.PartToContraptionData(part, tbl)
		end
	end

	return tbl
end
