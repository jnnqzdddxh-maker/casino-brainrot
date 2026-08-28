local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyManager = require(ServerScriptService.Economy.EconomyManager)
local CrashConfig = require(ReplicatedStorage.Shared.CrashConfig)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CrashPlaceBet = RemoteEvents:WaitForChild("CrashPlaceBet")
local CrashCashOut = RemoteEvents:WaitForChild("CrashCashOut")
local CrashRoundUpdate = RemoteEvents:WaitForChild("CrashRoundUpdate")
local CrashBetResult = RemoteEvents:WaitForChild("CrashBetResult")

local random = Random.new()

-- One shared round for the whole server: everyone bets on and watches the
-- same climbing multiplier. `bets` maps Player -> { amount, cashedOut }.
local round = {
	phase = "waiting", -- "waiting" | "running" | "crashed"
	crashPoint = 1,
	startTime = 0,
	bets = {},
}

local history = {}

local function currentMultiplier()
	local elapsed = os.clock() - round.startTime
	local multiplier = math.exp(CrashConfig.GrowthRate * elapsed)
	return math.min(multiplier, CrashConfig.MaxMultiplier)
end

-- Standard "provably fair" crash-point distribution: P(reach >= m) =
-- (1 - HouseEdge) / m, which yields ~ (1 - HouseEdge) expected return if a
-- player always cashed out at any fixed target.
local function generateCrashPoint()
	local r = random:NextNumber()
	if r < CrashConfig.HouseEdge then
		return 1
	end
	local crash = (1 - CrashConfig.HouseEdge) / (1 - r)
	return math.min(math.floor(crash * 100) / 100, CrashConfig.MaxMultiplier)
end

local function broadcast(data)
	CrashRoundUpdate:FireAllClients(data)
end

local function onPlaceBet(player, amount)
	if round.phase ~= "waiting" then
		CrashBetResult:FireClient(player, { success = false, error = "round_in_progress" })
		return
	end

	if typeof(amount) ~= "number" or amount ~= amount or amount < CrashConfig.MinBet or amount > CrashConfig.MaxBet then
		CrashBetResult:FireClient(player, { success = false, error = "invalid_bet" })
		return
	end

	if round.bets[player] then
		CrashBetResult:FireClient(player, { success = false, error = "already_bet" })
		return
	end

	amount = math.floor(amount)

	if not EconomyManager.TrySpend(player, amount) then
		CrashBetResult:FireClient(player, { success = false, error = "insufficient_balance" })
		return
	end

	round.bets[player] = { amount = amount, cashedOut = false }
	CrashBetResult:FireClient(player, { success = true, placed = true, amount = amount })
end

local function onCashOut(player)
	local bet = round.bets[player]
	if round.phase ~= "running" or not bet or bet.cashedOut then
		return
	end

	bet.cashedOut = true
	local multiplier = currentMultiplier()
	local payout = math.floor(bet.amount * multiplier)
	EconomyManager.AddChips(player, payout)

	CrashBetResult:FireClient(player, {
		success = true,
		cashedOut = true,
		multiplier = multiplier,
		payout = payout,
	})
end

CrashPlaceBet.OnServerEvent:Connect(onPlaceBet)
CrashCashOut.OnServerEvent:Connect(onCashOut)

local function runRound()
	round.phase = "waiting"
	round.bets = {}

	local waitEnd = os.clock() + CrashConfig.WaitingDuration
	while os.clock() < waitEnd do
		broadcast({ phase = "waiting", timeRemaining = waitEnd - os.clock(), history = history })
		task.wait(CrashConfig.UpdateInterval)
	end

	round.phase = "running"
	round.crashPoint = generateCrashPoint()
	round.startTime = os.clock()

	while true do
		local multiplier = currentMultiplier()
		if multiplier >= round.crashPoint then
			break
		end
		broadcast({ phase = "running", multiplier = multiplier })
		task.wait(CrashConfig.UpdateInterval)
	end

	round.phase = "crashed"
	table.insert(history, 1, round.crashPoint)
	if #history > CrashConfig.HistoryLength then
		table.remove(history)
	end

	broadcast({ phase = "crashed", multiplier = round.crashPoint, history = history })
	task.wait(CrashConfig.CooldownDuration)
end

while true do
	runRound()
end
