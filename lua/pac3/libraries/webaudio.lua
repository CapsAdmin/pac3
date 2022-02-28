local webaudio = _G.webaudio or {}
_G.webaudio = webaudio

if me then
	webaudio.debug = true
end

webaudio.sample_rate = nil
webaudio.speed_of_sound = 340.29 -- metres per
webaudio.buffer_size = CreateClientConVar("webaudio_buffer_size", "2048", true)

local function logn(str)
	MsgC(Color(0, 255, 0), "[pac webaudio] ")
	MsgC(Color(255, 255, 255), str)
	Msg("\n")
end

local function dprint(str)
    if webaudio.debug  then
        logn(str)
    end
end

cvars.AddChangeCallback("webaudio_buffer_size", function(_,_,val)
	dprint("buffer size changed to " .. val)
	webaudio.Shutdown()
	webaudio.Initialize()
end)

if webaudio.browser_panel and webaudio.browser_panel:IsValid() then
	webaudio.browser_panel:Remove()
	webaudio.browser_panel = nil
end

webaudio.browser_state = "uninitialized"
webaudio.volume = 1

local script_queue

local function run_javascript(code, stream)
	if stream and not stream:IsReady() then
		stream.js_queue = stream.js_queue or {}
		table.insert(stream.js_queue, code)
		return
	end

	if script_queue then
		table.insert(script_queue, code)
	else
		if code ~= "" then
			--print("|" .. code .. "|")
			webaudio.browser_panel:RunJavascript(code)
		end
	end
end

local function queue_javascript()
	script_queue = script_queue or {}
end

local function execute_javascript()
	if script_queue then
		local str = table.concat(script_queue, "\n")
		script_queue = nil
		run_javascript(str)
	end
end

do
	local last_eye_pos
	local last_eye_pos_time

	function webaudio.Update()
		if webaudio.browser_state ~= "initialized" then
			if webaudio.browser_state ~= "initializing" then
				webaudio.Initialize()
			end
			return
		end

		if not system.HasFocus() and GetConVar("snd_mute_losefocus"):GetBool() then
			webaudio.SetVolume(0)
		else
			webaudio.SetVolume(GetConVar("volume"):GetFloat())
		end

		local time = RealTime()

		last_eye_pos = last_eye_pos or webaudio.eye_pos
		last_eye_pos_time = last_eye_pos_time or (time - FrameTime())

		webaudio.eye_velocity = (webaudio.eye_pos - last_eye_pos) / (time - last_eye_pos_time)

		last_eye_pos = webaudio.eye_pos
		last_eye_pos_time = time

		for streamId, stream in pairs(webaudio.streams) do
			if stream:IsValid() then
				stream:Think()
			else
				webaudio.streams[streamId] = nil
			end
		end
	end
end

function webaudio.Shutdown()
	webaudio.browser_state = "uninitialized"
	if webaudio.browser_panel then
		webaudio.browser_panel:Remove()
	end
	webaudio.browser_panel = nil
	hook.Remove("RenderScene", "pac_webaudio2")
	hook.Remove("Think", "pac_webaudio2")
end

