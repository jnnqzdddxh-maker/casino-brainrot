local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local SpinSlotMachine = RemoteEvents:WaitForChild("SpinSlotMachine")
local SlotMachineResult = RemoteEvents:WaitForChild("SlotMachineResult")

local SlotMachineClient = {}

local resultCallbacks = {}

function SlotMachineClient.Spin(bet)
	SpinSlotMachine:FireServer(bet)
end

-- callback receives the table sent by the server:
-- { success, symbols, bet, payout, balance } on success
-- { success = false, error } on failure ("invalid_bet" | "insufficient_balance")
function SlotMachineClient.OnResult(callback)
	table.insert(resultCallbacks, callback)
end

SlotMachineResult.OnClientEvent:Connect(function(result)
	for _, callback in resultCallbacks do
		callback(result)
	end
end)

return SlotMachineClient
