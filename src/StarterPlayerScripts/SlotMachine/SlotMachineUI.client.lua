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
local GOLD = Color3.fromRGB(242, 179, 61)

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

local function randomSymbolName()
	return allSymbolNames[math.random(1, #allSymbolNames)]
end

local leaderstats = player:WaitForChild("leaderstats")
local chips = leaderstats:WaitForChild("Chips")

-- Reel strip: a tall column of stacked symbol labels that slides upward
-- behind a clipped "window" frame, landing exactly on the target symbol in
-- the middle slot — the classic sliding slot-machine reel effect.
local CELL_SIZE = SlotMachineConfig.CellSize
local FILLER_COUNT = 10
local STRIP_LENGTH = FILLER_COUNT + 3 -- + top/middle/bottom final trio
local MIDDLE_INDEX = FILLER_COUNT + 1 -- 0-based index of the middle slot
local REST_OFFSET = -FILLER_COUNT * CELL_SIZE

local function buildStrip(window, middleSymbolName)
	local strip = Instance.new("Frame")
	strip.Name = "Strip"
	strip.Size = UDim2.new(1, 0, 0, STRIP_LENGTH * CELL_SIZE)
	strip.Position = UDim2.new(0, 0, 0, 0)
	strip.BackgroundTransparency = 1
	strip.Parent = window

	for i = 0, STRIP_LENGTH - 1 do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, CELL_SIZE)
		label.Position = UDim2.new(0, 0, 0, i * CELL_SIZE)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.SourceSansBold
		label.TextScaled = true
		label.Text = SYMBOL_ICONS[i == MIDDLE_INDEX and middleSymbolName or randomSymbolName()]
		label.Parent = strip
	end

	return strip
end

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
	local windows = {}
	local currentStrips = {}
	for col = 1, SlotMachineConfig.ReelCount do
		windows[col] = reelsFrame:WaitForChild("Window" .. col)
		currentStrips[col] = buildStrip(windows[col], randomSymbolName())
	end

	local balanceLabel = panel:WaitForChild("Balance")
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

	local function setBetFraction(fraction)
		local raw = SlotMachineConfig.MaxBet * fraction
		local stepped = math.floor(raw / SlotMachineConfig.BetStep + 0.5) * SlotMachineConfig.BetStep
		currentBet = math.clamp(stepped, SlotMachineConfig.MinBet, SlotMachineConfig.MaxBet)
		refreshBetLabel()
	end

	minBetButton.MouseButton1Click:Connect(function()
		playSound("ButtonClick")
		currentBet = SlotMachineConfig.MinBet
		refreshBetLabel()
	end)

	quarterButton.MouseButton1Click:Connect(function()
		playSound("ButtonClick")
		setBetFraction(0.25)
	end)

	halfButton.MouseButton1Click:Connect(function()
		playSound("ButtonClick")
		setBetFraction(0.5)
	end)

	threeQuarterButton.MouseButton1Click:Connect(function()
		playSound("ButtonClick")
		setBetFraction(0.75)
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
			task.wait(0.05)
			elapsed += 0.05
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
			local longestDuration = 0
			for col, window in windows do
				local oldStrip = currentStrips[col]
				local strip = buildStrip(window, result.symbols[col])
				currentStrips[col] = strip

				local duration = 0.9 + (col - 1) * 0.35
				longestDuration = math.max(longestDuration, duration)

				local tween = TweenService:Create(strip, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(0, 0, 0, REST_OFFSET),
				})
				tween.Completed:Connect(function()
					if oldStrip then
						oldStrip:Destroy()
					end
				end)
				tween:Play()
			end

			task.wait(longestDuration)

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
				local counts = {}
				for _, name in result.symbols do
					counts[name] = (counts[name] or 0) + 1
				end

				if counts.Diamond == 2 then
					resultLabel.Text = "Presque ! Un 💎 de plus pour le JACKPOT !"
					resultLabel.TextColor3 = GOLD
				else
					resultLabel.Text = "Perdu, retente ta chance !"
					resultLabel.TextColor3 = RED
				end
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
