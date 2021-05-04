
local function list(mid, name, store, populate)
	local list = vgui.Create("DListView", mid)
	list:AddColumn(name)

	function list:Refresh()
		self:Clear()

		self.data = populate()

		for _, kv in ipairs(self.data) do
			self:AddLine(kv.name)
		end
	end

	function list:Store()
		for _, line in ipairs(list:GetSelected()) do
			local i = line:GetID()
			local kv = self.data[i]
			if kv then
				store(kv)
			end
		end
	end

	function list:Populate()
		self:Clear()
		self.data = populate()
	end

	list:Refresh()

	return list
end

return function(form, name, props)
	local pnl = vgui.Create("Panel", form)
	pnl:SetTall(200)

	pnl.left = list(pnl, props.name_left, props.store_left, props.populate_left)
	pnl.right = list(pnl, props.name_right, props.store_right, props.populate_right)

	local button = vgui.Create("DButton", pnl)
	button:SetText(props.empty_message)

	local store = function() end
	local selected_side = pnl.left

	pnl.left.OnRowSelected = function()
		pnl.right:ClearSelection()
		store = function() pnl.left:Store() end
		button:SetText("add to " .. name)
	end

	pnl.right.OnRowSelected = function()
		pnl.left:ClearSelection()
		store = function() pnl.right:Store() end
		button:SetText("remove from " .. name)
	end

	local function select()
		if #pnl.left:GetLines() == 0 then
			selected_side = pnl.right
		end

		if #pnl.right:GetLines() == 0 then
			selected_side = pnl.left
		end

		selected_side:SelectFirstItem()
	end

	button.DoClick = function()
		store()

		pnl.left:Refresh()
		pnl.right:Refresh()

		select()
	end

	select()

	pnl.Think = function()
		local p = 5
		local w = pnl:GetWide() / 2
		local h = pnl:GetTall() - button:GetTall() - p

		pnl.left:SetWide(w)
		pnl.left:SetTall(h)

		pnl.right:SetWide(w + 1)
		pnl.right:SetTall(h)

		pnl.right:MoveRightOf(pnl.left, -1)

		button:MoveBelow(pnl.left, p)
		button:CopyWidth(pnl)
	end
end