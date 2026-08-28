local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RouletteConfig = require(ReplicatedStorage.Shared.RouletteConfig)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RouletteRoundUpdate = RemoteEvents:WaitForChild("RouletteRoundUpdate")

local GREEN = Color3.fromRGB(63, 217, 160)
local RED = Color3.fromRGB(255, 93, 108)
local MUTED = Color3.fromRGB(139, 147, 167)
local TEXT = Color3.fromRGB(233, 236, 244)

local WHEEL_SEGMENT_ANGLE = 360 / #RouletteConfig.WheelOrder

local WHEEL_INDEX_BY_NUMBER = {}
for index, number in RouletteConfig.WheelOrder do
	WHEEL_INDEX_BY_NUMBER[number] = index
end

-- Mirrors the same server-broadcast round state the betting mat uses (see
-- RouletteUI.client.lua) — this script only needs phase + the winning
-- number, not the betting side of things.
local latestUpdate = { phase = "waiting", timeRemaining = RouletteConfig.WaitingDuration }

RouletteRoundUpdate.OnClientEvent:Connect(function(data)
	latestUpdate = data
end)

local function colorFor(colorName)
	if colorName == "red" then
		return RED
	elseif colorName == "green" then
		return GREEN
	end
	return TEXT
end

local function setupWheel(wheelModel)
	local screen = wheelModel:WaitForChild("Screen")
	local gui = screen:WaitForChild("ScreenGui")
	local panel = gui:WaitForChild("Panel")
	local wheelFrame = panel:WaitForChild("WheelFrame")
	local ballPivot = wheelFrame:WaitForChild("BallPivot")
	local winningNumberLabel = panel:WaitForChild("WinningNumberLabel")
	local statusLabel = panel:WaitForChild("StatusLabel")

	-- The wheel itself never moves — only BallPivot rotates, swinging the
	-- ball (offset from its center) around the fixed wheel until it lands
	-- directly over the winning pocket's own angular position, always
	-- spinning forward from wherever it currently rests.
	local currentRotation = 0

	local function spinBallTo(winningNumber)
		local index = WHEEL_INDEX_BY_NUMBER[winningNumber] or 1
		local targetMod = ((index - 1) * WHEEL_SEGMENT_ANGLE) % 360
		local currentMod = currentRotation % 360
		local delta = (targetMod - currentMod) % 360
		local newRotation = currentRotation + delta + 8 * 360

		TweenService:Create(ballPivot, TweenInfo.new(RouletteConfig.SpinDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Rotation = newRotation,
		}):Play()

		currentRotation = newRotation
	end

	local localPhase = "waiting"

	task.spawn(function()
		while wheelModel.Parent do
			local phase = latestUpdate.phase

			if phase ~= localPhase then
				if phase == "spinning" then
					spinBallTo(latestUpdate.winningNumber)
				end
				localPhase = phase
			end

			if phase == "waiting" then
				statusLabel.Text = ("Placez vos mises... %ds"):format(math.ceil(latestUpdate.timeRemaining or 0))
				statusLabel.TextColor3 = MUTED
			elseif phase == "spinning" then
				statusLabel.Text = "La roue tourne..."
				statusLabel.TextColor3 = MUTED
			elseif phase == "result" then
				winningNumberLabel.Text = tostring(latestUpdate.winningNumber)
				winningNumberLabel.TextColor3 = colorFor(latestUpdate.winningColor)
				statusLabel.Text = "Résultat !"
				statusLabel.TextColor3 = MUTED
			end

			task.wait(0.1)
		end
	end)
end

for _, descendant in Workspace:GetDescendants() do
	if descendant.Name == "RouletteWheel" then
		task.spawn(setupWheel, descendant)
	end
end

Workspace.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "RouletteWheel" then
		task.spawn(setupWheel, descendant)
	end
end)
