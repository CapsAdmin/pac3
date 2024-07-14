local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "health_modifier"

PART.Group = "combat"
PART.Icon = "icon16/heart.png"

BUILDER:StartStorableVars()

	BUILDER:SetPropertyGroup("Health")
		BUILDER:GetSet("ChangeHealth", false)
		BUILDER:GetSet("FollowHealth", true, {description = "whether changing the max health should try to set your health at the same time"})
		BUILDER:GetSet("MaxHealth", 100, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,0,math.huge)) end})

	BUILDER:SetPropertyGroup("ExtraHpBars")
		BUILDER:GetSet("FollowHealthBars", true, {description = "whether changing the extra health bars should try to update them at the same time"})
		BUILDER:GetSet("HealthBars", 0, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,0,100)) end})
		BUILDER:GetSet("BarsAmount", 100, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,0,math.huge)) end})
		BUILDER:GetSet("BarsLayer", 1, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,0,15)) end})
		BUILDER:GetSet("AbsorbFactor", 0, {editor_onchange = function(self,num) return math.Clamp(num,-1,1) end})
		BUILDER:GetSet("HPBarsResetOnHide", false)

	BUILDER:SetPropertyGroup("Armor")
		BUILDER:GetSet("ChangeArmor", false)
		BUILDER:GetSet("FollowArmor", true, {description = "whether changing the max armor should try to set your armor at the same time"})
		BUILDER:GetSet("MaxArmor", 100, {editor_onchange = function(self,num) return math.floor(math.Clamp(num,0,math.huge)) end})

	BUILDER:SetPropertyGroup("DamageMultipliers")
		BUILDER:GetSet("DamageMultiplier", 1)
		BUILDER:GetSet("ModifierId", "")
		BUILDER:GetSet("MultiplierResetOnHide", false)

BUILDER:EndStorableVars()

local part_UID_caches = {}

function PART:SendModifier(str)
	if self:IsHidden() then return end
	if LocalPlayer() ~= self:GetPlayerOwner() then return end
	if not GetConVar("pac_sv_health_modifier"):GetBool() then return end
	if util.NetworkStringToID( "pac_request_healthmod" ) == 0 then self:SetError("This part is deactivated on the server") return end
	pac.Blocked_Combat_Parts = pac.Blocked_Combat_Parts or {}
	if pac.Blocked_Combat_Parts then
		if pac.Blocked_Combat_Parts[self.ClassName] then return end
	end
	if not GetConVar("pac_sv_combat_enforce_netrate_monitor_serverside"):GetBool() then
		if not pac.CountNetMessage() then self:SetInfo("Went beyond the allowance") return end
	end
	part_UID_caches[self.UniqueID] = self
	if self.Name ~= "" then part_UID_caches[self.Name] = self end

	if str == "MaxHealth" and self.ChangeHealth then
		net.Start("pac_request_healthmod")
		net.WriteString(self.UniqueID)
		net.WriteString(self.ModifierId)
		net.WriteString("MaxHealth")
		net.WriteUInt(self.MaxHealth, 32)
		net.WriteBool(self.FollowHealth)
		net.SendToServer()
	elseif str == "MaxArmor" and self.ChangeArmor then
		net.Start("pac_request_healthmod")
		net.WriteString(self.UniqueID)
		net.WriteString(self.ModifierId)
		net.WriteString("MaxArmor")
		net.WriteUInt(self.MaxArmor, 32)
		net.WriteBool(self.FollowArmor)
		net.SendToServer()
	elseif str == "DamageMultiplier" then
		net.Start("pac_request_healthmod")
		net.WriteString(self.UniqueID)
		net.WriteString(self.ModifierId)
		net.WriteString("DamageMultiplier")
		net.WriteFloat(self.DamageMultiplier)
		net.WriteBool(true)
		net.SendToServer()
	elseif str == "HealthBars" then
		net.Start("pac_request_healthmod")
		net.WriteString(self.UniqueID)
		net.WriteString(self.ModifierId)
		net.WriteString("HealthBars")
		net.WriteUInt(self.HealthBars, 32)
		net.WriteUInt(self.BarsAmount, 32)
		net.WriteUInt(self.BarsLayer, 4)
		net.WriteFloat(self.AbsorbFactor)
		net.WriteBool(self.FollowHealthBars)
		net.SendToServer()

	elseif str == "all" then
		self:SendModifier("MaxHealth")
		self:SendModifier("MaxArmor")
		self:SendModifier("DamageMultiplier")
		self:SendModifier("HealthBars")
	end
end

function PART:SetHealthBars(val)
	self.HealthBars = val
	if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
	self:SendModifier("HealthBars")
end

function PART:SetBarsAmount(val)
	self.BarsAmount = val
	if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
	self:SendModifier("HealthBars")
	self:UpdateHPBars()
end

function PART:SetBarsLayer(val)
	self.BarsLayer = val
	if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
	self:SendModifier("HealthBars")
	self:UpdateHPBars()
end

function PART:SetMaxHealth(val)
	self.MaxHealth = val
	if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
	self:SendModifier("MaxHealth")
end

function PART:SetMaxArmor(val)
	self.MaxArmor = val
	if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
	self:SendModifier("MaxArmor")
