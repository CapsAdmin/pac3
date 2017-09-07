local CurTime = CurTime
local ParticleEffect = ParticleEffect
local ParticleEffectAttach = ParticleEffectAttach

local PART = {}

PART.ClassName = "effect"
PART.Groups = {'effects', 'model', 'entity'}
PART.Icon = 'icon16/wand.png'

pac.StartStorableVars()
	pac.GetSet(PART, "Effect", "default", {enums = function() return pac.particle_list end})
	pac.GetSet(PART, "Loop", true)
	pac.GetSet(PART, "Follow", true)
	pac.GetSet(PART, "Rate", 1, {editor_sensitivity = 0.1})
	pac.GetSet(PART, "UseParticleTracer", false)

	pac.SetupPartName(PART, "PointA")
	pac.SetupPartName(PART, "PointB")
	pac.SetupPartName(PART, "PointC")
	pac.SetupPartName(PART, "PointD")

pac.EndStorableVars()

pac.RemoveProperty(PART, "Translucent")

function PART:GetNiceName()
	return pac.PrettifyName(self:GetEffect())
end

function PART:Initialize()
	self:SetEffect(self.Effect)

	if not pac.particle_list then
		local found = {}

		for file_name in pairs(pac.loaded_particle_effects) do
			local data = file.Read("particles/"..file_name, "GAME", "b")
			for str in data:gmatch("\3%c([%a_]+)%c") do
				found[str] = true
			end
		end

		pac.particle_list = found
	end
end

function PART:SetControlPointA(var)
	self.ControlPointA = var
	self:ResolveControlPoints()
end

function PART:SetControlPointB(var)
	self.ControlPointB = var
	self:ResolveControlPoints()
end

function PART:GetOwner()
	local parent = self:GetParent()

	if parent:IsValid() and parent.ClassName == "model" and parent.Entity:IsValid() then
		return parent.Entity
	end

	return self.BaseClass.GetOwner(self)
end

PART.last_spew = 0

pac.loaded_particle_effects = pac.loaded_particle_effects or {}

for _, file_name in pairs(file.Find("particles/*.pcf", "GAME")) do
	if not pac.loaded_particle_effects[file_name] then
		game.AddParticles("particles/" .. file_name)
	end
	pac.loaded_particle_effects[file_name] = true
end

local already = {}
local alreadyServer = {}
local function pac_request_precache(name)
	if already[name] then return end
	already[name] = true
	PrecacheParticleSystem(name)
	net.Start("pac_request_precache")
	net.WriteString(name)
	net.SendToServer()
end

function PART:SetEffect(name)
	self.waitingForServer = true
	self.Effect = name
	self.Ready = alreadyServer[name] or false

	if not alreadyServer[name] then
		pac_request_precache(name)
	else
		self.waitingForServer = false
	end
end

hook.Add("pac_EffectPrecached", "pac_Effects", function(name)
	if alreadyServer[name] then return end
	alreadyServer[name] = true
	pac.dprint("effect %q precached!", name)
	for _, part in pairs(pac.GetParts()) do
		if part.ClassName == "effect" and part.Effect == name then
			part.Ready = true
			part.waitingForServer = false
		end
	end
end)

function PART:OnDraw(owner, pos, ang)
	if not self.Ready then
		if not self.waitingForServer then self:SetEffect(self.Effect) end
		return
	end

	local ent = self:GetOwner()

	if ent:IsValid() and self.Loop then
		local time = CurTime()
		if self.last_spew < time then
			ent:StopParticles()
			ent:StopParticleEmission()
			self:Emit(pos, ang)
			self.last_spew = time + math.max(self.Rate, 0.1)
		end
	end
end

function PART:OnHide()
	local ent = self:GetOwner()

	if ent:IsValid() then
		ent:StopParticles()
		ent:StopParticleEmission()
	end
end

function PART:ResolveControlPoints()
	for _, part in pairs(pac.GetParts()) do
		if part.Name == self.ControlPointA then
			self.ControlPointAPart = part
			break
		end
	end

	for _, part in pairs(pac.GetParts()) do
		if part.Name == self.ControlPointB then
			self.ControlPointBPart = part
			break
		end
	end
end

function PART:OnShow(from_rendering)
	if from_rendering then
		self:Emit(self:GetDrawPosition())
	end
end

function PART:Emit(pos, ang)
	local ent = self:GetOwner()

	if ent:IsValid() then
		if not self.Effect then
			ent:StopParticles()
			ent:StopParticleEmission()
			return
		end

		if self.UseParticleTracer and self.PointA:IsValid() then
			local ent2 = self.PointA.Entity and self.PointA.Entity or self.PointA:GetOwner()

			util.ParticleTracerEx(
				self.Effect,
				ent:GetPos(),
				ent2:GetPos(),
				true,
				ent:EntIndex(),
				0
			)
			return
		end

		if self.PointA:IsValid() then
			local points = {}

			table.insert(points, {
				entity = self.PointA.Entity and self.PointA.Entity or self.PointA:GetOwner(),
				attachtype = PATTACH_ABSORIGIN_FOLLOW,
			})

			if self.PointB:IsValid() then
				table.insert(points, {
					entity = self.PointB.Entity and self.PointB.Entity or self.PointB:GetOwner(),
					attachtype = PATTACH_ABSORIGIN_FOLLOW,
				})
			end

			if self.PointC:IsValid() then
				table.insert(points, {
					entity = self.PointC.Entity and self.PointC.Entity or self.PointC:GetOwner(),
					attachtype = PATTACH_ABSORIGIN_FOLLOW,
				})
			end

			if self.PointD:IsValid() then
				table.insert(points, {
					entity = self.PointD.Entity and self.PointD.Entity or self.PointD:GetOwner(),
					attachtype = PATTACH_ABSORIGIN_FOLLOW,
				})
			end

			ent:CreateParticleEffect(self.Effect, points)
		elseif self.Follow then
			ent:StopParticles()
			ent:StopParticleEmission()
			CreateParticleSystem(ent, self.Effect, PATTACH_ABSORIGIN_FOLLOW, 0)
		else
			ent:StopParticles()
			ent:StopParticleEmission()
			ParticleEffect(self.Effect, pos, ang, ent)
		end
	end
end

pac.RegisterPart(PART)