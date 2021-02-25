local entity = pac999.entity

local scene = {}

local components = {
	"node",
	"transform",
	"bounding_box",
	"input",
	"model",
	"gizmo"
}

scene.world = entity.Create(components)

function scene.AddNode(parent)
	parent = parent or scene.world

	local node = entity.Create(components)
	parent.node:AddChild(node)

	return node
end

return scene