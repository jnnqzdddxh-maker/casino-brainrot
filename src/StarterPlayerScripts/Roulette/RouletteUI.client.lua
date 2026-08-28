local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RouletteConfig = require(ReplicatedStorage.Shared.RouletteConfig)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RoulettePlaceBet = RemoteEvents:WaitForChild("RoulettePlaceBet")
local RouletteRoundUpdate = RemoteEvents:WaitForChild("RouletteRoundUpdate")
local RouletteBetResult = RemoteEvents:WaitForChild("RouletteBetResult")

local GREEN = Color3.fromRGB(63, 217, 160)
local RED = Color3.fromRGB(255, 93, 108)
local GOLD = Color3.fromRGB(242, 179, 61)
local MUTED = Color3.fromRGB(139, 147, 167)
local TEXT = Color3.fromRGB(233, 236, 244)
local BLACK_CHIP = Color3.fromRGB(60, 60, 66)

local ERROR_MESSAGES = {
	invalid_bet = "Mise invalide.",
	insufficient_balance = "Solde insuffisant.",
	round_in_progress = "Attends le prochain tour.",
}

-- One shared round for the whole server: every board mirrors the same
-- state. A player can place several bets per round (real roulette rules),
-- so there's no single "active bet" flag to track anymore.
local latestUpdate = { phase = "waiting", timeRemaining = RouletteConfig.WaitingDuration, history = {} }

RouletteRoundUpdate.OnClientEvent:Connect(function(data)
	latestUpdate = data
end)

local function refreshHistory(historyRow)
	for _, child in historyRow:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	for _, entry in latestUpdate.history or {} do
		local chip = Instance.new("TextLabel")
		chip.Size = UDim2.new(0, 50, 0, 40)
		chip.BackgroundColor3 = entry.color == "red" and RED or entry.color == "green" and GREEN or BLACK_CHIP
		chip.BorderSizePixel = 0
		chip.Font = Enum.Font.GothamBold
		chip.Text = tostring(entry.number)
		chip.TextColor3 = TEXT
		chip.TextScaled = true
		chip.Parent = historyRow

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = chip
	end
end