function webaudio.Initialize()
	if webaudio.browser_state ~= "uninitialized" then return end

	webaudio.browser_state = "initializing"

	if webaudio.browser_panel then
		webaudio.browser_panel:Remove()
	end

	webaudio.browser_panel = vgui.Create("DHTML")
	webaudio.browser_panel:SetVisible(false)
	webaudio.browser_panel:SetPos(ScrW(), ScrH())
	webaudio.browser_panel:SetSize(1, 1)

	local last_message = nil
	webaudio.browser_panel.ConsoleMessage = function(self, message)
		-- why does awesomium crash in the first place?
		if msg == "Uncaught ReferenceError: lua is not defined" then
			webaudio.browser_state = "uninitialized"
		end

		if last_message ~= message then
			last_message = message
			dprint(message)
		end
	end

	webaudio.browser_panel:AddFunction("lua", "print", dprint)
	webaudio.browser_panel:AddFunction("lua", "message", function(typ, ...)
		local args = {}

		for i = 1, select("#", ...) do
			args[i] = tostring(select(i, ...))
		end

		dprint(typ .. " " .. table.concat(args, ", "))

		if typ == "initialized" then
			webaudio.browser_state = "initialized"
			webaudio.sample_rate = args[1] or -1

		elseif typ == "stream" then
			local stream = webaudio.GetStream(tonumber(args[2]) or 0)
			if stream:IsValid() then
				stream:HandleBrowserMessage(args[1], unpack(args, 3, table.maxn(args)))
			end
		end
	end)

	local js = ([==[
/*jslint bitwise: true */

window.onerror = function(description, url, line)
{
	dprint("Unhandled exception at line " + line + ": " + description);
};

function dprint(str)
{
	]==] .. (webaudio.debug and "lua.print(str);" or "") .. [==[
}

var audio;
var gain;
var processor;
var streams = new Object();
var streams_array = [];

function open()
{
    if(audio)
    {
        audio.destination.disconnect();
    }

    if (typeof AudioContext != "undefined")
    {
        audio = new AudioContext();
        processor = audio.createScriptProcessor(]==] .. webaudio.buffer_size:GetInt() .. [==[, 2, 2);
        gain = audio.createGain();
		compressor = audio.createDynamicsCompressor()
    } else {
        audio = new webkitAudioContext();
        processor = audio.createJavaScriptNode(]==] .. webaudio.buffer_size:GetInt() .. [==[, 2, 2);
        gain = audio.createGainNode();
		compressor = audio.createDynamicsCompressor()
    }

    processor.onaudioprocess = function(event)
    {
        var output_left = event.outputBuffer.getChannelData(0);
        var output_right = event.outputBuffer.getChannelData(1);

        for(var i = 0; i < event.outputBuffer.length; ++i)
        {
            output_left[i] = 0;
            output_right[i] = 0;
        }

        for(var i = 0; i < streams_array.length; ++i)
        {
            var stream = streams_array[i];

            var buffer_length = stream.buffer.length;
            var buffer_left = stream.buffer.getChannelData(0);
            var buffer_right = stream.buffer.numberOfChannels == 1 ? buffer_left : stream.buffer.getChannelData(1);

			if (stream.use_smoothing)
			{
				stream.speed_smooth = stream.speed_smooth + (stream.speed - stream.speed_smooth) * 1;
				stream.vol_left_smooth = stream.vol_left_smooth  + (stream.vol_left  - stream.vol_left_smooth ) * 1;
				stream.vol_right_smooth = stream.vol_right_smooth + (stream.vol_right - stream.vol_right_smooth) * 1;
			}
			else
			{
				stream.speed_smooth = stream.speed;
				stream.vol_left_smooth  = stream.vol_left_smooth;
				stream.vol_right_smooth = stream.vol_right_smooth;
			}

			if(!stream.use_echo && (stream.paused || (stream.vol_left < 0.001 && stream.vol_right < 0.001)))
            {
                continue;
            }
            var echol;
            var echor;
            if (stream.use_echo && stream.echo_buffer)
            {
                echol = stream.echo_buffer.getChannelData(0);
                echor = stream.echo_buffer.getChannelData(1);
            }

            var sml = 0;
            var smr = 0;

            for(var j = 0; j < event.outputBuffer.length; ++j)
            {
				if (stream.paused || stream.max_loop > 0 && stream.position >= (buffer_length * stream.max_loop) - 1)
                {
                    stream.done_playing = true;

					if (!stream.paused)
					{
					    stream.paused = true;
					}

                    if (!stream.use_echo)
                    {
                        break;
                    }
                }
                else
                {
                    stream.done_playing = false;
                }

                var index = (stream.position >> 0) % buffer_length;

				if (stream.reverse)
				{
					index = -index + buffer_length;
				}

                var left  = 0;
                var right = 0;

                if (!stream.done_playing)
                {
                    // filters
					if (stream.filter_type == 0)
					{
						// None
                        left = buffer_left[index] * stream.vol_both;
                        right = buffer_right[index] * stream.vol_both;
					}
					else
                    {
                        sml = sml + (buffer_left[index] - sml) * stream.filter_fraction;
                        smr = smr + (buffer_right[index] - smr) * stream.filter_fraction;

                        if (stream.filter_type == 1)
                        {
							// Low pass
                            left = sml * stream.vol_both;
                            right = smr * stream.vol_both;
                        }
                        else if (stream.filter_type == 2)
                        {
							// High pass
                            left = (buffer_left[index] - sml) * stream.vol_both;
                            right = (buffer_right[index] - smr) * stream.vol_both;
                        }
                    }

					left = Math.min(Math.max(left, -1), 1) * stream.vol_left_smooth;
					right = Math.min(Math.max(right, -1), 1) * stream.vol_right_smooth;
                }

				if (stream.lfo_volume_time)
				{
					var res = (Math.sin((stream.position/audio.sampleRate)*10*stream.lfo_volume_time)*stream.lfo_volume_amount);
					left *= res;
					right *= res;
				}

                if (stream.use_echo)
                {
					var echo_index = (stream.position >> 0) % stream.echo_delay;

                    echol[echo_index] = echol[echo_index] * stream.echo_feedback + left;
                    echor[echo_index] = echor[echo_index] * stream.echo_feedback + right;

                    output_left[j] += echol[echo_index];
                    output_right[j] += echor[echo_index];
                }
                else
                {
                    output_left[j] += left;
                    output_right[j] += right;
                }

				var speed = stream.speed_smooth;

				if (stream.lfo_pitch_time)
				{
					speed -= (Math.sin((stream.position/audio.sampleRate)*10*stream.lfo_pitch_time)*stream.lfo_pitch_amount);
					speed += Math.pow(stream.lfo_pitch_amount*0.5,2);
				}

                stream.position += speed;

				var max = 1;

				output_left[j] = Math.min(Math.max(output_left[j], -max), max);
				output_right[j] = Math.min(Math.max(output_right[j], -max), max);

				if (!isFinite(output_left[j])) {
					output_left[j] = 0
				}

				if (!isFinite(output_right[j])) {
					output_right[j] = 0
				}
            }
        }
    };

    processor.connect(compressor);
    compressor.connect(gain);
    gain.connect(audio.destination);

    lua.message("initialized", audio.sampleRate);
}

function close()
{
    if(audio)
    {
        audio.destination.disconnect();
        audio = null;
        lua.message("uninitialized");
    }
}

var buffer_cache = new Object();

function download_buffer(url, callback, skip_cache, id)
{
    if (!skip_cache && buffer_cache[url])
    {
        callback(buffer_cache[url]);

        return;
    }

    var request = new XMLHttpRequest();

    request.open("GET", url);
    request.responseType = "arraybuffer";
    request.send();

    request.onload = function()
    {
        dprint("decoding " + url + " " + request.response.byteLength + " ...");

        audio.decodeAudioData(request.response,

            function(buffer)
            {
                dprint("decoded " + url + " successfully");

                callback(buffer);

                buffer_cache[url] = buffer;
            },

            function(err)
            {
                dprint("decoding error " + url + " " + err.message);
				lua.message("stream", "call", id, "OnError", "decoding failed", err.message);
            }
        );
    };

    request.onprogress = function(event)
    {
        dprint("downloading " +  (event.loaded / event.total) * 100);
    };

    request.onerror = function()
    {
        dprint("downloading " + url + " errored");
		lua.message("stream", "call", id, "OnError", "download failed: ", request.responseText);
    };
}

function CreateStream(url, id, skip_cache)
{
    dprint("Loading " + url);

    download_buffer(url, function(buffer)
    {
        var stream = {};

        stream.id = id;
        stream.position = 0;
        stream.buffer = buffer;
        stream.url = url;
        stream.speed = 1; // 1 = normal pitch
        stream.max_loop = 1; // -1 = inf
        stream.vol_both = 1;
        stream.vol_left = 1;
        stream.vol_right = 1;
        stream.paused = true;
        stream.use_smoothing = true;
        stream.echo_volume = 0;
        stream.filter_type = 0;
        stream.filter_fraction = 1;
        stream.done_playing = false;

        stream.use_echo = false;
        stream.echo_feedback = 0.75;
        stream.echo_buffer = false;

        stream.vol_left_smooth = 0;
        stream.vol_right_smooth = 0;
        stream.speed_smooth = stream.speed;

        stream.play = function(stop, position)
        {
			dprint("play " + stop + position)
            if(position !== undefined)
            {
                stream.position = position;
            }

            stream.paused = !stop;
        };

        stream.usefft = function(enable)
        {
            // later
        };

		stream.useEcho = function(b) {
			stream.use_echo = b;

			if (b)
			{
				stream.setEchoDelay(stream.echo_delay);
			}
			else
			{
				stream.echo_buffer = undefined;
			}
		};

        stream.setEchoDelay = function(x) {

            if(stream.use_echo && (!stream.echo_buffer || (x != stream.echo_buffer.length))) {
                var size = 1;

                while((size <<= 1) < x);

				stream.echo_buffer = audio.createBuffer(2, size, audio.sampleRate);
            }

            stream.echo_delay = x;
        };

        streams[id] = stream;
        streams_array.push(stream);

		dprint("created stream[" + id + "][" + stream.url + "]");
        lua.message("stream", "loaded", id, buffer.length);

		if (]==] .. (webaudio.debug and "true" or "false") .. [==[)
		{
			var size = 0, key;
			for (key in streams) {
				if (streams.hasOwnProperty(key)) size++;
			}
			dprint("total stream count " + size)
		}

    }, skip_cache, id);
}

function DestroyStream(id)
{
	var stream = streams[id];

	if (stream)
	{
		dprint("destroying stream[" + id + "][" + stream.url + "]");

		delete streams[id];
		delete buffer_cache[stream.url];

		var i = streams_array.indexOf(stream);
		streams_array.splice(i, 1);

		if (]==] .. (webaudio.debug and "true" or "false") .. [==[)
		{
			var size = 0, key;
			for (key in streams) {
				if (streams.hasOwnProperty(key)) size++;
			}
			dprint("total stream count " + size)
		}
	}
}

open();

]==])

	webaudio.browser_panel.OnFinishLoadingDocument = function(self)
		self.OnFinishLoadingDocument = nil

		dprint("OnFinishLoadingDocument")
		webaudio.browser_panel:RunJavascript(js)
	end

	file.Write("pac_webaudio2_blankhtml.txt", "<html></html>")
	webaudio.browser_panel:OpenURL("asset://garrysmod/data/pac_webaudio2_blankhtml.txt")

	webaudio.eye_pos = Vector()
	webaudio.eye_ang = Angle()

	hook.Add("RenderScene", "pac_webaudio2", function(pos, ang)
		webaudio.eye_pos = pos
		webaudio.eye_ang = ang
	end)

	hook.Add("Think", "pac_webaudio2", webaudio.Update)
