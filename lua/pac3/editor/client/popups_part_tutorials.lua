--[[
	This is the framework for popups. This should be expandable for various use cases.
	It uses DFrame as a base, overrides the Paint function for a basic fade effect.

	Tutorials will be written here
]]


CreateConVar("pac_popups_enable", 1, FCVAR_ARCHIVE, "Enables PAC editor popups. They provide some information but can be annoying")
CreateConVar("pac_popups_preserve_on_autofade", 1, FCVAR_ARCHIVE, "If set to 0, PAC editor popups appear only once and don't reappear when hovering over the part label or pressing F1")
CreateConVar("pac_popups_base_color", "215 230 255", FCVAR_ARCHIVE, "The color of the base filler rectangle for editor popups")
CreateConVar("pac_popups_base_color_pulse", "0", FCVAR_ARCHIVE, "Amount of pulse of the base filler rectangle for editor popups")

CreateConVar("pac_popups_base_alpha", "0.5", FCVAR_ARCHIVE, "The alpha opacity of the base filler rectangle for editor popups")
CreateConVar("pac_popups_fade_color", "100 220 255", FCVAR_ARCHIVE, "The color of the fading effect for editor popups")
CreateConVar("pac_popups_fade_alpha", "1", FCVAR_ARCHIVE, "The alpha opacity of the fading effect for editor popups")
CreateConVar("pac_popups_text_color", "100 220 255", FCVAR_ARCHIVE, "The color of the fading effect for editor popups")
CreateConVar("pac_popups_verbosity", "beginner tutorial", FCVAR_ARCHIVE, "Sets the amount of information added to PAC editor popups. While in development, there will be limited contextual support. If no special information is defined, it will indicate the part size information. Here are the planned modes: \nbeginner tutorial : Basic tutorials about pac parts, for beginners or casual users looking for a quick reference for what a part does\nReference tutorial : doesn't give part tutorials, but still keeps events' tutorial explanations.\n")
CreateConVar("pac_popups_preferred_location", "pac tree label", FCVAR_ARCHIVE, "Sets the preferred method of PAC editor popups.\n"..
	"pac tree label : the part label on the pac tree\n"..
	"part world : if part is base_movable, place it next to the part in the viewport\n"..
	"screen : static x,y on screen no matter what. That would be at the center\n"..
	"cursor : right on the cursor\n"..
	"menu bar : next to the toolbar")


function pace.OpenPopupConfig()
	local master_pnl = vgui.Create("DFrame")
	master_pnl:SetTitle("Configure PAC3 popups appearance")
	master_pnl:SetSize(400,800)
	master_pnl:Center()

	local list_pnl = vgui.Create("DListLayout", master_pnl)
	list_pnl:Dock(FILL)

	local basecolor = vgui.Create("DColorMixer")
	basecolor:SetSize(400,150)
	local col_args = string.Split(GetConVar("pac_popups_base_color"):GetString(), " ")
	basecolor:SetColor(Color(col_args[1] or 255, col_args[2] or 255, col_args[3] or 255))
	function basecolor:ValueChanged(col)
		GetConVar("pac_popups_base_color"):SetString(col.r .. " " .. col.g .. " " .. col.b)
		GetConVar("pac_popups_base_alpha"):SetString(col.a)
	end
	local basecolor_pulse = vgui.Create("DNumSlider")
	basecolor_pulse:SetMax(255)
	basecolor_pulse:SetMin(0)

	if isnumber(GetConVar("pac_popups_base_color_pulse"):GetInt()) then
		basecolor_pulse:SetValue(GetConVar("pac_popups_base_color_pulse"):GetInt())
	else
		basecolor_pulse:SetValue(0)
	end

	basecolor_pulse:SetText("base pulse")
	function basecolor_pulse:OnValueChanged(val)
		val = math.Round(tonumber(val),0)
		GetConVar("pac_popups_base_color_pulse"):SetInt(val)
	end

	local fadecolor = vgui.Create("DColorMixer")
	fadecolor:SetSize(400,150)
	col_args = string.Split(GetConVar("pac_popups_fade_color"):GetString(), " ")
	fadecolor:SetColor(Color(col_args[1] or 255, col_args[2] or 255, col_args[3] or 255))
	function fadecolor:ValueChanged(col)
		GetConVar("pac_popups_fade_color"):SetString(col.r .. " " .. col.g .. " " .. col.b)
		GetConVar("pac_popups_fade_alpha"):SetString(col.a)
	end

	local textcolor = vgui.Create("DColorMixer")
	textcolor:SetSize(400,150)
	col_args = string.Split(GetConVar("pac_popups_text_color"):GetString(), " ")

	if isnumber(col_args[1]) then
		textcolor:SetColor(Color(col_args[1] or 255, col_args[2] or 255, col_args[3] or 255))
	end

	textcolor:SetAlphaBar(false)
	function textcolor:ValueChanged(col)
		GetConVar("pac_popups_text_color"):SetString(col.r .. " " .. col.g .. " " .. col.b)
	end

	local invertcolor_btn = vgui.Create("DButton")
	invertcolor_btn:SetSize(400,30)
	invertcolor_btn:SetText("Use text invert color (experimental)")
	function invertcolor_btn:DoClick()
		GetConVar("pac_popups_text_color"):SetString("invert")
	end

	local preview_pnl = vgui.Create("DLabel")
	preview_pnl:SetSize(400,170)
	preview_pnl:SetText("")
	local label_text = "Popup preview! The text will look like this."

	local rgb1 = string.Split(GetConVar("pac_popups_base_color"):GetString(), " ")
	local r1,g1,b1 = tonumber(rgb1[1]) or 255, tonumber(rgb1[2]) or 255, tonumber(rgb1[3]) or 255
	local a1 = GetConVar("pac_popups_base_alpha"):GetFloat()
	local pulse = GetConVar("pac_popups_base_color_pulse"):GetInt()
	local rgb2 = string.Split(GetConVar("pac_popups_fade_color"):GetString(), " ")
	local r2,g2,b2 = tonumber(rgb2[1]) or 255, tonumber(rgb2[2]) or 255, tonumber(rgb2[3]) or 255
	local a2 = GetConVar("pac_popups_fade_alpha"):GetFloat()
	local rgb3 = string.Split(GetConVar("pac_popups_text_color"):GetString(), " ")
	if rgb3[1] == "invert" then rgb3 = {nil,nil,nil} end
	local r3,g3,b3 = tonumber(rgb3[1]) or (255 - (a1*r1/255 + a2*r2/255)/2), tonumber(rgb3[2]) or (255 - (a1*g1/255 + a2*g2/255)/2), tonumber(rgb3[3]) or (255 - (a1*b1/255 + a2*b2/255)/2)

	local preview_refresh_btn = vgui.Create("DButton")
	preview_refresh_btn:SetSize(400,30)
	preview_refresh_btn:SetText("Refresh")
	local oldpaintfunc = master_pnl.Paint
	local invis_frame = false
	function preview_refresh_btn:DoClick()
		invis_frame = not invis_frame
		if invis_frame then master_pnl.Paint = nil else master_pnl.Paint = oldpaintfunc end
		rgb1 = string.Split(GetConVar("pac_popups_base_color"):GetString(), " ")
		r1,g1,b1 = tonumber(rgb1[1]) or 255, tonumber(rgb1[2]) or 255, tonumber(rgb1[3]) or 255
		a1 = GetConVar("pac_popups_base_alpha"):GetFloat()
		pulse = GetConVar("pac_popups_base_color_pulse"):GetInt()
		rgb2 = string.Split(GetConVar("pac_popups_fade_color"):GetString(), " ")
		r2,g2,b2 = tonumber(rgb2[1]) or 255, tonumber(rgb2[2]) or 255, tonumber(rgb2[3]) or 255
		a2 = GetConVar("pac_popups_fade_alpha"):GetFloat()
		rgb3 = string.Split(GetConVar("pac_popups_text_color"):GetString(), " ")
		if rgb3[1] == "invert" then rgb3 = {nil,nil,nil} end
		r3,g3,b3 = tonumber(rgb3[1]) or (255 - (a1*r1/255 + a2*r2/255)/2), tonumber(rgb3[2]) or (255 - (a1*g1/255 + a2*g2/255)/2), tonumber(rgb3[3]) or (255 - (a1*b1/255 + a2*b2/255)/2)
	end

	function preview_pnl:Paint( w, h )
		--base layer
		local sine = 0.5 + 0.5*math.sin(CurTime()*2)
		draw.RoundedBox( 0, 0, 0, w, h, Color( r1 - (r1/255)*pulse*sine, g1 - (g1/255)*pulse*sine, b1 - (b1/255)*pulse*sine, a1 - (a1/255)*pulse*sine) )
		for band=0,w,1 do
			--per-pixel fade
			fade = 1 - (1/w * band * 1)
			fade = math.pow(fade,2)
			draw.RoundedBox( 0, band, 1, 1, h-2, Color( r2, g2, b2, fade*a2))
		end
		draw.DrawText(label_text, "DermaDefaultBold", 5, 5, Color(r3,g3,b3,255))
	end

	list_pnl:Add(Label("Base color"))
	list_pnl:Add(basecolor)
	list_pnl:Add(basecolor_pulse)
	list_pnl:Add(Label("Gradient color"))
	list_pnl:Add(fadecolor)
	list_pnl:Add(Label("Text color"))
	list_pnl:Add(textcolor)
	list_pnl:Add(invertcolor_btn)
	list_pnl:Add(preview_refresh_btn)
	list_pnl:Add(preview_pnl)
	master_pnl:MakePopup()


