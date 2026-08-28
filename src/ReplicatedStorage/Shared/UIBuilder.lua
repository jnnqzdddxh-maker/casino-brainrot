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

local SCREEN_COLOR = Color3.fromRGB(11, 14, 20)
local TRIM_COLOR = Color3.fromRGB(242, 179, 61)
local TEXT_COLOR = Color3.fromRGB(233, 236, 244)

local function quickButton(parent, name, text, layoutOrder)
	local button = UIBuilder.create("TextButton", {
		Name = name,
		LayoutOrder = layoutOrder,
		Size = UDim2.new(0, 60, 0, 50),
		BackgroundColor3 = SCREEN_COLOR,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = TRIM_COLOR,
		TextScaled = true,
		AutoButtonColor = true,
		Parent = parent,
	})
	UIBuilder.addCorner(button, 10)
	UIBuilder.addStroke(button, TRIM_COLOR, 0.6)
	return button
end

-- Builds a two-row bet control block: a quick-select row (MIN / 1/4 / 1/2 /
-- 3/4 / MAX) and a fine-tune row (- / current bet / +). Used by every game's
-- cabinet so they all share the same betting controls.
function UIBuilder.buildBetRow(parent, layoutOrder, minBet)
	local betRow = UIBuilder.create("Frame", {
		Name = "BetRow",
		LayoutOrder = layoutOrder,
		Size = UDim2.new(0, 360, 0, 118),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	UIBuilder.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = betRow,
	})

	local quickRow = UIBuilder.create("Frame", {
		Name = "QuickRow",
		LayoutOrder = 1,
		Size = UDim2.new(0, 340, 0, 50),
		BackgroundTransparency = 1,
		Parent = betRow,
	})
	UIBuilder.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = quickRow,
	})

	quickButton(quickRow, "MinBet", "MIN", 1)
	quickButton(quickRow, "Quarter", "¼", 2)
	quickButton(quickRow, "Half", "½", 3)
	quickButton(quickRow, "ThreeQuarter", "¾", 4)
	quickButton(quickRow, "MaxBet", "MAX", 5)

	local stepRow = UIBuilder.create("Frame", {
		Name = "StepRow",
		LayoutOrder = 2,
		Size = UDim2.new(0, 298, 0, 60),
		BackgroundTransparency = 1,
		Parent = betRow,
	})
	UIBuilder.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 14),
		Parent = stepRow,
	})

	local minusButton = UIBuilder.create("TextButton", {
		Name = "Minus",
		LayoutOrder = 1,
		Size = UDim2.new(0, 60, 0, 60),
		BackgroundColor3 = SCREEN_COLOR,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = "-",
		TextColor3 = TRIM_COLOR,
		TextScaled = true,
		AutoButtonColor = true,
		Parent = stepRow,
	})
	UIBuilder.addCorner(minusButton, 10)
	UIBuilder.addStroke(minusButton, TRIM_COLOR, 0.6)

	UIBuilder.create("TextLabel", {
		Name = "BetLabel",
		LayoutOrder = 2,
		Size = UDim2.new(0, 150, 0, 60),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "Mise : " .. minBet,
		TextColor3 = TEXT_COLOR,
		TextScaled = true,
		Parent = stepRow,
	})

	local plusButton = UIBuilder.create("TextButton", {
		Name = "Plus",
		LayoutOrder = 3,
		Size = UDim2.new(0, 60, 0, 60),
		BackgroundColor3 = SCREEN_COLOR,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = "+",
		TextColor3 = TRIM_COLOR,
		TextScaled = true,
		AutoButtonColor = true,
		Parent = stepRow,
	})
	UIBuilder.addCorner(plusButton, 10)
	UIBuilder.addStroke(plusButton, TRIM_COLOR, 0.6)

	return betRow
end

return UIBuilder
