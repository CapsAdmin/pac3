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
		local original_path = path
		if not util.IsValidModel(path) then
			path = player_manager.TranslatePlayerModel(path)
		end

		self.Entity:SetModel(path)
		self.actual_model = path

		if SERVER then
			if path ~= original_path and original_path:EndsWith(".mdl") then
				self.Owner:ChatPrint('[PAC3] ERROR: ' .. original_path .. " is not a valid player model on the server. Defaulting to kleiner.")
			end
		end
	end
end

pac.emut.Register(MUTATOR)