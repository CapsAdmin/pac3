local urlmat = pac.urlmat or {}

urlmat.TextureSize = 1024
urlmat.ActivePanel = urlmat.ActivePanel or NULL
urlmat.Queue = urlmat.Queue or {}
urlmat.Cache = urlmat.Cache or {}

if urlmat.ActivePanel:IsValid() then
	urlmat.ActivePanel:Remove()
end

function urlmat.GetMaterialFromURL(url, callback, skip_cache)
	if type(callback) == "function" and not skip_cache and urlmat.Cache[url] then
		local tex = urlmat.Cache[url]
		local vertex_mat = CreateMaterial("pac3_urlmat_" .. util.CRC(url .. SysTime()), "VertexLitGeneric")
		vertex_mat:SetMaterialTexture("$basetexture", tex)
		callback(vertex_mat, tex)
		return
	end
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
		urlmat.Busy = true
	else
		urlmat.Busy = false
	end
end

timer.Create("urlmat_queue", 0.1, 0, urlmat.Think)

function urlmat.StartDownload(url, data)

	if urlmat.ActivePanel:IsValid() then
		urlmat.ActivePanel:Remove()
	end

	local id = "urlmat_download_" .. url
	
	local pnl = vgui.Create("HTML")
	pnl:SetVisible(true)
	--pnl:SetPos(50,50)
	pnl:SetPos(ScrW()-1, ScrH()-1)
	pnl:SetSize(urlmat.TextureSize, urlmat.TextureSize)
	pnl:SetHTML(
		[[
			<style type="text/css">
				html 
				{			
					overflow:hidden;
					margin: -8px -8px;
				}
			</style>
			
			<body>
				<img src="]] .. url .. [[" alt="" width="]] .. urlmat.TextureSize..[[" height="]] .. urlmat.TextureSize .. [[" />
			</body>
		]]
	)
	

	local function start()
		local go = false
		local time = 0

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
					
			-- give it some time.. IsLoading is sometimes lying
			if not go and html_mat and not pnl:IsLoading() then
				time = RealTime() + 0.25
				go = true
			end
				
			if go and time < RealTime() then
				local vertex_mat = CreateMaterial("pac3_urlmat_" .. util.CRC(url .. SysTime()), "VertexLitGeneric")
				
				local tex
				
				if VERSION >= 150 then
					tex = html_mat:GetTexture("$basetexture")
					tex:Download()
					vertex_mat:SetTexture("$basetexture", tex)
				else
					tex = html_mat:GetMaterialTexture("$basetexture")
					vertex_mat:SetMaterialTexture("$basetexture", tex)
				end
				
				tex:Download()
				
				urlmat.Cache[url] = tex
				
				hook.Remove("Think", id)
				timer.Remove(id)
				urlmat.Queue[url] = nil
				timer.Simple(0.15, function() pnl:Remove() end)
								
				if data.callback then
					data.callback(vertex_mat, tex)
				end
			end
			
		end)
	end

	if VERSION >= 150 then
		start()
	else
		pnl.FinishedURL = start
	end
	
	-- 5 sec max timeout
	timer.Create(id, 5, 1, function()
		timer.Remove(id)
		urlmat.Queue[url] = nil
		pnl:Remove()
		
		if hook.GetTable().Think[id] then
			hook.Remove("Think", id)
		end

		if data.tries < 5 then
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