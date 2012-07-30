local urlmat = pac.urlmat or {}

urlmat.TextureSize = 1024
urlmat.ActivePanel = urlmat.ActivePanel or NULL
urlmat.Queue = urlmat.Queue or {}

if urlmat.ActivePanel:IsValid() then
	urlmat.ActivePanel:Remove()
end

function urlmat.GetMaterialFromURL(url, callback)	
	if urlmat.Queue[url] then
		local old = urlmat.Queue[url].callback
		urlmat.Queue[url].callback = function(...)	
			callback(...)
			old(...)
		end
	else
		urlmat.Queue[url] = {callback = callback, tries = 0}
	end
end

function urlmat.Think()
	if table.Count(urlmat.Queue) > 0 then
		for url, data in RandomPairs(urlmat.Queue) do
			-- when the panel is gone start a new one
			if not urlmat.ActivePanel:IsValid() then
				urlmat.StartDownload(url, data)
			end
		end
	end
end

timer.Create("urlmat_queue", 0.1, 0, urlmat.Think)

function urlmat.StartDownload(url, data)

	if urlmat.ActivePanel:IsValid() then
		urlmat.ActivePanel:Remove()
	end

	local id = "urlmat_download_" .. url
	
	local pnl = vgui.Create(not _BETA and "HTML" or "DHTML")
	pnl:SetVisible(true)
	pnl:SetPos(ScrW(), ScrH())
	pnl:SetSize(urlmat.TextureSize, urlmat.TextureSize)
	pnl:SetHTML(
		[[
			<style type="text/css">
				html 
				{			
					overflow:hidden;
					background-color:black;
				}
			</style>
			
			<body>
				<img src="]] .. url .. [[" alt="" width="]] .. urlmat.TextureSize..[[" height="]] .. urlmat.TextureSize .. [[" />
			</body>
		]]
	)
		
	function pnl.FinishedURL()
	
		-- restart the timeout
		timer.Stop(id)
		timer.Start(id)
		
		hook.Add("Think", id, function()
		
			-- panel is no longer valid
			if not pnl:IsValid() then
				hook.Remove("Think", id)
				-- let the timeout handle it
				return
			end
			
			local html_mat = pnl:GetHTMLMaterial()
			
			if html_mat then
				local vertex_mat = CreateMaterial(url, "VertexLitGeneric")
				local tex = html_mat:GetMaterialTexture("$basetexture")
				tex:Download()
				vertex_mat:SetMaterialTexture("$basetexture", tex)
				
				hook.Remove("Think", id)
				timer.Remove(id)
				urlmat.Queue[url] = nil
				pnl:Remove()
				
				if data.callback then
					data.callback(vertex_mat)
				end
			end
			
		end)
	end
	
	-- 5 sec max timeout
	timer.Create(id, 5, 1, function()
		timer.Remove(id)
		urlmat.Queue[url] = nil
		pnl:Remove()
		
		if hook.GetTable().Think[id] then
			hook.Remove("Think", id)
		end

		if data.tries < 3 then
			pac.dprint("material download %q timed out.. trying again for the %ith time", url, data.tries)
			-- try again
			data.tries = data.tries + 1
			urlmat.GetMaterialFromURL(url, data)
			urlmat.Queue[url] = data
		else
			pac.dprint("material download %q timed out for good", url, data.tries)
		end
	end)
	
	urlmat.ActivePanel = pnl
end

pac.urlmat = urlmat