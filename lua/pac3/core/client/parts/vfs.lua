local verbose = false

local function dprint(...)
	if verbose then print("[PAC3]",...) end
end

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

vfs = vfs or {}

function vfs.Download(url,fullpath,complete)
	if not vfs.Open then return end
    if not fullpath then fullpath = "downloads/"..string.GetFileFromFilename(url) end
    http.Fetch(url,function(body,len,headers,code)
        local file_handle = vfs.Open(fullpath,"wb")
        file_handle:Write(VFS_WRITE_DATA,body,len)
        file_handle:Close()
		if complete then timer.Simple(0.1,function() complete(fullpath) end) end
    end,function(err)
		
    end)
end

function vfs.DownloadJSONArchive(url,func)
	local fullpath = "downloads/temp/"..string.GetFileFromFilename(url)
	vfs.Download(url,fullpath,function(path)
		local entry = vfs.JSONExtract(file.Read(path,"GAME"),true)
		vfs.RemoveFile(fullpath)
		if func then func(entry) end
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

function vfs.JSONCompress(tbl,entry,out,compression)
	local container = {}
	local prepare_string
	if compression then
		if type(compression) == "boolean" then compression = "lzma" end
		prepare_string = function(str) return serialize_string(util.Compress(str)) end
		container.compression = compression
	else
		prepare_string = serialize_string
	end
	for _,filename in pairs(tbl) do
		local file_contents = file.Read(filename,"GAME")
		container[filename] = prepare_string(file_contents)
	end
	container.entry = prepare_string(entry)
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
	local entry = ""
	local tbl = util.JSONToTable(container_json)
	local examine_string
	if tbl.compression then
		local compression = tbl.compression
		if compression == "lzma" then
			examine_string = function(str) return util.Decompress(deserialize_string(str)) end
		else
			print("[PAC3] VFS JSON Extraction Error: Unknown compression method ("..compression..")")
			return
		end
	else 
		examine_string = deserialize_string 
	end
	
	if not tbl.entry then local keycache = {} end
	
	for filename,filedata in pairs(tbl) do
		if keycache then table.insert(keycache,filename) end
		filedata = examine_string(filedata)
		if filename ~= "entry" and filename ~= "compression" then
			dprint("Attempting to create "..filename.."...")
			if safe then
				local whitelist = {"mdl","vtx","vvd","phy","vmt","vtf"}
				local pass = false
				for _,ext in pairs(whitelist) do
					pass = pass or (filename:sub(-3) == ext)
				end
				if not pass then return end
			end
			
			local file_handle = vfs.Open(filename,"wb")
			file_handle:Write(VFS_WRITE_DATA,filedata,filedata:len())
			file_handle:Close()
		else
			entry = filedata
		end
	end
	if not entry and keycache then
		for _,filename in pairs(keycache) do
			if filename:sub(-3) == "mdl" then 
				entry = filename 
				break
			end
		end
	elseif not entry then
		dprint("Warning: VFS JSON Archive entrypoint not specified and no mdl file found!")
	end
	return entry
end

--vfs (part) stuff

local PART = {}

PART.ClassName = "vfs"
PART.NonPhysical = true

pac.StartStorableVars()
	pac.GetSet(PART, "URL", "")
pac.EndStorableVars()

function PART:GetNiceName()
	return string.GetFileFromFilename(self:GetURL()) or "nothing"
end

function PART:Init()
	if self.URL ~= "" then self:SetURL(url) end
end

function PART:SetURL(url)
	--notify parent
	local uid = self:GetUniqueID()
	local parent = self:GetParent()
	parent.vfs_loading = true
	parent.loading_obj = "downloading (vfs)"
	
	--sanity checks
	if not vfs then 
		if self:GetOwner() == LocalPlayer() then
			LocalPlayer():ChatPrint("[PAC3] You must install the VFS binary module to use the vfs part. See http://vfs.suchipi.com/")
		end
		return
	end
	if not string.find(url,"http") then return end
	
	self.URL = url
	
	--let's do it
	vfs.DownloadJSONArchive(url,function(entry)
		dprint("Attempting to load vfs model "..tostring(entry).."...")
		local parent = self:GetParent()
		parent.vfs_loading = nil
		parent.loading_obj = nil
		if parent.SetModel then parent:SetModel(entry) end
	end)
end

function PART:OnRemove()
	local parent = self:GetParent()
	if parent then parent.vfs_loading = nil end
end

pac.RegisterPart(PART)

--pac functionality Hooks

hook.Add("pac_pace.SaveParts","vfs",function(tbl)
	local function recurse_children(part,parent)
		if part.children ~= {} then     --if this part has children
			for _,child in pairs(part.children) do --for each child
				recurse_children(child,part) --we need to go deeper
			end
		end
		--but anyway, for every part
		if part.self.ClassName == "vfs" and parent.self and parent.self.ClassName and parent.self.ClassName == "model" then --if it's a vfs whose parent is a model
			parent.self.loading_obj = "downloading (vfs)" --for downloading... display
			parent.self.vfs_loading = true
			parent.self.Model = "models/editor/axis_helper.mdl" --placeholder
		end
		return parent
	end
		
	for _,part in pairs(tbl) do
		tbl = recurse_children(part,tbl)
	end
	
	return tbl
end)

hook.Add("pac_model:SetModel","vfs",function(modelpart,var)
	if not modelpart.vfs_loading then
		return var
	else
		return "models/editor/axis_helper.mdl"
	end
end)

hook.Add("pac_PART:SetTable","vfs",function(part,key,value)
	if key == "vfs_loading" then part.vfs_loading = value end
	if key == "loading_obj" then part.loading_obj = value end
	return part
end)