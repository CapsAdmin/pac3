nodes = {}

local cam_PushModelMatrix = cam.PushModelMatrix
local cam_PopModelMatrix = cam.PopModelMatrix
local Vector = Vector
local Angle = Angle
local EF_BONEMERGE = EF_BONEMERGE
local NULL = NULL
local Color = Color
local Matrix = Matrix
local vector_origin = vector_origin

local pos
local ang

local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "interpolated_multibone"
PART.Group = 'advanced'
PART.Icon = 'icon16/table_multiple.png'
PART.is_model_part = false

PART.ManualDraw = true
PART.HandleModifiersManually = true

BUILDER:StartStorableVars()
	:SetPropertyGroup("test")
		:GetSet("Test1", false)
		:GetSet("Test2", false)
		:GetSet("Force000", false)
	:SetPropertyGroup("Interpolation")
		:GetSet("LerpValue",0)
		:GetSet("InterpolatePosition", true)
		:GetSet("InterpolateAngles", true)
	:SetPropertyGroup("Nodes")
		:GetSetPart("Node1")
		:GetSetPart("Node2")
		:GetSetPart("Node3")
		:GetSetPart("Node4")
		:GetSetPart("Node5")
:EndStorableVars()

--PART:GetWorldPosition()
--PART:GetWorldAngles()
function PART:Initialize()
	print("a multiboner is born")
end

function PART:OnShow()

end
--NODES			self	1		2		3
--STAGE			0		1		2		3
--PROPORTION	0	0.5	0	0.5	0	0.5	3
function PART:OnDraw()
	local ent = self:GetOwner()
	self.pos,self.ang = self:GetDrawPosition()
	if not self.Test1 then hook.Remove("PostDrawOpaqueRenderables", "Multibone_draw") end

	local stage = math.max(0,math.floor(self.LerpValue))
	local proportion = math.max(0,self.LerpValue) % 1

	if self.Test1 then
		hook.Add("PostDrawOpaqueRenderables", "Multibone_draw", function()
			render.DrawLine(self.pos,self.pos + self.ang:Forward()*150, Color(255,0,0))
			render.DrawLine(self.pos,self.pos - self.ang:Right()*150, Color(0,255,0))
			render.DrawLine(self.pos,self.pos + self.ang:Up()*150, Color(0,0,255))
			render.DrawWireframeSphere(self.pos, 20 + 5*math.sin(5*RealTime()), 15, 15, Color(255,255,255), true)
		end)
	end
	self:Interpolate(stage,proportion)

	--[[self:PreEntityDraw(ent, pos, ang)
	self:DrawModel(ent, pos, ang)
	self:PostEntityDraw(ent, pos, ang)]]
	ent:SetPos(self.pos)
	ent:SetAngles(self.ang)
	pac.ResetBones(ent)
	--ent:DrawModel()
end

function PART:OnThink()
	if self.Node1 ~= nil then nodes["Node1"] = self.Node1 end
	if self.Node2 ~= nil then nodes["Node2"] = self.Node2 end
	if self.Node3 ~= nil then nodes["Node3"] = self.Node3 end
	if self.Node4 ~= nil then nodes["Node4"] = self.Node4 end
	if self.Node5 ~= nil then nodes["Node5"] = self.Node5 end
end

function PART:SetWorldPos(x,y,z)
	self.pos.x = x
	self.pos.y = y
	self.pos.z = z
end

function PART:Interpolate(stage, proportion)
	--print("Calculated the stage. We are at stage " .. stage .. " between nodes " .. stage .. " and " .. (stage + 1))
	local firstnode
	if stage <= 0 then
		firstnode = self
	else
		firstnode = nodes["Node"..stage] or self
	end
	
	
	local secondnode = nodes["Node"..stage+1]
	if firstnode == nil or firstnode == NULL then firstnode = self end
	if secondnode == nil or secondnode == NULL then secondnode = self end

	if secondnode ~= nil and secondnode ~= NULL then
		self.pos = (1-proportion)*firstnode:GetWorldPosition() + (secondnode:GetWorldPosition())*proportion
		self.ang = (1-proportion)*firstnode:GetWorldAngles() + (secondnode:GetWorldAngles())*proportion
	elseif proportion == 0 then
		self.pos = firstnode:GetWorldPosition()
		self.ang = firstnode:GetWorldAngles()
	else
		self.pos = (1-proportion)*self:GetWorldPosition() + (self:GetWorldPosition())*proportion
		self.ang = (1-proportion)*self:GetWorldPosition() + (self:GetWorldPosition())*proportion
	end

end

function PART:GoTo(part)
	self.pos = part:GetWorldPosition() or self:GetWorldPosition()
	self.ang = part:GetWorldAngles() or self:GetWorldAngles()
end

--we need to know the stage and proportion (progress)
--e.g. lerp 0.5 is stage 0, proportion 0.5 because it's 50% toward Node 1
--e.g. lerp 2.2 is stage 2, proportion 0.2 because it's 20% toward Node 3
function PART:GetInterpolationParameters()
	stage = math.max(0,math.floor(self.LerpValue))
	proportion = math.max(0,self.LerpValue) % 1
	--print("Calculated the stage. We are at stage " .. stage .. " between nodes " .. stage .. " and " .. (stage + 1))
	--print("proportion is " .. proportion)
	return stage, proportion
end

function PART:GetNodeAngle(nodenumber)
	--print("node" .. nodenumber .. " angle " .. self.__['Node'..nodenumber].Angles)
	--print("node" .. nodenumber .. " world angle " .. self.__['Node'..nodenumber]:GetWorldAngles())

	--return self.Node1:GetWorldAngles()
end

function PART:GetNodePosition(nodenumber)
	--print("node" .. nodenumber .. " position " .. self.__['Node'..nodenumber].Position)
	--print("node" .. nodenumber .. " world position " .. self.__['Node'..nodenumber]:GetWorldPosition())
	--return self.Node1:GetWorldPosition()
end

function PART:InterpolateFromLerp(lerp)
end

function PART:InterpolateFromNodes(firstnode, secondnode, proportion)
	--position_interpolated = InterpolateFromStage("position", stage, self.Lerp)
end

function PART:InterpolateFromStage(stage, proportion)
	self:InterpolateFromNodes(stage, stage + 1)
end

function PART:InterpolateAngle()

end

--[[function PART:ApplyMatrix()
	print("MATRIX???")
	local ent = self:GetOwner()
	if not ent:IsValid() then return end

	local mat = Matrix()

	if self.ClassName ~= "model2" then
		mat:Translate(self.Position + self.PositionOffset)
		mat:Rotate(self.Angles + self.AngleOffset)
	end

	if mat:IsIdentity() then
		ent:DisableMatrix("RenderMultiply")
	else
		ent:EnableMatrix("RenderMultiply", mat)
	end
end--]]

--[[function PART:SetLerpValue(var)
	print("adjusted lerp value. "..type(var).." "..var)
	self.LerpValue = var
	assert(self.LerpValue == var)
	assert(self.LerpValue ~= nil)
	self:Interpolate(self:GetInterpolationParameters())
end]]

function PART:SetInterpolatePosition(b)
	--print(type(b).." "..b)
	self.InterpolatePosition = b
end

function PART:SetInterpolateAngles(b)
	--print(type(b).." "..b)
	self.InterpolateAngles = b
end




BUILDER:Register()