end

function PART:SetDamageMultiplier(val)
	self.DamageMultiplier = val
	if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
	self:SendModifier("DamageMultiplier")
	local sv_min = GetConVar("pac_sv_health_modifier_min_damagescaling"):GetInt()
	if self.DamageMultiplier < sv_min then
		self:SetInfo("Your damage scaling is beyond the server's minimum permitted! Server minimum is " .. sv_min)
	else
		self:SetInfo(nil)
	end
end

function PART:OnRemove()
	part_UID_caches = {} --we'll need this part removed from the cache
	if pac.LocalPlayer ~= self:GetPlayerOwner() then return end
	if util.NetworkStringToID( "pac_request_healthmod" ) == 0 then return end
	local found_remaining_healthmod = false
	for _,part in pairs(pac.GetLocalParts()) do
		if part.ClassName == "health_modifier" and part ~= self then
			found_remaining_healthmod = true
		end
	end
	net.Start("pac_request_healthmod")
	net.WriteString(self.UniqueID)
	net.WriteString(self.ModifierId)
	net.WriteString("OnRemove")
	net.WriteFloat(0)
	net.WriteBool(true)
	net.SendToServer()

	if not found_remaining_healthmod then
		net.Start("pac_request_healthmod")
		net.WriteString(self.UniqueID)
		net.WriteString(self.ModifierId)
		net.WriteString("MaxHealth")
		net.WriteUInt(100,32)
		net.WriteBool(true)
		net.SendToServer()

		net.Start("pac_request_healthmod")
		net.WriteString(self.UniqueID)
		net.WriteString(self.ModifierId)
		net.WriteString("MaxArmor")
		net.WriteUInt(100,32)
		net.WriteBool(false)
		net.SendToServer()
	end
end

function PART:OnShow()
	self:SendModifier("all")
end

function PART:OnHide()
	if util.NetworkStringToID( "pac_request_healthmod" ) == 0 then self:SetError("This part is deactivated on the server") return end
	if self.HPBarsResetOnHide then
		net.Start("pac_request_healthmod")
		net.WriteString(self.UniqueID)
		net.WriteString(self.ModifierId)
		net.WriteString("HealthBars")
		net.WriteUInt(0, 32)
		net.WriteUInt(0, 32)
		net.WriteUInt(self.BarsLayer, 4)
		net.WriteFloat(1)
		net.WriteBool(self.FollowHealthBars)
		net.SendToServer()
	end
	if self.MultiplierResetOnHide then
		net.Start("pac_request_healthmod")
		net.WriteString(self.UniqueID)
		net.WriteString(self.ModifierId)
		net.WriteString("DamageMultiplier")
		net.WriteFloat(1)
		net.WriteBool(true)
		net.SendToServer()
	end
end

function PART:Initialize()
	self.healthbar_index = 0
	if not GetConVar("pac_sv_health_modifier"):GetBool() or pac.Blocked_Combat_Parts[self.ClassName] then self:SetError("health modifiers are disabled on this server!") end
end

function PART:UpdateHPBars()
	local ent = self:GetPlayerOwner()
	if ent.pac_healthbars_uidtotals and ent.pac_healthbars_uidtotals[self.UniqueID] then
		self.healthbar_index = math.ceil(ent.pac_healthbars_uidtotals[self.UniqueID] / self.BarsAmount)
		if ent.pac_healthbars_uidtotals[self.UniqueID] then
			self:SetInfo("Extra healthbars:\nHP is " .. ent.pac_healthbars_uidtotals[self.UniqueID] .. "/" .. self.HealthBars * self.BarsAmount .. "\n" .. self.healthbar_index .. " of " .. self.HealthBars .. " bars")
		end
	end
end

--expected structure : pac_healthbars uid_or_name action number
--actions: set, add, subtract, refill, replenish, remove
concommand.Add("pac_healthbar", function(ply, cmd, args)
	local uid_or_name = args[1]
	local num = tonumber(args[3]) or 0
	if part_UID_caches[uid_or_name] ~= nil and args[2] ~= nil then
		local part = part_UID_caches[uid_or_name]
		uid = part.UniqueID
		local action = args[2] or ""

		--doesnt make sense to add or subtract 0
		if ((action == "add" or action == "subtract") and num == 0) or (action == "") then return end
		--replenish means set to full
		if action == "refill" or  action == "replenish" then
			action = "set"
			num = part.BarsAmount * part.HealthBars
		end
		if action == "remove" then action = "set" num = 0 end
		net.Start("pac_request_extrahealthbars_action")
		net.WriteString(uid)
		net.WriteString(action)
		net.WriteInt(num, 16)
		net.SendToServer()
	end
	if args[2] == nil then ply:PrintMessage(HUD_PRINTCONSOLE, "\nthis command needs at least two arguments.\nuid or name: the unique ID or the name of the part\naction: add, subtract, refill, replenish, remove, set\nnumber\n\nexample: pac_healthbar my_healthmod add 50\n") end
end, nil, "changes your health modifier's extra health value. arguments:\nuid or name: the unique ID or the name of the part\naction: add, subtract, refill, replenish, remove, set\nnumber\n\nexample: pac_healthbar my_healthmod add 50")

BUILDER:Register()