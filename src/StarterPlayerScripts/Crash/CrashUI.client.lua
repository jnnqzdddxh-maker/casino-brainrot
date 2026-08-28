local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CrashConfig = require(ReplicatedStorage.Shared.CrashConfig)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CrashPlaceBet = RemoteEvents:WaitForChild("CrashPlaceBet")
local CrashCashOut = RemoteEvents:WaitForChild("CrashCashOut")
local CrashRoundUpdate = RemoteEvents:WaitForChild("CrashRoundUpdate")
local CrashBetResult = RemoteEvents:WaitForChild("CrashBetResult")

local GREEN = Color3.fromRGB(63, 217, 160)
local RED = Color3.fromRGB(255, 93, 108)
local GOLD = Color3.fromRGB(242, 179, 61)
local MUTED = Color3.fromRGB(139, 147, 167)
local TEXT = Color3.fromRGB(233, 236, 244)

local ERROR_MESSAGES = {
	invalid_bet = "Mise invalide.",
	insufficient_balance = "Solde insuffisant.",
	already_bet = "Mise déjà placée pour cette manche.",
	round_in_progress = "Attends le prochain tour.",
}

-- One shared round for the whole server: every board mirrors the same state.
local latestUpdate = { phase = "waiting", timeRemaining = CrashConfig.WaitingDuration, multiplier = 1, history = {} }
local hasActiveBet = false
local lastBetAmount = 0

CrashRoundUpdate.OnClientEvent:Connect(function(data)
	latestUpdate = data
	if data.phase == "waiting" then
		hasActiveBet = false
	end
end)

CrashBetResult.OnClientEvent:Connect(function(result)
	if result.success and result.placed then
		hasActiveBet = true
	elseif result.success and result.cashedOut then
		hasActiveBet = false
	end
end)

local function refreshHistory(historyRow)
	for _, child in historyRow:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	for _, crashValue in latestUpdate.history or {} do
		local chip = Instance.new("TextLabel")
		chip.Size = UDim2.new(0, 90, 0, 40)
		chip.BackgroundColor3 = Color3.fromRGB(26, 32, 50)
		chip.BorderSizePixel = 0
		chip.Font = Enum.Font.GothamBold
		chip.Text = string.format("%.2fx", crashValue)
		chip.TextColor3 = crashValue >= 2 and GREEN or RED
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

	local multiplierLabel = panel:WaitForChild("MultiplierLabel")
	local statusLabel = panel:WaitForChild("StatusLabel")
	local historyRow = panel:WaitForChild("HistoryRow")
	local betRow = panel:WaitForChild("BetRow")
	local minBetButton = betRow:WaitForChild("MinBet")
	local minusButton = betRow:WaitForChild("Minus")
	local betLabel = betRow:WaitForChild("BetLabel")
	local plusButton = betRow:WaitForChild("Plus")
	local maxBetButton = betRow:WaitForChild("MaxBet")
	local actionButton = panel:WaitForChild("ActionButton")
	local resultLabel = panel:WaitForChild("Result")

	local currentBet = CrashConfig.MinBet
	local function refreshBetLabel()
		betLabel.Text = "Mise : " .. currentBet
	end
	refreshBetLabel()

	minBetButton.MouseButton1Click:Connect(function()
		currentBet = CrashConfig.MinBet
		refreshBetLabel()
	end)

	minusButton.MouseButton1Click:Connect(function()
		currentBet = math.max(CrashConfig.MinBet, currentBet - CrashConfig.BetStep)
		refreshBetLabel()
	end)

	plusButton.MouseButton1Click:Connect(function()
		currentBet = math.min(CrashConfig.MaxBet, currentBet + CrashConfig.BetStep)
		refreshBetLabel()
	end)

	maxBetButton.MouseButton1Click:Connect(function()
		currentBet = CrashConfig.MaxBet
		refreshBetLabel()
	end)

	actionButton.MouseButton1Click:Connect(function()
		if latestUpdate.phase == "waiting" and not hasActiveBet then
			lastBetAmount = currentBet
			CrashPlaceBet:FireServer(currentBet)
		elseif latestUpdate.phase == "running" and hasActiveBet then
			CrashCashOut:FireServer()
		end
	end)

	CrashBetResult.OnClientEvent:Connect(function(result)
		if not result.success then
			resultLabel.Text = ERROR_MESSAGES[result.error] or "Erreur."
			resultLabel.TextColor3 = RED
		elseif result.cashedOut then
			resultLabel.Text = ("Encaissé à %.2fx : +%d Chips"):format(result.multiplier, result.payout)
			resultLabel.TextColor3 = GREEN
		elseif result.placed then
			resultLabel.Text = ("Mise de %d placée !"):format(result.amount)
			resultLabel.TextColor3 = GOLD
		end
	end)

	task.spawn(function()
		while boardModel.Parent do
			local phase = latestUpdate.phase

			if phase == "waiting" then
				multiplierLabel.Text = "1.00x"
				multiplierLabel.TextColor3 = TEXT
				statusLabel.Text = ("Place tes mises... %ds"):format(math.ceil(latestUpdate.timeRemaining or 0))
				statusLabel.TextColor3 = MUTED
				actionButton.Text = hasActiveBet and "MISE PLACÉE" or "MISER"
				actionButton.Active = not hasActiveBet
				refreshHistory(historyRow)
			elseif phase == "running" then
				local multiplier = latestUpdate.multiplier or 1
				multiplierLabel.Text = string.format("%.2fx", multiplier)
				multiplierLabel.TextColor3 = multiplier < 2 and GREEN or GOLD
				statusLabel.Text = "En vol..."
				statusLabel.TextColor3 = MUTED
				if hasActiveBet then
					actionButton.Text = ("CASH OUT (+%d)"):format(math.floor(lastBetAmount * multiplier))
					actionButton.Active = true
				else
					actionButton.Text = "EN COURS"
					actionButton.Active = false
				end
			elseif phase == "crashed" then
				multiplierLabel.Text = string.format("%.2fx", latestUpdate.multiplier or 1)
				multiplierLabel.TextColor3 = RED
				statusLabel.Text = "💥 CRASHED"
				statusLabel.TextColor3 = RED
				actionButton.Text = "..."
				actionButton.Active = false
			end

			task.wait(0.1)
		end
	end)
end

for _, descendant in Workspace:GetDescendants() do
	if descendant.Name == "CrashBoard" then
		task.spawn(setupBoard, descendant)
	end
end

Workspace.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "CrashBoard" then
		task.spawn(setupBoard, descendant)
	end
end)
