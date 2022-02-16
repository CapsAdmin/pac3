local urlobj = _G.pac_urlobj

local TIMEOUT_VALUE = CreateConVar('pac_objdl_timeout', '15', {FCVAR_ARCHIVE}, 'OBJ download timeout in seconds')
local CACHE_OBJS = CreateConVar('pac_obj_cache', '1', {FCVAR_ARCHIVE}, 'DEBUG: Cache Object files on disk. Disables disk cache access (like cache does not exist in code)')
local QUEUEITEM = {}

-- Warning: This code is concurrency hell
--     Either the decode from the cache or the decode from the web could finish first / last
--     And the web request handler will often decide to not override the cache

local function CreateQueueItem(url)
	local queueItem = {}
	setmetatable (queueItem, { __index = QUEUEITEM })

	queueItem:Initialize (url)

	return queueItem
end

function QUEUEITEM:Initialize (url)
	self.Url                  = url
	self.Data                 = nil
	self.UsingCachedData      = false

	-- Cache
	self.CacheDecodeFinished  = false

	-- Download
	self.DownloadAttemptCount = 0
	self.DownloadTimeoutTime  = 0
	self.Downloading          = false
	self.DownloadFinished     = false

	-- Status
	self.Status               = nil
	self.Finished             = false

	-- Model
	self.Model                = nil

	-- Decoding parameters
	self.GenerateNormals      = false

	-- Callbacks
	self.CallbackSet          = {}
	self.DownloadCallbackSet  = {}
	self.StatusCallbackSet    = {}
end

function QUEUEITEM:GetUrl ()
	return self.Url
end

-- Cache
function QUEUEITEM:BeginCacheRetrieval ()
	if not CACHE_OBJS:GetBool() then return end
	self.Data = urlobj.DataCache:GetItem(self.Url)
	if not self.Data then return end

	self.Model = urlobj.CreateModelFromObjData(self.Data, self.GenerateNormals,
		function (finished, statusMessage)
			if self:IsFinished ()    then return end
			if self.DownloadFinished and not self.UsingCachedData then return end

			if finished and not self.DownloadFinished then
				self:SetStatus ("")
			else
				self:SetStatus ("Cached model: " .. statusMessage)
			end

			if self.DownloadFinished and self.UsingCachedData then
				self:SetFinished (finished)
			end

			if finished then
				self.CacheDecodeFinished = true
			end
		end
	)

	self:DispatchCallbacks (self.Model)
end

function QUEUEITEM:IsCacheDecodeFinished ()
	return self.CacheDecodeFinished
end

-- Download
function QUEUEITEM:AbortDownload ()
	self.Downloading = false

	self:SetStatus ("Download aborted")
end

function QUEUEITEM:BeginDownload ()
	if self:IsDownloading () then return end

	self:SetStatus ("Downloading")

	self.Downloading          = true
	self.DownloadTimeoutTime  = pac.RealTime + TIMEOUT_VALUE:GetFloat()
	self.DownloadAttemptCount = self.DownloadAttemptCount + 1

	local function success(data)
		if not self.Downloading then return end
		self.Downloading      = false
		self.DownloadFinished = true

		pac.dprint("downloaded model %q %s", self.Url, string.NiceSize(#data))
		pac.dprint("%s", data)

		self:DispatchDownloadCallbacks ()
		self:ClearDownloadCallbacks ()

		self.UsingCachedData = self.Data == data

		if self.UsingCachedData then
			if self.CacheDecodeFinished then
				self:SetFinished (true)
			end
		else
			self.Data = data

			if CACHE_OBJS:GetBool() then
				urlobj.DataCache:AddItem (self.Url, self.Data)
			end

			self.Model = urlobj.CreateModelFromObjData(self.Data, self.GenerateNormals,
				function (finished, statusMessage)
					self:SetStatus (statusMessage)
					self:SetFinished (finished)

					if self:IsFinished () then
						self:ClearStatusCallbacks ()
					end
				end
			)
		end

		self:DispatchCallbacks (self.Model)
		self:ClearCallbacks ()
	end

	local function failure(err, fatal)
		-- dont bother with servezilf he said No
		if fatal then
			self.DownloadAttemptCount = 100
		end

		self.DownloadTimeoutTime = 0
		self:SetStatus ("Failed - " .. err)
	end

	pac.HTTPGet(self.Url, success, failure)
end

function QUEUEITEM:GetDownloadAttemptCount ()
	return self.DownloadAttemptCount
end

function QUEUEITEM:IsDownloading ()
	return self.Downloading
end

function QUEUEITEM:HasDownloadTimedOut ()
	return self:IsDownloading () and pac.RealTime > self.DownloadTimeoutTime
end

-- Status
function QUEUEITEM:GetStatus ()
	return self.Status
end

function QUEUEITEM:IsFinished ()
	return self.Finished
end

function QUEUEITEM:SetStatus (status)
	if self.Status == status then return self end

	self.Status = status

	self:DispatchStatusCallbacks (self.Finished, self.Status)

	return self
end

function QUEUEITEM:SetFinished (finished)
	if self.Finished == finished then return self end

	self.Finished = finished

	self:DispatchStatusCallbacks (self.Finished, self.Status)

	return self
end

-- Model
function QUEUEITEM:GetModel ()
	return self.Model
end

-- Callbacks
function QUEUEITEM:AddCallback (callback)
	self.CallbackSet [callback] = true

	if self.Model then
		callback (self.Model)
	end
end

function QUEUEITEM:AddDownloadCallback (downloadCallback)
	self.DownloadCallbackSet [downloadCallback] = true
end

function QUEUEITEM:AddStatusCallback (statusCallback)
	self.StatusCallbackSet [statusCallback] = true

	statusCallback (self.Finished, self.Status)
end

function QUEUEITEM:ClearCallbacks ()
	self.CallbackSet = {}
end

function QUEUEITEM:ClearDownloadCallbacks ()
	self.DownloadCallbackSet = {}
end

function QUEUEITEM:ClearStatusCallbacks ()
	self.StatusCallbackSet = {}
end

function QUEUEITEM:DispatchCallbacks (...)
	for callback, _ in pairs (self.CallbackSet) do
		callback (...)
	end
end

function QUEUEITEM:DispatchDownloadCallbacks (...)
	for downloadCallback, _ in pairs (self.DownloadCallbackSet) do
		downloadCallback (...)
	end
end

function QUEUEITEM:DispatchStatusCallbacks (...)
	for statusCallback, _ in pairs (self.StatusCallbackSet) do
		statusCallback (...)
	end
end

return CreateQueueItem