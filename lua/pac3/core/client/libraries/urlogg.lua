-- made by Morten and CapsAdmin

local webaudio = pac.webaudio or {}

webaudio.debug = 0
webaudio.initialized = false
webaudio.rate = 0
webaudio.SpeedOfSound = 2000

webaudio.streams = {}

local function dprint(str)

	if webaudio.debug == 0 then return end

	if webaudio.debug <= 1 then
		if epoe then
			epoe.MsgC(Color(0, 255, 0), "[WebAudio] ")
			epoe.MsgC(Color(255, 255, 255), str)
			epoe.Print("")
		end

		MsgC(Color(0, 255, 0), "[WebAudio] ")
		MsgC(Color(255, 255, 255), str)
		Msg("\b")
	end

	if webaudio.debug <= 2 then
		easylua.PrintOnServer("[WebAudio] " .. str)
	end
end

do -- STREAM
	local STREAM = {}
	STREAM.__index = STREAM

	STREAM.__tostring = function(s) return string.format("stream[%d][%s]", s.id, s.url) end

	STREAM.loaded = false
	STREAM.duration = 0
	STREAM.position = 0
	STREAM.rad3d = 1000
	STREAM.usedoppler = true
	STREAM.url = "" -- ??
	STREAM.__valid = true
	STREAM.paused = true

	function STREAM:Remove()
		self.__valid = false
	end

	function STREAM:IsValid()
		return self.__valid
	end

	function STREAM:Call(fmt, ...)
		if not self.loaded then return end

		local script = ("try { streams[%d]%s } catch(e) { lua.print(e.toString()) }"):format(self.id, fmt:format(...))
		--dprint(script)
		webaudio.html:QueueJavascript(script)
	end

	local function BIND(func_name, js_set, def, check)
		STREAM[func_name] = def

		STREAM["Set" .. func_name] = function(self, var)
			if check then
				var = check(var)
			end

			self[func_name] = var
			self:Call(js_set, var)
		end

		STREAM["Get" .. func_name] = function(self, ...)
			return self[func_name]
		end
	end

	BIND("SamplePosition", ".position = %f", 0)
	BIND("Speed", ".speed = %f", 1)
	
	STREAM.SetPitch = STREAM.SetSpeed
	STREAM.GetPitch = STREAM.GetSpeed

	webaudio.FILTER =
	{
		LOWPASS = 0,
		HIGHPASS = 1,
		BANDPASS = 2,
		LOWSHELF = 3,
		HIGHSHELF = 4,
		PEAKING = 5,
		NOTCH = 6,
		ALLPASS = 7,
	}

	BIND("FilterType", ".filter.type = %i", webaudio.FILTER.LOWPASS, function(num) return math.Clamp(num, 0, 7) end)
	BIND("FilterFrequency", ".filter.frequency.value = %f", 100, function(num) return math.Clamp(num, 1, (webaudio.rate/2) - 1) end)
	BIND("FilterQuality", ".filter.Q.value = %f", 1000)
	BIND("FilterGain", ".filter.gain.value = %f", 1000)

	function STREAM:SetFilterFraction(num)
		self:SetFilterFrequency((webaudio.rate/2) * num ^ 4)
	end
	
	function STREAM:SetLoopCount(var)
		self:Call(".looping = %i", var == 0 and -1 or var == true and 1 or var == false and -1 or tonumber(var) or 0)
		self.LoopCount = var
	end

	function STREAM:GetLength()
		return self.Length
	end

	function STREAM:Pause()
		self.paused = true
		self:Call(".play(false)")
	end

	function STREAM:Resume()
		self.paused = false
		self:Call(".play(true)")
	end

	function STREAM:Stop()
		self.paused = true
		self:Call(".play(false, 0)")
	end

	function STREAM:Start()
		self.paused = false
		self:Call(".play(true, 0)")
	end

	STREAM.Play = STREAM.Start

	function STREAM:Restart()
		self:SetSamplePosition(0)
	end

	function STREAM:SetPosition(num)
		self:SetSamplePosition((num%1) * self:GetLength())
	end

	do -- 3d
		function STREAM:Enable3D(b)
			self.use3d = b
		end

		function STREAM:EnableDoppler(b)
			self.usedoppler = b
		end

		function STREAM:Set3DPos(vec)
			self.pos3d = vec
		end

		function STREAM:Get3DPos(vec)
			return self.pos3d
		end

		function STREAM:Set3DRadius(num)
			self.rad3d = num
		end

		function STREAM:Get3DRadius(num)
			return self.rad3d
		end

		function STREAM:Set3DVelocity(vec)
			self.vel3d = vec
		end

		function STREAM:Get3DVelocity(vec)
			return self.vel3d
		end

		local eye_pos, eye_ang

		hook.Add("RenderScene", "webaudio_3d", function(pos, ang)
			eye_pos = pos
			eye_ang = ang
		end)

		function STREAM:Think()
			if self.paused then
			return end

			local ent = self.source_ent

			if ent:IsValid() then
				self.pos3d = ent:GetPos()
				self.vel3d = ent:GetVelocity()
			end

			if self.use3d then
				self.pos3d = self.pos3d or Vector()
				self.vel3d = self.vel3d or Vector()

				local offset = self.pos3d - eye_pos
				local pan = (offset):GetNormalized():Dot(eye_ang:Right())
				local vol = self.Volume / (1 + offset:LengthSqr() / (self.rad3d ^ 1.5))

				self:Call(".vol_right.gain.value = %f", math.Clamp(1 + pan, 0, 1) * vol)
				self:Call(".vol_left.gain.value = %f", math.Clamp(1 - pan, 0, 1) * vol)

				if self.usedoppler then
					local offset = self.pos3d - eye_pos
					local relative_velocity = self.vel3d - LocalPlayer():GetVelocity()
					local meters_per_second = offset:GetNormal():Dot(-relative_velocity) * 0.0254

					self:Call(".speed = %f", self.Speed + (meters_per_second / webaudio.SpeedOfSound))
				end
			end
		end

		STREAM.source_ent = NULL

		function STREAM:SetSourceEntity(ent, dont_remove)
			self.source_ent = ent

			if not dont_remove then
				ent:CallOnRemove("webaudio_remove_stream_" .. tostring(self), function()
					self:Remove()
				end)
			end
		end
	end

	do -- panning
		STREAM.Panning = 0

		function STREAM:SetPanning(num)
			self.Panning = num

			self:Call(".vol_right.gain.value = %f", math.Clamp(1 + num, 0, 1) * self.Volume)
			self:Call(".vol_left.gain.value = %f", math.Clamp(1 - num, 0, 1) * self.Volume)
		end

		function STREAM:GetPanning()
			return self.Panning
		end
	end

	do -- gain
		STREAM.Volume = 1

		function STREAM:SetVolume(num)
			self.Volume = num
			self:SetPanning(self:GetPanning())
		end

		function STREAM:GetVolume()
			return self.Volume
		end
	end

	local stream_count = 0

	function webaudio.Stream(url)	
		url = url:gsub("http[s?]://", "http://")

		if not url:find("http") then
			url = "asset://garrysmod/sound/" .. url
		end

		local stream = setmetatable({}, STREAM)

		stream_count = stream_count + 1

		stream.url = url
		stream.id = stream_count
		webaudio.html:QueueJavascript(string.format("createStream(%q, %d)", url, stream.id))

		webaudio.streams[stream.id] = stream

		return stream
	end
