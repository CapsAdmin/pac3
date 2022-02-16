local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "link"

PART.Group = 'advanced'
PART.Icon = 'icon16/weather_clouds.png'

local function fill_enums(target)
    if not target:IsValid() then return end

    local tbl = {}
    for _, prop in pairs(target:GetProperties()) do
        if prop.key == "UniqueID" then goto CONTINUE end

        local T = type(prop.get())
        if T == "number" or T == "Vector" or T == "Angle" or T == "boolean" then
            tbl[prop.key] = prop.key
        end
        ::CONTINUE::
    end

    return tbl
end

BUILDER:StartStorableVars()
	BUILDER:GetSetPart("From")
	BUILDER:GetSetPart("To")
    BUILDER:GetSet("Type", "from -> to", {enums = {"from -> to", "to -< from", "from <-> to"}})
	BUILDER:GetSet("FromVariableName", "", {enums = function(self) return fill_enums(self:GetFrom()) end})
	BUILDER:GetSet("ToVariableName", "", {enums = function(self) return fill_enums(self:GetTo()) end})
BUILDER:EndStorableVars()

local function hook_property(a, b, a_prop, b_prop, callback)
    if not a["Get" .. a_prop] or not a["Set" .. a_prop] then return end
    if not b["Get" .. b_prop] or not b["Set" .. b_prop] then return end
end

function PART:SetFrom(from)
    self.From = from

    if self.FromVariableName == "" then return end
    if not from:IsValid() then return end

    if not from["Set" .. self.FromVariableName] then return end

    local old_from_setter = from["Set" .. self.FromVariableName]
    local from_getter = from["Get" .. self.FromVariableName]
    from["Set" .. self.FromVariableName] = function(s, v)
        old_from_setter(s, v)

        local to = self:GetTo()
        if self.ToVariableName == "" then return end
        if not to:IsValid() then return end

        local to_setter = to["Set" .. self.FromVariableName]
        if not to_setter then return end

        to_setter(to, from_getter(from))
    end
end

BUILDER:Register()