local function setupBoard(boardModel)
	local screen = boardModel:WaitForChild("Screen")
	local gui = screen:WaitForChild("ScreenGui")
	local panel = gui:WaitForChild("Panel")

	local statusLabel = panel:WaitForChild("StatusLabel")
	local numbersRow = panel:WaitForChild("NumbersRow")
	local numberGrid = numbersRow:WaitForChild("NumberGrid")
	local zeroButton = numbersRow:WaitForChild("Num0")
	local outsideRow = panel:WaitForChild("OutsideBetsRow")
	local betRow = panel:WaitForChild("BetRow")
	local quickRow = betRow:WaitForChild("QuickRow")
	local stepRow = betRow:WaitForChild("StepRow")
	local minBetButton = quickRow:WaitForChild("MinBet")
	local quarterButton = quickRow:WaitForChild("Quarter")
	local halfButton = quickRow:WaitForChild("Half")
	local threeQuarterButton = quickRow:WaitForChild("ThreeQuarter")
	local maxBetButton = quickRow:WaitForChild("MaxBet")
	local minusButton = stepRow:WaitForChild("Minus")
	local betLabel = stepRow:WaitForChild("BetLabel")
	local plusButton = stepRow:WaitForChild("Plus")
	local historyRow = panel:WaitForChild("HistoryRow")
	local resultLabel = panel:WaitForChild("Result")

	local currentBet = RouletteConfig.MinBet
	local function refreshBetLabel()
		betLabel.Text = "Mise : " .. currentBet
	end
	refreshBetLabel()

	local function setBetFraction(fraction)
		local raw = RouletteConfig.MaxBet * fraction
		local stepped = math.floor(raw / RouletteConfig.BetStep + 0.5) * RouletteConfig.BetStep
		currentBet = math.clamp(stepped, RouletteConfig.MinBet, RouletteConfig.MaxBet)
		refreshBetLabel()
	end

	minBetButton.MouseButton1Click:Connect(function()
		currentBet = RouletteConfig.MinBet
		refreshBetLabel()
	end)
	quarterButton.MouseButton1Click:Connect(function()
		setBetFraction(0.25)
	end)
	halfButton.MouseButton1Click:Connect(function()
		setBetFraction(0.5)
	end)
	threeQuarterButton.MouseButton1Click:Connect(function()
		setBetFraction(0.75)
	end)
	minusButton.MouseButton1Click:Connect(function()
		currentBet = math.max(RouletteConfig.MinBet, currentBet - RouletteConfig.BetStep)
		refreshBetLabel()
	end)
	plusButton.MouseButton1Click:Connect(function()
		currentBet = math.min(RouletteConfig.MaxBet, currentBet + RouletteConfig.BetStep)
		refreshBetLabel()
	end)
	maxBetButton.MouseButton1Click:Connect(function()
		currentBet = RouletteConfig.MaxBet
		refreshBetLabel()
	end)

	-- Betting: clicking a number or an outside-bet button immediately places
	-- that bet at the current stepper amount. Several bets can be active at
	-- once (real roulette rules) — pendingButtons is a FIFO queue matched up
	-- against RouletteBetResult replies, which Roblox delivers in the order
	-- they were fired, so the Nth reply always corresponds to the Nth click.
	local pendingButtons = {}
	local highlightedButtons = {}

	local function clearHighlights()
		for _, button in highlightedButtons do
			local stroke = button:FindFirstChild("SelectedStroke")
			if stroke then
				stroke:Destroy()
			end
		end
		highlightedButtons = {}
	end

	local function placeBet(spec, buttonInstance)
		if latestUpdate.phase ~= "waiting" then
			return
		end
		table.insert(pendingButtons, buttonInstance)
		RoulettePlaceBet:FireServer(spec, currentBet)
	end

	local function registerBetButton(instance, spec)
		instance.MouseButton1Click:Connect(function()
			placeBet(spec, instance)
		end)
	end

	registerBetButton(zeroButton, { type = "straight", value = 0 })
	for number = 1, 36 do
		registerBetButton(numberGrid:WaitForChild("Num" .. number), { type = "straight", value = number })
	end
	registerBetButton(outsideRow:WaitForChild("Red"), { type = "color", value = "red" })
	registerBetButton(outsideRow:WaitForChild("Black"), { type = "color", value = "black" })
	registerBetButton(outsideRow:WaitForChild("Even"), { type = "parity", value = "even" })
	registerBetButton(outsideRow:WaitForChild("Odd"), { type = "parity", value = "odd" })
	registerBetButton(outsideRow:WaitForChild("Low"), { type = "range", value = "low" })
	registerBetButton(outsideRow:WaitForChild("High"), { type = "range", value = "high" })

	RouletteBetResult.OnClientEvent:Connect(function(result)
		if not result.success then
			resultLabel.Text = ERROR_MESSAGES[result.error] or "Erreur."
			resultLabel.TextColor3 = RED
			table.remove(pendingButtons, 1)
		elseif result.placed then
			local button = table.remove(pendingButtons, 1)
			if button and not button:FindFirstChild("SelectedStroke") then
				local stroke = Instance.new("UIStroke")
				stroke.Name = "SelectedStroke"
				stroke.Color = GOLD
				stroke.Thickness = 4
				stroke.Parent = button
				table.insert(highlightedButtons, button)
			end
			resultLabel.Text = ("Mise de %d placée !"):format(result.amount)
			resultLabel.TextColor3 = GOLD
		elseif result.resolved then
			if result.payout > 0 then
				resultLabel.Text = ("Gagné ! +%d Chips (numéro %d)"):format(result.payout, result.winningNumber)
				resultLabel.TextColor3 = GREEN
			else
				resultLabel.Text = ("Perdu — le numéro était %d"):format(result.winningNumber)
				resultLabel.TextColor3 = RED
			end
		end
	end)

	-- The wheel animation itself lives on the separate RouletteWheel sign
	-- (see RouletteWheelUI.client.lua) — this mat only needs to reflect
	-- phase/countdown and the betting UI.
	task.spawn(function()
		while boardModel.Parent do
			local phase = latestUpdate.phase

			if phase == "waiting" then
				statusLabel.Text = ("Placez vos mises... %ds"):format(math.ceil(latestUpdate.timeRemaining or 0))
				statusLabel.TextColor3 = MUTED
				clearHighlights()
				refreshHistory(historyRow)
			elseif phase == "spinning" then
				statusLabel.Text = "La roue tourne..."
				statusLabel.TextColor3 = MUTED
			elseif phase == "result" then
				statusLabel.Text = ("Résultat : %d"):format(latestUpdate.winningNumber)
				statusLabel.TextColor3 = MUTED
			end

			task.wait(0.1)
		end
	end)
end

for _, descendant in Workspace:GetDescendants() do
	if descendant.Name == "RouletteBoard" then
		task.spawn(setupBoard, descendant)
	end
end

Workspace.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "RouletteBoard" then
		task.spawn(setupBoard, descendant)
	end
end)