end

-- Audio
function webaudio.SetVolume(vol)
	if webaudio.volume ~= vol then
		webaudio.volume = vol
		run_javascript(string.format("gain.gain.value = %f", vol))
	end
end

webaudio.streams = setmetatable({}, {__mode = "kv"})

do
	local META = {}
	META.__index = META

	local function DECLARE_PROPERTY(name, default, javascriptSetterCode, filterFunction)
		META[name] = default

		META["Set" .. name] = function(self, value)
			if filterFunction then
				value = filterFunction(value, self)
			end

			self[name] = value

			if javascriptSetterCode then
				self:Call(javascriptSetterCode, value)
			end
		end

		META["Get" .. name] = function(self, ...)
			return self[name]
		end
	end

	DECLARE_PROPERTY("Loaded", false)
	DECLARE_PROPERTY("Paused", true)
	DECLARE_PROPERTY("SampleCount", 0)
	DECLARE_PROPERTY("MaxLoopCount", nil)

	DECLARE_PROPERTY("Panning", 0)
	DECLARE_PROPERTY("Volume", 1)
	DECLARE_PROPERTY("AdditiveVolumeFraction", 0)

	DECLARE_PROPERTY("3D", false)
	DECLARE_PROPERTY("Doppler", true)

	DECLARE_PROPERTY("SourceEntity", NULL)
	DECLARE_PROPERTY("SourcePosition", nil)
	DECLARE_PROPERTY("LastSourcePosition", nil)
	DECLARE_PROPERTY("LastSourcePositionTime", nil)
	DECLARE_PROPERTY("SourceVelocity", nil)
	DECLARE_PROPERTY("SourceRadius", 4300)
	DECLARE_PROPERTY("ListenerOutOfRadius", false)

	DECLARE_PROPERTY("Id")
	DECLARE_PROPERTY("Url", "")
	DECLARE_PROPERTY("PlaybackSpeed", 1)
	DECLARE_PROPERTY("AdditivePitchModifier", 0)
	DECLARE_PROPERTY("SamplePosition", 0, ".position = %f")

	DECLARE_PROPERTY("PitchLFOAmount", nil, ".lfo_pitch_amount = %f")
	DECLARE_PROPERTY("PitchLFOTime", nil, ".lfo_pitch_time = %f")

	DECLARE_PROPERTY("VolumeLFOAmount", nil, ".lfo_volume_amount = %f")
	DECLARE_PROPERTY("VolumeLFOTime", nil, ".lfo_volume_time = %f")

	DECLARE_PROPERTY("FilterType", nil, ".filter_type = %i")
	DECLARE_PROPERTY("FilterFraction", 0, ".filter_fraction = %f", function(num) return math.Clamp(num, 0, 1) end)

	DECLARE_PROPERTY("Echo", false, ".useEcho(%s)")
	DECLARE_PROPERTY("EchoDelay", 1, ".setEchoDelay(Math.ceil(audio.sampleRate * %f))", function(num) return math.Clamp(num, 0, 5) end)
	DECLARE_PROPERTY("EchoFeedback", 0.75, ".echo_feedback = %f")

	-- State
	function META:IsReady()
		return self.Loaded
	end

	function META:GetLength()
		if not self.Loaded then return 0 end
		return self.SampleCount / tonumber(webaudio.sample_rate)
	end

	function META:IsValid()
		return self.invalid == nil
	end

	function META:Remove()
		webaudio.streams[self:GetId()] = nil
		self:Stop()
		run_javascript(string.format("DestroyStream(%i)", self:GetId()))
		self.invalid = true
	end

	-- Browser
	function META:Call(fmt, ...)
		local code = string.format("var id = %d; try { if (streams[id]) { streams[id]%s } } catch(e) { dprint('streams[' + id + '] ' + e.toString()) }", self:GetId(), string.format(fmt, ...))

		run_javascript(code, self)
	end

	function META:HandleBrowserMessage(t, ...)
		if t == "call" then
			self:HandleCallBrowserMessage(...)
		elseif t == "fft" then
			self:HandleFFTBrowserMessage(...)
		elseif t == "stop" then
			self.Paused = true
		elseif t == "return" then
			self.ReturnedValues = {...}
		elseif t == "loaded" then
			self:HandleLoadedBrowserMessage(...)
		elseif t == "position" then
			self:HandlePositionBrowserMessage(...)
		end
	end

	function META:SetMaxLoopCount(maxLoopCount)
		self.MaxLoopCount = maxLoopCount
		self:Call(".max_loop = %i", maxLoopCount == true and -1 or maxLoopCount == false and 1 or tonumber(maxLoopCount) or 1)
	end

	function META:Pause()
		self.Paused = true
		self:Call(".play(false)")
	end

	function META:Resume()
		self.Paused = false

		self:UpdatePlaybackSpeed()
		self:UpdateVolume()

		self:Call(".play(true)")
	end

	function META:Play()
		self.Paused = false

		queue_javascript()

		self:UpdatePlaybackSpeed()
		self:UpdateVolume()

		self:Call(".play(true, 0)")

		execute_javascript()
	end

	function META:Stop()
		self.Paused = true
		self:Call(".play(false, 0)")
	end

	function META:Restart()
		self:SetSamplePosition(0)
	end

	function META:SetPosition(pos)
		self:SetSamplePosition((pos % 1) * self:GetSampleCount())
	end

	function META:SetPlaybackRate(mult)
		if self.PlaybackSpeed == mult then return self end

		self.PlaybackSpeed = mult

		self:UpdatePlaybackSpeed()

		return self
	end

	function META:SetAdditivePitchModifier(additivePitchModifier)
		if self.AdditivePitchModifier == additivePitchModifier then return self end

		self.AdditivePitchModifier = additivePitchModifier

		self:UpdatePlaybackSpeed()

		return self
	end

	function META:UpdatePlaybackSpeed(add)
		local speed = self.PlaybackSpeed + self.AdditivePitchModifier

		if speed < 0 then
			self:Call(".reverse = true")
			speed = math.abs(speed)
		end

		if add then
			speed = speed + add
		end

		if speed ~= self.last_speed then
			self:Call(".speed = %f", speed)
			self.last_speed = speed
		end
	end

	function META:SetPanning(panning)
		if self.Panning == panning then return self end

		self.Panning = panning

		self:UpdateVolume()

		return self
	end

	function META:SetVolume(volumeFraction)
		if self.Volume == volumeFraction then return self end

		self.Volume = volumeFraction

		self:UpdateVolume()

		return self
	end

	function META:SetAdditiveVolumeModifier(additiveVolumeFraction)
		if self.AdditiveVolumeFraction == additiveVolumeFraction then return self end

		self.AdditiveVolumeFraction = additiveVolumeFraction

		self:UpdateVolume()

		return self
	end

	local function FindHeadPos(ent)
		if ent.findheadpos_last_mdl ~= ent:GetModel() then
			ent.findheadpos_head_bone = nil
			ent.findheadpos_head_attachment = nil
			ent.findheadpos_last_mdl = ent:GetModel()
		end

		if not ent.findheadpos_head_bone then
			for i = 0, ent:GetBoneCount() or 0 do
				local name = ent:GetBoneName(i):lower()
				if name:find("head", nil, true) then
					ent.findheadpos_head_bone = i
					break
				end
			end
		end

		if ent.findheadpos_head_bone then
			local m = ent:GetBoneMatrix(ent.findheadpos_head_bone)
			if m then
				local pos = m:GetTranslation()
				if pos ~= ent:GetPos() then
					return pos, m:GetAngles()
				end
			end
		else
			if not ent.findheadpos_attachment_eyes then
				ent.findheadpos_head_attachment = ent:GetAttachments().eyes or ent:GetAttachments().forward
			end

			if ent.findheadpos_head_attachment then
				local angpos = ent:GetAttachment(ent.findheadpos_head_attachment)
				return angpos.Pos, angpos.Ang
			end
		end

		return ent:EyePos(), ent:EyeAngles()
	end

	function META:UpdateSourcePosition()
		if not self.SourceEntity:IsValid() then
			self:OutOfRadius()
			return
		end

		self.SourcePosition = FindHeadPos(self.SourceEntity)
	end

	function META:UpdateVolume()
		queue_javascript()
		if self:Get3D() then
			self:UpdateVolume3d()
		else
			self:UpdateVolumeFlat()
		end
		execute_javascript()
	end

	function META:UpdateVolumeFlat()
		self:SetRightVolume((math.Clamp(1 + self.Panning, 0, 1)) + self.AdditiveVolumeFraction)
		self:SetLeftVolume((math.Clamp(1 - self.Panning, 0, 1)) + self.AdditiveVolumeFraction)
	end

	function META:UpdateVolumeBoth()
		if self.last_vol_both ~= self.Volume then
			self:Call(".vol_both= %f", self.Volume)
			self.last_vol_both = self.Volume
		end
	end

	function META:SetLeftVolume(vol)
		if self.last_left_volume ~= vol then
			self:Call(".vol_left= %f", vol)
			self.last_left_volume = vol
		end
		self:UpdateVolumeBoth()
	end

	function META:SetRightVolume(vol)
		if self.last_right_volume ~= vol then
			self:Call(".vol_right = %f", vol)
			self.last_right_volume = vol
		end
		self:UpdateVolumeBoth()
	end

	function META:UpdateVolume3d()
		if self.SourceEntity == pac.LocalPlayer and not pac.LocalPlayer:ShouldDrawLocalPlayer() then
			self:UpdateVolumeFlat()
			return
		end


		self:UpdateSourcePosition()

		local time = RealTime()

		self.SourcePosition = self.SourcePosition or Vector()

		self.LastSourcePosition = self.LastSourcePosition or self.SourcePosition
		self.LastSourcePositionTime = self.LastSourcePositionTime or (time - FrameTime())

		self.SourceVelocity = (self.SourcePosition - self.LastSourcePosition) / (time - self.LastSourcePositionTime)

		self.LastSourcePosition = self.SourcePosition
		self.LastSourcePositionTime = time + 0.001

		local relativeSourcePosition = self.SourcePosition - webaudio.eye_pos
		local distanceToSource = relativeSourcePosition:Length()

		if distanceToSource < self.SourceRadius then
			local pan = relativeSourcePosition:GetNormalized():Dot(webaudio.eye_ang:Right())
			local volumeFraction = math.Clamp(1 - distanceToSource / self.SourceRadius, 0, 1) ^ 6
			volumeFraction = volumeFraction * 0.5

			self:SetRightVolume((math.Clamp(1 + pan, 0, 1) * volumeFraction) + self.AdditiveVolumeFraction)
			self:SetLeftVolume((math.Clamp(1 - pan, 0, 1) * volumeFraction) + self.AdditiveVolumeFraction)

			if self:GetDoppler() and webaudio.eye_velocity then
				local relativeSourceVelocity = self.SourceVelocity - webaudio.eye_velocity
				local relativeSourceSpeed    = relativeSourcePosition:GetNormalized():Dot(-relativeSourceVelocity) * 0.0254

				self:UpdatePlaybackSpeed(relativeSourceSpeed / webaudio.speed_of_sound)
			end

			self.ListenerOutOfRadius = false
		else
			self:OutOfRadius()
		end
	end

	function META:OutOfRadius()
		if not self.ListenerOutOfRadius then
			self:SetRightVolume(0)
			self:SetLeftVolume(0)
			self.ListenerOutOfRadius = true
		end
	end

	function META:SetSourceEntity(ent, dont_remove)
		self.SourceEntity = ent

		if not dont_remove and ent:IsValid() then
			ent:CallOnRemove("webaudio_remove_stream_" .. tostring(self), function()
				if self:IsValid() then
					self:Remove()
				end
			end)
		end
	end


	function META:Think()
		if self.Paused then return end

		self:UpdateVolume()
	end

	function META:__newindex(key, val)
		if key == "OnFFT" then
			if isfunction(val) then
				self:Call(".usefft(true)")
			else
				self:Call(".usefft(false)")
			end
		end

		rawset(self, key, val)
	end

	function META:__tostring()
		return string.format("stream[%p][%d][%s]", self, self:GetId(), self:GetUrl())
	end

	-- Internal browser message handlers
	function META:HandleCallBrowserMessage(methodName, ...)
		if not self[methodName] then return end

		self[methodName](self, ...)
	end

	function META:HandleFFTBrowserMessage(serializeFFTData)
		local fftArray = CompileString(serializeFFTData, "stream_fft_data")()
		self.OnFFT(fftArray)
	end

	function META:HandleLoadedBrowserMessage(sampleCount)
		self.Loaded = true

		self.SampleCount = sampleCount

		queue_javascript()
		self:SetFilterType(0)
		self:SetMaxLoopCount(self:GetMaxLoopCount())
		self:SetEcho(self:GetEcho())
		self:SetEchoFeedback(self:GetEchoFeedback())
		self:SetEchoDelay(self:GetEchoDelay())
		execute_javascript()

		if self.OnLoad then
			self:OnLoad()
		end

		if self.js_queue then
			for _, code in ipairs(self.js_queue) do
				run_javascript(code)
			end
			self.js_queue = nil
		end
	end

	function META:HandlePositionBrowserMessage(samplePosition)
		self.SamplePosition = samplePosition
	end

	webaudio.stream_meta = META
end

webaudio.streams = webaudio.streams or {}

webaudio.last_stream_id = 0

function webaudio.CreateStream(path)
	webaudio.Initialize()

	path = "../" .. path
	local self = setmetatable({}, webaudio.stream_meta)

	webaudio.last_stream_id = webaudio.last_stream_id + 1
	self:SetId(webaudio.last_stream_id)
	self:SetUrl(path)

	webaudio.streams[self:GetId()] = self

	run_javascript(string.format("CreateStream(%q, %i)", self:GetUrl(), self:GetId()))

	return self
end

function webaudio.Panic(strong)
	for k,v in pairs(webaudio.streams) do
		v:Remove()
	end
	webaudio.last_stream_id = 0
end

function webaudio.GetStream(streamId)
	return webaudio.streams[streamId] or NULL
end

function webaudio.StreamExists(streamId)
	return webaudio.streams[streamId] ~= nil
end

return webaudio
