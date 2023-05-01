local render_OverrideAlphaWriteEnable = render.OverrideAlphaWriteEnable
local render_OverrideColorWriteEnable = render.OverrideColorWriteEnable
local render_OverrideBlendFunc = render.OverrideBlendFunc
local ProtectedCall = ProtectedCall
local cam_IgnoreZ = cam.IgnoreZ
local pac = pac
local ipairs = ipairs
local table = table
local TEXFILTER_POINT = TEXFILTER.POINT
local render_PopFilterMag = render.PopFilterMag
local render_PopFilterMin = render.PopFilterMin
local render_PushFilterMin = render.PushFilterMin
local render_PushFilterMag = render.PushFilterMag

local BUILDER, PART = pac.PartTemplate("base_movable")

PART.ClassName = "base_drawable"
PART.BaseName = PART.ClassName

BUILDER
	:StartStorableVars()
		:SetPropertyGroup("appearance")
			:GetSet("Translucent", false)
			:GetSet("IgnoreZ", false)
			:GetSet("NoTextureFiltering", false)
			:GetSet("BlendMode", "", {enums = {
				none = "one;zero;one;zero",
				alpha = "src_alpha;one_minus_src_alpha;one;one_minus_src_alpha",
				multiplicative = "dst_color;zero;dst_color;zero",
				premultiplied = "one;one_src_minus_alpha;one;one_src_minus_alpha",
				additive = "src_alpha;one;src_alpha;one",
			}})
	:EndStorableVars()

do
	local blend_modes = {
		zero = 0,
		one = 1,
		dst_color = 2,
		one_minus_dst_color = 3,
		src_alpha = 4,
		one_minus_src_alpha = 5,
		dst_alpha = 6,
		one_minus_dst_alpha = 7,
		src_alpha_saturate = 8,
		src_color = 9,
		one_minus_src_color = 10,
	}

	function PART:SetBlendMode(str)
		str = str:lower():gsub("%s+", ""):gsub(",", ";"):gsub("blend_", "")

		self.BlendMode = str

		local tbl = str:Split(";")
		local src_color
		local dst_color

		local src_alpha
		local dst_alpha

		if tbl[1] then src_color = blend_modes[tbl[1]] end
		if tbl[2] then dst_color = blend_modes[tbl[2]] end

		if tbl[3] then src_alpha = blend_modes[tbl[3]] end
		if tbl[4] then dst_alpha = blend_modes[tbl[4]] end

		if src_color and dst_color then
			self.blend_override = {src_color, dst_color, src_alpha or 0, dst_alpha or 0, tbl[5]}
		else
			self.blend_override = nil
		end
	end

	function PART:StartBlend()
		if self.blend_override then
			render_OverrideBlendFunc(true,
				self.blend_override[1],
				self.blend_override[2],
				self.blend_override[3],
				self.blend_override[4]
			)

			if self.blend_override[5] then
				render_OverrideAlphaWriteEnable(true, self.blend_override[5] == "write_alpha")
			end

			if self.blend_override[6] then
				render_OverrideColorWriteEnable(true, self.blend_override[6] == "write_color")
			end
		end
	end

	function PART:StopBlend()
		if self.blend_override then
			render_OverrideBlendFunc(false)

			if self.blend_override[5] then
				render_OverrideAlphaWriteEnable(false)
			end

			if self.blend_override[6] then
				render_OverrideColorWriteEnable(false)
			end
		end
	end
end

do -- modifiers
	PART.HandleModifiersManually = false

	function PART:AddModifier(part)
		self:RemoveModifier(part)
		table.insert(self.modifiers, part)
	end

	function PART:RemoveModifier(part)
		for i, v in ipairs(self.modifiers) do
			if v == part then
				table.remove(self.modifiers, i)
				break
			end
		end
	end

	function PART:ModifiersPreEvent(event)
		if not self.modifiers[1] then return end

		for _, part in ipairs(self.modifiers) do
			if not part:IsHidden() then

				if not part.pre_draw_events then part.pre_draw_events = {} end
				if not part.pre_draw_events[event] then part.pre_draw_events[event] = "Pre" .. event end

				if part[part.pre_draw_events[event]] then
					part[part.pre_draw_events[event]](part)
				end
			end
		end
	end

	function PART:ModifiersPostEvent(event)
		if not self.modifiers[1] then return end

		for _, part in ipairs(self.modifiers) do
			if not part:IsHidden() then

				if not part.post_draw_events then part.post_draw_events = {} end
				if not part.post_draw_events[event] then part.post_draw_events[event] = "Post" .. event end

				if part[part.post_draw_events[event]] then
					part[part.post_draw_events[event]](part)
				end
			end
		end
	end

end

function PART:IsDrawHidden()
	return self.draw_hidden
end

local _self

local function call_draw()
	_self:OnDraw()
end

function PART:Draw(draw_type)
	if not self.OnDraw or not self.Enabled or self:IsHiddenCached() then return end

	if
		draw_type == "viewmodel" or draw_type == "hands" or
		((self.Translucent == true or self.force_translucent == true) and draw_type == "translucent")  or
		((self.Translucent == false or self.force_translucent == false) and draw_type == "opaque")
	then
		if not self.HandleModifiersManually then self:ModifiersPreEvent('OnDraw', draw_type) end

		if self.IgnoreZ then cam_IgnoreZ(true) end

		self:StartBlend()

		if self.NoTextureFiltering then
			render_PushFilterMin(TEXFILTER_POINT)
			render_PushFilterMag(TEXFILTER_POINT)
		end

		_self = self

		ProtectedCall(call_draw)

		if self.NoTextureFiltering then
			render_PopFilterMin()
			render_PopFilterMag()
		end

		self:StopBlend()

		if self.IgnoreZ then cam_IgnoreZ(false) end

		if not self.HandleModifiersManually then self:ModifiersPostEvent('OnDraw', draw_type) end
	end
end

BUILDER:Register()
