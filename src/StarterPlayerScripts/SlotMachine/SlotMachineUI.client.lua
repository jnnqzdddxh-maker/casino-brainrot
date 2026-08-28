local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SlotMachineClient = require(script.Parent.SlotMachineClient)
local SlotMachineConfig = require(ReplicatedStorage.Shared.SlotMachineConfig)

local player = Players.LocalPlayer

-- Casino Brainrot palette (matches the project's branding).
local BG = Color3.fromRGB(11, 14, 20)
local SURFACE = Color3.fromRGB(19, 24, 38)
local SURFACE_2 = Color3.fromRGB(26, 32, 50)
local GOLD = Color3.fromRGB(242, 179, 61)
local GREEN = Color3.fromRGB(63, 217, 160)
local RED = Color3.fromRGB(255, 93, 108)
local TEXT = Color3.fromRGB(233, 236, 244)
local MUTED = Color3.fromRGB(139, 147, 167)

local SYMBOL_ICONS = {
	Cherry = "🍒",
	Lemon = "🍋",
	Bell = "🔔",
	Star = "⭐",
	Diamond = "💎",
}

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
	create("UIStroke", {
		Color = color,
		Thickness = 1,
		Transparency = transparency or 0,
		Parent = parent,
	})
end

local screenGui = create("ScreenGui", {
	Name = "SlotMachineUI",
	ResetOnSpawn = false,
	Parent = player:WaitForChild("PlayerGui"),
})

local cabinet = create("Frame", {
	Name = "Cabinet",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 360, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = SURFACE,
	BorderSizePixel = 0,
	Parent = screenGui,
})
addCorner(cabinet, 18)
addStroke(cabinet, GOLD, 0.75)

create("UIPadding", {
	PaddingTop = UDim.new(0, 24),
	PaddingBottom = UDim.new(0, 24),
	PaddingLeft = UDim.new(0, 24),
	PaddingRight = UDim.new(0, 24),
	Parent = cabinet,
})

create("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 14),
	Parent = cabinet,
})

create("TextLabel", {
	Name = "Title",
	LayoutOrder = 1,
	Size = UDim2.new(0, 312, 0, 26),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "CASINO BRAINROT",
	TextColor3 = GOLD,
	TextSize = 22,
	Parent = cabinet,
})

create("TextLabel", {
	Name = "Subtitle",
	LayoutOrder = 2,
	Size = UDim2.new(0, 312, 0, 16),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "MACHINE À SOUS",
	TextColor3 = MUTED,
	TextSize = 12,
	Parent = cabinet,
})

local reelsFrame = create("Frame", {
	Name = "Reels",
	LayoutOrder = 3,
	Size = UDim2.new(0, 312, 0, 96),
	BackgroundTransparency = 1,
	Parent = cabinet,
})

create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 10),
	Parent = reelsFrame,
})

local reelLabels = {}
for i = 1, SlotMachineConfig.ReelCount do
	local reelSlot = create("Frame", {
		Name = "Reel" .. i,
		LayoutOrder = i,
		Size = UDim2.new(0, 96, 0, 96),
		BackgroundColor3 = SURFACE_2,
		BorderSizePixel = 0,
		Parent = reelsFrame,
	})
	addCorner(reelSlot, 12)
	addStroke(reelSlot, GOLD, 0.85)

	local reelLabel = create("TextLabel", {
		Name = "Symbol",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSansBold,
		Text = "🍒",
		TextScaled = true,
		Parent = reelSlot,
	})
	table.insert(reelLabels, reelLabel)
end

local balanceLabel = create("TextLabel", {
	Name = "Balance",
	LayoutOrder = 4,
	Size = UDim2.new(0, 312, 0, 22),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "Solde : — Chips",
	TextColor3 = TEXT,
	TextSize = 16,
	Parent = cabinet,
})

local betRow = create("Frame", {
	Name = "BetRow",
	LayoutOrder = 5,
	Size = UDim2.new(0, 232, 0, 44),
	BackgroundTransparency = 1,
	Parent = cabinet,
})

create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 12),
	Parent = betRow,
})

local function betButton(name, text, layoutOrder)
	local button = create("TextButton", {
		Name = name,
		LayoutOrder = layoutOrder,
		Size = UDim2.new(0, 44, 0, 44),
		BackgroundColor3 = SURFACE_2,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = GOLD,
		TextSize = 22,
		AutoButtonColor = true,
		Parent = betRow,
	})
	addCorner(button, 10)
	addStroke(button, GOLD, 0.8)
	return button
