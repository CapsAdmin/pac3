pace.util = {}

local surface = surface
local math = math

local white = surface.GetTextureID("gui/center_gradient.vtf")

function pace.util.DrawLine(x1, y1, x2, y2, w, skip_tex)
	w = w or 1
	if not skip_tex then surface.SetTexture(white) end

	local dx,dy = x1-x2, y1 - y2
	local ang = math.atan2(dx, dy)
	local dst = math.sqrt((dx * dx) + (dy * dy))

	x1 = x1 - dx * 0.5
	y1 = y1 - dy * 0.5

	surface.DrawTexturedRectRotated(x1, y1, w, dst, math.deg(ang))
end

function pace.util.FastDistance(x1, y1, z1, x2, y2, z2)
	return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2)
end

function pace.util.FastDistance2D(x1, y1, x2, y2)
	return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

local function isUpperCase(charIn)
	return
		charIn == 'A' or
		charIn == 'B' or
		charIn == 'C' or
		charIn == 'D' or
		charIn == 'E' or
		charIn == 'F' or
		charIn == 'G' or
		charIn == 'H' or
		charIn == 'I' or
		charIn == 'J' or
		charIn == 'K' or
		charIn == 'L' or
		charIn == 'M' or
		charIn == 'N' or
		charIn == 'O' or
		charIn == 'P' or
		charIn == 'Q' or
		charIn == 'R' or
		charIn == 'S' or
		charIn == 'T' or
		charIn == 'U' or
		charIn == 'V' or
		charIn == 'W' or
		charIn == 'X' or
		charIn == 'Y' or
		charIn == 'Z'
end

function pace.util.FriendlyName(strIn)
	local prevChar
	local outputTab = {}
	local iterableArray = string.Explode('', strIn)

	for i, charIn in ipairs(iterableArray) do
		if not prevChar and not isUpperCase(charIn) or prevChar == ' ' and not isUpperCase(charIn) then
			prevChar = string.upper(charIn)
			table.insert(outputTab, prevChar)
		elseif charIn == '_' then
			iterableArray[i] = ' '
			prevChar = ' '
			table.insert(outputTab, ' ')
		elseif isUpperCase(charIn) then
			if prevChar == '_' and (not iterableArray[i + 1] or isUpperCase(iterableArray[i + 1])) then
				if charIn == 'L' then
					prevChar = ' '
					table.insert(outputTab, 'Left ')
				elseif charIn == 'R' then
					prevChar = ' '
					table.insert(outputTab, 'Right ')
				-- elseif charIn == 'O' then
				--	prevChar = ' '
				-- 	table.insert(outputTab, 'Open ') -- i guess?
				else
					prevChar = charIn
					table.insert(outputTab, charIn)
				end
			elseif not isUpperCase(prevChar) then
				prevChar = charIn
				table.insert(outputTab, ' ')
				table.insert(outputTab, charIn)
			else
				prevChar = charIn
				table.insert(outputTab, charIn)
			end
		else
			local condUpper =
				charIn == 'm' and iterableArray[i + 1] == 'p' and iterableArray[i - 1] == ' ' or
				charIn == 'p' and iterableArray[i - 1] == 'm' and iterableArray[i - 2] == ' ' or
				charIn == 'w' and (iterableArray[i - 1] == 'C' or iterableArray[i - 1] == 'c') or
				charIn == 'c' and iterableArray[i + 1] == 'w' or
				charIn == 'i' and (iterableArray[i - 1] == 'C' or iterableArray[i - 1] == 'c') or
				charIn == 'c' and iterableArray[i + 1] == 'i' or
				(charIn == 'x' or charIn == 'y' or charIn == 'z') and not iterableArray[i + 1] and iterableArray[i - 1] == ' '

			if condUpper then
				prevChar = string.upper(charIn)
				table.insert(outputTab, prevChar)
			else
				prevChar = charIn
				table.insert(outputTab, charIn)
			end
		end
	end

	return table.concat(outputTab, '')
end


