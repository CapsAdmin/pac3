local SWEP = {Primary = {}, Secondary = {}}

SWEP.Author = "CapsAdmin"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.PrintName = "hands"   
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/v_hands.mdl"
SWEP.WorldModel = "models/weapons/w_bugbait.mdl"
SWEP.DrawWeaponInfoBox = true

SWEP.SlotPos = 1
SWEP.Slot = 1

SWEP.Spawnable = true
SWEP.AdminSpawnable	= true

SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom	= true
SWEP.Weight = 1

SWEP.HoldType = "normal"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:OnDrop()   
    if SERVER then
		self:Remove()
	end
end

function SWEP:GetViewModelPosition(pos, ang)
	-- die
	pos.z = 35575
	return pos, ang
end

function SWEP:TranslateActivity(act)
	return act
end

function SWEP:Deploy()
   self.Think = self._Think
   return true
end

function SWEP:_Think()
	if self.Owner:IsValid() and self.Owner:GetViewModel():IsValid() then
		self.Owner:GetViewModel():SetNoDraw(true)
		self.Think = nil
	end
end

function SWEP:Initialize() end
function SWEP:DrawHUD() end
function SWEP:PrintWeaponInfo() end
function SWEP:DrawWeaponSelection(x,y,w,t,a) end
function SWEP:DrawWorldModel() return true end
function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:Reload() return false end
function SWEP:Holster() return true end
function SWEP:ShouldDropOnDie() return false end

weapons.Register(SWEP, "hands", true)
