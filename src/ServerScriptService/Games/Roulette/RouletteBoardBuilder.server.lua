local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIBuilder = require(ReplicatedStorage.Shared.UIBuilder)
local RouletteConfig = require(ReplicatedStorage.Shared.RouletteConfig)
local create = UIBuilder.create
local addCorner = UIBuilder.addCorner
local addStroke = UIBuilder.addStroke

-- Place an empty Part anywhere in Workspace and rename it exactly
-- "RouletteSpawn" (position/rotation define where the board appears).
local SPAWN_MARKER_NAME = "RouletteSpawn"

local BODY_COLOR = Color3.fromRGB(19, 24, 38)
local SCREEN_COLOR = Color3.fromRGB(11, 14, 20)
local TRIM_COLOR = Color3.fromRGB(242, 179, 61)
local TEXT_COLOR = Color3.fromRGB(233, 236, 244)
local MUTED_COLOR = Color3.fromRGB(139, 147, 167)
local RED_COLOR = Color3.fromRGB(200, 45, 55)
local BLACK_COLOR = Color3.fromRGB(24, 24, 28)
local GREEN_COLOR = Color3.fromRGB(45, 165, 95)

local BOARD_SIZE = Vector3.new(9, 12.5, 0.6)
local CANVAS_SIZE = Vector2.new(800, 1020)

local function numberColor(number)
	local colorName = RouletteConfig.GetColor(number)
	if colorName == "red" then
		return RED_COLOR
	elseif colorName == "black" then
		return BLACK_COLOR
	end
	return GREEN_COLOR
end

local function buildWheel(parent)
	local wheelRow = create("Frame", {
		Name = "WheelRow",
		LayoutOrder = 2,
		Size = UDim2.new(0, 700, 0, 300),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 20),
		Parent = wheelRow,
	})

	local wheelContainer = create("Frame", {
		Name = "WheelContainer",
		LayoutOrder = 1,
		Size = UDim2.new(0, 280, 0, 300),
		BackgroundTransparency = 1,
		Parent = wheelRow,
	})

	local wheelFrame = create("Frame", {
		Name = "WheelFrame",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(0, 260, 0, 260),
		BackgroundColor3 = SCREEN_COLOR,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = wheelContainer,
	})
	addCorner(wheelFrame, 130)
	addStroke(wheelFrame, TRIM_COLOR, 0.3)

	local spinner = create("Frame", {
		Name = "Spinner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = wheelFrame,
	})

	local segmentAngle = 360 / #RouletteConfig.WheelOrder
	for i, number in RouletteConfig.WheelOrder do
		create("Frame", {
			Name = "Segment" .. i,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 16, 0, 124),
			Rotation = (i - 1) * segmentAngle,
			BackgroundColor3 = numberColor(number),
			BorderSizePixel = 0,
			Parent = spinner,
		})
	end

	create("TextLabel", {
		Name = "Pointer",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0, 34, 0, 34),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "▼",
		TextColor3 = TRIM_COLOR,
		TextScaled = true,
		Parent = wheelContainer,
	})

	create("TextLabel", {
		Name = "WinningNumberLabel",
		LayoutOrder = 2,
		Size = UDim2.new(0, 340, 0, 280),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "—",
		TextColor3 = TEXT_COLOR,
		TextScaled = true,
		Parent = wheelRow,
	})
end

local function buildNumberGrid(parent, layoutOrder)
	local numbersRow = create("Frame", {
		Name = "NumbersRow",
		LayoutOrder = layoutOrder,
		Size = UDim2.new(0, 715, 0, 156),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = numbersRow,
	})

	local zeroButton = create("TextButton", {
		Name = "Num0",
		LayoutOrder = 1,
		Size = UDim2.new(0, 50, 0, 156),
		BackgroundColor3 = numberColor(0),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = "0",
		TextColor3 = TEXT_COLOR,
		TextScaled = true,
		AutoButtonColor = true,
		Parent = numbersRow,
	})
	addCorner(zeroButton, 8)
	addStroke(zeroButton, TRIM_COLOR, 0.6)

	local numberGrid = create("Frame", {
		Name = "NumberGrid",
		LayoutOrder = 2,
		Size = UDim2.new(0, 657, 0, 156),
		BackgroundTransparency = 1,
		Parent = numbersRow,
	})
	create("UIGridLayout", {
		CellSize = UDim2.new(0, 52, 0, 50),
		CellPadding = UDim2.new(0, 3, 0, 3),
		FillDirection = Enum.FillDirection.Horizontal,
		FillDirectionMaxCells = 12,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = numberGrid,
	})

	local function makeCell(number, order)
		local button = create("TextButton", {
			Name = "Num" .. number,
			LayoutOrder = order,
			BackgroundColor3 = numberColor(number),
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Text = tostring(number),
			TextColor3 = TEXT_COLOR,
			TextScaled = true,
			AutoButtonColor = true,
			Parent = numberGrid,
		})
		addCorner(button, 6)
	end

	for column = 1, 12 do
		makeCell(3 * column, column) -- top row: 3, 6, 9, ... 36
		makeCell(3 * column - 1, 12 + column) -- middle row: 2, 5, 8, ... 35
		makeCell(3 * column - 2, 24 + column) -- bottom row: 1, 4, 7, ... 34
	end
end

