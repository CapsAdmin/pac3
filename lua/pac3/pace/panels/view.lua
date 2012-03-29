local PANEL = {}

PANEL.ClassName = "view"
PANEL.Base = "DPanel"

PANEL.Entity = NULL
PANEL.ents = {}


function PANEL:Init()
	self.fov = 75
	self.ang = Angle(0, 0, 0)
	self.pos = Vector(5, 5, 5)

	self.Outfit = pac.Null

	pace.view = self
end

function PANEL:SetViewOutfit(outfit)
	self.Outfit = outfit
	self.pos = outfit:GetOwner():EyePos()
end

function PANEL:OnMouseWheeled(delta)
	delta = delta * 5
	self.fov = math.Clamp(self.fov - delta, 1, 75)
end

function PANEL:OnMousePressed(mc)
	if pace.mctrl.GUIMousePressed(mc) then return end

	if mc == MOUSE_LEFT then
		self.held_ang = self.ang*1
		self.held_mpos = Vector(self:ScreenToLocal(gui.MousePos()))
	end

	if mc == MOUSE_RIGHT then
		pace.Call("OpenMenu")
	end

	self.mcode = mc
end

function PANEL:OnMouseReleased(mc)
	if pace.mctrl.GUIMouseReleased(mc) then return end
	self.mcode = nil
end

function PANEL:CalcDrag()
	local mult = 0.5
	if input.IsKeyDown(KEY_LCONTROL) then
		mult = 0.1
	end

	if input.IsKeyDown(KEY_LSHIFT) then
		mult = 1
	end

	if self.mcode == MOUSE_LEFT then
		local delta = (self.held_mpos - Vector(self:ScreenToLocal(gui.MousePos())))
		self.ang.p = math.Clamp(self.held_ang.p - delta.y, -90, 90)
		self.ang.y = self.held_ang.y + delta.x
	end

	if input.IsKeyDown(KEY_W) then
		self.pos = self.pos + self.ang:Forward() * mult
	elseif input.IsKeyDown(KEY_S) then
		self.pos = self.pos - self.ang:Forward() * mult
	end

	if input.IsKeyDown(KEY_D) then
		self.pos = self.pos + self.ang:Right() * mult
	elseif input.IsKeyDown(KEY_A) then
		self.pos = self.pos - self.ang:Right() * mult
	end

	if input.IsKeyDown(KEY_SPACE) then
		self.pos = self.pos + self.ang:Up() * mult
	end
end

function PANEL:CalcAnimationFix(ent)
	ent:SetEyeAngles(Angle(0,0,0))
	ent:SetupBones()
end

AccessorFunc(PANEL, "lighting", "Lighting")

function PANEL:Paint()
	if self.mcode and not input.IsMouseDown(self.mcode) then
		self.mcode = nil
	end

	local outfit = self.Outfit

	if outfit:IsValid() then
		local ent = outfit:GetOwner()

		self:CalcDrag()

		surface.SetDrawColor(20, 20, 20, 255)
		surface.DrawRect(0, 0, self:GetWide(), self:GetTall())

		local x, y = self:LocalToScreen(0, 0)

		cam.Start3D(self.pos, self.ang, self.fov, x, y, self:GetSize())
			render.SuppressEngineLighting(true)

			if self.lighting then
				render.SetLightingOrigin(self.pos)
				render.ResetModelLighting(0,0,0)
				local t = CurTime()
				local s = math.sin
				render.SetModelLighting(BOX_FRONT, s(t+10123), s(t+100), s(t+100))
				render.SetModelLighting(BOX_BOTTOM, s(t+623), s(t+1235), s(t+123123))
				render.SetModelLighting(BOX_TOP, s(t+123), s(t+125), s(t+834))
				render.SetModelLighting(BOX_BACK, s(t+60), s(t+437), s(t+324))
				render.SetModelLighting(BOX_LEFT, s(t+50), s(t+123), s(t+50234600))
				render.SetModelLighting(BOX_RIGHT, s(t+31), s(t+6234), s(t+2323))
			end

			self:CalcAnimationFix(ent)
			ent:DrawModel()
			if ent.GetActiveWeapon then
				local wep = ent:GetActiveWeapon()
				if wep:IsValid() then
					wep:DrawModel()
				end
			end

			render.SuppressEngineLighting(false)
		cam.End3D()

		pace.Call("Draw", self:GetSize())

	end
end

pace.RegisterPanel(PANEL)
