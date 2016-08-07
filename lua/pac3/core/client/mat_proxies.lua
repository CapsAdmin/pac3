local function BIND_MATPROXY(NAME, TYPE)

	set = "Set" .. TYPE

	matproxy.Add(
		{
			name = NAME,

			init = function(self, mat, values)
				self.result = values.resultvar
			end,

			bind = function(self, mat, ent)
				ent = ent or NULL
				if ent:IsValid() then
					if ent.pac_matproxies and ent.pac_matproxies[NAME] then
						mat[set](mat, self.result, ent.pac_matproxies[NAME])
					end
				end
			end
		}
	)

end

-- tf2
BIND_MATPROXY("ItemTintColor", "Vector")