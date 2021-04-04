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

		local c = part:GetColor()

		data.clr = {c.r, c.g, c.b, part:GetAlpha() * 255}
		data.ang = part:GetOwner():GetAngles()
		data.pos = part:GetOwner():GetPos()
		data.mat = part:GetMaterial()
		data.mdl = part:GetModel()
		data.skn = part:GetSkin()
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