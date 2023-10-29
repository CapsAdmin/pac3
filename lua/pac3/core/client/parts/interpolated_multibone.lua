local BUILDER, PART = pac.PartTemplate("base_drawable")

PART.ClassName = "interpolated_multibone"
PART.Group = 'advanced'
PART.Icon = 'icon16/table_multiple.png'
PART.is_model_part = false

PART.ManualDraw = true
PART.HandleModifiersManually = false

BUILDER:StartStorableVars()
	:SetPropertyGroup("test")
		:GetSet("Preview", false)
	:SetPropertyGroup("Interpolation")
		:GetSet("LerpValue",0)
		:GetSet("Power",1)
		:GetSet("InterpolatePosition", true)
		:GetSet("InterpolateAngles", true)
	:SetPropertyGroup("Nodes")
		:GetSetPart("Node1")
		:GetSetPart("Node2")
		:GetSetPart("Node3")
		:GetSetPart("Node4")
		:GetSetPart("Node5")
		:GetSetPart("Node6")
		:GetSetPart("Node7")
		:GetSetPart("Node8")
		:GetSetPart("Node9")
		:GetSetPart("Node10")
		:GetSetPart("Node11")
		:GetSetPart("Node12")
		:GetSetPart("Node13")
		:GetSetPart("Node14")
		:GetSetPart("Node15")
		:GetSetPart("Node16")
		:GetSetPart("Node17")
		:GetSetPart("Node18")
		:GetSetPart("Node19")
		:GetSetPart("Node20")
:EndStorableVars()

function PART:OnRemove()
	SafeRemoveEntityDelayed(self.Owner,0.1)
end

function PART:Initialize()
	self.nodes = {}
	self.Owner = pac.CreateEntity("models/pac/default.mdl")
	self.Owner:SetNoDraw(true)
	self.valid_time = CurTime() + 1
end

function PART:OnShow()
	self.valid_time = CurTime()
end

function PART:OnHide()
	hook.Remove("PostDrawOpaqueRenderables", "Multibone_draw"..self.UniqueID)

end

function PART:OnRemove()
	hook.Remove("PostDrawOpaqueRenderables", "Multibone_draw"..self.UniqueID)
end
--NODES			self	1		2		3
--STAGE			0		1		2		3
--PROPORTION	0	0.5	0	0.5	0	0.5	3
function PART:OnDraw()
	self:UpdateNodes()
	if self.valid_time > CurTime() then return end
	
	self.pos = self.pos or self:GetWorldPosition()
	self.ang = self.ang or self:GetWorldAngles()
	
	if not self.Preview then hook.Remove("PostDrawOpaqueRenderables", "Multibone_draw"..self.UniqueID) end

	local stage = math.max(0,math.floor(self.LerpValue))
	local proportion = math.max(0,self.LerpValue) % 1

	if self.Preview then
		hook.Add("PostDrawOpaqueRenderables", "Multibone_draw"..self.UniqueID, function()
			render.DrawLine(self.pos,self.pos + self.ang:Forward()*50, Color(255,0,0))
			render.DrawLine(self.pos,self.pos - self.ang:Right()*50, Color(0,255,0))
			render.DrawLine(self.pos,self.pos + self.ang:Up()*50, Color(0,0,255))
			render.DrawWireframeSphere(self.pos, 8 + 2*math.sin(5*RealTime()), 15, 15, Color(255,255,255), true)
		end)
	end
	self:Interpolate(stage,proportion)
	
end

function PART:UpdateNodes()
	for i=1,10,1 do
		self.nodes["Node"..i] = self["Node"..i]
	end
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
		firstnode = self.nodes["Node"..stage] or self
	end
	
	
	local secondnode = self.nodes["Node"..stage+1]
	if firstnode == nil or firstnode == NULL or not firstnode.GetWorldPosition then firstnode = self end
	if secondnode == nil or secondnode == NULL or not secondnode.GetWorldPosition then secondnode = self end

	proportion = math.pow(proportion,self.Power)
	if secondnode ~= nil and secondnode ~= NULL then
		self.pos = (1-proportion)*(firstnode:GetWorldPosition()) + (secondnode:GetWorldPosition())*proportion
		self.ang = GetClosestAngleMidpoint(firstnode:GetWorldAngles(), secondnode:GetWorldAngles(), proportion)
		--self.ang = (1-proportion)*(firstnode:GetWorldAngles() + Angle(360,360,360)) + (secondnode:GetWorldAngles() + Angle(360,360,360))*proportion
	elseif proportion == 0 then
		self.pos = firstnode:GetWorldPosition()
		self.ang = firstnode:GetWorldAngles()
	else
		if self.InterpolatePosition then self.pos = (1-proportion)*self:GetWorldPosition() + (self:GetWorldPosition())*proportion end
		if self.InterpolateAngles then self.ang = GetClosestAngleMidpoint(self:GetWorldAngles(), self:GetWorldAngles(), proportion) end
		--self.ang = (1-proportion)*(self:GetWorldAngles() + Angle(360,360,360)) + (self:GetWorldAngles() + Angle(360,360,360))*proportion
	end

	if not self.InterpolatePosition then
		self.pos = self:GetWorldPosition()
	end
	if not self.InterpolateAngles then
		self.ang = self:GetWorldAngles()
	end
	self.Owner:SetPos(self.pos)
	self.Owner:SetAngles(self.ang)
end

function GetClosestAngleMidpoint(a1, a2, proportion)
	--print(a1)
	--print(a2)
	local axes = {"p","y","r"}
	local ang_delta_candidate1
	local ang_delta_candidate2
	local ang_delta_candidate3
	local ang_delta_final
	local final_ang = Angle()
	for _,ax in pairs(axes) do
		ang_delta_candidate1 = a2[ax] - a1[ax]
		ang_delta_candidate2 = (a2[ax] + 360) - a1[ax]
		ang_delta_candidate3 = (a2[ax] - 360) - a1[ax]
		ang_delta_final = 180
		if math.abs(ang_delta_candidate1) < math.abs(ang_delta_final) then
			ang_delta_final = ang_delta_candidate1
		end
		if math.abs(ang_delta_candidate2) < math.abs(ang_delta_final) then
			ang_delta_final = ang_delta_candidate2
		end
		if math.abs(ang_delta_candidate3) < math.abs(ang_delta_final) then 
			ang_delta_final = ang_delta_candidate3
		end
		--print("at "..ax.." 1:"..ang_delta_candidate1.." 2:"..ang_delta_candidate2.." 3:"..ang_delta_candidate3.." pick "..ang_delta_final)
		final_ang[ax] = a1[ax] + proportion * ang_delta_final
	end

	return final_ang
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


function PART:SetInterpolatePosition(b)
	--print(type(b).." "..b)
	self.InterpolatePosition = b
end

function PART:SetInterpolateAngles(b)
	--print(type(b).." "..b)
	self.InterpolateAngles = b
end




BUILDER:Register()