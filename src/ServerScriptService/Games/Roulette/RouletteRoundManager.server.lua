local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomyManager = require(ServerScriptService.Economy.EconomyManager)
local RouletteConfig = require(ReplicatedStorage.Shared.RouletteConfig)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RoulettePlaceBet = RemoteEvents:WaitForChild("RoulettePlaceBet")
local RouletteRoundUpdate = RemoteEvents:WaitForChild("RouletteRoundUpdate")
local RouletteBetResult = RemoteEvents:WaitForChild("RouletteBetResult")

local random = Random.new()

local VALID_COLORS = { red = true, black = true }
local VALID_PARITIES = { even = true, odd = true }
local VALID_RANGES = { low = true, high = true }

-- One shared round for the whole server. `bets` maps Player -> an array of
-- { type, value, amount } — a player can place several bets in one round,
-- same as a real roulette table.
local round = {
	phase = "waiting", -- "waiting" | "spinning" | "result"
	bets = {},
}

local history = {}

local function isValidBet(bet)
	if type(bet) ~= "table" then
		return false
	end

	if bet.type == "straight" then
		return typeof(bet.value) == "number" and bet.value == math.floor(bet.value) and bet.value >= 0 and bet.value <= 36
	elseif bet.type == "color" then
		return VALID_COLORS[bet.value] == true
	elseif bet.type == "parity" then
		return VALID_PARITIES[bet.value] == true
	elseif bet.type == "range" then
		return VALID_RANGES[bet.value] == true
	end

	return false
end

-- 0 loses every outside bet (color/parity/range), same as real roulette.
local function resolveBet(bet, winningNumber)
	if bet.type == "straight" then
		if bet.value == winningNumber then
			return bet.amount * RouletteConfig.StraightPayout
		end
		return 0
	end

	if winningNumber == 0 then
		return 0
	end

	if bet.type == "color" then
		if bet.value == RouletteConfig.GetColor(winningNumber) then
			return bet.amount * RouletteConfig.EvenMoneyPayout
		end
	elseif bet.type == "parity" then
		local isEven = winningNumber % 2 == 0
		if (bet.value == "even") == isEven then
			return bet.amount * RouletteConfig.EvenMoneyPayout
		end
	elseif bet.type == "range" then
		local isLow = winningNumber <= 18
		if (bet.value == "low") == isLow then
			return bet.amount * RouletteConfig.EvenMoneyPayout
		end
	end

	return 0
end

local function broadcast(data)
	RouletteRoundUpdate:FireAllClients(data)
end

local function onPlaceBet(player, bet, amount)
	if round.phase ~= "waiting" then
		RouletteBetResult:FireClient(player, { success = false, error = "round_in_progress" })
		return
	end

	if not isValidBet(bet) then
		RouletteBetResult:FireClient(player, { success = false, error = "invalid_bet" })
		return
	end

	if typeof(amount) ~= "number" or amount ~= amount or amount < RouletteConfig.MinBet or amount > RouletteConfig.MaxBet then
		RouletteBetResult:FireClient(player, { success = false, error = "invalid_bet" })
		return
	end

	amount = math.floor(amount)

	if not EconomyManager.TrySpend(player, amount) then
		RouletteBetResult:FireClient(player, { success = false, error = "insufficient_balance" })
		return
	end

	round.bets[player] = round.bets[player] or {}
	table.insert(round.bets[player], { type = bet.type, value = bet.value, amount = amount })

	RouletteBetResult:FireClient(player, { success = true, placed = true, type = bet.type, value = bet.value, amount = amount })
end

RoulettePlaceBet.OnServerEvent:Connect(onPlaceBet)

local function runRound()
	round.phase = "waiting"
	round.bets = {}

	local waitEnd = os.clock() + RouletteConfig.WaitingDuration
	while os.clock() < waitEnd do
		broadcast({ phase = "waiting", timeRemaining = waitEnd - os.clock(), history = history })
		task.wait(0.1)
	end

	round.phase = "spinning"
	local winningNumber = RouletteConfig.WheelOrder[random:NextInteger(1, #RouletteConfig.WheelOrder)]
	local winningColor = RouletteConfig.GetColor(winningNumber)

	broadcast({ phase = "spinning", winningNumber = winningNumber, winningColor = winningColor })
	task.wait(RouletteConfig.SpinDuration)

	round.phase = "result"

	for player, bets in round.bets do
		local totalPayout = 0
		for _, bet in bets do
			totalPayout += resolveBet(bet, winningNumber)
		end

		if totalPayout > 0 then
			EconomyManager.AddChips(player, totalPayout)
		end

		RouletteBetResult:FireClient(player, {
			success = true,
			resolved = true,
			payout = totalPayout,
			winningNumber = winningNumber,
			winningColor = winningColor,
		})
	end

	table.insert(history, 1, { number = winningNumber, color = winningColor })
	if #history > RouletteConfig.HistoryLength then
		table.remove(history)
	end

	broadcast({ phase = "result", winningNumber = winningNumber, winningColor = winningColor, history = history })
	task.wait(RouletteConfig.CooldownDuration)
end

while true do
	runRound()
end
