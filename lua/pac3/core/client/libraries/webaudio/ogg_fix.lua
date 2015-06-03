// Hacky fix for oggs.
// The problem is not completely bass, its also holly_ogg.dll.
// If we stream them directly from the disk, then they work.

local ogg = {}
ogg.debug = false
ogg.enabled = false 


if !file.Exists("scache/","DATA") then
    file.CreateDir("scache")
end


function ogg.Download(url,callback,nocache)
    local urlsum  = os.time() ..  util.CRC(url)
    if not nocache then 
        if file.Exists("scache/"  .. urlsum .. ".txt", "DATA") then 
            callback(true, urlsum,"200")
            return true
        end
    end

    http.Fetch( url,
        function( body, len, headers, code )
            file.Write("scache/" .. urlsum .. ".txt",body)
            if debug then 
               MsgC(Color(255,255,0),"[OGG]: WRITE - > ") MsgC(Color(255,0,0), urlsum .. ".txt \n" )
            end
            callback(true,urlsum,code)
        end,
        function( error )
            callback(false,nil,error)
        end
    );
end
function ogg.enable(enabled)
    if enabled then 
        ogg.enabled = true 
        if sound._OldPlayURL then 
                sound.PlayURL = sound._OldPlayURL
        end
        sound._OldPlayURL = sound.PlayURL
        function sound.PlayURL(url,args,func,median)
            if median then 
                print(url,args,func)
                assert(type(func)=="function","Argument #3 to sound.PlayURL. Function expected, got " .. type(func))
                assert(type(url)=="string","Argument #1 to sound.PlayURL. String expected, got " .. type(url))
                assert(type(args)=="string","Argument #2 to sound.PlayURL. String expected, got " .. type(args))
                
                ogg.Download(url,function(succ,fname,err)
                    if not succ then
                        func(nil,0xFFF,"HTTP ERROR .. err")
                    end
                    if succ then 
                        sound.PlayFile("data/scache/" .. fname .. ".txt",args,func)            
                    end
                
                end)
            else
                sound._OldPlayURL(url,args,func)
                
            end
        end
    else 
        ogg.enabled = false
        if sound._OldPlayURL then 
            sound.PlayURL = sound._OldPlayURL
            sound._OldPlayURL = nil
        end
    end

end


ogg.cvar = CreateConVar( "pac_ogg_fix", "0", FCVAR_ARCHIVE , "Enable the broken fix for OGG Streaming") 


cvars.AddChangeCallback( "pac_ogg_fix", function( convar_name, value_old, value_new )
    if convar_name = "pac_ogg_fix" then 
            if tonumber(value_new)==1 then 
                ogg.enable(true)
            else
                ogg.enable(false)
            end
    end
end )


timer.Simple(0,function()
        ogg.enable(ogg.cvar:GetBool())
end)




pac.oggfix = ogg



