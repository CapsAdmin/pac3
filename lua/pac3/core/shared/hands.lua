local SWEP = {Primary = {}, Secondary = {}}

SWEP.Base = "weapon_base"

SWEP.Author     	= ""
SWEP.Contact      	= ""
SWEP.Purpose      	= ""
SWEP.Instructions   = "Right-Click to toggle crosshair"
SWEP.PrintName      = "hands"   
SWEP.DrawAmmo       = false
SWEP.DrawCrosshair	= true
SWEP.DrawWeaponInfoBox = false

SWEP.SlotPos      	= 1
SWEP.Slot         	= 1

SWEP.Spawnable    	= true
SWEP.AdminSpawnable	= false

SWEP.AutoSwitchTo	= true
SWEP.AutoSwitchFrom	= true
SWEP.Weight 		= 1

SWEP.HoldType = "normal"

SWEP.Primary.ClipSize      = -1
SWEP.Primary.DefaultClip   = -1
SWEP.Primary.Automatic     = false
SWEP.Primary.Ammo          = "none"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"


function SWEP:DrawHUD() 			end
function SWEP:PrintWeaponInfo() 	end

if CLIENT then
	surface.CreateFont("pac_hands_font", {font = "HalfLife2", size = 120, weight = 400, antialias = true, additive = true})

	function SWEP:DrawWeaponSelection(x,y,w,t,a)
		draw.SimpleText("C","pac_hands_font",x+w/2,y,Color(255, 220, 0,a),TEXT_ALIGN_CENTER)
	end
end

function SWEP:DrawWorldModel() 						 end
function SWEP:DrawWorldModelTranslucent() 			 end
function SWEP:CanPrimaryAttack()		return false end
function SWEP:CanSecondaryAttack()		return false end
function SWEP:Reload()					return false end
function SWEP:Holster()					return true  end
function SWEP:ShouldDropOnDie()			return false end

function SWEP:Initialize()
    self:SetWeaponHoldType( "normal" )
end

function SWEP:Deploy()
	self.Thinking = true
	return true
end

function SWEP:Think()

	if self.Thinking and self.Owner and self.Owner:IsValid() and self.Owner:GetViewModel():IsValid() then
		self.Thinking = false
		
		assert(self:GetClass()=="none","WTF WRONG SHIT: "..tostring(self:GetClass()))

		self.Owner:GetViewModel():SetNoDraw(true)
	
	end
end

function SWEP:GetViewModelPosition( pos, ang )
	if isthatyou then
		return pos,ang
	end
	assert(self:GetClass()=="none","WTF WRONG SHIT: "..tostring(self:GetClass()))

	pos.x=-3575
	pos.y=-3575
	pos.z=-3575 -- I don't want to see you ever again
	return pos,ang

end


function SWEP:OnDrop()   
    if SERVER then
		self:Remove()
	end
end

function SWEP:SecondaryAttack()
	if not IsFirstTimePredicted() then return end 
	self.DrawCrosshair = not self.DrawCrosshair 
	self:SetNextSecondaryFire(CurTime() + 0.3) 
end

weapons.Register(SWEP, "none", true)
