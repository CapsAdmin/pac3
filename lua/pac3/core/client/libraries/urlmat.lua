local urlmat = pac.urlmat or {}

urlmat.TextureSize = 1024

urlmat.Panels = urlmat.Panels or {}

function urlmat.Panic()
	for id, pnl in pairs(urlmat.Panels) do
		if pnl:IsValid() then
			pnl:Remove()
		end
		
		timer.Remove(id)
	end
end	

function urlmat.GetMaterialFromURL(url, callback, texture_only)
	local id = "html_material_" .. url
	
	if urlmat.Panels[id] and urlmat.Panels[id]:IsValid() then
		urlmat.Panels[id]:Remove()
	end
	
	local pnl= vgui.Create("HTML")
	urlmat.Panels[id] = pnl
	pnl:SetPos(ScrW(),ScrH())
	pnl:SetSize(urlmat.TextureSize, urlmat.TextureSize)
	pnl:SetHTML([[
		<style type="text/css">
		html {			
			background-color:black;
			
			margin-top:0px;
			margin-top:0px;
			margin-top:0px;
			margin-top:0px;
			
			padding-top:0px;
			padding-top:0px;
			padding-top:0px;
			padding-top:0px;
			
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
			if mat then
				if texture_only then
					callback(mat:GetMaterialTexture("$basetexture"))
				else
					local newmat = CreateMaterial(name or id, "VertexLitGeneric", shader_params)
					newmat:SetMaterialTexture("$basetexture", 	mat:GetMaterialTexture("$basetexture"))
				
					callback(newmat)
				end
				
				pac.dprint("got material %q", url)
				
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