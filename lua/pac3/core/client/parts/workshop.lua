local PART = {}

PART.ClassName = "workshop"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "WorkshopId", "")
pac.EndStorableVars()

function PART:GetNiceName()
	if self.WorkshopId and string.len(self.WorkshopId) > 0 then
		return "workshop " .. self.WorkshopId
	else
		return "workshop"
	end
end

function PART:OnShow()
	self:Fetch()
end

function PART:SetWorkshopId(id)
	self.WorkshopId = id
	self:Fetch()
end

-- If the client wants to download and mount workshop content
local cl_cvar = CreateClientConVar("pac_workshop_enabled", "1")
local sv_cvar = GetConVar("pac_sv_workshop_enabled")

local pacWorkshopAllowed = function()
	return cl_cvar:GetBool() and sv_cvar:GetBool()
end

local fetchAndMount = function(part, id)
	steamworks.FileInfo(id, function(info)
		steamworks.Download(info.fileid, true, function(filename)
			local success, files = game.MountGMA(filename)
			if success then
				part:RefreshModels()
			end

		end)
	end)
end

local fetchedIds = {}

function PART:Fetch()
	if not pacWorkshopAllowed() then return end

	if self.WorkshopId and string.len(self.WorkshopId) > 0 and not fetchedIds[self.WorkshopId] then
		fetchedIds[self.WorkshopId] = true
		fetchAndMount(self, self.WorkshopId)
	end
end

function PART:RefreshModels()
	local ply = self:GetOwner()
	local allParts = pac.UniqueIDParts[ply:UniqueID()]
	for _, part in pairs(allParts) do
		if part.SetModel then
			part:SetModel(part:GetModel())
		end
	end
end

pac.RegisterPart(PART)

hook.Add("pac_EditorPostConfig", "workshop", function()
	pace.PartTree.model.workshop = true
	pace.PartIcons.workshop = "icon16/package_link.png"
end)
