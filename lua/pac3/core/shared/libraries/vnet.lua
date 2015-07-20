--[[	vNet 1.1.8

	Copyright 2014 Alexandru-Mihai Maftei
			   aka Vercas

	The code below is subject to my license at http://www.vercas.com/license

	Containing GitHub Repository:
		https://github.com/vercas/vNet-for-GMod

	Here is a summary of it: do whatever you want as long as you acknowledge my contribution and preserve the license.

	To expand on that:
    -	Do not remove, alter or replace the license and copyright statements under any circumstances.
    -	I am not responsible for how, where and why the code is used.
    -	If you modify the code, publish your changes under the same license. If the changes are substantial, you may only append your copyright statement next to mine.
    -	If a project uses the code, ideally you should credit my work somewhere in the software if possible. Exception makes open-source software where the code is redistributed in the repository.
    -	The code may be used for personal, academic or commercial purposes as long as the terms of the licenses are met.

    Please check the full license text provided in the link above before continuing.
	If you disagree with the terms of the license, do not use the code.

-----------------------------------------------------------------------------------------------------------------------------
	
	Thanks to the following people for their contribution:
		-	Expression Advanced 2 Community, MDave [HUN]		Directly or indirectly asked me to write a piece of code to 
																solve a specific issue: bulk data transfer. Without their 
																incentive, this would not exist.
		-	Alex Grist											Beta tester; reported several major bugs.
		-	Rusketh												Beta tester; pointed out issue with sending entities; 
																suggested check for networked strings when writing to
																buffers; Suggested 'Broadcast' function for outgoing packets;
																Reported network string case insensitivity issue.

		-	People who contributed on the GitHub repository by reporting bugs, posting fixes, etc.

-----------------------------------------------------------------------------------------------------------------------------
	
	New in this version:
	-	I haven't touched GMod in some time...
--]]



if SERVER then
	AddCSLuaFile()
end

if not hook or not hook.Add then require "hook" end
if not net or not net.Receivers then require "net" end



local Receive, Start, Send, Broadcast, SendToServer, WriteString, WriteInt, WriteUInt, WriteData, ReadString, ReadInt, ReadUInt, ReadData
 = net.Receive, net.Start, net.Send, net.Broadcast, net.SendToServer, net.WriteString, net.WriteInt, net.WriteUInt, net.WriteData, net.ReadString, net.ReadInt, net.ReadUInt, net.ReadData
 local file, math_floor, math_ceil, math_random, math_min, math_max, table_remove, string_sub, type, player_GetAll, util, hook = file, math.floor, math.ceil, math.random, math.min, math.max, table.remove, string.sub, type, player.GetAll, util, hook
local Color, now, SERVER, CLIENT, IsValid, IsEntity = Color, RealTime, SERVER, CLIENT, IsValid, IsEntity

--[[local _p = print
local function print(...)
	local t = {...}
	for i = #t, 1, -1 do t[i] = tostring(t[i]) end
	local s = table.concat(t, "\t")
	file.Append("vnetlog.txt", s .. "\n")
	_p(s)
end
file.Append("vnetlog.txt", "\n\n----------------------------------------------------------------\n\t" .. os.date() .. "\n\n")--]]

--	--	--	--	--	--
--	Misecllaneous	--
--	--	--	--	--	--



if file.IsDir("pacvnet", "DATA") then
	local files, dirs = file.Find("pacvnet/*", "DATA")

	for i = 1, #files do
		file.Delete("pacvnet/" .. files[i])
	end
else
	file.CreateDir("pacvnet")
end

local function getFile()
	while true do
		local id = math_random(-2147483648, 2147483647)
		local path = "pacvnet/queue_" .. id .. ".txt"

		if not file.Exists(path, "DATA") then
			return path
		end
	end
end



local chunk_size_min, chunk_size_current, chunk_size_max = 64, 256, 65535 - 4096 --	Just accounting for errors and leaving 4 KiB for the engine.
local package_fraction_min, package_fraction_current, package_fraction_max = 16, 64, 65535 - 1024	--	A generous amount.
local compression_threshold_low_min, compression_threshold_low_current, compression_threshold_low_max = 32, 512, 65535 / 2 - 1024	--	The default is safe for pretty much any piece of data.
local compression_threshold_high_min, compression_threshold_high_current, compression_threshold_high_max = 32, 4 * 1024 * 1024, 100 * 1024 * 1024	--	The default is safe for pretty much any piece of data.



--[[if cvars and cvars.Number then
	local padding = 6 * 1000	--	6 KB reserved for the engine and other stuff
	local tickrate = 1000 / 15	--	15 milliseconds per tick

	local rate = cvars.Number("rate")

	if CLIENT then
		chunk_size_current = math_max(chunk_size_min, math_min(chunk_size_max, (rate - padding) / tickrate))
	else
		local maxplayers = cvars.Number("maxplayers")

		chunk_size_current = math_max(chunk_size_min, math_min(chunk_size_max, ((rate / maxplayers) - padding) / tickrate))
	end

	package_fraction_current = math_max(package_fraction_min, math_min(package_fraction_max, math_floor(chunk_size_current / 5)))
end--]] --	Totally futile.



local TYPE_FRAG_WHOLE = 0
local TYPE_FRAG_START = 1
local TYPE_FRAG_MID = 2
local TYPE_FRAG_END = 3

local TYPE_FRAG_CANCEL_MINE = 4
local TYPE_FRAG_CANCEL_YOURS = 5

local TYPE_FRAG_THROTTLE_YOURSELF = 6

local TYPE_STREAM_END = -1

local NODE_SERVER = 255	--	1111 1111
local NODE_STOP = 240	--	1111 0000


local vnet = {}


--	--	--	--	--
--	Operation	--
--	--	--	--	--



local msg_name = "pac_vNet"

if SERVER then
	util.AddNetworkString(msg_name)
end



local counter = 0

local function getNextId()
	local ret = counter

	if counter == 2147483647 then
		counter = -2147483648
	else
		counter = counter + 1
	end

	return ret
end



