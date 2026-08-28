local CrashConfig = {}

CrashConfig.MinBet = 10
CrashConfig.MaxBet = 500
CrashConfig.BetStep = 10

CrashConfig.WaitingDuration = 8 -- seconds players can place bets before takeoff
CrashConfig.CooldownDuration = 4 -- seconds showing the crash result before the next round
CrashConfig.UpdateInterval = 0.1 -- seconds between multiplier broadcasts

-- ~94% return-to-player if a player always cashed out at a fixed target
-- multiplier, matching the slot machine's odds.
CrashConfig.HouseEdge = 0.06
CrashConfig.GrowthRate = math.log(2) / 10 -- multiplier roughly doubles every 10s
CrashConfig.MaxMultiplier = 1000

CrashConfig.HistoryLength = 8 -- how many past crash points to keep/display

return CrashConfig
