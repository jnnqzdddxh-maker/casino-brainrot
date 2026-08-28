local UIBuilder = {}

function UIBuilder.create(className, props)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	return instance
end

function UIBuilder.addCorner(parent, radius)
	UIBuilder.create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

function UIBuilder.addStroke(parent, color, transparency)
	UIBuilder.create("UIStroke", { Color = color, Thickness = 2, Transparency = transparency or 0, Parent = parent })
end

return UIBuilder
