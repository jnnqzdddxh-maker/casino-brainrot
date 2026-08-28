local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIBuilder = require(ReplicatedStorage.Shared.UIBuilder)
local RouletteConfig = require(ReplicatedStorage.Shared.RouletteConfig)
local Theme = require(ReplicatedStorage.Shared.Theme)
local create = UIBuilder.create
local addCorner = UIBuilder.addCorner
local addStroke = UIBuilder.addStroke

-- Place an empty Part anywhere in Workspace and rename it exactly
-- "RouletteWheelSpawn" (position/rotation define where the wheel appears).
-- This is a big vertical wheel on a pole — separate from the flat betting
-- mat (RouletteSpawn) — so it reads from across the room like a real casino
-- wheel display, instead of being buried in a table you have to stand over.
local SPAWN_MARKER_NAME = "RouletteWheelSpawn"

-- Classic casino colors, matching RouletteBoardBuilder: green felt, true
-- red/black pockets, gold trim.
local TRIM_COLOR = Theme.Trim
local TEXT_COLOR = Theme.Text
local MUTED_COLOR = Theme.Muted
local BODY_COLOR = Color3.fromRGB(19, 46, 32)
local SCREEN_COLOR = Color3.fromRGB(12, 30, 21)
local RED_COLOR = Color3.fromRGB(200, 30, 40)
local BLACK_COLOR = Color3.fromRGB(42, 42, 46)
local GREEN_COLOR = Color3.fromRGB(30, 130, 75)

local POLE_HEIGHT = 5
local SIGN_SIZE = Vector3.new(11, 11, 0.7)
local CANVAS_SIZE = Vector2.new(1000, 1100)

