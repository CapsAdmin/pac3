--[[
    NetStream
    [url]http://www.revotech.org[/url]
     
    Copyright (c) 2012 Alexander Grist-Hucker
     
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
    documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
    the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
    and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 
    The above copyright notice and this permission notice shall be included in all copies or substantial portions 
    of the Software.
 
 
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
    TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
    CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
    DEALINGS IN THE SOFTWARE.
     
    Credits to:
        Alexandru-Mihai Maftei aka Vercas for vON.
        [url]https://dl.dropbox.com/u/1217587/GMod/Lua/von%20for%20GMOD.lua[/url]
--]]
 
 
local type, error, pcall, pairs, AddCSLuaFile, require, _player = type, error, pcall, pairs, AddCSLuaFile, require, player
local von = pac.von
 
if (!von) then
    error("NetStream: Unable to find vON!");
end;
 
local netstream = {};
netstream.stored = {};
 
 
-- A function to hook a data stream.
function netstream.Hook(name, Callback)
    netstream.stored[name] = Callback;
end;
 
 
if (SERVER) then
    util.AddNetworkString("NetStreamDS");
 
    -- A function to start a net stream.
    function netstream.Start(player, name, data)
        local recipients = {};
        local bShouldSend = false;
     
        if (type(player) != "table") then
            if (!player) then
                player = _player.GetAll();
            else
                player = {player};
            end;
        end;
         
        for k, v in pairs(player) do
            if (type(v) == "Player") then
                recipients[#recipients + 1] = v;
                 
                bShouldSend = true;
            elseif (type(k) == "Player") then
                recipients[#recipients + 1] = k;
             
                bShouldSend = true;
            end;
        end;
         
        local dataTable = {data = data};
        local vonData = von.serialize(dataTable);
        local encodedData = util.Compress(vonData);
             
        if (encodedData and #encodedData > 0 and bShouldSend) then
            net.Start("NetStreamDS");
                net.WriteString(name);
                net.WriteUInt(#encodedData, 32);
                net.WriteData(encodedData, #encodedData);
            net.Send(recipients);
        end;
    end;
     
    net.Receive("NetStreamDS", function(length, player)
        local NS_DS_NAME = net.ReadString();
        local NS_DS_LENGTH = net.ReadUInt(32);
        local NS_DS_DATA = net.ReadData(NS_DS_LENGTH);
         
        if (NS_DS_NAME and NS_DS_DATA and NS_DS_LENGTH) then
            NS_DS_DATA = util.Decompress(NS_DS_DATA);
             
            if (!NS_DS_DATA) then
                error("NetStream: The data failed to decompress!");
                 
                return;
            end;
             
            player.nsDataStreamName = NS_DS_NAME;
            player.nsDataStreamData = "";
             
            if (player.nsDataStreamName and player.nsDataStreamData) then
                player.nsDataStreamData = NS_DS_DATA;
                                 
                if (netstream.stored[player.nsDataStreamName]) then
                    local bStatus, value = pcall(von.deserialize, player.nsDataStreamData);
                     
                    if (bStatus) then
                        netstream.stored[player.nsDataStreamName](player, value.data);
                    else
                        error("NetStream: "..value);
                    end;
                end;
                 
                player.nsDataStreamName = nil;
                player.nsDataStreamData = nil;
            end;
        end;
         
        NS_DS_NAME, NS_DS_DATA, NS_DS_LENGTH = nil, nil, nil;
    end);
else
    -- A function to start a net stream.
    function netstream.Start(name, data)
        local dataTable = {data = data};
        local vonData = von.serialize(dataTable);
        local encodedData = util.Compress(vonData);
         
        if (encodedData and #encodedData > 0) then
            net.Start("NetStreamDS");
                net.WriteString(name);
                net.WriteUInt(#encodedData, 32);
                net.WriteData(encodedData, #encodedData);
            net.SendToServer();
        end;
    end;
     
    net.Receive("NetStreamDS", function(length)
        NS_DS_NAME = net.ReadString();
        NS_DS_LENGTH = net.ReadUInt(32);
        NS_DS_DATA = net.ReadData(NS_DS_LENGTH);
         
        if (NS_DS_NAME and NS_DS_DATA and NS_DS_LENGTH) then
            NS_DS_DATA = util.Decompress(NS_DS_DATA);
 
 
            if (!NS_DS_DATA) then
                error("NetStream: The data failed to decompress!");
                 
                return;
            end;
                         
            if (netstream.stored[NS_DS_NAME]) then
                local bStatus, value = pcall(von.deserialize, NS_DS_DATA);
             
                if (bStatus) then
                    netstream.stored[NS_DS_NAME](value.data);
                else
                    error("NetStream: "..value);
                end;
            end;
        end;
         
        NS_DS_NAME, NS_DS_DATA, NS_DS_LENGTH = nil, nil, nil;
    end);
end;

pac.netstream = netstream