function pace.MessagePrompt( strText, strTitle, strButtonText )

	local Window = vgui.Create( "DFrame" )
	Window:SetTitle( strTitle or "Message" )
	Window:SetDraggable( false )
	Window:ShowCloseButton( false )
	Window:SetBackgroundBlur( true )
	Window:SetDrawOnTop( true )
	Window:SetSizable(true)
	Window:SetTall(300)
	Window:SetWide(500)
	Window:Center()

	Window.OnRemove = function()
		hook.Remove("Think", "pace_modal_escape")
	end

	hook.Add("Think", "pace_modal_escape", function()
		if input.IsKeyDown(KEY_ESCAPE) then
			if Window:IsValid() then
				Window:Remove()
			end
		end
	end)

	local DScrollPanel = vgui.Create( "DScrollPanel", Window )
	DScrollPanel:Dock( FILL )

	local Text = DScrollPanel:Add("DLabel")
	Text:SetText( strText or "Message Text" )
	Text:SetTextColor( color_white )
	Text:Dock(FILL)
	Text:SetAutoStretchVertical(true)
	Text:SetWrap(true)

	local Button = vgui.Create( "DButton", Window )
	Button:SetText( strButtonText or "OK" )
	Button:Dock(BOTTOM)
	Button:SetTall( 20 )
	Button:SetPos( 5, 5 )
	Button.DoClick = function() Window:Close() end

	Window:MakePopup()
	Window:DoModal()

	Window:PerformLayout()

	return Window
end

function pace.MultilineStringRequest( strTitle, strText, strDefaultText, fnEnter, fnCancel, strButtonText, strButtonCancelText )
	if IsValid(pace.last_modal) then pace.last_modal:Remove() end
	local Window = vgui.Create( "DFrame" )
	pace.last_modal = Window
	Window:SetTitle( strTitle or "Message Title (First Parameter)" )
	Window:SetDraggable( false )
	Window:ShowCloseButton( false )
	Window:SetBackgroundBlur( true )
	Window:SetDrawOnTop( true )
	Window:SetSize(400, 400)

	local InnerPanel = vgui.Create( "DPanel", Window )
	InnerPanel:SetPaintBackground( false )
	InnerPanel:Dock( FILL )

	local Text = vgui.Create( "DLabel", InnerPanel )
	Text:SetText( strText or "Message Text (Second Parameter)" )
	Text:SizeToContents()
	Text:SetContentAlignment( 5 )
	Text:SetTextColor( color_white )
	Text:Dock( TOP )

	local TextEntry = vgui.Create( "DTextEntry", InnerPanel )
	TextEntry:SetText( strDefaultText or "" )
	TextEntry:SetMultiline(true)
	TextEntry:Dock(FILL)
	TextEntry:SetUpdateOnType(true)
	TextEntry.OnChange = function(self) self:SetText(self:GetValue():gsub("\t", "    ")) end
	TextEntry.OnEnter = function() Window:Close() fnEnter( TextEntry:GetValue() ) end

	local ButtonPanel = vgui.Create( "DPanel", Window )
	ButtonPanel:SetTall( 30 )
	ButtonPanel:SetPaintBackground( false )
	ButtonPanel:Dock(BOTTOM)

	local Button = vgui.Create( "DButton", ButtonPanel )
	Button:SetText( strButtonText or "OK" )
	Button:SizeToContents()
	Button:SetTall( 20 )
	Button:SetWide( Button:GetWide() + 20 )
	Button:SetPos( 5, 5 )
	Button.DoClick = function() Window:Close() fnEnter( TextEntry:GetValue() ) end

	local ButtonCancel = vgui.Create( "DButton", ButtonPanel )
	ButtonCancel:SetText( strButtonCancelText or "Cancel" )
	ButtonCancel:SizeToContents()
	ButtonCancel:SetTall( 20 )
	ButtonCancel:SetWide( Button:GetWide() + 20 )
	ButtonCancel:SetPos( 5, 5 )
	ButtonCancel.DoClick = function() Window:Close() if ( fnCancel ) then fnCancel( TextEntry:GetValue() ) end end
	ButtonCancel:MoveRightOf( Button, 5 )

	ButtonPanel:SetWide( Button:GetWide() + 5 + ButtonCancel:GetWide() + 10 )

	Window:MakePopup()
	Window:DoModal()
	Window:Center()

	return Window

end