local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SlotMachineClient = require(script.Parent.SlotMachineClient)
local SlotMachineConfig = require(ReplicatedStorage.Shared.SlotMachineConfig)
local SlotMachineSounds = require(ReplicatedStorage.Shared.SlotMachineSounds)

local player = Players.LocalPlayer

local GREEN = Color3.fromRGB(63, 217, 160)
local RED = Color3.fromRGB(255, 93, 108)
local MUTED = Color3.fromRGB(139, 147, 167)

local MIDDLE_ROW = math.ceil(SlotMachineConfig.GridRows / 2)

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

local function randomIcon()
	return SYMBOL_ICONS[allSymbolNames[math.random(1, #allSymbolNames)]]
end

local leaderstats = player:WaitForChild("leaderstats")
local chips = leaderstats:WaitForChild("Chips")

local function loadSounds(screenPart)
	local sounds = {}
	for name, soundId in SlotMachineSounds do
		sounds[name] = Instance.new("Sound")
		sounds[name].Name = name
		sounds[name].SoundId = soundId
		sounds[name].Parent = screenPart
	end

	return function(name)
		local sound = sounds[name]
		if sound and sound.SoundId ~= "" and sound.SoundId ~= "rbxassetid://0" then
			sound:Play()
		end
	end
end

local function showFloatingWin(screenPart, amount)
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CFrame = screenPart.CFrame * CFrame.new(0, 2.2, 0)
	anchor.Parent = screenPart

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 160, 0, 50)
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
	local playSound = loadSounds(screen)

	local reelsFrame = panel:WaitForChild("Reels")
	local columns = {}
	for col = 1, SlotMachineConfig.ReelCount do
		local column = reelsFrame:WaitForChild("Column" .. col)
		local rows = {}
		for row = 1, SlotMachineConfig.GridRows do
			table.insert(rows, column:WaitForChild("Row" .. row):WaitForChild("Symbol"))
		end
		table.insert(columns, rows)
	end

	local balanceLabel = panel:WaitForChild("Balance")
	local betRow = panel:WaitForChild("BetRow")
	local minBetButton = betRow:WaitForChild("MinBet")
	local minusButton = betRow:WaitForChild("Minus")
	local betLabel = betRow:WaitForChild("BetLabel")
	local plusButton = betRow:WaitForChild("Plus")
	local maxBetButton = betRow:WaitForChild("MaxBet")
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

	minBetButton.MouseButton1Click:Connect(function()
		playSound("ButtonClick")
		currentBet = SlotMachineConfig.MinBet
		refreshBetLabel()
	end)

	minusButton.MouseButton1Click:Connect(function()
		playSound("ButtonClick")
		currentBet = math.max(SlotMachineConfig.MinBet, currentBet - SlotMachineConfig.BetStep)
		refreshBetLabel()
	end)

	plusButton.MouseButton1Click:Connect(function()
		playSound("ButtonClick")
		currentBet = math.min(SlotMachineConfig.MaxBet, currentBet + SlotMachineConfig.BetStep)
		refreshBetLabel()
	end)

	maxBetButton.MouseButton1Click:Connect(function()
		playSound("ButtonClick")
		currentBet = SlotMachineConfig.MaxBet
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
		playSound("ButtonClick")

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
			for _, rows in columns do
				for _, symbolLabel in rows do
					symbolLabel.Text = randomIcon()
				end
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
			for col, rows in columns do
				for row, symbolLabel in rows do
					if row == MIDDLE_ROW then
						symbolLabel.Text = SYMBOL_ICONS[result.symbols[col]] or "❓"
					else
						symbolLabel.Text = randomIcon()
					end
				end
				task.wait(0.15)
			end

			if result.payout > 0 then
				resultLabel.Text = ("Gagné ! +%d Chips"):format(result.payout)
				resultLabel.TextColor3 = GREEN
				showFloatingWin(screen, result.payout)

				if result.matchType == "triple" and result.symbols[1] == "Diamond" then
					playSound("Jackpot")
				else
					playSound("Win")
				end
			else
				resultLabel.Text = "Perdu, retente ta chance !"
				resultLabel.TextColor3 = RED
				playSound("Lose")
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