end

local minusButton = betButton("Minus", "-", 1)

local betLabel = create("TextLabel", {
	Name = "BetLabel",
	LayoutOrder = 2,
	Size = UDim2.new(0, 120, 0, 44),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "Mise : " .. SlotMachineConfig.MinBet,
	TextColor3 = TEXT,
	TextSize = 16,
	Parent = betRow,
})

local plusButton = betButton("Plus", "+", 3)

local spinButton = create("TextButton", {
	Name = "SpinButton",
	LayoutOrder = 6,
	Size = UDim2.new(0, 232, 0, 50),
	BackgroundColor3 = GOLD,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBlack,
	Text = "SPIN",
	TextColor3 = BG,
	TextSize = 18,
	AutoButtonColor = true,
	Parent = cabinet,
})
addCorner(spinButton, 12)

local resultLabel = create("TextLabel", {
	Name = "Result",
	LayoutOrder = 7,
	Size = UDim2.new(0, 312, 0, 22),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "",
	TextColor3 = MUTED,
	TextSize = 14,
	Parent = cabinet,
})

-- Balance display

local leaderstats = player:WaitForChild("leaderstats")
local chips = leaderstats:WaitForChild("Chips")

local function refreshBalanceLabel()
	balanceLabel.Text = ("Solde : %d Chips"):format(chips.Value)
end

refreshBalanceLabel()
chips:GetPropertyChangedSignal("Value"):Connect(refreshBalanceLabel)

-- Bet stepper

local currentBet = SlotMachineConfig.MinBet

local function refreshBetLabel()
	betLabel.Text = "Mise : " .. currentBet
end

minusButton.MouseButton1Click:Connect(function()
	currentBet = math.max(SlotMachineConfig.MinBet, currentBet - SlotMachineConfig.BetStep)
	refreshBetLabel()
end)

plusButton.MouseButton1Click:Connect(function()
	currentBet = math.min(SlotMachineConfig.MaxBet, currentBet + SlotMachineConfig.BetStep)
	refreshBetLabel()
end)

-- Spin flow: fire the request, cycle random symbols client-side purely for
-- show while we wait, then reveal the server's authoritative result.

local allSymbolNames = {}
for _, symbol in SlotMachineConfig.Symbols do
	table.insert(allSymbolNames, symbol.Name)
end

local spinning = false
local pendingResult = nil

SlotMachineClient.OnResult(function(result)
	pendingResult = result
end)

local ERROR_MESSAGES = {
	invalid_bet = "Mise invalide.",
	insufficient_balance = "Solde insuffisant.",
}

local function spinReels()
	spinning = true
	pendingResult = nil
	resultLabel.Text = ""
	resultLabel.TextColor3 = MUTED
	spinButton.Text = "..."
	spinButton.Active = false

	SlotMachineClient.Spin(currentBet)

	local elapsed = 0
	while not pendingResult and elapsed < 5 do
		for _, reelLabel in reelLabels do
			reelLabel.Text = SYMBOL_ICONS[allSymbolNames[math.random(1, #allSymbolNames)]]
		end
		task.wait(0.08)
		elapsed += 0.08
	end

	local result = pendingResult

	if not result then
		resultLabel.Text = "Le serveur ne répond pas, réessaie."
		resultLabel.TextColor3 = RED
	elseif not result.success then
		resultLabel.Text = ERROR_MESSAGES[result.error] or "Erreur."
		resultLabel.TextColor3 = RED
	else
		for i, reelLabel in reelLabels do
			reelLabel.Text = SYMBOL_ICONS[result.symbols[i]] or "❓"
			task.wait(0.15)
		end

		if result.payout > 0 then
			resultLabel.Text = ("Gagné ! +%d Chips"):format(result.payout)
			resultLabel.TextColor3 = GREEN
		else
			resultLabel.Text = "Perdu, retente ta chance !"
			resultLabel.TextColor3 = RED
		end
	end

	spinButton.Text = "SPIN"
	spinButton.Active = true
	spinning = false
end

spinButton.MouseButton1Click:Connect(function()
	if spinning then
		return
	end
	spinReels()
end)
