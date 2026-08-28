local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIBuilder = require(ReplicatedStorage.Shared.UIBuilder)
local create = UIBuilder.create
local addCorner = UIBuilder.addCorner
local addStroke = UIBuilder.addStroke

-- Place an empty Part anywhere in Workspace and rename it exactly
-- "CrashSpawn" (position/rotation define where the board appears).
local SPAWN_MARKER_NAME = "CrashSpawn"

local BODY_COLOR = Color3.fromRGB(19, 24, 38)
local SCREEN_COLOR = Color3.fromRGB(11, 14, 20)
local TRIM_COLOR = Color3.fromRGB(242, 179, 61)
local TEXT_COLOR = Color3.fromRGB(233, 236, 244)
local MUTED_COLOR = Color3.fromRGB(139, 147, 167)

local BOARD_SIZE = Vector3.new(10, 7, 0.6)
local CANVAS_SIZE = Vector2.new(900, 640)

local function betButton(parent, name, text, layoutOrder)
	local button = create("TextButton", {
		Name = name,
		LayoutOrder = layoutOrder,
		Size = UDim2.new(0, 70, 0, 64),
		BackgroundColor3 = SCREEN_COLOR,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = TRIM_COLOR,
		TextScaled = true,
		AutoButtonColor = true,
		Parent = parent,
	})
	addCorner(button, 10)
	addStroke(button, TRIM_COLOR, 0.6)
	return button
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
		PaddingTop = UDim.new(0, 30),
		PaddingBottom = UDim.new(0, 30),
		PaddingLeft = UDim.new(0, 36),
		PaddingRight = UDim.new(0, 36),
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
		Text = "CASINO BRAINROT — CRASH",
		TextColor3 = TRIM_COLOR,
		TextScaled = true,
		Parent = panel,
	})

	create("TextLabel", {
		Name = "MultiplierLabel",
		LayoutOrder = 2,
		Size = UDim2.new(0, 700, 0, 160),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "1.00x",
		TextColor3 = TEXT_COLOR,
		TextScaled = true,
		Parent = panel,
	})

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

	local historyRow = create("Frame", {
		Name = "HistoryRow",
		LayoutOrder = 4,
		Size = UDim2.new(0, 700, 0, 40),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = historyRow,
	})

	local betRow = create("Frame", {
		Name = "BetRow",
		LayoutOrder = 5,
		Size = UDim2.new(0, 520, 0, 64),
		BackgroundTransparency = 1,
		Parent = panel,
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 14),
		Parent = betRow,
	})

	betButton(betRow, "MinBet", "MIN", 1)
	betButton(betRow, "Minus", "-", 2)

	create("TextLabel", {
		Name = "BetLabel",
		LayoutOrder = 3,
		Size = UDim2.new(0, 160, 0, 64),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "Mise : 10",
		TextColor3 = TEXT_COLOR,
		TextScaled = true,
		Parent = betRow,
	})

	betButton(betRow, "Plus", "+", 4)
	betButton(betRow, "MaxBet", "MAX", 5)

	local actionButton = create("TextButton", {
		Name = "ActionButton",
		LayoutOrder = 6,
		Size = UDim2.new(0, 520, 0, 80),
		BackgroundColor3 = TRIM_COLOR,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBlack,
		Text = "MISER",
		TextColor3 = SCREEN_COLOR,
		TextScaled = true,
		AutoButtonColor = true,
		Parent = panel,
	})
	addCorner(actionButton, 16)

	create("TextLabel", {
		Name = "Result",
		LayoutOrder = 7,
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
	model.Name = "CrashBoard"

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
