local RouletteConfig = {}

RouletteConfig.MinBet = 10
RouletteConfig.MaxBet = 500
RouletteConfig.BetStep = 10

RouletteConfig.WaitingDuration = 10 -- seconds players can place a bet before the wheel spins
RouletteConfig.SpinDuration = 4.5 -- seconds the wheel visually spins for
RouletteConfig.CooldownDuration = 4 -- seconds showing the result before the next round

-- European roulette: single zero, 37 pockets. Real-world odds (no extra
-- house edge tuning) — this is the one game where the house edge is exactly
-- what real roulette has (~2.7%), unlike the slot machine/Crash which are
-- tuned by hand.
RouletteConfig.StraightPayout = 36 -- total returned on a straight-number hit (35:1 profit)
RouletteConfig.EvenMoneyPayout = 2 -- total returned on red/black, even/odd, low/high (1:1 profit)

-- Physical wheel order (European layout), used for both the winning-number
-- draw and the spin animation.
RouletteConfig.WheelOrder = {
	0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10,
	5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26,
}

local RED_NUMBERS = {
	1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36,
}
RouletteConfig.RedNumbers = {}
for _, number in RED_NUMBERS do
	RouletteConfig.RedNumbers[number] = true
end

function RouletteConfig.GetColor(number)
	if number == 0 then
		return "green"
	end
	return RouletteConfig.RedNumbers[number] and "red" or "black"
end

RouletteConfig.HistoryLength = 8

return RouletteConfig