end

concommand.Add("pac_popups_settings", function() pace.OpenPopupConfig() end)

--[[
	info_string,											main string
	{													   info about where to position the label
		pac_part = part,									that would be the pac part if applicable
		obj = self.Label,								   that would be the positioning target
		obj_type = "pac tree label",						what type of thing is the target, for positioning
																pac tree label = on the editor, needs to realign when scrolling
																part world = if base_movable, place it next to the part in the view, if not, owner entity
																screen = static x,y on screen no matter what, needs the further x,y args specified outside
																cursor = right on the cursor
																editor bar = next to the toolbar
		hoverfunc = function() end,						 a function to run when hovering.
		doclickfunc = function() end,					   a function to run when clicking
		panel_exp_width = 900, panel_exp_height = 200	   prescribed dimensions to expand to
	},
	self:LocalToScreen()									x,y
]]



--[[
we generally have two routes to create a popup: part and direct
at the part level we can tell pac to try to create a popup
pac.AttachInfoPopupToPart(part : obj, string : str, table : tbl)	--naming scheme close to a general pac function
	PART:AttachEditorPopup(string : str, bool : flash, table : tbl) --calls the generic base setup in base_part, shouldn't be overridden
		PART:SetupEditorPopup(str, force_open, tbl)				 --calls the specific setup, can be overridden for different classes
			pac.InfoPopup(str, tbl, x, y)						   --creates the vgui element

we can directly create an independent editor popup
pac.InfoPopup(str, tbl, x, y)
]]


