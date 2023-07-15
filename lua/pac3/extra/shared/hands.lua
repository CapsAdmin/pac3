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
SWEP.ViewModel = "models/effects/vol_light.mdl" --Invisible ViewModel

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
