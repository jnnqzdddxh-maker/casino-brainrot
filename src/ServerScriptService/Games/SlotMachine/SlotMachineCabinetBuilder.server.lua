local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SlotMachineConfig = require(ReplicatedStorage.Shared.SlotMachineConfig)
local UIBuilder = require(ReplicatedStorage.Shared.UIBuilder)
local Theme = require(ReplicatedStorage.Shared.Theme)
local create = UIBuilder.create
local addCorner = UIBuilder.addCorner
local addStroke = UIBuilder.addStroke

-- Place an empty Part anywhere in Workspace and rename it exactly
-- "SlotMachineSpawn" (position/rotation define where the cabinet appears).
-- This script replaces it with a fully built, playable cabinet.
local SPAWN_MARKER_NAME = "SlotMachineSpawn"

local BODY_COLOR = Theme.Body
local SCREEN_COLOR = Theme.Screen
local TRIM_COLOR = Theme.Trim
local TEXT_COLOR = Theme.Text
local MUTED_COLOR = Theme.Muted

local CABINET_SIZE = Vector3.new(5, 10, 2.5)
local CANVAS_SIZE = Vector2.new(500, 780)
local CELL_SIZE = SlotMachineConfig.CellSize
local CELL_GAP = 8

-- Builds the interactive panel (title, reels, bet stepper, spin button,
-- result text) inside the cabinet's screen SurfaceGui. Behavior (clicks,
-- animation, RemoteEvent calls) is wired up client-side.
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
		PaddingLeft = UDim.new(0, 24),
		PaddingRight = UDim.new(0, 24),
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
		Size = UDim2.new(0, 352, 0, 34),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "CASINO BRAINROT",
		TextColor3 = TRIM_COLOR,
		TextScaled = true,
		Parent = panel,
	})

	create("TextLabel", {
		Name = "Subtitle",
		LayoutOrder = 2,
		Size = UDim2.new(0, 352, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = "MACHINE À SOUS",
		TextColor3 = MUTED_COLOR,
		TextScaled = true,
		Parent = panel,
	})

	-- No vertical gap: each reel is one continuous clipped "window" that a
	-- scrolling strip of symbols slides behind (built client-side), giving a
	-- real slot-machine reel effect instead of 3 static boxes.
	local gridWidth = SlotMachineConfig.ReelCount * CELL_SIZE + (SlotMachineConfig.ReelCount - 1) * CELL_GAP
	local gridHeight = SlotMachineConfig.GridRows * CELL_SIZE

	local reelsFrame = create("Frame", {
		Name = "Reels",
		LayoutOrder = 3,
		Size = UDim2.new(0, gridWidth, 0, gridHeight),
		BackgroundTransparency = 1,
		Parent = panel,
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, CELL_GAP),
		Parent = reelsFrame,
	})

	for col = 1, SlotMachineConfig.ReelCount do
		local window = create("Frame", {
			Name = "Window" .. col,
			LayoutOrder = col,
			Size = UDim2.new(0, CELL_SIZE, 0, gridHeight),
			BackgroundColor3 = SCREEN_COLOR,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Parent = reelsFrame,
		})
		addCorner(window, 12)
		addStroke(window, TRIM_COLOR, 0.7)
	end

	create("TextLabel", {
		Name = "Balance",
		LayoutOrder = 4,
		Size = UDim2.new(0, 352, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "Solde : — Chips",
		TextColor3 = TEXT_COLOR,
		TextScaled = true,
		Parent = panel,
	})

	UIBuilder.buildBetRow(panel, 5, SlotMachineConfig.MinBet)

	local spinButton = create("TextButton", {
		Name = "SpinButton",
		LayoutOrder = 6,
		Size = UDim2.new(0, 300, 0, 70),
		BackgroundColor3 = TRIM_COLOR,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBlack,
		Text = "SPIN",
		TextColor3 = SCREEN_COLOR,
		TextScaled = true,
		AutoButtonColor = true,
		Parent = panel,
	})
	addCorner(spinButton, 14)

	create("TextLabel", {
		Name = "Result",
		LayoutOrder = 7,
		Size = UDim2.new(0, 352, 0, 26),
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

local function buildCabinetAt(markerCFrame)
	-- Treat the marker as the cabinet's floor position, not its center.
	local cframe = markerCFrame * CFrame.new(0, CABINET_SIZE.Y / 2, 0)

	local model = Instance.new("Model")
	model.Name = "SlotMachineCabinet"

	local body = create("Part", {
		Name = "Body",
		Size = CABINET_SIZE,
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
			Size = Vector3.new(CABINET_SIZE.X + 0.1, 0.15, CABINET_SIZE.Z + 0.1),
			Anchored = true,
			CanCollide = false,
			Material = Enum.Material.Neon,
			Color = TRIM_COLOR,
			CFrame = cframe * CFrame.new(0, yOffset, 0),
			Parent = model,
		})
	end

	trimStrip("TrimTop", CABINET_SIZE.Y / 2 - 0.1)
	local trimBottom = trimStrip("TrimBottom", -CABINET_SIZE.Y / 2 + 0.15)

	create("PointLight", {
		Color = TRIM_COLOR,
		Range = 12,
		Brightness = 2.5,
		Parent = trimBottom,
	})

	local screen = create("Part", {
		Name = "Screen",
		Size = Vector3.new(CABINET_SIZE.X - 0.4, CABINET_SIZE.Y - 1.4, 0.1),
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = SCREEN_COLOR,
		CFrame = cframe * CFrame.new(0, 0.3, -CABINET_SIZE.Z / 2 - 0.06),
		Parent = model,
	})

	buildScreenPanel(screen)

	local sign = create("Part", {
		Name = "Sign",
		Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
		Anchored = true,
		CanCollide = false,
		CFrame = cframe * CFrame.new(0, CABINET_SIZE.Y / 2 + 0.7, 0),
		Parent = model,
	})

	local signGui = create("BillboardGui", {
		Name = "SignGui",
		Size = UDim2.new(0, 180, 0, 46),
		AlwaysOnTop = true,
		Parent = sign,
	})

	local signLabel = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBlack,
		Text = "SLOTS",
		TextColor3 = TRIM_COLOR,
		TextScaled = true,
		Parent = signGui,
	})

	create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 2, Parent = signLabel })

	model.PrimaryPart = body
	model.Parent = Workspace
end

local function onMarkerFound(marker)
	local cframe = getMarkerCFrame(marker)
	if not cframe then
		return
	end

	marker:Destroy()
	buildCabinetAt(cframe)
end

UIBuilder.rebuildExistingBoards("SlotMachineCabinet", CABINET_SIZE.Y / 2, buildCabinetAt)

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
