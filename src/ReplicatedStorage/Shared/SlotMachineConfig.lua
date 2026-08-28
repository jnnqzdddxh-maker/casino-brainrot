local SlotMachineConfig = {}

-- Higher Weight = more common. Payout is the multiplier applied to the bet
-- when all reels land on that symbol.
SlotMachineConfig.Symbols = {
	{ Name = "Cherry", Weight = 40, Payout = 2 },
	{ Name = "Lemon", Weight = 28, Payout = 3 },
	{ Name = "Bell", Weight = 18, Payout = 5 },
	{ Name = "Star", Weight = 10, Payout = 10 },
	{ Name = "Diamond", Weight = 4, Payout = 25 },
}

SlotMachineConfig.ReelCount = 3
SlotMachineConfig.MinBet = 10
SlotMachineConfig.MaxBet = 1000
SlotMachineConfig.BetStep = 10

-- Fraction of a symbol's Payout awarded when only 2 of the 3 reels match
-- (instead of all 3).
SlotMachineConfig.TwoMatchMultiplier = 0.5

return SlotMachineConfig
