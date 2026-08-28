local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyManager = require(ServerScriptService.Economy.EconomyManager)
local SlotMachineConfig = require(ReplicatedStorage.Shared.SlotMachineConfig)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local SpinSlotMachine = RemoteEvents:WaitForChild("SpinSlotMachine")
local SlotMachineResult = RemoteEvents:WaitForChild("SlotMachineResult")

local totalWeight = 0
for _, symbol in SlotMachineConfig.Symbols do
	totalWeight += symbol.Weight
end

local random = Random.new()

local function rollSymbol()
	local roll = random:NextNumber() * totalWeight
	local cumulative = 0

	for _, symbol in SlotMachineConfig.Symbols do
		cumulative += symbol.Weight
		if roll <= cumulative then
			return symbol
		end
	end

	return SlotMachineConfig.Symbols[#SlotMachineConfig.Symbols]
end

-- 3 matching reels pay the symbol's full multiplier; 2 matching reels pay a
-- reduced multiplier; anything else pays nothing.
local function spin(bet)
	local reels = table.create(SlotMachineConfig.ReelCount)
	for i = 1, SlotMachineConfig.ReelCount do
		reels[i] = rollSymbol()
	end

	local counts = {}
	for _, symbol in reels do
		counts[symbol.Name] = (counts[symbol.Name] or 0) + 1
	end

	local bestSymbol, bestCount = reels[1], 0
	for _, symbol in reels do
		local count = counts[symbol.Name]
		if count > bestCount then
			bestSymbol, bestCount = symbol, count
		end
	end

	local payout = 0
	local matchType = "none"

	if bestCount >= SlotMachineConfig.ReelCount then
		payout = bet * bestSymbol.Payout
		matchType = "triple"
	elseif bestCount == 2 then
		matchType = "double"
		if not bestSymbol.DoubleMatchExcluded then
			payout = math.max(1, math.floor(bet * bestSymbol.Payout * SlotMachineConfig.TwoMatchMultiplier))
		end
	end

	local symbolNames = table.create(#reels)
	for i, symbol in reels do
		symbolNames[i] = symbol.Name
	end

	return symbolNames, payout, matchType
end

local function onSpinRequested(player, bet)
	if typeof(bet) ~= "number" or bet ~= bet or bet < SlotMachineConfig.MinBet or bet > SlotMachineConfig.MaxBet then
		SlotMachineResult:FireClient(player, { success = false, error = "invalid_bet" })
		return
	end

	bet = math.floor(bet)

	if not EconomyManager.TrySpend(player, bet) then
		SlotMachineResult:FireClient(player, { success = false, error = "insufficient_balance" })
		return
	end

	local symbols, payout, matchType = spin(bet)

	if payout > 0 then
		EconomyManager.AddChips(player, payout)
	end

	SlotMachineResult:FireClient(player, {
		success = true,
		symbols = symbols,
		bet = bet,
		payout = payout,
		matchType = matchType,
		balance = EconomyManager.GetBalance(player),
	})
end

SpinSlotMachine.OnServerEvent:Connect(onSpinRequested)
