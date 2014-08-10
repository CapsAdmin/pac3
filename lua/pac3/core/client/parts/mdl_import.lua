if file.Exists("lua/bin/gmcl_vfs_win32.dll","GAME") or 
   file.Exists("lua/bin/gmcl_vfs_linux.dll","GAME") or 
   file.Exists("lua/bin/gmcl_vfs_osx.dll","GAME") then
	require("vfs")
	hook.Add("pac.net.PlayerInitialSpawn","pac_vfsnotify",function()
		pac.setHasVfs(true)
		pac.requestVfsStatus()
	end)
else
	Msg("[PAC3] VFS Module not installed. mdl_import part will not function.")
	hook.Add("pac.net.PlayerInitialSpawn","pac_vfsnotify",function()
		pac.setHasVfs(true)
		pac.requestVfsStatus()
	end)
end
 

local PART = {}

PART.ClassName = "mdl_import"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
	pac.GetSet(PART, "IncludePhy", false)
pac.EndStorableVars()

local function HexMdlFile(mdlfile,newpath)
	local filler = string.char(00)
	filler = filler:rep(0x40)
	
	mdlfile:Seek(0x0C, VFS_SEEK_SET)
	mdlfile:Write(VFS_WRITE_STRING,filler)
	
	mdlfile:Seek(0x0C, VFS_SEEK_SET)
	mdlfile:Write(VFS_WRITE_STRING,newpath)
end

function PART:GetNiceName()
	return string.GetFileFromFilename(self:GetURL()) or "no mdl"
end

function PART:GetModelPath(ext,url,prefix)
	local filename = string.GetFileFromFilename(url)
	if prefix then
		return "models/pac_import/"..self:GetUniqueID()..filename.."."..ext
	else
		return "pac_import/"..self:GetUniqueID()..filename.."."..ext
	end
end

function PART:SetParentModel(path)
	local parent = self:GetParent()
	if parent:IsValid() and parent.GetModel then
		parent:SetModel(path,true)
		parent.loading_obj = false
	end
end

function PART:SetURL(url)
	local parent = self:GetParent()
	parent.has_mdl_import_child = true
	
	if not vfs then 
		if self:GetOwner() == LocalPlayer() then
			LocalPlayer():ChatPrint("[PAC3] You must install the VFS binary module to use the mdl_import part.")
		end
		return 
	end
	if not string.find(url,"http") then return end
	
	local replacements = {"%.mdl","%.vvd","%.dx80%.vtx","%.dx90%.vtx","%.sw%.vtx","%.phy"}
	for _,patt in pairs(replacements) do
		url = string.gsub(url,patt,"")
	end
	
	self.URL = url
	
	local exttbl = {"mdl","sw.vtx","dx90.vtx","dx80.vtx","vvd"}
	
	local extrequires = {}
	extrequires["mdl"] = "IDST"
	extrequires["phy"] = "VPHY"
	extrequires["vvd"] = "IDSV"
	
	if self.IncludePhy then 
		table.insert(exttbl,"phy")
	end
	
	local uid = self:GetUniqueID()
	parent.loading_obj = "downloading mdl"
	
	local processedfiles = 0
	
	for _,ext in pairs(exttbl) do
		http.Fetch(url.."."..ext,
		function(mdlstr,length,header,code)
			if code ~= 200 then
				Msg	"[PAC3] " print("Download failed: "..url.."."..ext.." (UID:"..uid..") Error code "..code)
				return
			end
			local modelpath = self:GetModelPath(ext,url,true)
			
			if !(file.Exists(modelpath,"GAME")) then
				local pass = true
				if extrequires[ext] and !string.find(mdlstr,extrequires[ext]) then pass = false end
				if pass then
					local extfile = vfs.Open(modelpath,"wb")
					extfile:Write(VFS_WRITE_DATA,mdlstr,length)
					
					if ext == "mdl" then
						HexMdlFile(extfile,self:GetModelPath("mdl",url))
					end
					
					timer.Create("pac_mdl_import_"..uid..ext,1,0,function()
						local filesize = file.Size(modelpath,"GAME")
						if filesize >= length then
							processedfiles = processedfiles + 1
							timer.Remove("pac_mdl_import_"..uid..ext)
						end
					end)
				else
					Msg"[PAC3] " print("WARNING: mdl_import "..uid.." did not pass file validation check.")
					processedfiles = processedfiles + 1
				end
				
			else
				Msg"[PAC3] " print("WARNING: Not writing "..uid.." because file exists.")
				processedfiles = processedfiles + 1
			end
		end,
		function(error)
			Msg"[PAC3] " print("ERROR: "..url.."."..ext.." failed to download. (UID:"..uid..") Error code "..error)
			processedfiles = processedfiles + 1
		end)
	end
	
	timer.Create("pac_mdl_import_"..uid,1,0,function()
		if (processedfiles == #exttbl) then
			--Msg"[PAC3] " print("mdl_import download for "..uid.." complete!")
			util.PrecacheModel(self:GetModelPath("mdl",url,true))
			self:SetParentModel(self:GetModelPath("mdl",url,true))
			timer.Remove("pac_mdl_import_"..uid)
		else
			--Msg"[PAC3] " print("mdl_import download for "..uid.." in progress...")
		end
	end)
end

function PART:OnRemove()
	local uid = self:GetUniqueID()
	timer.Remove("pac_mdl_import_"..uid)
	
	local exttbl = {"mdl","sw.vtx","dx90.vtx","dx80.vtx","vvd"}
	if self.IncludePhy then 
		table.insert(exttbl,"phy")
	end
	for _,ext in pairs(exttbl) do
		timer.Remove("pac_mdl_import_"..uid..ext)
	end
end

pac.RegisterPart(PART)

local function RemoveImportedModels()
	if not vfs then return end
	local files,dirs = file.Find("/models/pac_import/*","GAME")
	for _,filename in pairs(files) do
		vfs.RemoveFile(filename)
	end
end

concommand.Add("pac_remove_imported_models",RemoveImportedModels)
