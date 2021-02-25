local META = {}
META.__index = META

for key, val in pairs(FindMetaTable("VMatrix")) do
	if key ~= "__index" and key ~= "__tostring" and key ~= "__gc" then
		META[key] = function(self, ...)
			local a,b,c = self.m[key](self.m, ...)
			if a == nil then
				return self
			end
			return a,b,c
		end
	end
end

local function Matrix44(pos, ang, scale)
	local m = Matrix()
	if pos then
		m:SetTranslation(pos)
	end
	if ang then
		m:SetAngles(ang)
	end
	if scale then
		m:SetScale(scale)
	end

	return setmetatable({m = m}, META)
end

return Matrix44