local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SlotMachineClient = require(script.Parent.SlotMachineClient)
local SlotMachineConfig = require(ReplicatedStorage.Shared.SlotMachineConfig)

local player = Players.LocalPlayer

local GREEN = Color3.fromRGB(63, 217, 160)
local RED = Color3.fromRGB(255, 93, 108)
local MUTED = Color3.fromRGB(139, 147, 167)

local SYMBOL_ICONS = {
	Cherry = "🍒",
	Lemon = "🍋",
	Bell = "🔔",
	Star = "⭐",
	Diamond = "💎",
}

local ERROR_MESSAGES = {
	invalid_bet = "Mise invalide.",
	insufficient_balance = "Solde insuffisant.",
}

local allSymbolNames = {}
for _, symbol in SlotMachineConfig.Symbols do
	table.insert(allSymbolNames, symbol.Name)
end

local leaderstats = player:WaitForChild("leaderstats")
local chips = leaderstats:WaitForChild("Chips")

local function showFloatingWin(screenPart, amount)
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CFrame = screenPart.CFrame * CFrame.new(0, 1.8, 0)
	anchor.Parent = screenPart

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 140, 0, 44)
	billboard.AlwaysOnTop = true
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = "+" .. amount
	label.TextColor3 = GREEN
	label.TextScaled = true
	label.Parent = billboard

	local rise = TweenService:Create(anchor, TweenInfo.new(1.2, Enum.EasingStyle.Quad), {
		CFrame = anchor.CFrame * CFrame.new(0, 2, 0),
	})
	local fade = TweenService:Create(label, TweenInfo.new(1.2), { TextTransparency = 1 })

	rise:Play()
	fade:Play()
	rise.Completed:Connect(function()
		anchor:Destroy()
	end)
end

local function setupCabinet(cabinetModel)
	local screen = cabinetModel:WaitForChild("Screen")
	local gui = screen:WaitForChild("ScreenGui")
	local panel = gui:WaitForChild("Panel")

	local reelsFrame = panel:WaitForChild("Reels")
	local reelLabels = {}
	for i = 1, SlotMachineConfig.ReelCount do
		table.insert(reelLabels, reelsFrame:WaitForChild("Reel" .. i):WaitForChild("Symbol"))
	end

	local balanceLabel = panel:WaitForChild("Balance")
	local betRow = panel:WaitForChild("BetRow")
	local minusButton = betRow:WaitForChild("Minus")
	local betLabel = betRow:WaitForChild("BetLabel")
	local plusButton = betRow:WaitForChild("Plus")
	local spinButton = panel:WaitForChild("SpinButton")
	local resultLabel = panel:WaitForChild("Result")

	local function refreshBalanceLabel()
		balanceLabel.Text = ("Solde : %d Chips"):format(chips.Value)
	end
	refreshBalanceLabel()
	chips:GetPropertyChangedSignal("Value"):Connect(refreshBalanceLabel)

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

	local spinning = false
	local pendingResult = nil
	local waitingForThisCabinet = false

	SlotMachineClient.OnResult(function(result)
		if waitingForThisCabinet then
			pendingResult = result
		end
	end)

	spinButton.MouseButton1Click:Connect(function()
		if spinning then
			return
		end
		spinning = true
		waitingForThisCabinet = true
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
		waitingForThisCabinet = false

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
				showFloatingWin(screen, result.payout)
			else
				resultLabel.Text = "Perdu, retente ta chance !"
				resultLabel.TextColor3 = RED
			end
		end

		spinButton.Text = "SPIN"
		spinButton.Active = true
		spinning = false
	end)
end

for _, descendant in Workspace:GetDescendants() do
	if descendant.Name == "SlotMachineCabinet" then
		task.spawn(setupCabinet, descendant)
	end
end

Workspace.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "SlotMachineCabinet" then
		task.spawn(setupCabinet, descendant)
	end
end)
