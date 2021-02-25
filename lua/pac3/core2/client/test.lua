
local me = LocalPlayer()

if me:IsValid() then
	local world = pac999.scene.AddNode()
	world:SetName("world")
	world:SetPosition(Vector(-380, -2184, -895))

	if false then
		local ent = pac999.scene.AddNode(world)
		ent:SetModel("models/hunter/blocks/cube025x025x025.mdl")
		ent:SetName("test")
		ent:SetPosition(Vector(100, 1, 1))
		ent:SetCageSizeMin(Vector(100,0,0))
		ent:SetCageSizeMax(Vector(100,0,0))
		ent:SetLocalScale(Vector(1,1,1))
		ent:SetAngles(Angle(45,45,45))
		ent:EnableGizmo(true)
		if false then
		print(pos, ang)
		local ent = pac999.scene.AddNode(ent)
		ent:SetModel("models/hunter/blocks/cube025x025x025.mdl")
		local pos, ang = ent:WorldToLocal(EyePos(), EyeAngles())
		ent:SetPosition(pos)
		ent:SetAngles(ang)
		end
		--ent:SetWorldPosition(EyePos())
		--ent:SetWorldAngles(EyeAngles())
	end

	if false then
		local root = world
		local i = 1
		local n = function(x,y,z)
			local node = pac999.scene.AddNode(root)
			node:SetName(i)
			i = i + 1
			node:SetPosition(Vector(x,y,z))
			node:SetModel("models/props_c17/lampShade001a.mdl")

			return node
		end


		local m = n(80, 80+35.5*0, 10)
		m.transform:SetCageSizeMax(Vector(35.5*4,1,1))
		m.transform:SetCageSizeMin(Vector(35.5*1,1,1))
		m.transform:SetCageSizeMin(Vector(35.5*2,1,1))
		m.transform:SetCageSizeMin(Vector(35.5*4,1,1))

		local m = n(80, 80+38*1, 10)
		m.transform:SetCageSizeMax(Vector(1,1,1))
		m.transform:SetCageSizeMin(Vector(35.5*4,1,1))

		local m = n(80, 80+38*2, 10)
		m.transform:SetCageSizeMax(Vector(35.5*4,1,1))
		m.transform:SetCageSizeMin(Vector(1,1,1))

		for i = 0, 4 do
			local m = n(80 + (i*-35.5), 80+38*3, 10)
			m:SetAlpha(1)
			m:SetCageSizeMax(Vector(0,0,0))

			if i == 4 then
				m:EnableGizmo(true)
			end

			local m = n(80 + (i*35.5), 80+38*3, 10)
			m:SetCageSizeMax(Vector(0,0,0))
			m:SetAlpha(1)
			m:SetAngles(Angle(45,0,0))
			if i == 4 then
				m:SetAngles(Angle(45,45,0))
				m:EnableGizmo(true)
			end
		end

		local m = n(80, 80+38*4 + 250, 10)
		m.transform:SetCageSizeMax(Vector(1,1,1))
		m.transform:SetCageSizeMin(Vector(35.5*4,1,1))
		m.transform:SetAngles(Angle(0,45,0))
		m.gizmo:EnableGizmo(true)

		for i = 1, 1 do
--			root = n(0, 0, 60)
		end
	end

	world:SetTRScale(Vector(1,1,1))
--	world:SetScale(Vector(1,1,1)/3)

	for k,v in pairs(ents.GetAll()) do
		v.LOL = nil
	end

	for _, ent in ipairs(ents.GetAll()) do
		if IsValid(ent:CPPIGetOwner()) and ent:CPPIGetOwner():UniqueID() == "1416729906" and ent:GetModel() and not ent:GetParent():IsValid() and not ent:GetOwner():IsValid() then
			local node = pac999.scene.AddNode(root)
			node:SetModel(ent:GetModel())

			local m = ent:GetWorldTransformMatrix()
			--m:Translate(node.transform:GetCageCenter())
			node.transform:SetWorldMatrix(m)
			node:EnableGizmo(true)
			node:SetCageSizeMin(Vector(100,100,0))
		end
	end

	hook.Add("PreDrawOpaqueRenderables", "pac_999", function()
		for _, obj in ipairs(pac999.entity.GetAll()) do
			obj:FireEvent("Update")
		end

		do return end

		local tr = LocalPlayer():GetEyeTrace()

		if tr.Entity:IsValid() and tr.Entity:GetModel() and not tr.Entity:IsPlayer() and tr.Entity:CPPIGetOwner():UniqueID() == "1416729906" then
			if not tr.Entity.LOL then
				local node = pac999.scene.AddNode(root)
				node:SetModel(tr.Entity:GetModel())

				local m = tr.Entity:GetWorldTransformMatrix()
				--m:Translate(node.transform:GetCageCenter())
				node.transform:SetWorldMatrix(m)
				--node:EnableGizmo(true)
				tr.Entity.LOL = node
			end
		end

	end)
end
