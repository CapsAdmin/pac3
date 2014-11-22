--vfs (module) stuff

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
		pac.setHasVfs(false)
		pac.requestVfsStatus()
	end)
end

function vfs.Download(url,fullpath,complete)
	if not vfs then return end
    if not fullpath then fullpath = "downloads/"..string.GetFileFromFilename(url) end
    http.Fetch(url,function(body,len,headers,code)
        local file_handle = vfs.Open(fullpath,"wb")
        file_handle:Write(VFS_WRITE_DATA,body,len)
        file_handle:Close()
		if complete then complete(fullpath) end
    end,function(err)
		
    end)
end

function vfs.DownloadJSONArchive(url,func)
	local fullpath = "downloads/temp/"..string.GetFileFromFilename(url)
	vfs.Download(url,fullpath,function(path)
		vfs.JSONExtract(file.Read(path,"GAME"),true)
		vfs.RemoveFile(fullpath)
		if func then func() end
	end)
end

local function serialize_string(str)
	local out = {}
	local i = 1
	while i <= str:len() do
		out[#out+1] = tostring(tonumber(str:byte(i)))
		i = i + 1
	end
	return table.concat(out," ")
end

local function deserialize_string(str)
	local out = {}
	for num in string.gmatch(str, "%d+") do 
		out[#out+1] = string.char(tonumber(num))
	end
	return table.concat(out)
end

function vfs.JSONCompress(tbl,out)
	local container = {}
	for _,filename in pairs(tbl) do
		local file_contents = file.Read(filename,"GAME")
		container[filename] = serialize_string(file_contents)
	end
	local container_json = util.TableToJSON(container)
	if out and vfs then
		local file_handle = vfs.Open(out,"wb")
		file_handle:Write(VFS_WRITE_DATA,container_json,container_json:len())
		file_handle:Close()
	else
		return container_json
	end
end

function vfs.JSONExtract(container_json,safe)
	if not vfs then return false end
	local tbl = util.JSONToTable(container_json)
	for filename,filedata in pairs(tbl) do
		filedata = deserialize_string(filedata)
		
		if safe then
			local whitelist = {"mdl","vtx","vvd","phy","vmt","vtf"}
			local pass = false
			for _,ext in pairs(whitelist) do
				pass = pass or (fullpath:sub(-3) == ext)
			end
			if not pass then return end
		end
		
		local file_handle = vfs.Open(filename,"wb")
		file_handle:Write(VFS_WRITE_DATA,filedata,filedata:len())
		file_handle:Close()
	end
end

--vfs (part) stuff

local PART = {}

PART.ClassName = "vfs"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
	pac.GetSet(PART, "ForwardValue", "models/pac/default.mdl")
pac.EndStorableVars()

function PART:GetNiceName()
	return string.GetFileFromFilename(self:GetURL()) or "nothing"
end

function PART:SetURL(url)
	--notify parent
	local uid = self:GetUniqueID()
	local parent = self:GetParent()
	parent.vfs_loading = true
	
	--sanity checks
	if not vfs then 
		if self:GetOwner() == LocalPlayer() then
			LocalPlayer():ChatPrint("[PAC3] You must install the VFS binary module to use the vfs part.")
		end
		return
	end
	if not string.find(url,"http") then return end
	
	self.URL = url
	
	--let's do it
	vfs.DownloadJSONArchive(url,function()
		parent.vfs_loading = nil
		parent:SetModel(self.ForwardValue)
	end)
end

function PART:OnRemove()
	local uid = self:GetUniqueID()
	parent.vfs_loading = nil
end

pac.RegisterPart(PART)