function pac.InfoPopup(str, tbl, x, y)
	if not GetConVar("pac_popups_enable"):GetBool() then return end
	local x = x
	local y = y
	if not x or not y then
		x = ScrW()/2 + math.Rand(-300,300)
		y = ScrH()/2 + math.Rand(-300,0)
	end
	tbl = tbl or {}
	if not tbl.obj then
		if tbl.obj_type == "pac tree label" then
			tbl.obj = tbl.pac_part.pace_tree_node
		elseif tbl.obj_type == "part world" then
			tbl.obj = tbl.pac_part
		end
	end

	str = str or ""
	local verbosity = GetConVar("pac_popups_verbosity"):GetString()

	local rgb1 = string.Split(GetConVar("pac_popups_base_color"):GetString(), " ")
	local r1,g1,b1 = tonumber(rgb1[1]) or 255, tonumber(rgb1[2]) or 255, tonumber(rgb1[3]) or 255
	local a1 = GetConVar("pac_popups_base_alpha"):GetFloat()
	local pulse = GetConVar("pac_popups_base_color_pulse"):GetInt()
	local rgb2 = string.Split(GetConVar("pac_popups_fade_color"):GetString(), " ")
	local r2,g2,b2 = tonumber(rgb2[1]) or 255, tonumber(rgb2[2]) or 255, tonumber(rgb2[3]) or 255
	local a2 = GetConVar("pac_popups_fade_alpha"):GetFloat()
	local rgb3 = string.Split(GetConVar("pac_popups_text_color"):GetString(), " ")
	if rgb3[1] == "invert" then rgb3 = {nil,nil,nil} end
	local r3,g3,b3 = tonumber(rgb3[1]) or (255 - (a1*r1/255 + a2*r2/255)/2), tonumber(rgb3[2]) or (255 - (a1*g1/255 + a2*g2/255)/2), tonumber(rgb3[3]) or (255 - (a1*b1/255 + a2*b2/255)/2)

	local pnl = vgui.Create("DFrame")
	local txt_zone = vgui.Create("RichText", pnl)

	--function pnl:PerformLayout() end
	pnl:SetTitle("") pnl:SetText("") pnl:ShowCloseButton( false )
	txt_zone:SetPos(5,25)
	txt_zone:SetContentAlignment( 7 ) --top left

	if tbl.pac_part then
		if verbosity == "reference tutorial" or verbosity == "beginner tutorial" then
			if pace.TUTORIALS.PartInfos[tbl.pac_part.ClassName] then
				str = str .. "\n\n" .. pace.TUTORIALS.PartInfos[tbl.pac_part.ClassName].popup_tutorial .. "\n"
			end
		end
	end


	pnl.hoverfunc = function() end
	pnl.doclickfunc = function() end
	pnl.titletext = "Click for more information! (or F1)"
	pnl.alternativetitle = "Right click / Alt+P to kill popups. \"pac_popups_preserve_on_autofade\" is set to " .. GetConVar("pac_popups_preserve_on_autofade"):GetInt() .. ", " .. (GetConVar("pac_popups_preserve_on_autofade"):GetBool() and "If it fades away, the popup is allowed to reappear on hover or F1" or "If it fades away, the popup will not reappear")

	--pnl:SetPos(ScrW()/2 + math.Rand(-100,100), ScrH()/2 + math.Rand(-100,100))

	function pnl:FixPartReference(tbl)
		if not tbl or table.IsEmpty(tbl) then self:Remove() end
		if tbl.pac_part then tbl.obj = tbl.pac_part.pace_tree_node end

	end

	function pnl:MoveToObj(tbl)
		--self:MakePopup()
		if tbl.obj_type == "pac tree label" then
			if not IsValid(tbl.obj) then
				self:FixPartReference(tbl)
				self:SetPos(x,y)
			else
				local x,y = tbl.obj:LocalToScreen()
				x = pace.Editor:GetWide()
				--print(pace.Editor:GetWide(), input.GetCursorPos())
				self:SetPos(x,y)
			end
			if pace then
				if pace.Editor then
					if pace.Editor.IsLeft then
						if not pace.Editor:IsLeft() then
							self:SetPos(pace.Editor:GetX() - self:GetWide(),self:GetY())
						else
							self:SetPos(pace.Editor:GetX() + pace.Editor:GetWide(),self:GetY())
						end
					end
				end
			end

		elseif tbl.obj_type == "part world" then
			if tbl.pac_part then
				local ent = tbl.pac_part:GetRootPart():GetOwner()
				if not IsValid(ent) then ent = pac.LocalPlayer end
				local global_position = pac.LocalPlayer:GetPos()
				if ent.GetPos then global_position = (ent:GetPos() + ent:OBBCenter()*1.5) end
				if tbl.pac_part.GetWorldPosition then
					global_position = tbl.pac_part:GetWorldPosition() --if part is a base_movable, we'll get its position right away
				elseif tbl.pac_part:GetParent().GetWorldPosition then
					global_position = tbl.pac_part:GetParent():GetWorldPosition() --if part isn't but has a base_movable parent, get that
				end
				local scr_tbl = global_position:ToScreen()
				self:SetPos(scr_tbl.x, scr_tbl.y)
			end

		elseif tbl.obj_type == "screen" then
			self:SetPos(x,y)

		elseif tbl.obj_type == "cursor" then
			self:SetPos(input.GetCursorPos())

		elseif tbl.obj_type == "menu bar" then
			if not pace.Editor:IsLeft() then
				self:SetPos(pace.Editor:GetX() - self:GetWide(),self:GetY())
			else
				self:SetPos(pace.Editor:GetX() + pace.Editor:GetWide(),self:GetY())
			end
		end

	end


	if tbl then
		pnl.tbl = tbl
		pnl:MoveToObj(tbl)
		if tbl.hoverfunc then
			if tbl.hoverfunc == "open" then
				pnl.hoverfunc = function()
					pnl.hovering = true
					pnl:keep_alive(3)
					if not pnl.hovering and not pnl.expand then
						pnl.resizing = true
						pnl.expand = true

						pnl.ResizeStartTime = CurTime()
						pnl.ResizeEndTime = CurTime() + 0.3
					end
				end
			else
				pnl.hoverfunc = tbl.hoverfunc
			end
		end
		pnl.exp_height = tbl.panel_exp_height or 400
		pnl.exp_width = tbl.panel_exp_width or 800
	end

	pnl.exp_height = pnl.exp_height or 400
	pnl.exp_width = pnl.exp_width or 800
	pnl:SetSize(200,20)

	pnl.DeathTimeAdd = 0
	if GetConVar("pac_popups_preserve_on_autofade"):GetBool() then
		pnl.DeathTimeAdd = 240
	end
	pnl.DeathTime = CurTime() + 13
	pnl.FadeTime = CurTime() + 10
	pnl.FadeDuration = pnl.DeathTime - pnl.FadeTime
	pnl.ResizeEndTime = 0
	pnl.ResizeStartTime = 0
	pnl.resizing = false

	function pnl:keep_alive(extra_time)
		pnl.DeathTime = math.max(pnl.DeathTime, CurTime() + extra_time + pnl.FadeDuration)
		pnl.FadeTime = math.max(pnl.FadeTime, CurTime() + extra_time)
		pnl:SetAlpha(255)
	end

	--the header needs a label to click on to open the popup
	function pnl:DoClick()

		if input.IsKeyDown(KEY_F1) or (self:IsHovered() and not txt_zone:IsHovered()) then
			pnl.expand = not pnl.expand
			pnl.ResizeStartTime = CurTime()
			pnl.ResizeEndTime = CurTime() + 0.3
			pnl.resizing = true
		end

		pnl:keep_alive(3)
		pnl.doclickfunc()
	end

	--handle positioning, expanding and termination
	function pnl:Think()
		self:MoveToObj(tbl)
		if input.IsButtonDown(KEY_P) and input.IsButtonDown(KEY_LALT) then --auto-kill if alt-p
			if tbl.pac_part then tbl.pac_part.killpopup = true end
			self:Remove()
		end

		if input.IsMouseDown(MOUSE_RIGHT) then
			if self:IsHovered() and not txt_zone:IsHovered() then
				self:Remove()
			end
		end

		self.F1_doclick_possible_at = self.F1_doclick_possible_at or 0
		self.mouse_doclick_possible_at = self.mouse_doclick_possible_at or 0

		if input.IsButtonDown(KEY_F1) then --expand if press F1, but only after a delay
			if self.F1_doclick_possible_at == 0 then
				self.F1_doclick_possible_at = CurTime() + 0.3
			end
			if CurTime() > self.F1_doclick_possible_at then
				self.F1_doclick_possible_at = 0
				self:DoClick()
			end
		end
		if input.IsMouseDown(MOUSE_LEFT) and self:IsHovered() or self:IsChildHovered() then --expand if press mouse left
			if self.mouse_doclick_possible_at == 0 then
				self.mouse_doclick_possible_at = CurTime() + 1
			end
			if CurTime() > self.mouse_doclick_possible_at then
				self.mouse_doclick_possible_at = 0
				self:DoClick()
			end
		end
		if not input.IsMouseDown(MOUSE_LEFT) then
			self.mouse_doclick_possible_at = CurTime()
		end

		if not IsValid(tbl.pac_part) and tbl.pac_part ~= false and tbl.pac_part ~= nil then self:Remove() end
		self.exp_width = self.exp_width or 800
		self.exp_height = self.exp_height or 500
		--resizing code, initially the label should start small
		if self.resizing then
			local expand_frac_w = math.Clamp((self.ResizeEndTime - CurTime()) / 0.3,0,1)
			local expand_frac_h = math.Clamp((self.ResizeEndTime - (CurTime() - 0.5)) / 0.5,0,1)
			local width,height
			if not self.expand then
				width = 200 + (self.exp_width - 200)*(expand_frac_w)
				height = 20 + (self.exp_height - 20)*(expand_frac_h)
				if self.hovering and not self:IsHovered() then self.hovering = false end
			else
				width = 200 + (self.exp_width - 200)*(1 - expand_frac_h)
				height = 20 + (self.exp_height - 20)*(1 - expand_frac_w)

			end
			self:SetSize(width,height)
			txt_zone:SetSize(width-10,height-30)
		end


		self.fade_factor = math.Clamp((self.DeathTime - CurTime()) / self.FadeDuration,0,1)
		self.fade_factor = math.pow(self.fade_factor, 3)

		if CurTime() > self.DeathTime + self.DeathTimeAdd then
			self:Remove()
		end
		if pace.Focused then self:SetAlpha(255*self.fade_factor) end
		if self:IsHovered() then
			self:keep_alive(1)
			self.hoverfunc()
			if input.IsMouseDown(MOUSE_RIGHT) then
				if tbl.pac_part then
					tbl.pac_part.killpopup = true
				end
				self:Remove()
			end

		end

		if not pace.Focused then
			self.has_focus = false
			self:AlphaTo(0, 0.1, 0)
			self:KillFocus()
			self:SetMouseInputEnabled(false)
			self:SetKeyBoardInputEnabled(false)
			gui.EnableScreenClicker(false)
		else
			if not self.has_focus then
				self:RequestFocus()
				self:MakePopup()
				self.has_focus = true
			end
		end

		function pnl:OnRemove()
			if not GetConVar("pac_popups_preserve_on_autofade"):GetBool() then
				tbl.pac_part.killpopup = true
			end
		end
	end

	pnl.doclickfunc = tbl.doclickfunc or function() end



	pnl.exp_height = tbl.panel_exp_height
	pnl.exp_width = tbl.panel_exp_width

	--cast the convars values
	r1 = tonumber(r1)
	g1 = tonumber(g1)
	b1 = tonumber(b1)
	a1 = tonumber(a1)
	r2 = tonumber(r2)
	g2 = tonumber(g2)
	b2 = tonumber(b2)
	a2 = tonumber(a2)
	r3 = tonumber(r3)
	g3 = tonumber(g3)
	b3 = tonumber(b3)

	local col = Color(r3,g3,b3,255)

	--txt_zone:SetFont("DermaDefaultBold")
	function txt_zone:PerformLayout()
		txt_zone:SetBGColor(0,0,0,0)
		txt_zone:SetFGColor(col)
	end

	function txt_zone:Think()
		if self:IsHovered() then
			pnl:keep_alive(3)
		end
	end

	txt_zone:SetText("")
	txt_zone:AppendText(str)

	txt_zone:SetVerticalScrollbarEnabled(true)

	function pnl:Paint( w, h )


		self.fade_factor = self.fade_factor or 1
		--base layer
		local sine = 0.5 + 0.5*math.sin(CurTime()*2)
		draw.RoundedBox( 0, 0, 0, w, h, Color( r1 - (r1/255)*pulse*sine, g1 - (g1/255)*pulse*sine, b1 - (b1/255)*pulse*sine, a1 - (a1/255)*pulse*sine) )
		--draw.RoundedBox( 0, 0, 0, 1, h, Color( 88, 179, 255, 255))
		for band=0,w,1 do
			--per-pixel fade
			fade = 1 - (1/w * band * self.fade_factor)
			fade2 = math.pow(fade,3)
			fade = math.pow(fade,2)
		  --draw.RoundedBox( c, x,	y, w, h, color )
			draw.RoundedBox( 0, band, 1, 1, h-2, Color( r2, g2, b2, fade*a2))
			--draw.RoundedBox( 0, band, 0, 1, 1, Color( 88, 179, 255, 255))
			--draw.RoundedBox( 0, band, h-1, 1, 1, Color( 0, 0, 0, 255))
		end

		if self.expand then
			draw.DrawText(self.alternativetitle, "DermaDefaultBold", 5, 5, Color(r3,g3,b3,self.fade_factor * 255))
		else
			draw.DrawText(self.titletext, "DermaDefaultBold", 5, 5, Color(r3,g3,b3,self.fade_factor * 255))
		end
	end

	pnl:MakePopup()
	return pnl
