local MUTATOR = {}

MUTATOR.ClassName = "model"
MUTATOR.UpdateRate = 0.25

function MUTATOR:WriteArguments(path)
	assert(type(path) == "string", "path must be a string")

	net.WriteString(path:lower())
end

function MUTATOR:ReadArguments()
	return net.ReadString():lower()
end

function MUTATOR:Update(val)
	if not self.actual_model then return end

	if self.Entity:GetModel():lower() ~= self.actual_model then
		self.Entity:SetModel(self.actual_model)
	end
end

function MUTATOR:StoreState()
	return self.Entity:GetModel()
end

function MUTATOR:Mutate(path)
	if path:find("^http") then
		pac.Message(self.Owner, " wants to use ", path, " as model on ", ent)

		pac.DownloadMDL(path, function(mdl_path)
			pac.Message(mdl_path, " downloaded for ", ent, ': ', path)

			self.Entity:SetModel(mdl_path)
			self.actual_model = mdl_path

		end, function(err)
			pac.Message(err)
		end, self.Owner)
	else
		if path:EndsWith(".mdl") then
			if not util.IsValidModel(path) then
				util.PrecacheModel(path)
			end

			if not util.IsValidModel(path) then
				self.Owner:ChatPrint('[PAC3] ERROR: ' .. path .. " is not a valid model on the server.")
			else
				self.Entity:SetModel(path)
			end
		else
			local translated = player_manager.TranslatePlayerModel(path)

			if translated ~= path then
				self.Owner:ChatPrint('[PAC3] ERROR: ' .. path .. " is not a valid player model on the server.")
			else
				self.Entity:SetModel(path)
			end
		end
	end
end

pac.emut.Register(MUTATOR)