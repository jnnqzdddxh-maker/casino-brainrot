local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
local previousPhase = "waiting"

CrashRoundUpdate.OnClientEvent:Connect(function(data)
	-- Only clear the active-bet flag when a *new* round's waiting phase
	-- begins (crashed/running -> waiting), not on every waiting broadcast —
	-- otherwise a bet placed mid-waiting-phase gets forgotten by the time
	-- the round actually starts, and Cash Out never shows up.
	if data.phase == "waiting" and previousPhase ~= "waiting" then
		hasActiveBet = false
	end
	previousPhase = data.phase
	latestUpdate = data
end)

CrashBetResult.OnClientEvent:Connect(function(result)
	if result.success and result.placed then
		hasActiveBet = true
	elseif result.success and result.cashedOut then
		hasActiveBet = false
	end
end)

-- Graph: the curve is drawn as short rotated line segments connecting each
-- new point to the previous one, with the rocket riding the leading edge.
local GRAPH_MARGIN = 20
local GRAPH_MAX_TIME = 15 -- seconds of flight to reach the graph's right edge
local GRAPH_MAX_MULTIPLIER = 10 -- multiplier (log scale) to reach the top edge

local function computeGraphPoint(elapsed, multiplier, graphWidth, graphHeight)
	local xFraction = math.clamp(elapsed / GRAPH_MAX_TIME, 0, 1)
	local yFraction = math.clamp(math.log(multiplier) / math.log(GRAPH_MAX_MULTIPLIER), 0, 1)

	local x = GRAPH_MARGIN + xFraction * (graphWidth - GRAPH_MARGIN * 2)
	local y = (graphHeight - GRAPH_MARGIN) - yFraction * (graphHeight - GRAPH_MARGIN * 2)

	return Vector2.new(x, y)
end

local function drawSegment(container, p1, p2, color)
	local diff = p2 - p1
	local length = diff.Magnitude
	if length < 0.5 then
		return
	end

	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Position = UDim2.new(0, p1.X, 0, p1.Y)
	line.Size = UDim2.new(0, length, 0, 4)
	line.Rotation = math.deg(math.atan2(diff.Y, diff.X))
	line.BackgroundColor3 = color
	line.BorderSizePixel = 0
	line.Parent = container
end

local function spawnExplosion(container, point)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(0, point.X, 0, point.Y)
	label.Size = UDim2.new(0, 60, 0, 60)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSansBold
	label.Text = "💥"
	label.TextScaled = true
	label.Parent = container

	local tween = TweenService:Create(label, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 140, 0, 140),
		TextTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		label:Destroy()
	end)
end

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

	local graphArea = panel:WaitForChild("GraphArea")
	local curveContainer = graphArea:WaitForChild("CurveContainer")
	local rocketLabel = graphArea:WaitForChild("RocketLabel")
	local multiplierLabel = graphArea:WaitForChild("MultiplierLabel")
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

	local graphWidth = graphArea.Size.X.Offset
	local graphHeight = graphArea.Size.Y.Offset
	local startPoint = Vector2.new(GRAPH_MARGIN, graphHeight - GRAPH_MARGIN)
	local lastPoint = nil
	local explosionShown = false

	local function resetGraph()
		for _, child in curveContainer:GetChildren() do
			child:Destroy()
		end
		lastPoint = nil
		explosionShown = false
		rocketLabel.Position = UDim2.new(0, startPoint.X, 0, startPoint.Y)
	end

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
				resetGraph()
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

				local elapsed = math.log(math.max(multiplier, 1.0001)) / CrashConfig.GrowthRate
				local point = computeGraphPoint(elapsed, multiplier, graphWidth, graphHeight)
				if lastPoint then
					drawSegment(curveContainer, lastPoint, point, multiplier < 2 and GREEN or GOLD)
				end
				lastPoint = point
				rocketLabel.Position = UDim2.new(0, point.X, 0, point.Y)
			elseif phase == "crashed" then
				multiplierLabel.Text = string.format("%.2fx", latestUpdate.multiplier or 1)
				multiplierLabel.TextColor3 = RED
				statusLabel.Text = "💥 CRASHED"
				statusLabel.TextColor3 = RED
				actionButton.Text = "..."
				actionButton.Active = false

				if not explosionShown then
					explosionShown = true
					spawnExplosion(curveContainer, lastPoint or startPoint)
				end
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
