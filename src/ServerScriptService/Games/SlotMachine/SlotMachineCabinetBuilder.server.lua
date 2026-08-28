local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SlotMachineConfig = require(ReplicatedStorage.Shared.SlotMachineConfig)

-- Place an empty Part anywhere in Workspace and rename it exactly
-- "SlotMachineSpawn" (position/rotation define where the cabinet appears).
-- This script replaces it with a fully built, playable cabinet.
local SPAWN_MARKER_NAME = "SlotMachineSpawn"

local BODY_COLOR = Color3.fromRGB(19, 24, 38) -- surface
local SCREEN_COLOR = Color3.fromRGB(11, 14, 20) -- bg
local TRIM_COLOR = Color3.fromRGB(242, 179, 61) -- gold
local TEXT_COLOR = Color3.fromRGB(233, 236, 244)
local MUTED_COLOR = Color3.fromRGB(139, 147, 167)

local CABINET_SIZE = Vector3.new(5, 10, 2.5)
local CANVAS_SIZE = Vector2.new(500, 950)
local CELL_SIZE = 100
local CELL_GAP = 8

local function create(className, props)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	return instance
end

local function addCorner(parent, radius)
	create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function addStroke(parent, color, transparency)
	create("UIStroke", { Color = color, Thickness = 2, Transparency = transparency or 0, Parent = parent })
end

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

	local gridWidth = SlotMachineConfig.ReelCount * CELL_SIZE + (SlotMachineConfig.ReelCount - 1) * CELL_GAP
	local gridHeight = SlotMachineConfig.GridRows * CELL_SIZE + (SlotMachineConfig.GridRows - 1) * CELL_GAP

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

	-- Each reel is a column of GridRows symbols. Only the middle row is the
	-- real (server-authoritative) payline; the rest is visual flavor.
	for col = 1, SlotMachineConfig.ReelCount do
		local column = create("Frame", {
			Name = "Column" .. col,
			LayoutOrder = col,
			Size = UDim2.new(0, CELL_SIZE, 0, gridHeight),
			BackgroundTransparency = 1,
			Parent = reelsFrame,
		})

		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, CELL_GAP),
			Parent = column,
		})

		for row = 1, SlotMachineConfig.GridRows do
			local cell = create("Frame", {
				Name = "Row" .. row,
				LayoutOrder = row,
				Size = UDim2.new(0, CELL_SIZE, 0, CELL_SIZE),
				BackgroundColor3 = SCREEN_COLOR,
				BorderSizePixel = 0,
				Parent = column,
			})
			addCorner(cell, 12)
			addStroke(cell, TRIM_COLOR, 0.7)

			create("TextLabel", {
				Name = "Symbol",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Font = Enum.Font.SourceSansBold,
				Text = "🍒",
				TextScaled = true,
				Parent = cell,
			})
		end
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

	local betRow = create("Frame", {
		Name = "BetRow",
		LayoutOrder = 5,
		Size = UDim2.new(0, 420, 0, 56),
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

	local function betButton(name, text, layoutOrder)
		local button = create("TextButton", {
			Name = name,
			LayoutOrder = layoutOrder,
			Size = UDim2.new(0, 56, 0, 56),
			BackgroundColor3 = SCREEN_COLOR,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Text = text,
			TextColor3 = TRIM_COLOR,
			TextScaled = true,
			AutoButtonColor = true,
			Parent = betRow,
		})
		addCorner(button, 10)
		addStroke(button, TRIM_COLOR, 0.6)
		return button
	end

	betButton("MinBet", "MIN", 1)
	betButton("Minus", "-", 2)

	create("TextLabel", {
		Name = "BetLabel",
		LayoutOrder = 3,
		Size = UDim2.new(0, 140, 0, 56),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "Mise : " .. SlotMachineConfig.MinBet,
		TextColor3 = TEXT_COLOR,
		TextScaled = true,
		Parent = betRow,
	})

	betButton("Plus", "+", 4)
	betButton("MaxBet", "MAX", 5)

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

local function buildCabinetAt(cframe)
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
