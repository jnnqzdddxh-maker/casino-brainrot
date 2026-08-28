local SlotMachineConfig = {}

-- Higher Weight = more common. Payout is the multiplier applied to the bet
-- when all reels land on that symbol.
SlotMachineConfig.Symbols = {
	{ Name = "Cherry", Weight = 35, Payout = 2 },
	{ Name = "Lemon", Weight = 25, Payout = 3 },
	{ Name = "Bell", Weight = 20, Payout = 5 },
	{ Name = "Star", Weight = 13, Payout = 10 },
	{ Name = "Diamond", Weight = 7, Payout = 25 },
}

-- The machine displays a 3x3 grid (GridRows symbols per reel) but only the
-- middle row is the actual payline the server evaluates; top/bottom rows are
-- cosmetic, client-side only.
SlotMachineConfig.ReelCount = 3
SlotMachineConfig.GridRows = 3
SlotMachineConfig.MinBet = 10
SlotMachineConfig.MaxBet = 500
SlotMachineConfig.BetStep = 10

-- Fraction of a symbol's Payout awarded when only 2 of the 3 reels match
-- (instead of all 3). With only 5 symbols, 2-of-3 matches happen on roughly
-- half of all spins, so this is kept low to target ~85% return-to-player
-- overall (i.e. the machine wins on average, like a real casino).
SlotMachineConfig.TwoMatchMultiplier = 0.3

return SlotMachineConfig
