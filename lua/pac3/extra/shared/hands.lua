local SWEP = { Primary = {}, Secondary = {} }

local baseClass = baseclass.Get( "weapon_base" )

SWEP.Author     	= ""
SWEP.Contact      	= ""
SWEP.Purpose      	= ""
SWEP.Instructions   = "Right-Click to toggle crosshair"
SWEP.PrintName      = "Hands"
SWEP.DrawAmmo       = false
SWEP.DrawCrosshair	= true
SWEP.DrawWeaponInfoBox = true

SWEP.SlotPos      	= 1
SWEP.Slot         	= 1

SWEP.Spawnable    	= true
SWEP.AdminSpawnable	= false

SWEP.AutoSwitchTo	= true
SWEP.AutoSwitchFrom	= true
SWEP.Weight 		= 1

SWEP.HoldType = "normal"
SWEP.ViewModel = "models/weapons/c_arms.mdl"

SWEP.Primary.ClipSize      = -1
SWEP.Primary.DefaultClip   = -1
SWEP.Primary.Automatic     = false
SWEP.Primary.Ammo          = "none"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"


function SWEP:DrawHUD() end
function SWEP:DrawWorldModel() end
function SWEP:DrawWorldModelTranslucent() end
function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:Reload() return false end
function SWEP:Holster() return true  end
function SWEP:ShouldDropOnDie() return false end

local weaponSelectionColor = Color( 255, 220, 0, 255 )
function SWEP:DrawWeaponSelection( x, y, w, t, a )
    weaponSelectionColor.a = a
    draw.SimpleText( "C", "creditslogo", x + w / 2, y, weaponSelectionColor, TEXT_ALIGN_CENTER )

    baseClass.PrintWeaponInfo( self, x + w + 20, y + t * 0.95, alpha )
end

function SWEP:Initialize()
    if self.SetHoldType then
        self:SetHoldType( "normal" )
    else
        self:SetWeaponHoldType( "normal" )
    end

    self:DrawShadow( false )
    self:SetSequence( "ragdoll" ) -- paired with SWEP.ViewModel = "models/weapons/c_arms.mdl" to make the arms invisible
end

function SWEP:OnDrop()
    if SERVER then
        self:Remove()
    end
end

function SWEP:SecondaryAttack()
    if not IsFirstTimePredicted() then return end
    self.DrawCrosshair = not self.DrawCrosshair
    self:SetNextSecondaryFire( CurTime() + 0.3 )
end

weapons.Register( SWEP, "none", true )