local function pckPrint(pck)
	local t = {"["}

	t[#t+1] = "ID: "
	t[#t+1] = tostring(pck.ID)

	t[#t+1] = " | Type: "
	t[#t+1] = tostring(pck.Type)

	t[#t+1] = " | Progress: "
	t[#t+1] = tostring(pck.Progress)

	t[#t+1] = " | Compressed: "
	t[#t+1] = tostring(pck.Compressed)

	t[#t+1] = " | Size: "
	t[#t+1] = tostring(pck.Size)

	t[#t+1] = " | Completed: "
	t[#t+1] = tostring(pck.Completed)

	t[#t+1] = " | Clones: "
	
	if type(pck.Clones) == "table" then
		t[#t+1] = #pck.Clones
	else
		t[#t+1] = tostring(pck.Clones)
	end

	t[#t+1] = " | Includes Server: "
	t[#t+1] = tostring(pck.IncludeServer)

	t[#t+1] = " | Nodes: "
	
	if type(pck.Nodes) == "table" then
		t[#t+1] = "("

		for i = 1, #pck.Nodes do
			if i > 1 then
				t[#t+1] = "; "
			end

			t[#t+1] = tostring(pck.Nodes[i])
		end

		t[#t+1] = ")"
	else
		t[#t+1] = tostring(pck.Nodes)
	end

	t[#t+1] = "]"

	return table.concat(t)
end

--	Sending and receiving

local post
local TRACKING, trackFed, trackReg, trackMid, trackEnd
local enqueue, enqueueMisc, cancel_in, cancel_out, fracStart, fracMiddle, fracEnd, fracWhole, fracThrottle
local stepsize = 0.035

do
	local writeNodes, readNodes

	local function writePacket(pck, prog, frac, dequeue)
		if type(pck.Nodes) ~= "boolean" and type(pck.Nodes) ~= "table" and not IsValid(pck.Nodes) then
			--print("not valid shit for", pckPrint(pck))

			return prog, false
		end

		if not pck.Completed and pck.Progress == #pck.Data and pck.Progress ~= 0 then
			--print("skipping", pckPrint(pck))
			return prog, false
		end

		--print("writing", os.date(), os.time(), SysTime(), pckPrint(pck))

		if #pck.Data <= frac and pck.Completed then
			WriteInt(TYPE_FRAG_WHOLE, 8)								--	Fragment type
			WriteUInt(#pck.Data, 16)							--	Payload size
			WriteData(pck.Data, #pck.Data)						--	Payload itself
			prog = writeNodes(pck, prog)						--	Nodes (source, targets)
			WriteUInt(pck.Compressed and 255 or 0, 8)			--	Compressed or not
			WriteInt(pck.Type, 32)								--	Type

			dequeue()

			prog = prog + #pck.Data + 10

			if TRACKING then trackFed(false, pck) end

			--print("WHOLE")
		else
			if pck.Progress == 0 then
				local data = string_sub(pck.Data, 1, frac)

				WriteInt(TYPE_FRAG_START, 8)					--	Fragment type
				WriteUInt(#data, 16)							--	Payload fragment size
				WriteData(data, #data)							--	Payload fragment
				prog = writeNodes(pck, prog)					--	Nodes (source, targets)
				WriteUInt(pck.Compressed and 255 or 0, 8)		--	Compressed or not
				WriteInt(pck.Size, 32)							--	Payload actual size
				WriteInt(pck.Type, 32)							--	Type
				pck.Progress = #data

				prog = prog + #data + 10

				if TRACKING then trackReg(false, pck) end

				--print("START")
			elseif pck.Progress + frac < #pck.Data or not pck.Completed then	--	Incomplete packets will not have their end sent yet.
				local data = string_sub(pck.Data, pck.Progress + 1, pck.Progress + frac)

				WriteInt(TYPE_FRAG_MID, 8)						--	Fragment type
				WriteUInt(#data, 16)							--	Payload fragment size
				WriteData(data, #data)							--	Payload fragment
				pck.Progress = pck.Progress + #data

				prog = prog + #data

				if TRACKING then trackMid(false, pck) end

				--print("MIDDLE")
			else
				local data = string_sub(pck.Data, pck.Progress + 1)

				WriteInt(TYPE_FRAG_END, 8)						--	Fragment type
				WriteUInt(#data, 16)							--	Payload fragment size
				WriteData(data, #data)							--	Payload fragment

				dequeue()

				prog = prog + #pck.Data - pck.Progress

				pck.Progress = #pck.Data

				if TRACKING then trackEnd(false, pck) end
				--print("END")
			end

			WriteInt(pck.ID, 32)								--	Fragment ID, because this is not a whole package. [sadface]

			prog = prog + 4
		end

		--print("returning writing", prog + 3, true)

		return prog + 3, true // 3 bytes for data length prefix and fraction type
	end

	local function writeMisc(typ, val, prog)
		WriteInt(typ, 8)
		WriteInt(val, 32)

		return prog + 5
	end

	local function readPacket(ply, len)
		local fractype = ReadInt(8)

		if fractype == TYPE_STREAM_END then
			return false, 0
		end

		if TYPE_FRAG_CANCEL_MINE == fractype then
			local id = ReadInt(32)

			cancel_in(id, ply)

			len = len - 4
		elseif TYPE_FRAG_CANCEL_YOURS == fractype then
			local id = ReadInt(32)

			cancel_out(id, ply)

			len = len - 4
		elseif TYPE_FRAG_THROTTLE_YOURSELF == fractype then
			local val = ReadInt(32)

			fracThrottle(val, ply)

			len = len - 4
		else
			local payloadSize = ReadUInt(16)

			if payloadSize > len - 6 then
				error("payload size would indicate reading beyond end of stream!")
			end

			local payload = ReadData(payloadSize)

			len = len - 2 - payloadSize

			if TYPE_FRAG_WHOLE == fractype then
				local nodes
				nodes, len = readNodes(len)
				local compressed = ReadUInt(8) >= 128
				local pcktype = ReadInt(32)

				len = len - 5

				fracWhole(pcktype, payload, compressed, nodes, ply, true)
			elseif TYPE_FRAG_START == fractype then
				local nodes
				nodes, len = readNodes(len)
				local compressed = ReadUInt(8) >= 128
				local size = ReadInt(32)
				local pcktype = ReadInt(32)
				local id = ReadInt(32)

				len = len - 13

				fracStart(id, pcktype, payload, compressed, size, nodes, ply)
			elseif TYPE_FRAG_MID == fractype then
				local id = ReadInt(32)

				len = len - 4

				fracMiddle(id, payload, ply)
			elseif TYPE_FRAG_END == fractype then
				local id = ReadInt(32)

				len = len - 4

				fracEnd(id, payload, ply)
			end
		end

		return true, len
	end



	if SERVER then
		writeNodes = function(pck, prog)
			if type(pck.Nodes) == "Player" then
				WriteUInt(pck.Nodes:EntIndex(), 8)
			else
				WriteUInt(NODE_SERVER, 8)
			end

			return prog + 1
		end

		readNodes = function(len)
			local includeServer = false
			local targets = {}

			repeat
				local val = ReadUInt(8)

				if val == NODE_SERVER then
					targets[#targets+1] = true
				elseif val ~= NODE_STOP then
					targets[#targets+1] = Entity(val)
				end

				len = len - 1
			until val == NODE_STOP

			--local ts = {} for i = #targets, 1, -1 do ts[i] = tostring(targets[i]) end
			--print("reading nodes from client to server ", unpack(ts))

			return targets, len
		end


		
		local queue_outgoing, misc_outgoing = {}, {}
		stepsize = {}

		for i = 1, 128 do
			queue_outgoing[i] = {}
			misc_outgoing[i] = {}
			stepsize[i] = 0.035
		end

		enqueue = function(ind, pck, src)
			pck = { 
				ID = getNextId(), 
				Type = pck.Type, 
				Progress = 0, 
				Data = pck.Data, 
				IncludeServer = false, 
				Nodes = src, 
				Compressed = pck.Compressed,
				Size = pck.Size,
				Completed = true, 
				Clones = false,
				DestinationIndex = ind,
			}

			local q = queue_outgoing[ind]
			q[#q+1] = pck

			return pck
		end

		enqueueMisc = function(ind, typ, val)
			misc_outgoing[ind][#misc_outgoing[ind]+1] = { typ, val }
		end

		local function peek(ind)
			return queue_outgoing[ind][1]
		end

		local function dequeue(ind)
			local ret = queue_outgoing[ind][1]

			table_remove(queue_outgoing[ind], 1)

			--[[MsgC(Color(255, 0, 255), "Dequeuing")
			Msg(" for ")
			MsgC(Color(0, 255, 255), Entity(ind), " ")
			print(pckPrint(ret))--]]

			return ret
		end

		local function dequeueMisc(ind)
			local ret = misc_outgoing[ind][1]

			if ret then
				table_remove(misc_outgoing[ind], 1)
			end

			return ret
		end



		local expiry_incoming, lastFlushes = {}, {}

		hook.Add("Think", "pac_vNet", function()
			local nao, toRemove = now(), {}

			for pck, data in pairs(expiry_incoming) do
				if nao > data[1] then	--	If zee tiem haz pasd
					toRemove[#toRemove+1] = pck	--	Must not modify while iterating

					enqueueMisc(data[2], TYPE_FRAG_CANCEL_YOURS, pck.ID)
				end
			end

			for i = #toRemove, 1, -1 do
				expiry_incoming[toRemove[i]] = nil	--	Must not modify while iterating.
			end

			local allplys = player_GetAll()

			for z = #allplys, 1, -1 do
				local ply = allplys[z]
				local ind = ply:EntIndex()
				local qc, tc, lf = queue_outgoing[ind], misc_outgoing[ind], lastFlushes[ind]

				if (not lf or (nao - lf) > stepsize[ind]) and (#qc > 0 or #tc > 0) then
					lastFlushes[ind] = nao

					--print(" -- new round", ply, lf, nao, " -- ")

					local function specificDequeue() return dequeue(ind) end

					local frac = math_max(package_fraction_current, math_floor((chunk_size_current - 14 - #tc * 5) / #qc))	//	"14" is the max size of extra data per packet.
					local prog, totalfails, suc = 0, 0, false

					Start(msg_name)

					repeat
						local cid = dequeueMisc(ind)

						if cid then
							prog = writeMisc(cid[1], cid[2], prog)
						else
							break
						end
					until cid == nil

					while prog < chunk_size_current and totalfails < #qc do
						local pck = peek(ind)

						if pck == nil then
							break
						end

						prog, suc = writePacket(pck, prog, frac, specificDequeue)

						if suc then
							frac = math_max(frac, math_floor((chunk_size_current - prog - 14) / #qc))	//	Without this, it could write multiple pieces of remaining packets, wasting some bytes.
						else
							totalfails = totalfails + 1

							specificDequeue()

							qc[#qc+1] = pck
						end
					end

					WriteInt(TYPE_STREAM_END, 8)

					Send(ply)
				end
			end
		end)



		local buffer_incoming = {}

		for i = 1, 128 do
			buffer_incoming[i] = {}
		end

		fracWhole = function(pcktype, payload, compressed, nodes, ply, whole)
			--print("GOT PACKET!", ply, pcktype, util.NetworkIDToString(pcktype), #payload, payload, compressed, nodes or "NIL NODES")

			local includeServer = false

			for i = #nodes, 1, -1 do
				if nodes[i] == true then
					includeServer = true
					table_remove(nodes, i)
				elseif whole then
					local pck = enqueue(nodes[i]:EntIndex(), { Type = pcktype, Data = payload, Size = #payload, Compressed = compressed }, ply)

					--[[MsgC(Color(255, 0, 0), "Bouncing ")
					Msg(" to ")
					MsgC(Color(0, 255, 255), tostring(nodes[i]), " ")
					print(pckPrint(pck))--]]
				end
			end

			if includeServer or TRACKING then
				local pck = { 
					ID = -1, 
					Type = pcktype, 
					Progress = #payload, 
					Data = payload, 
					IncludeServer = includeServer, 
					Nodes = ply, 
					Compressed = compressed, 
					Size = #payload,
					Completed = true, 
					Clones = false,
				}

				if TRACKING then trackFed(true, pck) end
				
				if includeServer then post(pck) end
			end

			--[[MsgC(Color(255, 255, 0), "Received")
			Msg(" from ")
			MsgC(Color(0, 255, 255), tostring(ply), " ")
			print(pckPrint(pck))--]]
		end

		fracStart = function(id, pcktype, payload, compressed, size, nodes, ply)
			local ind = ply:EntIndex()

			if buffer_incoming[ind][id] then
				enqueueMisc(ind, TYPE_FRAG_CANCEL_YOURS, id)

				error("a package with id " .. id .. " for " .. tostring(ply) .. " is already being processed")
			end

			local includeServer = false
			local aux = {}

			for i = #nodes, 1, -1 do
				if nodes[i] == true then
					includeServer = true
					table_remove(nodes, i)
				else
					local pck = enqueue(nodes[i]:EntIndex(), { Type = pcktype, Data = payload, Size = size, Compressed = compressed }, ply)

					pck.Completed = false

					aux[#aux+1] = pck

					--[[MsgC(Color(255, 0, 0), "Bouncing ")
					Msg(" to ")
					MsgC(Color(0, 255, 255), tostring(nodes[i]), " ")
					print(pckPrint(pck))--]]
				end
			end

			local pck = { 
				ID = id, 
				Type = pcktype, 
				Progress = #payload, 
				Data = payload, 
				IncludeServer = includeServer, 
				Nodes = ply, 
				Compressed = compressed, 
				Size = size,
				Completed = false, 
				Clones = aux,
				SourceIndex = ind,
			}

			for i = #aux, 1, -1 do
				aux[i].Owner = pck
			end

			buffer_incoming[ind][id] = pck

			expiry_incoming[pck] = { now() + ply:Ping() * 20 / 1000, ind }

			if TRACKING then trackReg(true, pck) end

			--[[MsgC(Color(255, 255, 0), "Starting")
			Msg(" from ")
			MsgC(Color(0, 255, 255), tostring(ply), " ")
			print(pckPrint(buffer_incoming[ind][id]))--]]
		end

		fracMiddle = function(id, payload, ply)
			local ind = ply:EntIndex()

			if not buffer_incoming[ind][id] then
				enqueueMisc(ind, TYPE_FRAG_CANCEL_YOURS, id)

				--error("a package with id " .. id .. " for " .. tostring(ply) .. " was not started")

				return -- ignore
			end

			local pck = buffer_incoming[ind][id]

			if not expiry_incoming[pck] then
				return -- should get cancelled soon
			end

			pck.Data = pck.Data .. payload
			pck.Progress = #pck.Data

			if pck.Clones then
				for i = #pck.Clones, 1, -1 do
					pck.Clones[i].Data = pck.Data
				end
			end

			expiry_incoming[pck][1] = now() + ply:Ping() * 20 / 1000 

			if TRACKING then trackMid(true, pck) end
		end

		fracEnd = function(id, payload, ply)
			local ind = ply:EntIndex()

			if not buffer_incoming[ind][id] then
				enqueueMisc(ind, TYPE_FRAG_CANCEL_YOURS, id)

				--error("a package with id " .. id .. " for " .. tostring(ply) .. " was not started")

				return -- ignore
			end

			local pck = buffer_incoming[ind][id]
			buffer_incoming[ind][id] = nil

			if not expiry_incoming[pck] then
				return -- should get cancelled soon
			end

			pck.Data = pck.Data .. payload
			pck.Progress = #pck.Data
			pck.Completed = true	--	Package is complete.

			if pck.Clones then
				for i = #pck.Clones, 1, -1 do
					pck.Clones[i].Data = pck.Data
					pck.Clones[i].Completed = true
				end
			end

			expiry_incoming[pck] = nil

			if TRACKING then trackEnd(true, pck) end

			if pck.IncludeServer then
				post(pck)
			end

			--fracWhole(pck.Type, pck.Data, pck.Compressed, pck.Nodes, ply, false)

			--[[MsgC(Color(255, 255, 0), "Finished")
			Msg(" from ")
			MsgC(Color(0, 255, 255), tostring(ply), " ")
			print(pckPrint(pck))--]]
		end


		cancel_in = function(id, ply)
			local ind = ply:EntIndex()

			if not buffer_incoming[ind][id] then
				--error("a package with id " .. id .. " for " .. tostring(ply) .. " was not started")

				return -- tolerate
			end

			local pck = buffer_incoming[ind][id]
			buffer_incoming[ind][id] = nil

			if pck.Clones then
				local aux = pck.Clones

				for i = #aux, 1, -1 do
					enqueueMisc(aux[i].DestinationIndex, TYPE_FRAG_CANCEL_MINE, aux[i].ID)
				end
			end
		end

		cancel_out = function(id, ply)
			local ind = ply:EntIndex()
			local qo = queue_outgoing[ind]
			
			for i = 1, #qo do
				local pck = qo[i]

				if pck.ID == id then
					table_remove(qo, i)
					enqueueMisc(ind, TYPE_FRAG_CANCEL_MINE, id)

					--	If this is a bounced packet, it might be the case to tell the source client to stop.

					if pck.Owner and pck.Owner.Clones then
						local pcki = pck.Owner	--	Now this is an incoming packet.
						local aux = pcki.Clones

						for j = #aux, 1, -1 do
							if aux[j] == pck then
								table_remove(aux, j)

								if not pck.IncludeServer and #aux == 0 then
									enqueueMisc(pcki.SourceIndex, TYPE_FRAG_CANCEL_YOURS, pcki.ID)

									buffer_incoming[pcki.SourceIndex][pcki.ID] = nil
								end

								break
							end
						end
					end

					return
				end
			end

			--error("a package with id " .. id .. " for " .. tostring(ply) .. " was not started")

			--	Just in case.
		end


		fracThrottle = function(amnt, ply)
			stepsize[ply:EntIndex()] = amnt / 1000000
		end



		net.Receive(msg_name, function(len, ply)
			len = len / 8
			local okay = true

			while okay do
				okay, len = readPacket(ply, len)
			end
		end)



		hook.Add("PlayerDisconnect", "pac_vNet Cleanup", function(ply)
			local ind = ply:EntIndex()

			queue_outgoing[ind] = {}
			misc_outgoing[ind] = {}
			buffer_incoming[ind] = {}
			stepsize[ind] = 0.035

			local toRemoveExpiry = {}

			for pck, data in pairs(expiry_incoming) do
				if pck.SourceIndex == ind then
					toRemoveExpiry[#toRemoveExpiry+1] = pck
				end
			end

			for i = #toRemoveExpiry, 1, -1 do
				expiry_incoming[toRemoveExpiry[i]] = nil
			end
		end)
	else
		writeNodes = function(pck, prog)
			if pck.IncludeServer then
				WriteUInt(NODE_SERVER, 8)

				prog = prog + 1
			end

			local tars = pck.Nodes
			for i = #tars, 1, -1 do
				WriteUInt(tars[i]:EntIndex(), 8)
			end

			WriteUInt(NODE_STOP, 8)

			return prog + 1 + #tars
		end

		readNodes = function(len)
			local val = ReadUInt(8)

			if val == NODE_SERVER then
				return true, len - 1
			else
				return Entity(val), len - 1
			end

			error("unknown packet node value: " .. val)
		end



		local queue_outgoing, misc_outgoing = {}, {}

		enqueue = function(pck)
			queue_outgoing[#queue_outgoing+1] = { 
				ID = getNextId(), 
				Type = pck.Type, 
				Progress = 0, 
				Data = pck.Data, 
				IncludeServer = pck.IncludeServer, 
				Nodes = pck.Targets, 
				Compressed = pck.Compressed, 
				Size = pck.Size,
				Completed = true, 
				Clones = false
			}
		end

		enqueueMisc = function(typ, val)
			misc_outgoing[#misc_outgoing+1] = { typ, val }
		end

		local function peek()
			return queue_outgoing[1]
		end

		local function dequeue()
			local ret = queue_outgoing[1]

			table_remove(queue_outgoing, 1)

			return ret
		end

		local function dequeueMisc()
			local ret = misc_outgoing[1]

			table_remove(misc_outgoing, 1)

			return ret
		end



		local expiry_incoming, lastFlush = {}

		hook.Add("Think", "pac_vNet", function()
			local nao = now()

			if (#queue_outgoing == 0 and #misc_outgoing == 0) or (lastFlush and (nao - lastFlush) < stepsize) then return end

			lastFlush = nao

			local frac = math_max(package_fraction_current, math_floor((chunk_size_current - 20) / #queue_outgoing))	//	"20" is the estimated max size of extra data per packet.
			local prog = 0

			Start(msg_name)

			repeat
				local cid = dequeueMisc()

				if cid then
					prog = writeMisc(cid[1], cid[2], prog)
				else
					break
				end
			until cid == nil

			while prog < chunk_size_current do
				local pck = peek()

				if pck == nil then
					break
				end

				prog = writePacket(pck, prog, frac, dequeue)

				frac = math_max(package_fraction_current, math_floor((chunk_size_current - prog - 20) / #queue_outgoing))
			end

			WriteInt(TYPE_STREAM_END, 8)

			SendToServer()
		end)



		local buffer_incoming = {}

		fracWhole = function(pcktype, payload, compressed, nodes, ply, whole)
			local pck = { 
				ID = -1, 
				Type = pcktype, 
				Progress = #payload, 
				Data = payload, 
				IncludeServer = node == true, 
				Nodes = nodes, 
				Compressed = compressed, 
				Size = #payload,
				Completed = true, 
				Clones = false
			}

			if TRACKING then trackFed(true, pck) end

			post(pck)

			--[[MsgC(Color(255, 255, 0), "Received")
			Msg(" from ")
			MsgC(Color(0, 255, 255), tostring(nodes), " ")
			print(pckPrint(pck))--]]
		end

		fracStart = function(id, pcktype, payload, compressed, size, nodes, ply)
			if buffer_incoming[id] then
				enqueueMisc(TYPE_FRAG_CANCEL_YOURS, id)

				error("a package with id " .. id .. " is already being processed")
			end

			buffer_incoming[id] = { 
				ID = id, 
				Type = pcktype, 
				Progress = #payload, 
				Data = payload, 
				IncludeServer = false, 
				Nodes = nodes, 
				Compressed = compressed, 
				Size = size,
				Completed = true, 
				Clones = false
			}

			if TRACKING then trackReg(true, pck) end
		end

		fracMiddle = function(id, payload, ply)
			if not buffer_incoming[id] then
				enqueueMisc(TYPE_FRAG_CANCEL_YOURS, id)

				--error("a package with id " .. id .. " was not started")

				return
			end

			local pck = buffer_incoming[id]

			pck.Data = pck.Data .. payload
			pck.Progress = #pck.Data

			if TRACKING then trackMid(true, pck) end
		end

		fracEnd = function(id, payload, ply)
			if not buffer_incoming[id] then
				enqueueMisc(TYPE_FRAG_CANCEL_YOURS, id)

				--error("a package with id " .. id .. " was not started")

				return
			end

			local pck = buffer_incoming[id]
			buffer_incoming[id] = nil

			pck.Data = pck.Data .. payload
			pck.Progress = #pck.Data

			if TRACKING then trackEnd(true, pck) end

			post(pck)

			--fracWhole(pck.Type, pck.Data, pck.Compressed, pck.Nodes, ply, false)
		end


		cancel_in = function(id, ply)
			if not buffer_incoming[id] then
				error("a package with id " .. id .. " for " .. tostring(ply) .. " was not started")

				return
			end

			buffer_incoming[id] = nil
		end

		cancel_out = function(id, ply)
			for i = 1, #queue_outgoing do
				local pck = queue_outgoing[i]

				if pck.ID == id then
					table_remove(queue_outgoing, i)
					enqueueMisc(TYPE_FRAG_CANCEL_MINE, id)
					return
				end
			end

			--error("a package with id " .. id .. " for " .. tostring(ply) .. " was not started")
		end


		fracThrottle = function(amnt, ply)
			stepsize = amnt / 1000000
		end



		net.Receive(msg_name, function(len)
			len = len / 8
			local okay = true

			while okay do
				okay, len = readPacket(true, len)
			end
		end)
	end
end



--	--	--	--	--
--	Packages	--
--	--	--	--	--



local function	_checkpck(self)
	if self.Sent then
		error("package is already sent")
	elseif self.Discarded then
		error("package is already discarded")
	end
end



local WritePacketIndex = {
	
}

function WritePacketIndex:Size()
	_checkpck(self)

	return self.File:Size()
end

--	Writing

function WritePacketIndex:String(val)
	_checkpck(self)

	if type(val) ~= "string" then
		error("bad argument #1: 'string' expected, got '" .. type(val) .. "'.")
	end

	local nid = util.NetworkStringToID(val)

	if nid and (nid <= 0 or util.NetworkIDToString(nid) ~= val) then
		nid = nil
	end

	if nid then
		self.File:WriteLong(-nid)
	else
		self.File:WriteLong(#val)

		if val ~= "" then
			self.File:Write(val)
		end
	end

	return self
end

function WritePacketIndex:Int(val)
	_checkpck(self)

	if type(val) ~= "number" then
		error("bad argument #1: 'number' expected, got '" .. type(val) .. "'.")
	elseif val % 1 ~= 0 then
		error("bad argument #1: given number is not an integer.")
	elseif val < -2147483648 or val > 2147483647 then
		error("bad argument #1: given number is outside the range of a 32-bit signed integer.")
	end

	self.File:WriteLong(val)

	return self
end

function WritePacketIndex:Short(val)
	_checkpck(self)

	if type(val) ~= "number" then
		error("bad argument #1: 'number' expected, got '" .. type(val) .. "'.")
	elseif val % 1 ~= 0 then
		error("bad argument #1: given number is not an integer.")
	elseif val < -32768 or val > 32767 then
		error("bad argument #1: given number is outside the range of a 16-bit signed integer.")
	end

	self.File:WriteShort(val)

	return self
end

function WritePacketIndex:Byte(val)
	_checkpck(self)

	if type(val) ~= "number" then
		error("bad argument #1: 'number' expected, got '" .. type(val) .. "'.")
	elseif val % 1 ~= 0 then
		error("bad argument #1: given number is not an integer.")
	elseif val < 0 or val > 255 then
		error("bad argument #1: given number is outside the range of an 8-bit unsigned integer.")
	end

	self.File:WriteByte(val)

	return self
end

function WritePacketIndex:Double(val)
	_checkpck(self)

	if type(val) ~= "number" then
		error("bad argument #1: 'number' expected, got '" .. type(val) .. "'.")
	end

	self.File:WriteDouble(val)

	return self
end

function WritePacketIndex:Float(val)
	_checkpck(self)

	if type(val) ~= "number" then
		error("bad argument #1: 'number' expected, got '" .. type(val) .. "'.")
	end

	self.File:WriteFloat(val)

	return self
end

function WritePacketIndex:Bool(val)
	_checkpck(self)

	if type(val) ~= "boolean" then
		error("bad argument #1: 'boolean' expected, got '" .. type(val) .. "'.")
	end

	self.File:WriteBool(val)

	return self
end

--	Sending

local function _addplys(self, plys)
	for i = 1, #plys do
		local ply = plys[i]

		if not self.Targets[ply] then
			if type(ply) == "Player" or (type(ply) == "Entity" and ply:IsPlayer()) then
				self.Targets[#self.Targets+1] = ply
				self.Targets[ply] = true
			elseif type(ply) == "table" then
				_addplys(self, ply)
			else
				error("cannot add a " .. type(ply) .. " as target(s)")
			end
		end
	end
end

local function _remplys(self, plys)
	for i = 1, #plys do
		local ply = plys[i]
		
		if self.Targets[ply] then
			if type(ply) == "Player" or (type(ply) == "Entity" and ply:IsPlayer()) then
				local t = self.Targets

				for j = 1, #t do
					if t[j] == ply then
						table_remove(t, j)
						self.Targets[ply] = false
						j = 128
					end
				end
			elseif type(ply) == "table" then
				_remplys(self, ply)
			else
				error("cannot remove a " .. type(ply) .. " as target(s)")
			end
		end
	end
end

function WritePacketIndex:AddTargets(...)
	_checkpck(self)

	_addplys(self, {...})

	return self
end

function WritePacketIndex:RemoveTargets(...)
	_checkpck(self)

	_remplys(self, {...})

	return self
end

if CLIENT then
	function WritePacketIndex:AddServer()
		if not self.File then
			error("package is already sent or discarded")
		end

		self.IncludeServer = true

		return self
	end

	function WritePacketIndex:RemoveServer()
		if not self.File then
			error("package is already sent")
		end

		self.IncludeServer = false

		return self
	end
end

--	Sending

function WritePacketIndex:Send()
	_checkpck(self)

	if #self.Targets == 0 and (SERVER or not self.IncludeServer) then
		error("package has no targets registered whatsoever")
	end

	self.File:Flush()
	self.File:Close()
	self.File = false

	self.Data = file.Read(self.FilePath, "DATA")

	if #self.Data >= compression_threshold_low_current and #self.Data <= compression_threshold_high_current then
		self.Compressed = true
		self.Data = util.Compress(self.Data)
	end

	self.Size = #self.Data

	file.Delete(self.FilePath)

	if SERVER then
		for i = #self.Targets, 1, -1 do
			enqueue(self.Targets[i]:EntIndex(), self, true)
		end
	else
		enqueue(self)
	end

	self.Sent = true

	return self
end

function WritePacketIndex:Broadcast(includeServer)
	_checkpck(self)

	local allplys = player_GetAll()
	self:AddTargets(allplys)

	if SERVER then
		if #allplys == 0 then
			return self, false
		end

		if includeServer ~= nil then
			error("bad argument #1 to 'Broadcast' (nil expected on server)")
		end
	else
		self.IncludeServer = includeServer == true

		if #allplys == 1 and not includeServer then
			return self, false
		end
	end

	return self:Send(), true
end

function WritePacketIndex:Discard()
	_checkpck(self)

	self.File:Close()
	self.File = false

	file.Delete(self.FilePath)

	self.Discarded = true

	return self
end


local WritePacketMeta = {
	__index = WritePacketIndex,

	__metatable = "NEIN!",
}

local function createWritePacket(typ)
	local fPath = getFile()
	local fObject, fErr = file.Open(fPath, "wb", "DATA")

	if not fObject then
		error("file creation error: " .. tostring(fErr))
	end

	local new = {
		FilePath = fPath,
		File = fObject,
		Type = typ,
		Data = false,
		Compressed = false,
		Targets = {},
		IncludeServer = CLIENT,
		Sent = false,
		Discarded = false,
	}

	return setmetatable(new, WritePacketMeta)
end




local ReadPacketIndex = {
	
}

function ReadPacketIndex:Size()
	_checkpck(self)

	return self.File:Size()
end

--	Writing

function ReadPacketIndex:String()
	_checkpck(self)

	local len = self.File:ReadLong()

	if len == 0 then
		return ""
	elseif len < 0 then
		return util.NetworkIDToString(-len)
	else
		return self.File:Read(len)
	end
end

function ReadPacketIndex:Int()
	_checkpck(self)

	return self.File:ReadLong()
end

function ReadPacketIndex:Short()
	_checkpck(self)

	return self.File:ReadShort()
end

function ReadPacketIndex:Byte()
	_checkpck(self)

	return self.File:ReadByte()
end

function ReadPacketIndex:Double()
	_checkpck(self)

	return self.File:ReadDouble()
end

function ReadPacketIndex:Float()
	_checkpck(self)

	return self.File:ReadFloat()
end

function ReadPacketIndex:Bool()
	_checkpck(self)

	return self.File:ReadBool()
end

--	Status

function ReadPacketIndex:Conserve()
	_checkpck(self)

	self.Conserved = true
end

function ReadPacketIndex:Discard()
	_checkpck(self)

	self.File:Close()
	self.File = false

	file.Delete(self.FilePath)

	self.Discarded = true
end


local ReadPacketMeta = {
	__index = ReadPacketIndex,

	__metatable = "NEIN!",
}

local function createReadPacket(pck)
	local fPath = getFile()

	if pck.Compressed then
		pck.Data = util.Decompress(pck.Data)
	end

	file.Write(fPath, pck.Data)

	local fObject, fErr = file.Open(fPath, "rb", "DATA")

	if not fObject then
		error("file opening error: " .. tostring(fErr))
	end

	local new = {
		FilePath = fPath,
		File = fObject,
		Type = pck.Type,
		Data = pck.Data,
		Compressed = pck.Compressed,
		Size = pck.Size,
		Source = pck.Nodes,
		Discarded = false,
		Conserved = false,
	}

	return setmetatable(new, ReadPacketMeta)
end



--	--	--	--
--	Postage	--
--	--	--	--



local wall = {}

post = function(pck)
	wall[#wall+1] = pck
end

local function unpost()
	local ret = wall[1]

	table_remove(wall, 1)

	return ret
end



local callbacks, toDiscard = {}, {}

hook.Add("Think", "pac_vNet Postage", function()
	if #toDiscard > 0 then
		for i = #toDiscard, 1, -1 do
			if not toDiscard[i].Conserved and not toDiscard[i].Discarded then
				toDiscard[i]:Discard()
			end
		end

		toDiscard = {}
	end

	while #wall > 0 do
		local pck = unpost()
		local typ = pck.Type

		if callbacks[typ] then
			if callbacks[typ][2] then
				callbacks[typ][1](pck.Data)
			else
				pck = createReadPacket(pck)

				toDiscard[#toDiscard+1] = pck
				
				callbacks[typ][1](pck)

				if not pck.Conserved and not pck.Discarded then
					pck:Discard()
				end
			end
		else
			ErrorNoHalt("Received vNet package with no registered callback: " .. typ .. " (" .. tostring(util.NetworkIDToString(typ)) .. ")")
		end
	end
end)



--	--	--	--	--
--	Extensions	--
--	--	--	--	--



function WritePacketIndex:Color(val)
	_checkpck(self)

	if not IsColor(val) then
		error("bad argument #1: expected a color table")
	end

	self.File:WriteByte(val.r)
	self.File:WriteByte(val.g)
	self.File:WriteByte(val.b)
	self.File:WriteByte(val.a)

	return self
end

function ReadPacketIndex:Color()
	_checkpck(self)

	return Color(self.File:ReadByte(), self.File:ReadByte(), self.File:ReadByte(), self.File:ReadByte())
end


function WritePacketIndex:Entity(val)
	_checkpck(self)

	if not IsEntity(val) then
		error("bad argument #1: expected 'entity', got '" .. type(val) .. "'.")
	end

	self.File:WriteShort(val:EntIndex())

	return self
end

function ReadPacketIndex:Entity()
	_checkpck(self)

	return Entity(self.File:ReadShort())
end


function WritePacketIndex:Angle(val)
	_checkpck(self)

	if type(val) ~= "Angle" then
		error("bad argument #1: 'Angle' expected, got '" .. type(val) .. "'.")
	end

	self.File:WriteFloat(val.p)
	self.File:WriteFloat(val.y)
	self.File:WriteFloat(val.r)

	return self
end

function ReadPacketIndex:Angle()
	_checkpck(self)

	return Angle(self.File:ReadFloat(), self.File:ReadFloat(), self.File:ReadFloat())
end


function WritePacketIndex:Vector(val)
	_checkpck(self)

	if type(val) ~= "Vector" then
		error("bad argument #1: 'Vector' expected, got '" .. type(val) .. "'.")
	end

	self.File:WriteFloat(val.x)
	self.File:WriteFloat(val.y)
	self.File:WriteFloat(val.z)

	return self
end

function ReadPacketIndex:Vector()
	_checkpck(self)

	return Vector(self.File:ReadFloat(), self.File:ReadFloat(), self.File:ReadFloat())
end



--	Table data types

local TABLE_TYPE_NIL = 0
local TABLE_TYPE_NUMBER = 1
local TABLE_TYPE_STRING = 2
local TABLE_TYPE_BOOLEAN = 3
local TABLE_TYPE_TABLE = 4

local TABLE_TYPE_ANGLE = 210
local TABLE_TYPE_VECTOR = 211

local TABLE_TYPE_ENTITY_SINGLE = 220
local TABLE_TYPE_ENTITY_DOUBLE = 221

local TABLE_TYPE_TABLE_COLOR = 230

local TABLE_TYPE_BOOLEAN_TRUE = 241
local TABLE_TYPE_BOOLEAN_FALSE = 240

local TABLE_TYPE_STRING_NETWORKED = 245
local TABLE_TYPE_STRING_EMPTY = 246

local TABLE_TYPE_END = 255
local TABLE_TYPE_SPLIT = 254
local TABLE_TYPE_REFERENCE = 253

--	End of table data types

local specialKeyForTheReferenceCounter = {}

local typemap = {
	["nil"] = TABLE_TYPE_NIL,
	[TABLE_TYPE_NIL] = "nil",

	["number"] = TABLE_TYPE_NUMBER,
	[TABLE_TYPE_NUMBER] = "number",

	["string"] = TABLE_TYPE_STRING,
	[TABLE_TYPE_STRING] = "string",

	["boolean"] = TABLE_TYPE_BOOLEAN,
	[TABLE_TYPE_BOOLEAN] = "boolean",

	["table"] = TABLE_TYPE_TABLE,
	[TABLE_TYPE_TABLE] = "table",

	["Angle"] = TABLE_TYPE_ANGLE,
	[TABLE_TYPE_ANGLE] = "Angle",

	["Vector"] = TABLE_TYPE_VECTOR,
	[TABLE_TYPE_VECTOR] = "Vector",

	[TABLE_TYPE_END] = "END OF TABLE",
	[TABLE_TYPE_SPLIT] = "TABLE SPLIT",
	[TABLE_TYPE_REFERENCE] = "REFERENCE",
}

local writevar, writetable, readvar, readtable

writevar = function(v, f, d)
	if v ~= nil and d[v] then
		f:WriteByte(TABLE_TYPE_REFERENCE)
		f:WriteShort(d[v])

		--print("  - ref ", d[v], "(" .. tostring(v) .. ")")
	else
		local tid = typemap[type(v)]

		if TABLE_TYPE_NIL == tid then
			f:WriteByte(tid)
		elseif TABLE_TYPE_BOOLEAN == tid then
			f:WriteByte(v and TABLE_TYPE_BOOLEAN_TRUE or TABLE_TYPE_BOOLEAN_FALSE)

			--print("  - bool type:", v, v and TABLE_TYPE_BOOLEAN_TRUE or TABLE_TYPE_BOOLEAN_FALSE)
		elseif TABLE_TYPE_STRING == tid then
			if v == "" then
				f:WriteByte(TABLE_TYPE_STRING_EMPTY)
			else
				local nid = util.NetworkStringToID(v)

				if nid and (nid <= 0 or util.NetworkIDToString(nid) ~= v) then
					nid = nil
				end

				if nid and nid > 0 then
					f:WriteByte(TABLE_TYPE_STRING_NETWORKED)
					f:WriteShort(nid)
				else
					f:WriteByte(tid)

					f:WriteLong(#v)
					f:Write(v)

					d[specialKeyForTheReferenceCounter] = d[specialKeyForTheReferenceCounter] + 1
					d[v] = d[specialKeyForTheReferenceCounter]
				end
			end
		elseif TABLE_TYPE_TABLE == tid then
			if IsColor(v) then
				f:WriteByte(TABLE_TYPE_TABLE_COLOR)

				f:WriteByte(v.r)
				f:WriteByte(v.g)
				f:WriteByte(v.b)
				f:WriteByte(v.a)
			else
				f:WriteByte(tid)

				writetable(v, f, d)
			end
		elseif TABLE_TYPE_NUMBER == tid then
			f:WriteByte(tid)
			f:WriteDouble(v)
		elseif IsEntity(v) then
			local ei = v:EntIndex()

			if ei <= 255 then
				f:WriteByte(TABLE_TYPE_ENTITY_SINGLE)
				f:WriteByte(ei)
			else
				f:WriteByte(TABLE_TYPE_ENTITY_DOUBLE)
				f:WriteShort(ei)
			end
		elseif TABLE_TYPE_ANGLE == tid then
			f:WriteByte(tid)
			f:WriteFloat(v.p)
			f:WriteFloat(v.y)
			f:WriteFloat(v.r)
		elseif TABLE_TYPE_VECTOR == tid then
			f:WriteByte(tid)
			f:WriteFloat(v.x)
			f:WriteFloat(v.y)
			f:WriteFloat(v.z)
		else
			error("cannot write value of type '" .. type(v) .. "'!")
		end
	end
end

writetable = function(t, f, d)
	d[specialKeyForTheReferenceCounter] = d[specialKeyForTheReferenceCounter] + 1
	d[t] = d[specialKeyForTheReferenceCounter]

	local kvps, len = {}, #t

	for k, v in pairs(t) do
		if type(k) ~= "number" or k < 1 or k > len or (k % 1 ~= 0) then
			kvps[#kvps+1] = k
		end
	end

	--print("- got ", #kvps, " kvps and ", len, " indexes; refid: ", d[specialKeyForTheReferenceCounter])

	for i = 1, len do
		--print(" - writing index ", i)
		writevar(t[i], f, d)
	end

	if #kvps > 0 then
		f:WriteByte(TABLE_TYPE_SPLIT)

		--print(" - wrote splitter")

		for i = 1, #kvps do
			--print(" - writing key ", i, ": ", kvps[i])
			writevar(kvps[i], f, d)
			--print(" - writing value ", i, ": ", t[kvps[i]])
			writevar(t[kvps[i]], f, d)
		end
	end

	f:WriteByte(TABLE_TYPE_END)

	--print(" - wrote end")
end

readvar = function(tid, f, d)
	if TABLE_TYPE_NIL == tid then
		return nil
	elseif TABLE_TYPE_NUMBER == tid then
		return f:ReadDouble()
	elseif TABLE_TYPE_STRING == tid then
		local len = f:ReadLong()
		local s = f:Read(len)

		d[specialKeyForTheReferenceCounter] = d[specialKeyForTheReferenceCounter] + 1
		d[d[specialKeyForTheReferenceCounter]] = s

		return s
	elseif TABLE_TYPE_STRING_NETWORKED == tid then
		return util.NetworkIDToString(f:ReadShort())
	elseif TABLE_TYPE_STRING_EMPTY == tid then
		return ""
	elseif TABLE_TYPE_BOOLEAN_TRUE == tid then
		return true
	elseif TABLE_TYPE_BOOLEAN_FALSE == tid then
		return false
	elseif TABLE_TYPE_TABLE == tid then
		return readtable(f, d)
	elseif TABLE_TYPE_TABLE_COLOR == tid then
		local r = f:ReadByte()
		local g = f:ReadByte()
		local b = f:ReadByte()
		local a = f:ReadByte()

		return Color(r, g, b, a)
	elseif TABLE_TYPE_ENTITY_SINGLE == tid then
		return Entity(f:ReadByte())
	elseif TABLE_TYPE_ENTITY_DOUBLE == tid then
		return Entity(f:ReadShort())
	elseif TABLE_TYPE_ANGLE == tid then
		return Angle(f:ReadFloat(), f:ReadFloat(), f:ReadFloat())
	elseif TABLE_TYPE_VECTOR == tid then
		return Vector(f:ReadFloat(), f:ReadFloat(), f:ReadFloat())
	elseif TABLE_TYPE_REFERENCE == tid then
		return d[f:ReadShort()]
	else
		error("unknown type ID: " .. tid)
	end
end

readtable = function(f, d)
	local t, i = {}, 0

	d[specialKeyForTheReferenceCounter] = d[specialKeyForTheReferenceCounter] + 1
	d[d[specialKeyForTheReferenceCounter]] = t

	local tid

	--print("- reading table; refid: ", d[specialKeyForTheReferenceCounter])

	repeat
		tid = f:ReadByte()

		--print(" - read type: ", tid, "; known string: ", tostring(typemap[tid]))

		if TABLE_TYPE_SPLIT == tid then
			i = -1
		elseif TABLE_TYPE_END == tid then
			break
		elseif i > -1 then
			i = i + 1
			--print(" - reading for index: ", i)
			t[i] = readvar(tid, f, d)
		else
			local key = readvar(tid, f, d)
			--print(" - read key: ", tostring(key))
			tid = f:ReadByte()
			--print(" - read tid for value: ", tid)
			t[key] = readvar(tid, f, d)
			--print(" - read value: ", tostring(t[key]))
		end
	until tid == TABLE_TYPE_END

	return t
end


function WritePacketIndex:Table(val)
	_checkpck(self)

	if type(val) ~= "table" then
		error("bad argument #1: expected 'table', got '" .. type(val) .. "'.")
	end

	writetable(val, self.File, { [specialKeyForTheReferenceCounter] = -1 })

	return self
end

function ReadPacketIndex:Table()
	_checkpck(self)

	return readtable(self.File, { [specialKeyForTheReferenceCounter] = -1 })
end


function WritePacketIndex:Variable(val)
	_checkpck(self)

	writevar(val, self.File, { [specialKeyForTheReferenceCounter] = -1 })

	return self
end

function ReadPacketIndex:Variable()
	_checkpck(self)

	local tid = self.File:ReadByte()

	return readvar(tid, self.File, { [specialKeyForTheReferenceCounter] = -1 })
end



--	--	--
--	API	--
--	--	--



vnet.OPTION_SENDSTRING_EXCLUDESERVER = 3
vnet.OPTION_SENDSTRING_FORCECOMPRESSION = 4
vnet.OPTION_SENDSTRING_NOCOMPRESSION = 5

vnet.OPTION_WATCH_OVERRIDE = 1
vnet.OPTION_WATCH_PURESTRING = 2



function vnet.CreatePacket(typ)
	if type(typ) == "string" then
		typ = util.NetworkStringToID(typ)

		if typ == 0 then
			error("bad argument #1 to 'CreatePacket': given string is not a network string.")
		end
	elseif type(typ) ~= "number" or typ % 1 ~= 0 then
		error("bad argument #1 to 'CreatePacket': type must be an integer or a network string.")
	end

	return createWritePacket(typ)
end

function vnet.SendString(typ, str, targets, ops)
	if type(typ) == "string" then
		typ = util.NetworkStringToID(typ)

		if typ == 0 then
			error("bad argument #1 to 'SendString': given string is not a network string.")
		end
	elseif type(typ) ~= "number" or typ % 1 ~= 0 then
		error("bad argument #1 to 'SendString': type must be an integer or a network string.")
	end

	if type(str) ~= "string" then
		error("bad argument #2 to 'SendString': 'string' expected, got '" .. type(str) .. "'.")
	end

	if targets == nil then
		targets = {}
	elseif type(targets) == "Player" then
		targets = { targets }
	elseif type(targets) ~= "table" then
		error("bad argument #3 to 'SendString': 'table', 'Player' or nil expected, got '" .. type(targets) .. ".")
	end

	if ops == nil then
		ops = {}
	elseif type(ops) == "number" then
		ops = { ops }
	elseif type(ops) ~= "table" then
		error("bad argument #3 to 'Watch': 'table', 'number' or nil expected, got '" .. type(ops) .. "'.")
	end

	local compressionStatus, excludeServer = 0, false

	for i = #ops, 1, -1 do
		if vnet.OPTION_SENDSTRING_FORCECOMPRESSION == ops[i] then
			if compressionStatus == 1 then
				error("flag 'OPTION_SENDSTRING_FORCECOMPRESSION' was specified multiple times!")
			elseif compressionStatus == -1 then
				error("flag 'OPTION_SENDSTRING_FORCECOMPRESSION' was specified after 'OPTION_SENDSTRING_NOCOMPRESSION', causing contradiction!")
			else
				compressionStatus = 1
			end
		elseif vnet.OPTION_SENDSTRING_NOCOMPRESSION == ops[i] then
			if compressionStatus == 1 then
				error("flag 'OPTION_SENDSTRING_NOCOMPRESSION' was specified after 'OPTION_SENDSTRING_FORCECOMPRESSION', causing contradiction!")
			elseif compressionStatus == -1 then
				error("flag 'OPTION_SENDSTRING_NOCOMPRESSION' was specified multiple times!")
			else
				compressionStatus = -1
			end
		elseif vnet.OPTION_SENDSTRING_EXCLUDESERVER == ops[i] then
			if SERVER then
				error("flag 'OPTION_SENDSTRING_EXCLUDESERVER' cannot be specified on server!")
			end

			if excludeServer then
				error("flag 'OPTION_SENDSTRING_EXCLUDESERVER' was specified multiple times!")
			else
				excludeServer = true
			end
		else
			error("unknown option flag specified!")
		end
	end

	local pck = {
		Type = typ,
		Data = str,
		Compressed = false,
		Size = #str,
		IncludeServer = CLIENT and not excludeServer,
		Targets = {},
	}

	_addplys(pck, targets)

	if compressionStatus == 1 or (compressionStatus == 0 and #str >= compression_threshold_low_current and #str <= compression_threshold_high_current) then
		pck.Compressed = true
		pck.Data = util.Compress(str)
		pck.Size = #pck.Data
	end

	if SERVER then
		for i = #pck.Targets, 1, -1 do
			enqueue(pck.Targets[i]:EntIndex(), pck, true)
		end
	else
		enqueue(pck)
	end
end

function vnet.Watch(typ, cbk, ops)
	if type(typ) == "string" then
		typ = util.NetworkStringToID(typ)

		if typ == 0 then
			error("bad argument #1 to 'Watch': given string is not a network string.")
		end
	elseif type(typ) ~= "number" or typ % 1 ~= 0 then
		error("bad argument #1 to 'Watch': type must be an integer or a network string.")
	end

	if type(cbk) ~= "function" then
		error("bad argument #2 to 'Watch': callback must be a function.")
	end

	if ops == nil then
		ops = {}
	elseif type(ops) == "number" then
		ops = { ops }
	elseif type(ops) ~= "table" then
		error("bad argument #3 to 'Watch': 'table', 'number' or nil expected, got '" .. type(ops) .. "'.")
	end

	local override, justString

	for i = #ops, 1, -1 do
		if vnet.OPTION_WATCH_OVERRIDE == ops[i] then
			if override then
				error("flag 'OPTION_WATCH_OVERRIDE' was specified multiple times!")
			else
				override = true
			end
		elseif vnet.OPTION_WATCH_PURESTRING == ops[i] then
			if justString then
				error("flag 'OPTION_WATCH_PURESTRING' was specified multiple times!")
			else
				justString = true
			end
		else
			error("unknown option flag specified!")
		end
	end

	if callbacks[typ] and not override then
		error("a callback is already registered for this type; perhaps you meant to override?")
	end

	callbacks[typ] = { cbk, justString }
end



--[[function vnet.SetChunkSize(val)
	if type(val) ~= "number" or val % 1 ~= 0 then
		error("given argument must be an integer")
	end

	if val < chunk_size_min then
		error("given argument is below the minimum value (" .. chunk_size_min .. ")")
	elseif val > chunk_size_max then
		error("given argument is above the minimum value (" .. chunk_size_max .. ")")
	end

	chunk_size_current = val
end

function vnet.GetChunkSize()
	return chunk_size_current
end--]]

function vnet.SetPackageFraction(val)
	if type(val) ~= "number" or val % 1 ~= 0 then
		error("given argument must be an integer")
	end

	if val < package_fraction_min then
		error("given argument is below the minimum value (" .. package_fraction_min .. ")")
	elseif val > package_fraction_max then
		error("given argument is above the minimum value (" .. package_fraction_max .. ")")
	end

	package_fraction_current = val
end

function vnet.GetPackageFraction()
	return package_fraction_current
end

function vnet.SetCompressionThreshold(low, high)
	if type(low) ~= "number" or low % 1 ~= 0 then
		error("argument #1 (lower threshold) must be an integer")
	elseif type(high) ~= "number" or high % 1 ~= 0 then
		error("argument #2 (upper threshold) must be an integer")
	end

	if low < compression_threshold_low_min then
		error("argument #1 (lower threshold) is below the minimum value (" .. compression_threshold_low_min .. ")")
	elseif low > compression_threshold_low_max then
		error("argument #1 (lower threshold) is above the minimum value (" .. compression_threshold_low_max .. ")")
	elseif high < compression_threshold_high_min then
		error("argument #2 (upper threshold) is below the minimum value (" .. compression_threshold_high_min .. ")")
	elseif high > compression_threshold_high_max then
		error("argument #2 (upper threshold) is above the minimum value (" .. compression_threshold_high_max .. ")")
	end

	compression_threshold_low_current = low
end

function vnet.GetCompressionThreshold()
	return compression_threshold_low_current, compression_threshold_high_current
end



--	--	--	--	--	--
--	Self-throttling	--
--	--	--	--	--	--



if CLIENT then
	local function throttler(convar_name, value_old, value_new)
		if convar_name == "cl_cmdrate" then
			stepsize = 1 / value_new
		elseif convar_name == "cl_updaterate" then
			enqueueMisc(TYPE_FRAG_THROTTLE_YOURSELF, math_floor(1000000 / value_new))
		end
	end



	cvars.AddChangeCallback("cl_cmdrate", throttler)
	cvars.AddChangeCallback("cl_updaterate", throttler)



	hook.Add("Initialize", "pac_vNet Initial Throttle", function()
		throttler("cl_cmdrate", nil, cvars.Number("cl_cmdrate"))
		throttler("cl_updaterate", nil, cvars.Number("cl_updaterate"))
	end)
end



vnet.versionString = "1.1.5"
vnet.versionNumber = 1001005

pac.vnet = vnet