local function numberColor(number)
	local colorName = RouletteConfig.GetColor(number)
	if colorName == "red" then
		return RED_COLOR
	elseif colorName == "black" then
		return BLACK_COLOR
	end
	return GREEN_COLOR
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
		PaddingTop = UDim.new(0, 24),
		PaddingBottom = UDim.new(0, 24),
		Parent = panel,
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 12),
		Parent = panel,
	})

	create("TextLabel", {
		Name = "Title",
		LayoutOrder = 1,
		Size = UDim2.new(0, 900, 0, 46),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "CASINO BRAINROT — ROULETTE",
		TextColor3 = TRIM_COLOR,
		TextScaled = true,
		Parent = panel,
	})

	local wheelFrame = create("Frame", {
		Name = "WheelFrame",
		LayoutOrder = 2,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(0, 760, 0, 760),
		BackgroundColor3 = SCREEN_COLOR,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = panel,
	})
	addCorner(wheelFrame, 380)
	addStroke(wheelFrame, TRIM_COLOR, 0.1)

	local spinner = create("Frame", {
		Name = "Spinner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = wheelFrame,
	})

	-- Segments reach almost all the way to the wheel's own edge (radius 380)
	-- and are wide enough to overlap their neighbors, so the wheel reads as
	-- one solid disc filling its circular frame — not a smaller disc with a
	-- dark ring around it, and not a spiky pinwheel with gaps between
	-- wedges. The wheel never rotates — only the ball does.
	local segmentAngle = 360 / #RouletteConfig.WheelOrder
	local WHEEL_RADIUS = 376
	for i, number in RouletteConfig.WheelOrder do
		create("Frame", {
			Name = "Segment" .. i,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 92, 0, WHEEL_RADIUS),
			Rotation = (i - 1) * segmentAngle,
			BackgroundColor3 = numberColor(number),
			BorderSizePixel = 0,
			Parent = spinner,
		})
	end

	-- Thin, subtle gold dividers at each pocket boundary — kept faint so the
	-- colored wedges read as a solid disc rather than a gold sunburst — plus
	-- the number printed on each pocket.
	for i, number in RouletteConfig.WheelOrder do
		create("Frame", {
			Name = "Divider" .. i,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 1, 0, WHEEL_RADIUS),
			Rotation = (i - 1.5) * segmentAngle,
			BackgroundColor3 = TRIM_COLOR,
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = spinner,
		})

		local labelPivot = create("Frame", {
			Name = "NumberPivot" .. i,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, 40, 0, WHEEL_RADIUS - 32),
			Rotation = (i - 1) * segmentAngle,
			BackgroundTransparency = 1,
			ZIndex = 2,
			Parent = spinner,
		})
		-- Cancel out the pivot's own rotation so every number renders upright
		-- and horizontal, regardless of where it sits around the wheel —
		-- rotating it to match the pivot (as a real wheel's paint would)
		-- reads as illegible/upside-down for anything past the very top.
		create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 6),
			Size = UDim2.new(1, 0, 0, 34),
			Rotation = -((i - 1) * segmentAngle),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = tostring(number),
			TextColor3 = TEXT_COLOR,
			TextScaled = true,
			Parent = labelPivot,
		})
	end

	local hub = create("Frame", {
		Name = "Hub",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 100, 0, 100),
		BackgroundColor3 = TRIM_COLOR,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = spinner,
	})
	addCorner(hub, 50)

	-- The ball: offset from a pivot at the wheel's center, riding near the
	-- outer rim. Rotating BallPivot (client-side, on spin) swings the ball
	-- around the fixed wheel and lands it on the winning pocket.
	local ballPivot = create("Frame", {
		Name = "BallPivot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = wheelFrame,
	})

	local ball = create("Frame", {
		Name = "Ball",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -330),
		Size = UDim2.new(0, 34, 0, 34),
		BackgroundColor3 = Color3.fromRGB(248, 248, 252),
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = ballPivot,
	})
	addCorner(ball, 17)
	addStroke(ball, Color3.new(0, 0, 0), 0.7)

	create("TextLabel", {
		Name = "Pointer",
		LayoutOrder = 0,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -2),
		Size = UDim2.new(0, 54, 0, 54),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "▼",
		TextColor3 = TRIM_COLOR,
		TextScaled = true,
		ZIndex = 5,
		Parent = wheelFrame,
	})

	create("TextLabel", {
		Name = "WinningNumberLabel",
		LayoutOrder = 3,
		Size = UDim2.new(0, 900, 0, 90),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "—",
		TextColor3 = TEXT_COLOR,
		TextScaled = true,
		Parent = panel,
	})

	create("TextLabel", {
		Name = "StatusLabel",
		LayoutOrder = 4,
		Size = UDim2.new(0, 900, 0, 40),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = "En attente...",
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

local function buildWheelAt(markerCFrame)
	local model = Instance.new("Model")
	model.Name = "RouletteWheel"

	local pole = create("Part", {
		Name = "Pole",
		Size = Vector3.new(1.4, POLE_HEIGHT, 1.4),
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.SmoothPlastic,
		Color = BODY_COLOR,
		CFrame = markerCFrame * CFrame.new(0, POLE_HEIGHT / 2, 0),
		Parent = model,
	})

	local signCFrame = markerCFrame * CFrame.new(0, POLE_HEIGHT + SIGN_SIZE.Y / 2, 0)

	local trim = create("Part", {
		Name = "Trim",
		Size = Vector3.new(SIGN_SIZE.X + 0.3, SIGN_SIZE.Y + 0.3, 0.3),
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = TRIM_COLOR,
		CFrame = signCFrame * CFrame.new(0, 0, SIGN_SIZE.Z / 2 + 0.1),
		Parent = model,
	})
	create("PointLight", {
		Color = TRIM_COLOR,
		Range = 20,
		Brightness = 2.5,
		Parent = trim,
	})

	local sign = create("Part", {
		Name = "Sign",
		Size = SIGN_SIZE,
		Anchored = true,
		CanCollide = true,
		Material = Enum.Material.SmoothPlastic,
		Color = BODY_COLOR,
		CFrame = signCFrame,
		Parent = model,
	})

	local screen = create("Part", {
		Name = "Screen",
		Size = Vector3.new(SIGN_SIZE.X - 0.5, SIGN_SIZE.Y - 0.5, 0.1),
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.SmoothPlastic,
		Color = SCREEN_COLOR,
		CFrame = signCFrame * CFrame.new(0, 0, -SIGN_SIZE.Z / 2 - 0.06),
		Parent = model,
	})

	buildScreenPanel(screen)

	model.PrimaryPart = pole
	model.Parent = Workspace
end

local function onMarkerFound(marker)
	local cframe = getMarkerCFrame(marker)
	if not cframe then
		return
	end

	marker:Destroy()
	buildWheelAt(cframe)
end

-- PrimaryPart is Pole, whose own CFrame is offset up from the marker by
-- half its height, hence POLE_HEIGHT / 2 here (not 0).
UIBuilder.rebuildExistingBoards("RouletteWheel", POLE_HEIGHT / 2, buildWheelAt)

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
