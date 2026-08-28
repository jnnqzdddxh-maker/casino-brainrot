local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIBuilder = require(ReplicatedStorage.Shared.UIBuilder)
local RouletteConfig = require(ReplicatedStorage.Shared.RouletteConfig)
local Theme = require(ReplicatedStorage.Shared.Theme)
local create = UIBuilder.create
local addCorner = UIBuilder.addCorner
local addStroke = UIBuilder.addStroke

-- Place an empty Part anywhere in Workspace and rename it exactly
-- "RouletteSpawn" (position/rotation define where the board appears).
local SPAWN_MARKER_NAME = "RouletteSpawn"

local BODY_COLOR = Theme.Body
local SCREEN_COLOR = Theme.Screen
local TRIM_COLOR = Theme.Trim
local TEXT_COLOR = Theme.Text
local MUTED_COLOR = Theme.Muted
local RED_COLOR = Theme.Red
local BLACK_COLOR = Theme.RouletteBlack
local GREEN_COLOR = Theme.Green
local NEUTRAL_COLOR = Theme.Neutral

-- A flat table, not a standee: X/Z are the tabletop footprint, Y is table
-- height. The screen sits on the TOP face, so players look down onto it.
-- The wheel itself lives separately on RouletteWheelBuilder's big sign —
-- this mat is just the betting layout, so it can stay wide and low.
local TABLE_SIZE = Vector3.new(11, 3, 7.6)
local CANVAS_SIZE = Vector2.new(1100, 740)

local function numberColor(number)
	local colorName = RouletteConfig.GetColor(number)
	if colorName == "red" then
		return RED_COLOR
	elseif colorName == "black" then
		return BLACK_COLOR
	end
	return GREEN_COLOR
end

local function buildNumberGrid(parent, layoutOrder)
	local numbersRow = create("Frame", {
		Name = "NumbersRow",
		LayoutOrder = layoutOrder,
		Size = UDim2.new(0, 1017, 0, 226),
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
		Size = UDim2.new(0, 66, 0, 226),
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
	addStroke(zeroButton, TRIM_COLOR, 0.2)
	UIBuilder.addRaisedLook(zeroButton)

	local numberGrid = create("Frame", {
		Name = "NumberGrid",
		LayoutOrder = 2,
		Size = UDim2.new(0, 943, 0, 226),
		BackgroundTransparency = 1,
		Parent = numbersRow,
	})
	create("UIGridLayout", {
		CellSize = UDim2.new(0, 74, 0, 72),
		CellPadding = UDim2.new(0, 5, 0, 5),
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
		addStroke(button, TRIM_COLOR, 0.2)
		UIBuilder.addRaisedLook(button)
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
		Size = UDim2.new(0, 950, 0, 64),
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
			Size = UDim2.new(0, 150, 0, 64),
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
		addStroke(button, TRIM_COLOR, 0.3)
		UIBuilder.addRaisedLook(button)
	end

	outsideButton("Red", "ROUGE", RED_COLOR, 1)
	outsideButton("Black", "NOIR", BLACK_COLOR, 2)
	outsideButton("Even", "PAIR", NEUTRAL_COLOR, 3)
	outsideButton("Odd", "IMPAIR", NEUTRAL_COLOR, 4)
	outsideButton("Low", "1-18", NEUTRAL_COLOR, 5)
	outsideButton("High", "19-36", NEUTRAL_COLOR, 6)
end

local function buildScreenPanel(screenPart)
	local surfaceGui = create("SurfaceGui", {
		Name = "ScreenGui",
		Face = Enum.NormalId.Top,
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
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 16),
		Parent = panel,
	})

	create("TextLabel", {
		Name = "Title",
		LayoutOrder = 1,
		Size = UDim2.new(0, 1017, 0, 38),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "CASINO BRAINROT — ROULETTE",
		TextColor3 = TRIM_COLOR,
		TextScaled = true,
		Parent = panel,
	})

	create("TextLabel", {
		Name = "StatusLabel",
		LayoutOrder = 3,
		Size = UDim2.new(0, 1017, 0, 30),
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
		Size = UDim2.new(0, 1017, 0, 44),
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
		Size = UDim2.new(0, 1017, 0, 30),
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
	local cframe = markerCFrame * CFrame.new(0, TABLE_SIZE.Y / 2, 0)

	local model = Instance.new("Model")
	model.Name = "RouletteBoard"

	local body = create("Part", {
		Name = "Body",
		Size = TABLE_SIZE,
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.SmoothPlastic,
		Color = BODY_COLOR,
		CFrame = cframe,
		Parent = model,
	})

	-- A glowing gold frame around the tabletop's rim, just under the glass.
	local function edgeStrip(name, size, offset)
		return create("Part", {
			Name = name,
			Size = size,
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Neon,
			Color = TRIM_COLOR,
			CFrame = cframe * CFrame.new(offset),
			Parent = model,
		})
	end

	local rimY = TABLE_SIZE.Y / 2 - 0.05
	edgeStrip("TrimFront", Vector3.new(TABLE_SIZE.X, 0.15, 0.2), Vector3.new(0, rimY, TABLE_SIZE.Z / 2 - 0.1))
	edgeStrip("TrimBack", Vector3.new(TABLE_SIZE.X, 0.15, 0.2), Vector3.new(0, rimY, -TABLE_SIZE.Z / 2 + 0.1))
	edgeStrip("TrimLeft", Vector3.new(0.2, 0.15, TABLE_SIZE.Z), Vector3.new(TABLE_SIZE.X / 2 - 0.1, rimY, 0))
	local trimRight = edgeStrip("TrimRight", Vector3.new(0.2, 0.15, TABLE_SIZE.Z), Vector3.new(-TABLE_SIZE.X / 2 + 0.1, rimY, 0))

	create("PointLight", {
		Color = TRIM_COLOR,
		Range = 14,
		Brightness = 2.5,
		Parent = trimRight,
	})

	local screen = create("Part", {
		Name = "Screen",
		Size = Vector3.new(TABLE_SIZE.X - 0.4, 0.1, TABLE_SIZE.Z - 0.4),
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = SCREEN_COLOR,
		CFrame = cframe * CFrame.new(0, TABLE_SIZE.Y / 2 + 0.06, 0),
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

UIBuilder.rebuildExistingBoards("RouletteBoard", TABLE_SIZE.Y / 2, buildBoardAt)

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
