local entity = pac999.entity

local events = {}

do
	local META = entity.ComponentTemplate("test")

	function META:Start()
		table.insert(events, "start")
	end

	function META.EVENTS:Update()
		table.insert(events, "update")
	end

	function META:Finish()
		table.insert(events, "finish")
	end

	META:Register()

	local META = entity.ComponentTemplate("test2")
	META:Register()
end

do
	assert(#entity.GetAll() == 0)
	local a = entity.Create({"test"})
	assert(#entity.GetAll() == 1)
	a:AddComponent("test2")
	assert(#entity.GetAllComponents("test2") == 1)
	a:RemoveComponent("test2")
	assert(#entity.GetAllComponents("test2") == 0)
	a:Remove()
	assert(#entity.GetAll() == 0)
end

do
	local a = entity.Create({"test"})
	a:AddComponent("test2")
	a:Remove()
	assert(#entity.GetAllComponents("test2") == 0)
	assert(#entity.GetAll() == 0)
end

do
	events = {}

	local obj = entity.Create({"test"})
	obj:FireEvent("Update")
	obj:FireEvent("Update")
	obj:Remove()

	assert(table.remove(events, 1) == "start")
	assert(table.remove(events, 1) == "update")
	assert(table.remove(events, 1) == "update")
	assert(table.remove(events, 1) == "finish")
end

do
	local META = entity.ComponentTemplate("test")

	function META:Start()
		self.FooBar = true
	end

	function META:SetFoo(b)
		self.FooBar = b
	end

	META:Register()

	local META = entity.ComponentTemplate("test2")

	function META:SetFoo(b)
		self.FooBar = b
	end

	META:Register()

	local ent = entity.Create()
	local cmp = ent:AddComponent("test")
	assert(cmp.FooBar == true)
	assert(ent.test.FooBar == true)
	assert(entity.GetAllComponents("test")[1].FooBar == true)

	ent:SetFoo("bar")
	assert(cmp.FooBar == "bar")

	ent:AddComponent("test2")
	ent:SetFoo("noyesthat")

	assert(ent.test.FooBar == "noyesthat")
	assert(ent.test2.FooBar == "noyesthat")

	ent:Remove()
end

assert(#entity.GetAll() == 0)