end

function pac.AttachInfoPopupToPart(obj, str, tbl)
	if not obj then return end
	obj:AttachEditorPopup(str, true, tbl)
end

function pace.FlushInfoPopups()
	for _,part in pairs(pac.GetLocalParts()) do
		local node = part.pace_tree_node
		if not node or not node:IsValid() then continue end
		if node.popupinfopnl then
			node.popupinfopnl:Remove()
			node.popupinfopnl = nil
		end
	end

end

--[[
	part classes info

ideally we should have:
1-a tooltip form (7 words max)
		e.g. projectile:				throws missiles into the world
2-a fuller form for the popups (4-5 sentences or more if needed)
		e.g. projectile:				the projectile part creates physical entities and launches them forward.\n
										the entity has physics but it can be clientside (visual) or serverside (physical)\n
										by selecting an outfit part, the entity can bear a PAC3 part or group to have a PAC3 outfit of its own\n
										the entity can do damage but servers can restrict that.

but then again we should probably look for better ways for the full-length explanations,
		maybe grab some of them from the wiki or have a web browser for the wiki
]]

do

	pace.TUTORIALS = pace.TUTORIALS or {}
	pace.TUTORIALS.PartInfos = {

		["trail"] = {
			tooltip = "leaves a trail behind",
			popup_tutorial =
			"the trail part creates beams along its path to make a trail\n"..
			"nothing unique that I need to tell you, this part is mostly self-explanatory.\n"..
			"you can set how it looks, how big it becomes etc."
		},

		["trail2"] = {
			tooltip = "leaves a trail behind",
			popup_tutorial =
			"the trail part creates beams along its path to make a trail\n"..
			"nothing unique that I need to tell you, this part is mostly self-explanatory.\n"..
			"you can set how it looks, how big it becomes etc."
		},

		["sound"] = {
			tooltip = "plays sounds",
			popup_tutorial = "plays sounds in wav, mp3, ogg formats.\n"..
			"for random sounds, paste each path separated by semicolons e.g. sound1.wav;sound3.wav;sound8.wav\n"..
			"we have a special bracket notation for sound lists: sound[1,50].wav\n\n"..
			"some of the parameters to know:\n"..
			"sound level affects the falloff along with volume; a good starting point is 70 level, 0.6 volume\n"..
			"overlapping means it doesn't get cut off if hidden\n"..
			"sequential plays sounds in a list in order once you have the semicolon or bracket notation;\n"..
			"\tthe steps is how much you progress by each activation. it can go one by one (1), every other sound (2+), stay there (0) or go back (negative values)"
		},

		["sound2"] = {
			tooltip = "plays web sounds",
			popup_tutorial = "plays sounds in wav, mp3, ogg formats, with the option to download sound files from the internet\n"..
			"people usually use dropbox, google drive, other cloud hosts or their own server host to store and distribute their files. each has its limitations.\n\n"..
			"WARNING! Downloading and using these sounds is only possible in the chromium branch of garry's mod!\n\n"..
			"to randomize sounds, we still have the same notations as legacy sound:\n"..
			"\tsemicolon notation e.g. path1.wav;https://url1.wav;https://url2.wav\n"..
			"\tbracket notation   e.g. sound[1,50].wav\n\n"..
			"some of the parameters to know, you'll already know some of them from legacy sound:\n"..
			"-radius affects the falloff distance\n"..
			"-overlapping means it doesn't get cut off if hidden\n"..
			"-sequential plays sounds in a list in order"
		},

		["ogg"] = {
			tooltip = "plays ogg sounds (broken)",
			popup_tutorial = "This part is not supported anymore. Do not bother. Use the new web sound."
		},

		["webaudio"] = {
			tooltip = "plays web sounds (legacy)",
			popup_tutorial = "This part is not supported anymore. Do not bother. Use the new web sound."
		},


		["halo"] = {
			tooltip = "makes models glow",
			popup_tutorial =
			"This part creates a halo around a model entity.\n"..
			"That could be your playermodel or a pac3 model, but for some reason it doesn't work on your player if you have an entity part.\n"..
			"passes is the thickness of the halo, amount is the brightness, blur x and y spread out the shape"
		},

		["bodygroup"] = {
			tooltip = "changes body parts on supported models",
			popup_tutorial =
			"Bodygroups are a Source engine model feature which allows to easily show or hide different pieces of a model\n"..
			"those are often used for accessories and styles. But it won't work unless your model has bodygroups.\n"..
			"this part does exactly that. but you might do that directly with the model part or entity part"
		},

		["holdtype"] = {
			tooltip = "changes your animation set",
			popup_tutorial =
			"this part allows you to change animations played in individual movement slots, so you can mix and match from the available animations in your playermodel\n"..
			"a holdtype is a set of animations for holding one kind of weapon, such as one-handed pistols vs two-handed revolvers, rifles, melee weapons etc.\n"..
			"The option is also in the normal animation part, but this part goes in more detail in choosing different animations"
		},

		["clip"] = {
			tooltip = "cuts a model in a plane (legacy)",
			popup_tutorial =
			"This part cuts off one side of the model in rendering.\n"..
			"It only cuts in a plane, with the forward red arrow as its normal. there are no other shapes."
		},

		["clip2"] = {
			tooltip = "cuts a model in a plane",
			popup_tutorial =
			"This part cuts off one side of the model in rendering.\n"..
			"It only cuts in a plane, with the forward red arrow as its normal. there are no other shapes."
		},

		["model"] = {
			tooltip = "places a model (legacy)",
			popup_tutorial = "The old model part still does the basic things you need a model to do"
		},

		["model2"] = {
			tooltip = "places a model",
			popup_tutorial =
			"The model part creates a clientside entity to draw a model locally.\n"..
			"Being a base_movable, parts inside it will be physically arented to it.\n"..
			"therefore, it can act as a regrouper, rail or anchoring point for your pac structuring needs, although you probably shouldn't abuse it.\n"..
			"It can accept most modifiers and play animations, if present or referenced in the model.\n\n"..
			"It can load MDL zips or OBJ files from a direct link to a server host or cloud provider, allowing you to use pretty much any model as long as it's the right format for Source. And on that subject, you would do well to install Crowbar, as well as Blender with Blender Source Tools, if you want to extract and edit models. Consult the valve developer community wiki for more information about QC; I view this as common knowledge rather than the purview of pac3 so you have to do some research."
		},

		["material"] = {
			tooltip = "defines a material (legacy)",
			popup_tutorial =
			"the old material still works as it says. it lets you define some VMT parameters for a material"
		},

		["material_3d"] = {
			tooltip = "defines a material for models",
			popup_tutorial =
			"This part creates a VMT material of the shader type VertexLitGeneric.\n"..
			"If you have experience in Source engine things, you probably should know what some of these do, I won't expound fully but here's the essential summary anyway:\n\n"..
			"\tbase texture is the base image. It's basically just color pixels.\n"..
			"\tbump map / normal map is a relief that gives a texture on the surface. It uses a distinctly purple pixel format; it's not color but directional information\n"..
			"\tdetail is a second base image added on top to modify the pixels. It's usually grayscale because we don't need to add color to give more grit to an image\n"..
			"\tself illumination and emissive blend are glowing layers. emissive blend is more complex and needs three necessary components before it starts to work properly.\n"..
			"\tenvironment map is a layer for pre-baked room reflection, by default env_cubemap  tries to get the nearest cubemap but you can choose another texture, although cubemaps are a very specific format\n"..
			"\tphong is a layer of dynamic light reflections\n\n"..
			"If you want to edit a material, you can load its VMT with a right click on \"load vmt\", then select the right material override\n"..
			"Reminder that transparent textures may need additive or some form of translucent setting on the model and on the material.\n\n"..
			"For more information, search the Valve developer community site or elsewhere. Many material features are standard, and if you want to push this part to the limit, the extra research will be worth it."
		},

		["material_2d"] = {
			tooltip = "defines a material for sprites",
			popup_tutorial =
			"This part creates a VMT material of the shader type UnlitGeneric. This is used by particles and sprites.\n"..
			"For transparent textures, use additive or vertex alpha/vertex color (for particles and decals). Some VTF or PNG textures have an alpha channel, but many just have a black background meant for additive rendering.\n\n"..
			"For more information, search the Valve developer community site"
		},

		["material_refract"] = {
			tooltip = "defines a refracting material",
			popup_tutorial =
			"This part creates a VMT material of the shader type Refract. As with other material parts, you would find it useful to name the material to use that in multiple models' \"material\" fields\n"..
			"In a way, it doesn't work by surface, but by silhouette. But the surface does determine how the refraction occurs. Setting a base texture creates a flat wall behind it that can distort in interesting ways but it'll replace the view behind.\n"..
			"The normal section does most of the heavy lifting. This is where the image behind the material gets refracted according to the surface. You can blend between two normal maps in greater detail.\n"..
			"Your model needs to be set to \"translucent\" rendering mode for this to work because the shader is in a multi-step rendering process.\n\n"..
			"For more information, search the Valve developer community site"
		},

		["material_eye refract"] = {
			tooltip = "defines a refracting eye material",
			popup_tutorial =
			"This part creates a VMT material of the shader type EyeRefract.\n"..
			"It's tricky to use because of how it involves projections and entity eye position, but you can more easily get something working on premade HL2 or other Source games' characters with QC eyes."
		},

		["submaterial"] = {
			tooltip = "applies a material on a submaterial zone",
			popup_tutorial =
			"Models can be comprised of multiple materials in different areas. This part can replace the material applied to one of these zones.\n"..
			"Depending on how the model was made, it might correspond to what you want, or it might not.\n"..
			"As usual, as with other model modifiers your expectations should always line up with the quality of the model you're using."
		},

		["bone"] = {
			tooltip = "changes a bone (legacy)",
			popup_tutorial =
			"The legacy bone part still does the basic things you need a bone part to do, but you should probably use the new bone part."
		},

		["bone2"] = {
			tooltip = "changes a bone (legacy)",
			popup_tutorial =
			"The legacy experimental bone part still does the basic things you need a bone part to do, but you should probably use the new bone part."
		},

		["bone3"] = {
			tooltip = "changes a bone",
			popup_tutorial =
			"This part modifies a model's bone. It can move relative to the parent bone, scale, and rotate.\n"..
			"Follow part forces the bone to relocate to a base_movable part. Might have issues if you successively follow part multiple related bones. You could try to fix that by changing draw orders of the follow parts and bones."
		},

		["player_config"] = {
			tooltip = "sets your player entity's behaviour",
			popup_tutorial =
			"This part has access to some of your player's behavior, like whether you will play footsteps, the chat animation etc.\n"..
			"Some of these may or may not work as intended..."
		},

		["light"] = {
			tooltip = "lights up the world (legacy)",
			popup_tutorial =
			"This legacy part still does the basic thing you want from a light, but the new light part is more fully-featured, for the most part.\n"..
			"There is one thing it does that the new part doesn't, and that's styles."
		},

		["light2"] = {
			tooltip = "lights up models or the world",
			popup_tutorial =
			"This part creates a dynamic light that can illuminate models or the world independently.\n"..
			"There are some options for the light's falloff shape (inner and outer angles).\n"..
			"Its brightness works by magnitude and size, not multiplication. Which means you can still have light at 0 or lower brightness."
		},

		["event"] = {
			tooltip = "activates or deactivates other parts",
			popup_tutorial =
			"This part hides or shows connected parts when certain conditions are met. We won't describe them in this tutorial, you'll have to read them individually. The essential behaviour remains common accross events.\n\n"..
			"Domain, in other words, which parts get affected:\n"..
			"\t1-Default: The event will command its direct parent. Because parts can contain other parts, this includes the event itself, and parts beside the event too. While this is not usually a problem, you have to be aware of that.\n"..
			"\t2-ACO: Affect Children Only. The event will command parts inside it, not beside, not above. This is the first step to isolate your setup and have clean logic in your pac.\n"..
			"\t3-Targeted: The event gets wired to a part directly, including its children of course. This is accessed when you select a part in the \"targeted part\" field, which has an unfortunate name because there's still the old \"target part\" parameter\n\n"..
			"Some events, like is_touching, can select an external \"target\" to use as a point to gather information.\n\n"..
			"Operators:\n"..
			"Operators are just how the event asks the question to determine when to activate or deactivate. Just read the event the same way as it asks the question: is my source equal to the value? can I find this text in my source?\n"..
			"\tnumber-related operators: equal, above, below, equal or above, equal or below\n"..
			"\tstring-related operators: equal, find, find simple\n"..
			"There's still a caveat. If you use the wrong type of operator for your event, it will NOT work. Please trust the editor autopilot when it automatically changes your operator to a good one. Do not change it unless you know what you're doing."
		},

		["sprite"] = {
			tooltip = "draws a 2D texture",
			popup_tutorial =
			"Sprites are another Source engine thing which are useful for some point effects. Most textures being for model surfaces will look like squares if drawn flat, but sprite and particle textures are made specially for this purpose.\n"..
			"They should have a transparent background or black background. The difference is because of rendering modes or blend modes.\n"..
			"Additive rendering adds pixels' values. So, bright pixels will be more visible, but dark pixels end up being faded or invisible because their amounts are low."
		},

		["fog"] = {
			tooltip = "colors a model with fog",
			popup_tutorial =
			"This strange modifier renders a fog-like color over a model. Not in the world, not inside the model, but over its surface.\n"..
			"For that reason, you might do well to change rendering-related values like blend mode on the host model's side\n"..
			"It requires to be attached to a base_drawable part, keep in mind the start and end values are multiplied by 100 in post for some reason."..
			"start is the distance where the fog starts to appear outside, end is where the fog is thickest."
		},

		["force"] = {
			tooltip = "provides physical force",
			popup_tutorial =
			"This part tries to tell the server to do a force impulse, or continually request small impulses for a continuous force. It should work for most physics props, some item and ammo entities, players and NPCs. But it may or may not be allowed on the server due to server settings: pac_sv_force.\n\n"..
			"There's a base force and an added xyz vector force. You have options to choose how they're applied. Aside from that, the part's area is mainly for detection.\n\n"..
			"For the Base force, Radial is from to self to each entity, Locus is from locus to each entity, Local is forward of self\n\n"..
			"For the Vector force, Global is on world coordinates, Local is on self's coordinates, Radial is relative to the line from the self or locus toward the entity (Used in orbits/vortex/circular motion with centrifugal force)\n\n"..
			"NPCs might have weird movement so don't expect much from pushing them."
		},

		["faceposer"] = {
			tooltip = "Adjusts multiple facial expression slots",
			popup_tutorial =
			"This part gives access to multiple facial expressions defined by your model's shape keys in one part.\n"..
			"The flex multiplier affects the whole model, so you should avoid stacking faceposers if they have different multipliers."
		},

		["command"] = {
			tooltip = "Runs a console command or lua code",
			popup_tutorial = "This part attempts to run a command or Lua code on your client. It may or may not work depending on the command and some servers don't allow you to run clientside lua, because of sv_allowcslua 0.\n\n"..
			"Some example lua bits:\n"..
			"\tif LocalPlayer():Health() > 0 then print(\"I'm alive\") RunConsoleCommand(\"say\", \"I\'m alive\") end\n"..
			"\tfor i=0,100,1 do print(\"number\" .. i) end\n"..
			"\tfor _,ent in pairs(ents.GetAll()) do print(ent, ent:Health()) end\n"..
			"\tlocal random_n = 1 + math.floor(math.random()*5) RunConsoleCommand(\"pac_event\", \"event_\"..random_n)"

		},

		["weapon"] = {
			tooltip = "configures your weapon entity",
			popup_tutorial = "This part is like an entity part, but for weapons. It can change your weapon's position and appearance, for all or one weapon class."
		},

		["woohoo"] = {
			tooltip = "applies a censor square",
			popup_tutorial =
			"This part draws a pixelated square with what's behind it, with a possible blur filter and adjustable resolution.\n"..
			"It requires a lot of resources to set up and needs to refresh in specific circumstances, which is why you can't change its resolution or blur filtering state with proxies."
		},

		["flex"] = {
			tooltip = "Adjusts one facial expression slot",
			popup_tutorial =
			"This part gives access to one facial expression defined by your model's shape keys."
		},

		["particles"] = {
			tooltip = "Emits particles",
			popup_tutorial =
			"Throws particles into the world. They are quite configurable, can be flat 3D or 2D sprites, can be stretched with start/end length.\n"..
			"To start with, you may want to set zero angle to false and particle angle velocity to (0, 0, 0)\n"..
			"You can use a web texture but you might still need to work around material limitations for transparent images\n"..
			"They are not PCF effects though. But I think that with a wise choice and layered particles, you can recreate something that looks like an effect."
		},

		["custom_animation"] = {
			tooltip = "sets up an editable bone animation",
			popup_tutorial =
			"This part creates a custom animation with a separate editor menu. It is not a sequence, but it moves bones on top of your base animations. It morphs between keyframes which correspond to bones' positions and angles. This is what creates movement.\n\n"..
			"Custom animation types:\n"..
			"\tsequence: loopable. plays the A-pose animation as a base, layers bone movements on top."..
			"\tstance: loopable. layers bone movements on top."..
			"\tgesture: not loopable. layers bone movements on top. ideally you should start with duplicating your initial frame once for smoothly going back to 0."..
			"\tposture: only applies one non-moving frame. this is like a set of bones.\n\n"..
			"There are interesting Easing styles available when you select the linear interpolation mode. They're useful in many ways, if you want to have more control over the dynamics and ultimately give character to your animation.\n"..
			"While this is not the place to write a full tutorial for how to animate, or explaining animation principles in depth, I editorialize a bit and say those are two I try to aim for:\n"..
			"\tinertia: trying to carry some movement over from a previous frame, because real physics take time to decelerate and accelerate between positions.\n"..
			"\texaggeration: animations often use unnatural movement dynamics (e.g. different speeds at different times) to make movements look more pleasing by giving it more character. This goes in hand with anticipation."
		},

		["beam"] = {
			tooltip = "draws a rope or beam",
			popup_tutorial =
			"This part renders a rope or beam between itself and the end point. It can bend relative to the two endpoints' angles.\n"..
			"frequency determines how many half-cycles it goes through. 1 is half a cycle (1 bump), 2 is one cycle(2 bumps)\n"..
			"resolution is how many segments it tries to draw for that.\n\n"..
			"And here's another reminder that while it can load url images, there are limitations so you may have to do something with a material part or blend mode if you want a custom transparent texture."
		},

		["animation"] = {
			tooltip = "plays a sequence animation",
			popup_tutorial =
			"This part plays a sequence animation defined in your model via the model's inherent animation definitions, included animations and active addons. Cannot load custom animations, not even .ani, .mdl or .smd\n"..
			"If you want to import an animation from somewhere else, you need to know some decompiling/recompiling QC knowledge"
		},

		["player_movement"] = {
			tooltip = "edits your player movement",
			popup_tutorial = "This part tells the server to handle your movement manually with a Move hook.\n"..
			"Z-Velocity means you can move in the air relative to your eye angles, with WASD and jump almost like noclip. It is however still subject to air friction (needs friction to move, but friction also decelerates you) and uses ground friction as a driver.\n"..
			"Friction  generally cuts your movement as a percentage every tick. This is why it's very sensitive because its effect is exponential. Horizontal air friction tries to mitigate that a bit\n"..
			"Reverse pitch is probably buggy. "
		},

		["group"] = {
			tooltip = "organizes parts",
			popup_tutorial =
			"This part groups parts. That's all it does. It bypasses parenting, which means it has no side effect, aside from when modifiers act on their direct parent, in which case the group can get in the way.\n"..
			"But with a root group, (a group at the root/top level, \"my outfit\"), you can choose an owner name to select another entity to bear the pac outfit."
		},

		["lock"] = {
			tooltip = "grabs or teleports",
			popup_tutorial =
			"This part allows you to grab things or teleport yourself.\n\n"..
			"Warning in advance: It has the most barriers because it probably has the most potential for abuse out of all parts.\n"..
			"\tClients need to give consent explicitly (pac_client_grab_consent 1), otherwise you can't grab them.\n"..
			"\tThis is doubly true for players' view position. That's another consent (pac_client_lock_camera_consent 1) layered on top of the existing grab consent.\n"..
			"\tOn top of that, grabbed players will get a notification if you grab them, and they will know how to break the lock. Clients have multiple commands (pac_break_lock, pac_stop_lock) to request the server to force you to release them. It is mildly punitive.\n"..
			"\tThere are multiple server-level settings to limit it. Some servers may even wholesale disable the new combat parts for all players by default until they're trusted/whitelisted.\n\n"..
			"Now, here's business. How it works, and how to use this part:\n"..
			"\tThe part searches for entities around a sphere, selects the closest one and locks onto it. You should plan ahead for the fact that it only picks up entities by their origin position, which for NPCs and players is between their feet. offset down amount compensates for this, but only for where the detection radius begins.\n"..
			"\tIt will then start communicating with the server and the server may reposition the entity if it's allowed. If rejected, you may get a warning in the console, and the part will be stopped for a while."..
			"\tOverrideEyeAngles works for players only, and as stated previously, is subject to consent restrictions.\n"
		},

		["physics"] = {
			tooltip = "creates a clientside physics object",
			popup_tutorial =
			"This part creates a physics object clientside which can be a box or a sphere. It will relocate the model and pac parts contained and put them in the object.\n"..
			"It's not compatible with the force part, unfortunately, because it's clientside. There are other reasonably fun things it can do though.\n"..
			"It only works as a direct modifier on a model."
		},

		["jiggle"] = {
			tooltip = "wobbles around",
			popup_tutorial =
			"This part creates a subpoint that carries base_movables, and moves around with a certain type of dynamics that can lag behind and then catch up, or wiggle back and forth for a while. Strain is how much it will wobble. The children parts will be contained within that subpoint.\n"..
			"There is immense utility to control movement and have some physicality to your parts' movement. To name a few examples:\n"..
			"\tThe jiggle 0 speed trick: Having your jiggle set at 0 speed will freeze what's inside. You can easily control that with two proxies: one for moving (not 0), one for stopping (0)\n"..
			"\tPets and drones: Fun things that are semi-independent. Easy to do with jiggle.\n"..
			"\tSmoother transitions with multiple static proxies: If you have position proxies that snap to different positions, making a model teleport too fast, using these proxies on a jiggle instead will let the jiggle do the work of smoothing things out with the movement.\n"..
			"\tForward velocity indicator via a counter-lagger: jiggle lags behind an origin, model points to origin with aim part, other model is forward relative to the pointer. Result: a model that goes in the direction of your movement.\n\n"..
			"The part, however, has issues when crossing certain angles (up and down)."
		},

		["projected_texture"] = {
			tooltip = "creates a lamp",
			popup_tutorial =
			"This part creates a dynamic light / projected texture that can project onto models or the world. That's pretty much it. It's useful for lamps, flashlights and the like.\n"..
			"But if you're expecting a proper light, its directed lighting method gives mediocre results alone. With another light, and a sprite maybe, it'll look nicer. We won't have point_spotlights though.\n"..
			"Its brightness works by multiplication, not magnitude. 0 is a proper 0 amount.\n\n"..
			"Because it uses ITexture / VTF, it doesn't link up with pac materials. Animated textures must be done by frames instead of proxies. Although you can still set a custom image. But it's additive so the transparency can't be done with alpha, but on a black background\t"..
			"fov on one hand, and horizontal/vertical fovs on the other hand, compete; so you should touch only one and leave the other."
		},

		["hitscan"] = {
			tooltip = "fires bullets",
			popup_tutorial =
			"This part tries to fire bullets. There are damaging serverside bullets and non-damaging clientside bullets. Both could be useful in their own scenarios.\n"..
			"For serverside bullets, the server might restrict that. For example, it can force you to spread your damage among all your bullets, to notably prevent you from stacking tons of bullets to multiply your damage beyond the limit.\n"..
			"Damage falloff works with a fractional floor on individual bullets, which means each bullet is lowered to a percentage of its max damage."
		},

		["motion_blur"] = {
			tooltip = "makes a trail of after-images",
			popup_tutorial =
			"This part continually renders a series of ghost copies of your model along its path to simulate a motion blur-like effect.\n"..
			"It has limited options because of how models' clientside entity is set up, allegedly."
		},

		["link"] = {
			tooltip = "transfers variables between parts",
			popup_tutorial =
			"This part tries to copy variables between two parts and update them when their values change.\n"..
			"It doesn't work for all variables especially booleans! Also, \"link\" is a strong word. Whatever you think it means, it's not doing that."..
			"Might require a rewear to work properly."
		},

		["effect"] = {
			tooltip = "runs a PCF effect",
			popup_tutorial =
			"This part uses an existing PCF effect on your game installation, from your mounted games or addons. No importable PCFs from the web.\n"..
			"It apparently can use control points and make tracers work. It may or may not be supported by different effects; start by putting the effect in a basic model to position the effect.\n"..
			"And PCF effects can be a gigantic pain, with for example looping issues, permanence issues (BEWARE OF TF2 UNUSUAL EFFECTS!), wrong positions etc."..
			"You should probably look into particles and think about how to layer them if you're looking for something more configurable."
		},

		["text"] = {
			tooltip = "draws 3D2D or 2D text",
			popup_tutorial =
			"This part renders text on a flat surface (3D2D with the DrawTextOutlined mode) or on the screen (2D with the SurfaceText mode). Due to technical limitations, some features in one may not be present in the other, such as the outline and the size scaling\n\n"..
			"You can use a combination of data and text to build up your text. Combined text tells the part to use both, and text position tells you whether the text is before or after the data.\n"..
			"What's this data? text override. There are a handful of presets, like your health, name, position. If you want more control, you can use Proxy, and it will use the dynamic text value (a simple number variable) which you can control with proxies.\n\n"..
			"If you want to raise the resolution of the text, you should try making a bigger font. But creating fonts is expensive so it's throttled. You can only make one every 3 seconds.\n"..
			"Although you can use any of gmod's or try to use your operating system's font names, there are still limits to fonts' features, both in their definitions and in the lua code. Not everything will work. But it will create a unique ID for the font it creates, and you can reuse that font in other text parts."
		},

		["camera"] = {
			tooltip = "changes your view",
			popup_tutorial =
			"This part runs a CalcView hook to allow you to go into a third person mode and change your view accordingly. Some parts on your player may get in the way.\n"..
			"eye angle lerp determines how much you mix the original eye angles into the view. Otherwise at 0 it will fully use the part's local angles.\n"..
			"Remember a right hand rule! Point forward, thumb up, middle finger perpendicular to the palm. This is how the camera will look with 0 lerp.\n"..
			"\tX = Red  = index finger  = forward\n"..
			"\tY = Green= middle finger = left\n"..
			"\tZ = Blue = thumb finger  = up\n"..
			"As an example, if you apply this, you will learn that, on the head, you can simply take a 0,-90,-90 angle value and be done with it.\n\n"..
			"Because of how pac3 works, you should be careful when toggling between cameras. I've made some fixes to prevent part of that, but if you hide with events, and lose your final camera, you can't come back unless you go back to third person (to restart the cameras) and then back into first person (to put priority back on an active camera)."
		},

		["decal"] = {
			tooltip = "applies decals",
			popup_tutorial =
			"Decals are a Source engine thing for bullet holes, sprays and other such flat details as manholes and posters. This part when shown emits one by tracing a line forward and applying it at the hit surface.\n"..
			"It can use web images and pac materials, but still subject to rendering quirks depending on transparency and others.\n"..
			"Decals are semi-permanent, you can only remove them with r_cleardecals"
		},

		["projectile"] = {
			tooltip = "throws missiles into the world",
			popup_tutorial =
			"the projectile part creates physical entities and launches them forward.\n"..
			"the entity has physics but it can be clientside (visual) or serverside (physical)\n"..
			"by selecting an outfit part, the entity can bear a PAC3 part or group to have a PAC3 outfit of its own\n"..
			"the entity can do damage but servers can restrict that.\n"..
			"For visual reference, a 1x1x1 cubeex is around radius 24, and a default pac sphere is around 8."
		},

		["poseparameter"] = {
			tooltip = "sets a pose parameter",
			popup_tutorial =
			"pose parameters are a Source engine thing that helps models animate using a \"blend sequence\". For instance, this is how the body and head are rotated, and how 8-way walks are blended.\n"..
			"It goes without saying that not all models have those, and some have fewer supported pose parameters because of how they were made."
		},

		["entity"] = {
			tooltip = "edits an entity (legacy)",
			popup_tutorial = "The legacy entity part still does the usual things you need to edit your entity. Color, model, size, no draw etc. But better use the new entity part."
		},

		["entity2"] = {
			tooltip = "edits an entity",
			popup_tutorial =
			"This part can edit some properties of an entity. This can be your playermodel, a pac3 model (it's a clientside entity) or a prop (you give a prop a pac outfit by selecting it with the owner name on a root group).\n"..
			"It supports web models. See the model part's tutorial or read the MDL zips page on our wiki for further info.\n\n"..
			"As with other bone-related things, it might not work properly if you use it on a ragdoll or some similar entities.\n\n"..
			"Another warning in advance, if you wonder why your playermodel won't change, there are some addons, such as Enhanced Playermodel Selector, known to cause issues because they override your entity, thus conflicting with pac3. This one can be fixed if you disable \"enforce playermodel\"\n"..
			"Other than that, the server setting pac_modifier_model and pac_modifier_size can forbid you from changing your playermodel and size respectively."
		},

		["interpolated_multibone"] = {
			tooltip = "morphs position between nodes",
			popup_tutorial =
			"A node-based path/morpher. This part allows you to move its contents by blending positions and angles between different points. Obviously enough, the nodes you select need to be base_movable parts.\n"..
			"The first (Zeroth) node is the interpolated_multibone itself. From then on, the next node is reached when lerp reaches the corresponding number, and when you're at the end, i.e. an invalid or missing node, it morphs back to the origin.\n"..
			"For example, 0.5 lerp will be halfway between the first node and the origin.\n"..
			"While this part finally breaks through one of pac3's fundamental limitations (that of base_movables being limited to specific bones as anchoring points), there are still known issues, namely because of how angles are morphed. Roll angles might break.\n\n"..
			"Suggested use cases: multi-position cutscene camera, returning hitpos pseudo-projectile, joints."
		},

		["proxy"] = {
			tooltip = "applies math to parts",
			popup_tutorial =
			"This part computes math and applies the numbers it gives to a parameter on a part, for number (x), vector (x,y,z) or boolean(true (1) or false (0)) types.  It can send to the parent, to all its children, or to an external target part.\n"..
			"Easy setup can help you make a rough idea quickly, but writing math yourself in the expression gives supremely superior control over what the math does.\n\n"..
			"Here's a quick crash course in the syntax with basic examples showing the rules to observe:\n\n"..
			"Basic numbers /math operators : 4^0.5 - 2*(0.2 / 5) + timeex()%4\n"..
			"The only basic operators are: + - * / % ^\n"..
			"Functions:\n"..
			"\tFunctions are like variables that gather data from the world or that process math.\n"..
			"\tMost functions are nullary, which means they have no argument: timeex(), time(), owner_health(), owner_armor_fraction()\n"..
			"\tOthers have arguments, which can be required or optional: clamp(x,min,max), random(), random(min,max), random_once(seed,min,max), etc.\n"..
			"\tAll Lua functions are declared by a set of parentheses containing arguments, possibly separated by commas.\n"..
			"Arguments and tokens:\n"..
			"\tMost arguments\' type is numbers, but some might be strings with some requirements; Most of the time it\'s a name or a part UID, for example:\n"..
			"\tValid number arguments are numbers, functions or well-formed expressions. It\'s the same type because at the end of the day it gives you a number.\n"..
			"\t\tNeedless to say, if you compose an expression, you need a coherent link between the tokens (i.e. math operators or functions). 2 + 2 is valid, 2 2 is not.\n"..
			"\tValid string arguments are text declared by double quotes. Lua\'s string concatenation operator works. command(\"name\"..2) is the same as command(\"name2\")\n"..
			"\t\tWithout the string declaration, Lua tries to look for a global variable. command(\"name\") is valid, command(name) is not.\n\n"..
			"Nested functions (composition) : clamp(1 - timeex()^0.5,0,1)\n"..
			"XYZ / Vectors (comma notation) : 100,0,50\n"..
			"nil (skipping an axis) : 100,nil,0\n\n"..
			"You can write pretty much any math using the existing functions as long as you observe the syntax\'s rules: the most common ones being to close your brackets properly, don't misspell your functions\' names and give them all their necessary arguments.\n\n"..
			"There are lots of technical things to learn, but you can consult my example proxy bank by right clicking the expression field, and go consult our wiki for reference. https://wiki.pac3.info/part/proxy\n\n"..
			"As a conclusion, I\'m gonna editorialize and give my recommendations:\n"..
			"\t-Write with purpose. Avoid unnecessary math.\n"..
			"\t\t->But still, write in a way that lets you understand the concept better.\n"..
			"\t-More to the point, please have patience and deliberation. Make sure every piece works BEFORE moving on and making it more complex.\n"..
			"\t-The fundamental mechanism of developing and applying new ideas is composition / compounding.\n"..
			"\t\t->Multiplying different expression bits together tends to combine the concepts\n"..
			"\t\t->e.g. clamp(0.2*timeex(),0,1)*sin(10*time()) is a fadein and a sine wave. What do you get? sine wave fading to full power.\n"..
			"\t-Please read the debug messages in the console or in chat, they help the correction process if we make mistakes."

		},

		["sunbeams"] = {
			tooltip = "shines like rays of light",
			popup_tutorial =
			"This part applies a sunbeam effect centered around the part.\n"..
			"Multiplier is the strength of the effect. It can also be negative for engulfing darkness.\n"..
			"Darken is how much to darken or brighten the whole effect. It helps control the contrast in conjunction with multiplier. With enough darken, only the brightest rays will go through, otherwise with unchecked multipliers or negative darken there's a whole blob of white that just overpowers everything\n"..
			"Size affects the after-images projected around the center, which serve as a base for the effect."
		},

		["shake"] = {
			tooltip = "shakes nearby viewers\' camera",
			popup_tutorial =
			"This part applies a shake that uses the camera\'s position to take effect. For that reason, it may be nullified by certain third person addons, as well as the pac3 editor camera. You can still temporarily disable it to preview your shakes."
		},

		["gesture"] = {
			tooltip = "plays a gesture",
			popup_tutorial =
			"Gestures are a type of animation usually added as a layer on top of other animations, this part tries to play one but not all animations listed are gestures, so it might not work for most."
		},

		["damage_zone"] = {
			tooltip = "deals damage in a zone",
			popup_tutorial =
			"This part tries to deal hitbox damage via the server. It may or may not be allowed because of server settings (pac_sv_damage_zone) and client consents (pac_client_damage_zone_consent), etc. Server owners can add or remove entity classes that can be damaged with pac_damage_zone_blacklist_entity_class, pac_damage_zone_whitelist_entity_class commands.\n"..
			"Among NPCs it should include VJ and DRG base NPCs, but only if they have npc_ or drg_ in their name\n"..
			"Most shapes should be self-explanatory but you can use the preview function to see what it should cover. There are some settings for raycasts which could come in handy for some niche use cases even if the basic ones you'll use most of the time (box, sphere, cone from spheres, ray) will not really use these."..
			"There are certain special damage types. the dissolves can disintegrate entities but can be restricted in the server, prevent_physics_force suppresses the corpse force, removenoragdoll removes the corpse.\n"..
			""
		},

		["health_modifier"] = {
			tooltip = "modifies your health, armor",
			popup_tutorial =
			"This part allows you to quickly change your max health, max armor, damage multiplier taken, and has the possibility to give you extra health bars that absorb damage before the main health gets damaged.\n"..
			"For the extra bars, you need to set a layer priority to pick which ones get damaged first. Outer ones are higher layer values. But they're still invisible for now... events and proxies will come later...\n"..
			"The part's usage may or may not be allowed by the server."
		}

	}
	--print("we have defined the pace.TUTORIALS.PartInfos", pace.TUTORIALS.PartInfos)

	for i,v in pairs(pace.TUTORIALS.PartInfos) do
		--print(i,v)
		if pace.PartTemplates then
			if pace.PartTemplates[i] then
				pace.PartTemplates[i].TutorialInfo = v
			end
		end
	end
end


