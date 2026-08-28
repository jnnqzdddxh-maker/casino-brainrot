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

-- All reels must land on the same symbol to win; payout = bet * that symbol's multiplier.
local function spin(bet)
	local reels = table.create(SlotMachineConfig.ReelCount)
	for i = 1, SlotMachineConfig.ReelCount do
		reels[i] = rollSymbol()
	end

	local allMatch = true
	for i = 2, #reels do
		if reels[i].Name ~= reels[1].Name then
			allMatch = false
			break
		end
	end

	local payout = allMatch and (bet * reels[1].Payout) or 0

	local symbolNames = table.create(#reels)
	for i, symbol in reels do
		symbolNames[i] = symbol.Name
	end

	return symbolNames, payout
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

	local symbols, payout = spin(bet)

	if payout > 0 then
		EconomyManager.AddChips(player, payout)
	end

	SlotMachineResult:FireClient(player, {
		success = true,
		symbols = symbols,
		bet = bet,
		payout = payout,
		balance = EconomyManager.GetBalance(player),
	})
end

SpinSlotMachine.OnServerEvent:Connect(onSpinRequested)
