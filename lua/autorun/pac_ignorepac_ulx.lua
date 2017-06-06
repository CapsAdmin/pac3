if ulx then
	function ulx.ignorepac(ply,target)
		ply:SendLua[[if pac.IgnoreEntity then pac.IgnoreEntity(]]..target..[[) end]]
	end

	local ignorepac = ulx.command( "ignorepac", "ulx ignorepac", ulx.ignorepac, "!ignorepac" )
	ignorepac:addParam{ type=ULib.cmds.PlayersArg }
	ignorepac:defaultAccess( ULib.ACCESS_USER )
	ignorepac:help( "Ignores a player's PAC outfit." )

	function ulx.unignorepac(ply,target)
		ply:SendLua[[if pac.UnIgnoreEntity then pac.UnIgnoreEntity(]]..target..[[) end]]
	end

	local unignorepac = ulx.command( "unignorepac", "ulx unignorepac", ulx.unignorepac, "!unignorepac" )
	unignorepac:addParam{ type=ULib.cmds.PlayersArg }
	unignorepac:defaultAccess( ULib.ACCESS_USER )
	unignorepac:help( "Unignores a player's PAC outfit." )
end
