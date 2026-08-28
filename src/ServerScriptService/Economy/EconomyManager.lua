local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- GetDataStore throws if the place has never been published to Roblox, which
-- is the normal case while testing in Studio. Fall back to in-memory-only
-- balances (no persistence) instead of crashing the whole module.
local storeSuccess, ChipsStore = pcall(function()
	return DataStoreService:GetDataStore("PlayerChips_v1")
end)

if not storeSuccess then
	warn("EconomyManager: DataStore unavailable (publish the place to Roblox to enable saving) — balances won't persist.")
	ChipsStore = nil
end

local STARTING_BALANCE = 500

local EconomyManager = {}

local function getChipsValue(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Chips")
end

local function loadBalance(player)
	if not ChipsStore then
		return STARTING_BALANCE
	end

	local success, result = pcall(function()
		return ChipsStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and result ~= nil then
		return result
	end

	if not success then
		warn(("EconomyManager: failed to load chips for %s (%d): %s"):format(player.Name, player.UserId, tostring(result)))
	end

	return STARTING_BALANCE
end

local function saveBalance(player)
	if not ChipsStore then
		return
	end

	local chips = getChipsValue(player)
	if not chips then
		return
	end

	local success, err = pcall(function()
		ChipsStore:SetAsync("Player_" .. player.UserId, chips.Value)
	end)

	if not success then
		warn(("EconomyManager: failed to save chips for %s (%d): %s"):format(player.Name, player.UserId, tostring(err)))
	end
end

local function setupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local chips = Instance.new("IntValue")
	chips.Name = "Chips"
	chips.Value = loadBalance(player)
	chips.Parent = leaderstats

	leaderstats.Parent = player
end

function EconomyManager.GetBalance(player)
	local chips = getChipsValue(player)
	return chips and chips.Value or 0
end

function EconomyManager.AddChips(player, amount)
	assert(type(amount) == "number" and amount == amount, "amount must be a valid number")

	local chips = getChipsValue(player)
	if not chips then
		return false
	end

	chips.Value = math.max(0, chips.Value + amount)
	return true
end

-- Attempts to deduct `amount` chips. Returns false without changing the
-- balance if the player can't afford it.
function EconomyManager.TrySpend(player, amount)
	assert(type(amount) == "number" and amount > 0, "amount must be a positive number")

	local chips = getChipsValue(player)
	if not chips or chips.Value < amount then
		return false
	end

	chips.Value -= amount
	return true
end

local function onPlayerAdded(player)
	setupLeaderstats(player)
end

local function onPlayerRemoving(player)
	saveBalance(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		saveBalance(player)
	end
end)

for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

return EconomyManager
