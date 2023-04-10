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

local BUILDER, PART = pac.PartTemplate("base_movable")

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
	
	self.pos = Vector()
	self.vel = Vector()

	self.ang = Angle()
	self.angvel = Angle()
	--[[]
	self:SetLerpValue(self.LerpValue or 0)
	self:SetInterpolatePosition(self.InterpolatePosition or true)
	self:SetInterpolateAngles(self.InterpolateAngles or true)]]
end

function PART:OnDraw()
	self:GetWorldPosition()
	self:GetWorldAngles()
	--self:ModifiersPreEvent("OnDraw")
	--self:ModifiersPostEvent("OnDraw")
end

function PART:OnThink()
	self:OnDraw()

	if self.Force000 then
		print("forcing 0 0 0 world position")
		self:SetWorldPos(0,0,0)
	end
	--self:GetWorldPosition()
	--self:GetWorldAngles()
	--self:GetDrawPosition()
	--print(self.pos.x, self.pos.y, self.pos.z)
	--print(self:GetDrawPosition().x, self:GetDrawPosition().y, self:GetDrawPosition().z)
end

function PART:SetWorldPos(x,y,z)
	self.pos.x = x
	self.pos.y = y
	self.pos.z = z
end

function PART:Interpolate(stage, proportion)
end

--we need to know the stage and proportion (progress)
--e.g. lerp 0.5 is stage 0, proportion 0.5 because it's 50% toward Node 1
--e.g. lerp 2.2 is stage 2, proportion 0.2 because it's 20% toward Node 3
function PART:GetInterpolationParameters()
	--[[stage = math.max(0,math.floor(self.LerpValue))
	proportion = math.max(0,self.LerpValue) % 1
	print("Calculated the stage. We are at stage " .. stage .. " between nodes " .. stage .. " and " .. (stage + 1))
	print("proportion is " .. proportion)
	return stage, proportion]]--
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

function PART:SetLerpValue(var)
	--[[print("adjusted lerp value. "..type(var).." "..var)
	self.LerpValue = var
	assert(self.LerpValue == var)
	assert(self.LerpValue ~= nil)
	self:Interpolate(self:GetInterpolationParameters())]]--
end

function PART:SetInterpolatePosition(b)
	--print(type(b).." "..b)
	self.InterpolatePosition = b
end

function PART:SetInterpolateAngles(b)
	--print(type(b).." "..b)
	self.InterpolateAngles = b
end




BUILDER:Register()