local function buildOutsideBets(parent, layoutOrder)
	local outsideRow = create("Frame", {
		Name = "OutsideBetsRow",
		LayoutOrder = layoutOrder,
		Size = UDim2.new(0, 700, 0, 50),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = outsideRow,
	})

	local function outsideButton(name, text, color, order)
		local button = create("TextButton", {
			Name = name,
			LayoutOrder = order,
			Size = UDim2.new(0, 110, 0, 50),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Text = text,
			TextColor3 = TEXT_COLOR,
			TextScaled = true,
			AutoButtonColor = true,
			Parent = outsideRow,
		})
		addCorner(button, 10)
		addStroke(button, TRIM_COLOR, 0.6)
	end

	outsideButton("Red", "ROUGE", RED_COLOR, 1)
	outsideButton("Black", "NOIR", BLACK_COLOR, 2)
	outsideButton("Even", "PAIR", SCREEN_COLOR, 3)
	outsideButton("Odd", "IMPAIR", SCREEN_COLOR, 4)
	outsideButton("Low", "1-18", SCREEN_COLOR, 5)
	outsideButton("High", "19-36", SCREEN_COLOR, 6)
end

local function buildScreenPanel(screenPart)
	local surfaceGui = create("SurfaceGui", {
		Name = "ScreenGui",
		Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.FixedSize,
		CanvasSize = CANVAS_SIZE,
		Parent = screenPart,
	})

	local panel = create("Frame", {
		Name = "Panel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BODY_COLOR,
		BorderSizePixel = 0,
		Parent = surfaceGui,
	})

	create("UIPadding", {
		PaddingTop = UDim.new(0, 26),
		PaddingBottom = UDim.new(0, 26),
		PaddingLeft = UDim.new(0, 30),
		PaddingRight = UDim.new(0, 30),
		Parent = panel,
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 16),
		Parent = panel,
	})

	create("TextLabel", {
		Name = "Title",
		LayoutOrder = 1,
		Size = UDim2.new(0, 700, 0, 34),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "CASINO BRAINROT — ROULETTE",
		TextColor3 = TRIM_COLOR,
		TextScaled = true,
		Parent = panel,
	})

	buildWheel(panel)

	create("TextLabel", {
		Name = "StatusLabel",
		LayoutOrder = 3,
		Size = UDim2.new(0, 700, 0, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = "En attente...",
		TextColor3 = MUTED_COLOR,
		TextScaled = true,
		Parent = panel,
	})

	buildNumberGrid(panel, 4)
	buildOutsideBets(panel, 5)

	UIBuilder.buildBetRow(panel, 6, RouletteConfig.MinBet)

	local historyRow = create("Frame", {
		Name = "HistoryRow",
		LayoutOrder = 7,
		Size = UDim2.new(0, 700, 0, 40),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = historyRow,
	})

	create("TextLabel", {
		Name = "Result",
		LayoutOrder = 8,
		Size = UDim2.new(0, 700, 0, 28),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "",
		TextColor3 = MUTED_COLOR,
		TextScaled = true,
		Parent = panel,
	})
end

local function getMarkerCFrame(marker)
	if marker:IsA("BasePart") then
		return marker.CFrame
	elseif marker:IsA("Model") then
		return marker:GetPivot()
	end
	return nil
end

local function buildBoardAt(markerCFrame)
	local cframe = markerCFrame * CFrame.new(0, BOARD_SIZE.Y / 2, 0)

	local model = Instance.new("Model")
	model.Name = "RouletteBoard"

	local body = create("Part", {
		Name = "Body",
		Size = BOARD_SIZE,
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.SmoothPlastic,
		Color = BODY_COLOR,
		CFrame = cframe,
		Parent = model,
	})

	local function trimStrip(name, yOffset)
		return create("Part", {
			Name = name,
			Size = Vector3.new(BOARD_SIZE.X + 0.1, 0.15, BOARD_SIZE.Z + 0.1),
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Neon,
			Color = TRIM_COLOR,
			CFrame = cframe * CFrame.new(0, yOffset, 0),
			Parent = model,
		})
	end

	trimStrip("TrimTop", BOARD_SIZE.Y / 2 - 0.1)
	local trimBottom = trimStrip("TrimBottom", -BOARD_SIZE.Y / 2 + 0.15)

	create("PointLight", {
		Color = TRIM_COLOR,
		Range = 14,
		Brightness = 2.5,
		Parent = trimBottom,
	})

	local screen = create("Part", {
		Name = "Screen",
		Size = Vector3.new(BOARD_SIZE.X - 0.4, BOARD_SIZE.Y - 0.6, 0.1),
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = SCREEN_COLOR,
		CFrame = cframe * CFrame.new(0, 0, -BOARD_SIZE.Z / 2 - 0.06),
		Parent = model,
	})

	buildScreenPanel(screen)

	model.PrimaryPart = body
	model.Parent = Workspace
end

local function onMarkerFound(marker)
	local cframe = getMarkerCFrame(marker)
	if not cframe then
		return
	end

	marker:Destroy()
	buildBoardAt(cframe)
end

for _, descendant in Workspace:GetDescendants() do
	if descendant.Name == SPAWN_MARKER_NAME then
		onMarkerFound(descendant)
	end
end

Workspace.DescendantAdded:Connect(function(descendant)
	if descendant.Name == SPAWN_MARKER_NAME then
		onMarkerFound(descendant)
	end
end)
