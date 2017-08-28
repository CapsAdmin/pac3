local urltex = pac.urltex or {}

urltex.TextureSize = 1024
urltex.ActivePanel = urltex.ActivePanel or NULL
urltex.Queue = urltex.Queue or {}
urltex.Cache = urltex.Cache or {}

concommand.Add("pac_urltex_clear_cache", function()
	urltex.Cache = {}
	urltex.Queue = {}
end)

if urltex.ActivePanel:IsValid() then
	urltex.ActivePanel:Remove()
end

local enable = CreateClientConVar("pac_enable_urltex", "1", true)
local EMPTY_FUNC = function() end

function urltex.GetMaterialFromURL(url, callback, skip_cache, shader, size, size_hack, additionalData)
	if size_hack == nil then
		size_hack = true
	end

	additionalData = additionalData or {}
	shader = shader or "VertexLitGeneric"
	if not enable:GetBool() then return end

	url = pac.FixupURL(url)

	if type(callback) == "function" and not skip_cache and urltex.Cache[url] then
		local tex = urltex.Cache[url]
		local mat = CreateMaterial("pac3_urltex_" .. util.CRC(url .. SysTime()), shader, additionalData)
		mat:SetTexture("$basetexture", tex)
		callback(mat, tex)
		return
	end

	callback = callback or EMPTY_FUNC

	if urltex.Queue[url] then
		table.insert(urltex.Queue[url].callbacks, callback)
	else
		urltex.Queue[url] = {
			callbacks = {callback},
			tries = 0,
			size = size,
			size_hack = size_hack,
			shader = shader,
			additionalData = additionalData
		}
	end
end

function urltex.Think()
	if table.Count(urltex.Queue) > 0 then
		for url, data in pairs(urltex.Queue) do
			-- when the panel is gone start a new one
			if not urltex.ActivePanel:IsValid() then
				urltex.StartDownload(url, data)
			end
		end
		urltex.Busy = true
	else
		urltex.Busy = false
	end
end

timer.Create("urltex_queue", 0.1, 0, urltex.Think)

function urltex.StartDownload(url, data)

	if urltex.ActivePanel:IsValid() then
		urltex.ActivePanel:Remove()
	end

	local size = data.size or urltex.TextureSize
	local id = "urltex_download_" .. url
	local pnl

	local function createDownloadPanel()
		pnl = vgui.Create("DHTML")
		-- Tested in PPM/2, this code works perfectly
		pnl:SetVisible(false)
		pnl:SetSize(size, size)
		pnl:SetHTML(
			[[
				<style type="text/css">
					html
					{
						overflow:hidden;
						]] .. (data.size_hack and "margin: -8px -8px;" or "margin: 0px 0px;") .. [[
					}
				</style>

				<body>
					<img src="]] .. url .. [[" alt="" width="]] .. size..[[" height="]] .. size .. [[" />
				</body>
			]]
		)
		pnl:Refresh()
		urltex.ActivePanel = pnl
	end

	local go = false
	local time = 0
	local timeoutNum = 0
	local think

	local function onTimeout()
		timeoutNum = timeoutNum + 1
		if IsValid(pnl) then pnl:Remove() end

		if timeoutNum < 5 then
			pac.dprint("material download %q timed out.. trying again for the %ith time", url, timeoutNum)
			-- try again
			go = false
			time = 0
			createDownloadPanel()
		else
			pac.dprint("material download %q timed out for good", url, timeoutNum)
			hook.Remove("Think", id)
			timer.Remove(id)
			urltex.Queue[url] = nil
		end
	end

	function think()
		-- panel is no longer valid
		if not pnl:IsValid() then
			onTimeout()
			return
		end

		-- give it some time.. IsLoading is sometimes lying
		if not go and not pnl:IsLoading() then
			time = pac.RealTime + 0.1
			go = true
		end

		if go and time < pac.RealTime then
			pnl:UpdateHTMLTexture()
			local html_mat = pnl:GetHTMLMaterial()

			if html_mat then
				local vertex_mat = CreateMaterial("pac3_urltex_" .. util.CRC(url .. SysTime()), data.shader, data.additionalData)

				local tex = html_mat:GetTexture("$basetexture")
				tex:Download()
				vertex_mat:SetTexture("$basetexture", tex)
				-- tex:Download()

				urltex.Cache[url] = tex

				hook.Remove("Think", id)
				timer.Remove(id)
				urltex.Queue[url] = nil
				timer.Simple(0, function() pnl:Remove() end)

				if data.callbacks then
					for i, callback in pairs(data.callbacks) do
						callback(vertex_mat, tex)
					end
				end
			end
		end
	end

	hook.Add("Think", id, think)

	-- 5 sec max timeout, 5 maximal timeouts
	timer.Create(id, 5, 5, onTimeout)
	createDownloadPanel()
end

pac.urltex = urltex