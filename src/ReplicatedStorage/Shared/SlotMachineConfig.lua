local SlotMachineConfig = {}

-- Higher Weight = more common. Payout is the multiplier applied to the bet
-- when all reels land on that symbol.
-- Diamond is the jackpot symbol: it only pays out on a full triple match
-- (DoubleMatchExcluded), but pays big when it hits.
SlotMachineConfig.Symbols = {
	{ Name = "Cherry", Weight = 35, Payout = 2 },
	{ Name = "Lemon", Weight = 25, Payout = 3 },
	{ Name = "Bell", Weight = 18, Payout = 6 },
	{ Name = "Star", Weight = 14, Payout = 15 },
	{ Name = "Diamond", Weight = 8, Payout = 100, DoubleMatchExcluded = true },
}

-- The machine displays a 3x3 grid (GridRows symbols per reel) but only the
-- middle row is the actual payline the server evaluates; top/bottom rows are
-- cosmetic, client-side only.
SlotMachineConfig.ReelCount = 3
SlotMachineConfig.GridRows = 3
-- Pixel height/width of one symbol cell in the reel display. Shared by the
-- server (cabinet layout) and client (reel scroll animation) so they always
-- agree on the geometry.
SlotMachineConfig.CellSize = 100
SlotMachineConfig.MinBet = 10
SlotMachineConfig.MaxBet = 500
SlotMachineConfig.BetStep = 10

-- Fraction of a symbol's Payout awarded when only 2 of the 3 reels match
-- (instead of all 3). Targets ~90% return-to-player overall (the machine
-- wins on average, like a real casino, without feeling stingy).
SlotMachineConfig.TwoMatchMultiplier = 0.32

return SlotMachineConfig
