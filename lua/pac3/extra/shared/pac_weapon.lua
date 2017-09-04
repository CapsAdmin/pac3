do return end
local SWEP = {Primary = {}, Secondary = {}}

SWEP.Author = "CapsAdmin"
SWEP.Contact = ""
SWEP.Purpose = ""
SWEP.Instructions = ""
SWEP.PrintName = "pac weapon"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.DrawWeaponInfoBox = true
SWEP.Base = "weapon_base"

SWEP.SlotPos = 1
SWEP.Slot = 1

SWEP.Spawnable = true
SWEP.AdminSpawnable	= true

SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom	= true
SWEP.Weight = 1

SWEP.HoldType = "normal"

SWEP.Primary.ClipSize = 10
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

SWEP.Secondary.ClipSize = 10
SWEP.Secondary.DefaultClip = 10
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "pistol"

function SWEP:OnDrop()
end

function SWEP:GetViewModelPosition(pos, ang)
	return pos, ang
end

function SWEP:TranslateActivity(act)
	return act
end

function SWEP:Deploy()
   return true
end

function SWEP:Initialize() end
function SWEP:DrawHUD() end
function SWEP:PrintWeaponInfo() end
function SWEP:DrawWeaponSelection(x,y,w,t,a) end
function SWEP:DrawWorldModel() return true end
function SWEP:CanPrimaryAttack() return true end
function SWEP:CanSecondaryAttack() return true end
function SWEP:Reload() return false end
function SWEP:Holster() return true end
function SWEP:ShouldDropOnDie() return false end

weapons.Register(SWEP, "pac_weapon", true)

if CLIENT then
	local PART = {}

	PART.ClassName = "weapon"
	PART.NonPhysical = true

	pac.StartStorableVars()
		for key, val in pairs(SWEP) do
			if type(val) ~= "table" and type(val) ~= "function" then
				pac.GetSet(PART, key, val)
			end
		end

		for key, val in pairs(SWEP.Primary) do
			pac.GetSet(PART, "Primary"..key, val)
		end

		for key, val in pairs(SWEP.Secondary) do
			pac.GetSet(PART, "Secondary"..key, val)
		end
	pac.EndStorableVars()

	pac.RegisterPart(PART)
end