local SWEP = {Primary = {}, Secondary = {}}


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

function SWEP:DrawWeaponSelection(x,y,w,t,a)

    draw.SimpleText("C","creditslogo",x+w/2,y,Color(255, 220, 0,a),TEXT_ALIGN_CENTER)

end

function SWEP:DrawWorldModel() 						 end
function SWEP:DrawWorldModelTranslucent() 			 end
function SWEP:CanPrimaryAttack()		return false end
function SWEP:CanSecondaryAttack()		return false end
function SWEP:Reload()					return false end
function SWEP:Holster()					return true  end
function SWEP:ShouldDropOnDie()			return false end

function SWEP:Initialize()
    if self.SetHoldType then
		self:SetHoldType"normal"
	else
		self:SetWeaponHoldType( "normal" )
	end

	self:DrawShadow(false)
end

function SWEP:Deploy()
	self.Thinking = true
	return true
end

function SWEP:Think()

	if self.Thinking and self.Owner and self.Owner:IsValid() and self.Owner:GetViewModel():IsValid() then
		self.Thinking = false

		assert(self:GetClass()=="none","WTF WRONG SHIT: "..tostring(self:GetClass()))

	end
end

local gtfo=Vector(1,1,1)*65000
function SWEP:GetViewModelPosition( pos, ang )
	return gtfo,ang
end

function SWEP:PreDrawViewModel( )
	return true
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