end

local cvar = CreateConVar("pac_ogg_volume", "1")

function webaudio.SetVolume(num)
	webaudio.html:QueueJavascript(string.format("gain.gain.value = %f", num))
end

hook.Add("Think", "webaudio", function()
	local mult = cvar:GetFloat()
	
	if not webaudio.preinit then
		if webaudio.html then webaudio.html:Remove() end
		
		local html = vgui.Create("DHTML") or NULL
		if html:IsValid() then
			
			html:SetVisible(true)
			html:SetPos(0, 0)
			html:SetSize(256, 256)
			
			html:AddFunction("lua", "print", function(text)
				dprint(text)
			end)

			html:AddFunction("lua", "message", function(name, ...)
				local args = {...}

				if name == "initialized" then
					webaudio.initialized = true
					webaudio.rate = args[1]
				elseif name == "stream" then
					local stream = webaudio.streams[tonumber(args[2]) or 0]

					if stream then
						if args[1] == "stop" then
							stream.paused = true
						elseif args[1] == "return" then
							stream.returned_var = {select(3, ...)}
						elseif args[1] == "loaded" then
							stream.loaded = true
							stream.Length = args[3]
							if stream.paused then
								stream:Call(".vol_right.gain.value = 0")
								stream:Call(".vol_left.gain.value = 0")
							end
							stream:SetFilterType(3)
							stream:SetFilterFrequency(100)
						elseif args[1] == "position" then
							stream.position = args[3]
						end
					end
				end

				dprint(name .. " " .. table.concat({...}, ", "))
			end)
			
			html:SetHTML([==[
<script>

window.onerror = function(a,b,c) {
	lua.print("UNHANDELED EXCEPTION: " + a + " " + b + " " + c)
}

function load(url, callback) {
	var request = new XMLHttpRequest
	request.onerror = function() { lua.print("error") }
	request.onload = function() { lua.print("hello") }
	request.open("GET", url)
	request.send()
}

var audio, gain, analyser
var streams = []

function initialize() {
	if(audio) {
		audio.destination.disconnect()
		delete audio
		delete gain
	}
	audio = new webkitAudioContext
	gain = audio.createGainNode()
	gain.connect(audio.destination)
	lua.message("initialized", audio.sampleRate)
}

function uninitialize() {
	if(audio) {
		delete audio
		lua.message("uninitialized")
	}
}

function download(url, callback)
{
	var request = new XMLHttpRequest

	request.open("GET", url, true)
	request.responseType = "arraybuffer"
	request.send()

	request.onload = function()
	{
		lua.print("loaded \"" + url + "\"")
		lua.print("status " + request.status)

		lua.print("decoding " + request.response.byteLength + " ...")

		audio.decodeAudioData(request.response, function(buffer)
		{
			source = audio.createBufferSource()

			source.buffer = buffer
			source.loop = false
			source.noteOn(0)

			callback(source)

			lua.print("decoded successfully")
		},
		function(err)
		{
			lua.print("decoding error " + err)
		})
	}

	request.onprogress = function(event)
	{
		try {
			lua.print(Math.round(event.loaded / event.total * 100) + "%")
		} catch(e) {
		}
	}
}

function createStream(url, id) {
	lua.print("Loading " + url)

	download(url, function(obj)
	{
		var stream = {id: id, url: url}

		stream.obj = obj
		stream.src = url
		stream.speed = 1
		stream.loop = true
		stream.stop = 0

		var vol_left = audio.createGainNode()
		stream.vol_left = vol_left

		var vol_right = audio.createGainNode()
		stream.vol_right = vol_right

		var splitter = audio.createChannelSplitter()
			splitter.connect(vol_left, 0, 0)
			splitter.connect(vol_right, obj.buffer.numberOfChannels == 1 ? 0 : 1, 0)
		stream.splitter = splitter

		var merger = audio.createChannelMerger()
			vol_left.connect(merger, 0, 0)
			vol_right.connect(merger, 0, 1)
		stream.merger = merger

		vol_left.gain.value = 0.5
		vol_right.gain.value = 1

		var filter = audio.createBiquadFilter()
		stream.filter = filter

		var proc = audio.createJavaScriptNode(4096, 0, 1)

		stream.position = 0
		stream.looping =1

		stream.play = function(b, sample_pos)
		{
			stream.muted = !b
			if (sample_pos !== undefined) stream.position = 0
		}

		proc.onaudioprocess = function(event)
		{
			try {
				var buffer_out_left = event.outputBuffer.getChannelData(0)
				var buffer_out_right = event.outputBuffer.getChannelData(1)
				var buffer_in_left = obj.buffer.getChannelData(0)
				var buffer_in_right = obj.buffer.numberOfChannels == 1 ? buffer_in_left : obj.buffer.getChannelData(1)

				for (var i = 0; i < buffer_out_left.length; ++i, stream.position += stream.speed)
				{
					if (stream.muted)
					{
						buffer_out_left[i] = 0
						buffer_out_right[i] = 0
					}
					else
					{
						buffer_out_left[i] = buffer_in_left[(stream.position >>> 0) % buffer_in_left.length]
						buffer_out_right[i] = buffer_in_right[(stream.position >>> 0) % buffer_in_right.length]

						var count = Math.floor(stream.position / buffer_in_left.length)

						if (stream.looping != -1 && count >= stream.looping)
						{
							stream.play(false, 0)
							lua.message("stream", "stop", id)
							
							lua.print("stopping at " + stream.position)
							lua.print("total samples" + buffer_in_left.length)
						}
					}
				}
			} catch(e) {
				lua.print("SOMETHING BAD HAPPENED")
			}
		}
		merger.connect(gain)
		proc.connect(filter)
		filter.connect(splitter)

		stream.proc = proc

		streams[id] = stream

		lua.message("stream", "loaded", id, obj.buffer.length)
	})
}

function destroyStream(id) {
	if (streams[id])
	{
		streams[id].speed = 0
		streams[id].onaudioprocess = function() {}

		streams[id] = undefined
	}
}

initialize()

</script>

]==])			
		end
		
		webaudio.html = html		
		webaudio.preinit = true
	end
	
	if not webaudio.initialized then return end

	if mult ~= 0 then

		local vol = GetConVarNumber("volume")

		if not system.HasFocus() and GetConVarNumber("snd_mute_losefocus") == 1 then
			vol = 0
		end

		vol = vol * mult

		webaudio.SetVolume(vol)

		for key, stream in pairs(webaudio.streams) do
			if stream:IsValid() then
				stream:Think()
			else
				stream:Stop()
				webaudio.streams[key] = nil
				webaudio.html:QueueJavascript(("destroyStream(%i)"):format(stream.id))

				setmetatable(stream, getmetatable(NULL))
			end
		end
	end
end)

pac.webaudio = webaudio