local table_remove = table.remove

local utility = {}

function utility.DivideVector(a,b)
	return Vector(a.x / b.x, a.y / b.y, a.z / b.z)
end

do
	local hooks = {}

	function utility.ObjectFunctionHook(id, tbl, func_name, callback)
		if callback then
			local old = hooks[id] or tbl[func_name]

			tbl[func_name] = function(...)
				if old then
					old(...)
				end
				callback(...)
			end

			hooks[id] = old

			return old
		else
			if hooks[id] ~= nil then
				tbl[func_name] = hooks[id]
				hooks[id] = nil
			end
		end
	end

	function utility.CreateObjectPool(name)
		return {
			i = 1,
			list = {},
			map = {},
			remove = function(self, obj)
				if not self.map[obj] then
					error("tried to remove non existing object '"..tostring(obj).."'  in pool " .. name, 2)
				end

				for i = 1, self.i do
					if obj == self.list[i] then
						table_remove(self.list, i)
						self.map[obj] = nil
						self.i = self.i - 1
						break
					end
				end

				if self.map[obj] then
					error("unable to remove " .. tostring(obj) .. " from pool " .. name)
				end
			end,
			insert = function(self, obj)
				if self.map[obj] then
					error("tried to add existing object to pool " .. name, 2)
				end

				self.list[self.i] = obj
				self.map[obj] = self.i
				self.i = self.i + 1
			end,
			call = function(self, func_name, ...)
				for _, obj in ipairs(self.list) do
					if obj[func_name] then
						obj[func_name](obj, ...)
					end
				end
			end,
		}
	end
end

function utility.TriangleIntersect(rayOrigin, rayDirection, world_matrix, v1,v2,v3)
	local EPSILON = 1 / 1048576

	local rdx, rdy, rdz = rayDirection.x, rayDirection.y, rayDirection.z
	local v1x, v1y, v1z = utility.TransformVectorFast(world_matrix, v1)
	local v2x, v2y, v2z = utility.TransformVectorFast(world_matrix, v2)
	local v3x, v3y, v3z = utility.TransformVectorFast(world_matrix, v3)


	-- find vectors for two edges sharing vert0
	--local edge1 = self.y - self.x
	--local edge2 = self.z - self.x
	local e1x, e1y, e1z = (v2x - v1x), (v2y - v1y), (v2z - v1z)
	local e2x, e2y, e2z = (v3x - v1x), (v3y - v1y), (v3z - v1z)

	-- begin calculating determinant - also used to calculate U parameter
	--local pvec = rayDirection:cross( edge2 )
	local pvx = (rdy * e2z) - (rdz * e2y)
	local pvy = (rdz * e2x) - (rdx * e2z)
	local pvz = (rdx * e2y) - (rdy * e2x)

	-- if determinant is near zero, ray lies in plane of triangle
	--local det = edge1:dot( pvec )
	local det = (e1x * pvx) + (e1y * pvy) + (e1z * pvz)

	if (det > -EPSILON) and (det < EPSILON) then return end

	local inv_det = 1 / det

	-- calculate distance from vertex 0 to ray origin
	--local tvec = rayOrigin - self.x
	local tvx = rayOrigin.x - v1x
	local tvy = rayOrigin.y - v1y
	local tvz = rayOrigin.z - v1z

	-- calculate U parameter and test bounds
	--local u = tvec:dot( pvec ) * inv_det
	local u = ((tvx * pvx) + (tvy * pvy) + (tvz * pvz)) * inv_det
	if (u < 0) or (u > 1) then return end

	-- prepare to test V parameter
	--local qvec = tvec:cross( edge1 )
	local qvx = (tvy * e1z) - (tvz * e1y)
	local qvy = (tvz * e1x) - (tvx * e1z)
	local qvz = (tvx * e1y) - (tvy * e1x)

	-- calculate V parameter and test bounds
	--local v = rayDirection:dot( qvec ) * inv_det
	local v = ((rdx * qvx) + (rdy * qvy) + (rdz * qvz)) * inv_det
	if (v < 0) or (u + v > 1) then return end

	-- calculate t, ray intersects triangle
	--local hitDistance = edge2:dot( qvec ) * inv_det
	local hitDistance = ((e2x * qvx) + (e2y * qvy) + (e2z * qvz)) * inv_det

	-- only allow intersections in the forward ray direction
	local dist = (hitDistance >= 0) and hitDistance or nil

	if dist and pac999.DEBUG then
		debugoverlay.Triangle(Vector(v1x, v1y, v1z), Vector(v3x, v3y, v3z), Vector(v3x, v3y, v3z), 0, Color(0,255,0,50), true)
		debugoverlay.Triangle(Vector(v3x, v3y, v3z), Vector(v2x, v2y, v2z), Vector(v1x, v1y, v1z), 0, Color(0,255,0,50), true)
	end

	return dist
end

function utility.TransformVectorFast(matrix, vec)
	local
	m00,m10,m20,m30,
	m01,m11,m21,m31,
	m02,m12,m22,m32,
	m03,m13,m23,m33
	= matrix:Unpack()

	local x, y, z = vec:Unpack()

	m30 = m00 * x + m10 * y + m20 * z + m30
	m31 = m01 * x + m11 * y + m21 * z + m31
	m32 = m02 * x + m12 * y + m22 * z + m32
	m33 = m03 * x + m13 * y + m23 * z + m33

	return m30,m31,m32
end

function utility.TransformVector(matrix, vec)
	return Vector(utility.TransformVectorFast(matrix, vec))
end


do -- table copy
	local lookup_table

	local function copy(obj, skip_meta)
		local t = type(obj)

		if t == "number" or t == "string" or t == "function" or t == "boolean" or t == "nil" or t == "IMaterial" or obj == NULL then
			return obj
		end

		if t == "Vector" or t == "Angle" then
			return obj * 1
		elseif t == "VMatrix" then
			return Matrix():Set(obj)
		elseif lookup_table[obj] then
			return lookup_table[obj]
		elseif t == "table" then
			local new_table = {}

			lookup_table[obj] = new_table

			for key, val in pairs(obj) do
				new_table[copy(key, skip_meta)] = copy(val, skip_meta)
			end

			return skip_meta and new_table or setmetatable(new_table, getmetatable(obj))
		else
			error("cannot copy " .. t)
		end

		return obj
	end

	function utility.CopyValue(obj, skip_meta)
		lookup_table = {}
		return copy(obj, skip_meta)
	end
end


return utility