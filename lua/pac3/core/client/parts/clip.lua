local PART = {}

PART.ClassName = "clip"
PART.NeedsParent = true

function PART:OnParent(parent)
	if not parent:IsValid() then
		self:OnRemove()
	elseif parent.AddClipPlane then
		self.clip_id = parent:AddClipPlane(self)
	end
end

function PART:OnUnParent()
	self:OnRemove()
end

function PART:OnRemove()
	local parent = self:GetParent()
	
	if parent:IsValid() and self.clip_id then
		parent:RemoveClipPlane(self.clip_id)
	end
end

pac.RegisterPart(PART)