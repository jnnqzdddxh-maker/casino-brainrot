-- Shared color palette for every game's UI. One place to tune brightness/
-- contrast across the whole casino instead of editing four separate files.
local Theme = {}

Theme.Body = Color3.fromRGB(30, 37, 54) -- panel background
Theme.Screen = Color3.fromRGB(22, 27, 40) -- "screen" surfaces (reel windows, graph area, wheel backing)
Theme.Trim = Color3.fromRGB(242, 179, 61) -- gold accent/branding
Theme.Text = Color3.fromRGB(233, 236, 244) -- primary text
Theme.Muted = Color3.fromRGB(168, 175, 194) -- secondary text

Theme.Green = Color3.fromRGB(60, 210, 130) -- wins, "up"
Theme.Red = Color3.fromRGB(235, 60, 75) -- losses, "down", roulette red
Theme.Gold = Theme.Trim

-- Roulette-specific, but bright/high-contrast enough to reuse anywhere a
-- "black" or "neutral" chip color is needed.
Theme.RouletteBlack = Color3.fromRGB(78, 78, 90)
Theme.Neutral = Color3.fromRGB(68, 77, 102)

return Theme
