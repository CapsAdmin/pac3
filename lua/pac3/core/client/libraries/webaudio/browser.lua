-- made by Morten and CapsAdmin

pac.webaudio = pac.webaudio or {}
local webaudio = pac.webaudio

webaudio.Browser = webaudio.Browser or {}

webaudio.Browser.States =
{
	Uninitialized = 0,
	Initializing  = 1,
	Initialized   = 2
}

if webaudio.Browser.Control and
   webaudio.Browser.Control:IsValid () then
	webaudio.Browser.Control:Remove ()
	webaudio.Browser.Control = nil
end

webaudio.Browser.State           = webaudio.Browser.States.Uninitialized
webaudio.Browser.Control         = nil
webaudio.Browser.JavascriptQueue = {}

webaudio.Browser.Volume          = nil

function webaudio.Browser.Initialize()
	if webaudio.Browser.State ~= webaudio.Browser.States.Uninitialized then return end
	
	webaudio.Browser.State = webaudio.Browser.States.Initializing
	
	if webaudio.Browser.Control then webaudio.Browser.Control:Remove() end

	webaudio.Browser.Control = vgui.Create("DHTML")
	webaudio.Browser.Control:SetVisible(false)
	webaudio.Browser.Control:SetPos(ScrW(), ScrH())
	webaudio.Browser.Control:SetSize(1, 1)
	
	local lastMessage = nil
	webaudio.Browser.Control.ConsoleMessage = function(self, message)
		-- why does awesomium crash in the first place?
		if msg == "Uncaught ReferenceError: lua is not defined" then
			webaudio.Browser.State = webaudio.Browser.States.Uninitialized
		end

		if lastMessage ~= message then 
			lastMessage = message 
			Msg("[PAC] ")
			MsgN(message) 
		end 
	end

	webaudio.Browser.Control:AddFunction("lua", "print", webaudio.DebugPrint)

	webaudio.Browser.Control:AddFunction("lua", "message", function(messageType, ...)
		local args = {...}
		
		webaudio.DebugPrint(messageType .. " " .. table.concat(args, ", "))
		
		if messageType == "initialized" then
			webaudio.Browser.State = webaudio.Browser.States.Initialized
			webaudio.SampleRate = args[1]
		elseif messageType == "stream" then
			local stream = webaudio.Streams.GetStream(tonumber(args[2]) or 0)
			if not stream then return end
			
			local messageType = args[1]
			stream:HandleBrowserMessage(messageType, unpack(args, 3, table.maxn(args)))
		end
	end)

	--webaudio.Browser.Control:OpenURL("asset://garrysmod/lua/pac3/core/client/libraries/urlogg.lua")
	webaudio.Browser.Control:SetHTML(webaudio.Browser.HTML)
end

function webaudio.Browser.IsInitializing()
	return webaudio.Browser.State == webaudio.Browser.States.Initializing
end

function webaudio.Browser.IsInitialized()
	return webaudio.Browser.State == webaudio.Browser.States.Initialized
end

-- Javascript
function webaudio.Browser.RunJavascript(code)
	webaudio.Browser.Control:QueueJavascript(code)
end

