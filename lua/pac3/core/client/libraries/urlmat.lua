local urlmat = pac.urlmat or {}

urlmat.TextureSize = 1024
urlmat.RT = urlmat.RT or GetRenderTarget("urlmat_rt", urlmat.TextureSize, urlmat.TextureSize, false)
urlmat.Panels = urlmat.Panels or {}

function urlmat.Panic()
	for id, pnl in pairs(urlmat.Panels) do
		if pnl:IsValid() then
			pnl:Remove()
		end
		
		timer.Remove(id)
	end
end	

function urlmat.GetMaterialFromURL(url, callback, texture_only, shader_params)
	local id = "html_material_" .. url
	
	if urlmat.Panels[id] and urlmat.Panels[id]:IsValid() then
		urlmat.Panels[id]:Remove()
	end
	
	local pnl= vgui.Create("HTML")
	urlmat.Panels[id] = pnl
	pnl:SetPaintedManually(true)
	pnl:SetPos(ScrW(),ScrH())
	pnl:SetSize(urlmat.TextureSize, urlmat.TextureSize)
	pnl:SetHTML([[
		<style type="text/css">
		html {			
			-webkit-transform: matrix(1, 0, 
								  0, 1, 
								  0, 0);
								  
			background-color:rgb(0,0,0);
			
			overflow:hidden;
		}
		
		</style>

		<body>
			<img src="]] .. url .. [[" alt="" width="]]..urlmat.TextureSize..[[" height="]]..urlmat.TextureSize..[[" />
		</body>
	]])
	
	pac.dprint("loading material %q", url)
	function pnl.FinishedURL()
		pac.dprint("finished loading material %q", url)

		local i = 0
		timer.Create(id, 0, 200, function()
			
			-- timeout
			if i == 200 then
				if pnl:IsValid() then
					pnl:Remove()
				end
				
				timer.Remove(id)
				urlmat.Panels[id] = nil
				return
			end
			
			-- panel is no longer valid
			if not pnl:IsValid() then
				timer.Remove(id)
				urlmat.Panels[id] = nil
				return
			end
			
			local mat = pnl:GetHTMLMaterial()	
			local tex
			if mat then
				if texture_only then
					callback(mat:GetMaterialTexture("$basetexture"))
				else								
					local newmat = CreateMaterial(name or id, "VertexLitGeneric", shader_params)
					newmat:SetMaterialTexture("$basetexture", mat:GetMaterialTexture("$basetexture"))
					
					callback(newmat)
					
					pac.dprint("got material %q", url)
				end
				
				pnl:Remove()
				timer.Remove(id)
				urlmat.Panels[id] = nil
			end
			
			i = i + 1
		end)
	end

	timer.Simple(20, function()
		if pnl:IsValid() then
			pac.dprint("material %q timed out", url)
			pnl:Remove()
			urlmat.Panels[id] = nil
		end
	end)
end

urlmat.Panic()

pac.urlmat = urlmat