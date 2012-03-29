local PART = {}

PART.ClassName = "clip"

function PART:OnParent(parent)
	if not parent:IsValid() then
		self:OnRemove()
	elseif parent.ClassName == "model" then
		self.clip_id = parent:AddClipPlane(self)
	end
end

function PART:OnRemove()
	local parent = self.RealParent or pac.Null
	if parent:IsValid() and self.clip_id then
		parent:RemoveClipPlane(self.clip_id)
	end
end

pac.RegisterPart(PART)