function webaudio.Browser.QueueJavascript(code)
	webaudio.Browser.JavascriptQueue [#webaudio.Browser.JavascriptQueue + 1] = code
end

function webaudio.Browser.Think()
	if #webaudio.Browser.JavascriptQueue == 0 then return end
	
	local code = table.concat(webaudio.Browser.JavascriptQueue, "\n")
	webaudio.Browser.RunJavascript(code)
	webaudio.Browser.JavascriptQueue = {}
end

-- Audio
function webaudio.Browser.SetVolume (volumeFraction)
	if webaudio.Browser.Volume == volumeFraction then return end
	
	webaudio.Browser.Volume = volumeFraction
    webaudio.Browser.QueueJavascript(string.format("gain.gain.value = %f", volumeFraction))
end

webaudio.Browser.HTML = [==[
<script>

window.onerror = function(description, url, line)
{
    lua.print("Unhandled exception at line " + line + ": " + description)
}

function lerp(x, y, a)
{
    return x * (1 - a) + y * a;
}

var audio, gain, processor, analyser, streams = []

function open()
{
    if(audio)
    {
        audio.destination.disconnect()
        delete audio
        delete gain
    }

    audio = new webkitAudioContext
    processor = audio.createJavaScriptNode(4096, 0, 1);
    gain = audio.createGainNode()

    processor.onaudioprocess = function(event)
    {
        var outl = event.outputBuffer.getChannelData(0);
        var outr = event.outputBuffer.getChannelData(1);
    
        for(var i = 0; i < event.outputBuffer.length; ++i)
        {
            outl[i] = 0;
            outr[i] = 0;
        }

        for(var i in streams)
        {
            var stream = streams[i]

            if(!stream.use_echo && (stream.paused || (stream.vol_left < 0.001 && stream.vol_right < 0.001)))
            {
                continue;
            }
            
            var echol
            var echor
            
            if (stream.use_echo && stream.echo_buffer)
            {
                echol = stream.echo_buffer.getChannelData(0);
                echor = stream.echo_buffer.getChannelData(1);
            }

            var inl = stream.buffer.getChannelData(0)
            var inr = stream.buffer.numberOfChannels == 1 ? inl : stream.buffer.getChannelData(1)

            var sml = 0
            var smr = 0

            for(var j = 0; j < event.outputBuffer.length; ++j)
            {

                if (stream.use_smoothing)
                {
                    stream.speed_smooth = stream.speed_smooth + (stream.speed - stream.speed_smooth) * 0.001
                    stream.vol_left_smooth = stream.vol_left_smooth + (stream.vol_left - stream.vol_left_smooth) * 0.001
                    stream.vol_right_smooth = stream.vol_right_smooth + (stream.vol_right - stream.vol_right_smooth) * 0.001
                }
                else
                {
                    stream.speed_smooth = stream.speed
                    stream.vol_left_smooth = stream.vol_left_smooth
                    stream.vol_right_smooth = stream.vol_right_smooth
                }

                var length = stream.buffer.length;

                if (stream.paused || stream.max_loop > 0 && stream.position > length * stream.max_loop)
                {
                    if (stream.use_echo)
                    {
                        stream.done_playing = true
                    }
                    else
                    {
                        break
                    }              
                }
                else
                {
                    stream.done_playing = false
                }                

                var index = (stream.position >> 0) % length;                
                var echo_index = (stream.position >> 0) % stream.echo_delay;
                
                var left = 0
                var right = 0
                
                if (!stream.done_playing)
                {
                    // filters
                    if (stream.filter_type != 0)
                    {
                        sml = sml + (inl[index] - sml) * stream.filter_fraction
                        smr = smr + (inr[index] - smr) * stream.filter_fraction
    
                        if (stream.filter_type == 2)
                        {
                            left = (inl[index] - sml) * stream.vol_left_smooth
                            right = (inr[index] - smr) * stream.vol_right_smooth
                        }
                        else
                        {
                            left = sml * stream.vol_left_smooth
                            right = smr * stream.vol_right_smooth
                        }
                    }
                    else
                    {
                        left = inl[index] * stream.vol_left_smooth
                        right = inr[index] * stream.vol_right_smooth
                    }
                }
                
                if (stream.use_echo)
                {   
                    echol[echo_index] = echol[echo_index] * stream.echo_feedback + left
                    echor[echo_index] = echor[echo_index] * stream.echo_feedback + right
                    
                    outl[j] += echol[echo_index]
                    outr[j] += echor[echo_index]
                }
                else
                {
                    outl[j] += left
                    outr[j] += right
                }                                
                
                stream.position += stream.speed_smooth
            }
        }
    };

    processor.connect(gain)
    gain.connect(audio.destination)

    lua.message("initialized", audio.sampleRate)
}

function close()
{
    if(audio)
    {
        audio.destination.disconnect();
        delete audio
        audio = null
        lua.message("uninitialized")
    }
}

var buffer_cache = []

function download_buffer(url, callback, skip_cache, id)
{
    if (!skip_cache && buffer_cache[url])
    {
        callback(buffer_cache[url])

        return
    }

    var request = new XMLHttpRequest

    request.open("GET", url)
    request.responseType = "arraybuffer"
    request.send()

    request.onload = function()
    {
        lua.print("decoding " + url + " " + request.response.byteLength + " ...")

        audio.decodeAudioData(request.response,

            function(buffer)
            {
                lua.print("decoded " + url + " successfully")

                callback(buffer)

                buffer_cache[url] = buffer
            },

            function(err)
            {
                lua.print("decoding error " + url + " " + err)
				lua.message("stream", "call", id, "OnError", "decoding failed", err)
            }
        )
    }

    request.onprogress = function(event)
    {
        lua.print("downloading " +  (event.loaded / event.total) * 100)
    }

    request.onerror = function()
    {
        lua.print("downloading " + url + " errored")
		lua.message("stream", "call", id, "OnError", "download failed")
    };
}

function createStream(url, id, skip_cache)
{
    lua.print("Loading " + url)

    download_buffer(url, function(buffer)
    {
        var stream = {}

        stream.id = id
        stream.position = 0
        stream.buffer = buffer
        stream.url = url
        stream.speed = 1 // 1 = normal pitch
        stream.max_loop = 1 // -1 = inf
        stream.vol_left = 1
        stream.vol_right = 1
        stream.filter = audio.createBiquadFilter();
        stream.paused = true
        stream.use_smoothing = true
        stream.echo_volume = 0
        stream.filter_type = 0
        stream.filter_fraction = 1
        stream.done_playing = false
        
        stream.use_echo = false
        stream.echo_feedback = 0.75
        stream.echo_buffer = false

        stream.vol_left_smooth = 0
        stream.vol_right_smooth = 0
        stream.speed_smooth = stream.speed

        stream.play = function(stop, position)
        {
            if(position !== undefined)
            {
                stream.position = position
            }

            stream.paused = !stop
        };

        stream.usefft = function(enable)
        {
            // later
        }
		
		stream.useEcho = function(b) {
			stream.use_echo = b
			
			if (b)
			{
				stream.setEchoDelay(stream.echo_delay)
			}
			else
			{
				stream.echo_buffer = undefined
			}
		}
		        
        stream.setEchoDelay = function(x) {
		
            if(stream.use_echo && (!stream.echo_buffer || (x != stream.echo_buffer.length))) {
                var size = 1;
                
                while((size <<= 1) < x);
                
				stream.echo_buffer = audio.createBuffer(2, size, audio.sampleRate);
            }
            
            stream.echo_delay = x;
        }
        
        streams[id] = stream

        lua.message("stream", "loaded", id, buffer.length)
    }, skip_cache, id)
}

function destroyStream(id)
{
}

open()

</script>

]==]