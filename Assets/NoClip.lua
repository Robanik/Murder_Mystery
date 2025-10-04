local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Список частей для noclip
local noclipParts = {}

-- Обновление списка частей
local function updateNoclipParts()
    noclipParts = {}
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Добавляем ВСЕ части тела
            table.insert(noclipParts, part)
        end
    end
end

updateNoclipParts()

-- Главный noclip (ТОЛЬКО CanCollide, ничего больше!)
RunService.Stepped:Connect(function()
    for _, part in pairs(noclipParts) do
        if part and part.Parent then
            part.CanCollide = false
        end
    end
end)

-- Обновление при добавлении новых частей (аксессуары)
character.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("BasePart") then
        table.insert(noclipParts, descendant)
    end
end)

-- Обновление при респавне
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    updateNoclipParts()
end)

print("NOCLIP | BY ROBANIK")
