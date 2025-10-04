-- MM2 AUTO KILL (БЕЗ GUI)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Настройки
local KILL_KEY = Enum.KeyCode.Q  -- Клавиша для убийства
local TELEPORT_DISTANCE = 3  -- Расстояние телепорта

local currentRole = "Innocent"
local teleportConnection = nil

-- 🎭 ОПРЕДЕЛЕНИЕ РОЛИ
local function getRole()
    local backpack = player:WaitForChild("Backpack")
    
    -- Проверка на нож (Murderer)
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("нож")) then
            return "Murderer"
        end
    end
    for _, item in pairs(character:GetChildren()) do
        if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("нож")) then
            return "Murderer"
        end
    end
    
    -- Проверка на пистолет (Sheriff)
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") and (item.Name:lower():find("gun") or item.Name:lower():find("revolver")) then
            return "Sheriff"
        end
    end
    for _, item in pairs(character:GetChildren()) do
        if item:IsA("Tool") and (item.Name:lower():find("gun") or item.Name:lower():find("revolver")) then
            return "Sheriff"
        end
    end
    
    return "Innocent"
end

-- 🔍 НАЙТИ MURDERER
local function findMurderer()
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local backpack = otherPlayer:FindFirstChild("Backpack")
            local char = otherPlayer.Character
            
            if backpack then
                for _, item in pairs(backpack:GetChildren()) do
                    if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("нож")) then
                        return otherPlayer
                    end
                end
            end
            
            if char then
                for _, item in pairs(char:GetChildren()) do
                    if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("нож")) then
                        return otherPlayer
                    end
                end
            end
        end
    end
    return nil
end

-- 👥 ПОЛУЧИТЬ ЖИВЫХ ИГРОКОВ
local function getAlivePlayers()
    local alivePlayers = {}
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local humanoid = otherPlayer.Character:FindFirstChild("Humanoid")
            local root = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and root then
                table.insert(alivePlayers, otherPlayer)
            end
        end
    end
    return alivePlayers
end

-- 📍 ЗАПУСК ВИЗУАЛЬНОГО ТЕЛЕПОРТА
local function startTeleport()
    if teleportConnection then
        teleportConnection:Disconnect()
    end
    
    currentRole = getRole()
    
    if currentRole == "Murderer" then
        print("🔪 MURDERER: Телепортирую всех к себе...")
        
        teleportConnection = RunService.Heartbeat:Connect(function()
            local alivePlayers = getAlivePlayers()
            local myPosition = humanoidRootPart.CFrame
            
            for i, otherPlayer in pairs(alivePlayers) do
                if otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local otherRoot = otherPlayer.Character.HumanoidRootPart
                    
                    -- Расставляем по кругу вокруг себя
                    local angle = (i / #alivePlayers) * math.pi * 2
                    local offsetX = math.cos(angle) * TELEPORT_DISTANCE
                    local offsetZ = math.sin(angle) * TELEPORT_DISTANCE
                    
                    otherRoot.CFrame = myPosition * CFrame.new(offsetX, 0, offsetZ)
                end
            end
        end)
        
    elseif currentRole == "Sheriff" then
        print("🔫 SHERIFF: Телепортирую убийцу к себе...")
        
        teleportConnection = RunService.Heartbeat:Connect(function()
            local murderer = findMurderer()
            if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
                local murdererRoot = murderer.Character.HumanoidRootPart
                local myPosition = humanoidRootPart.CFrame
                
                -- Телепортируем прямо перед собой
                murdererRoot.CFrame = myPosition * CFrame.new(0, 0, -TELEPORT_DISTANCE)
            end
        end)
        
    else
        print("😐 INNOCENT: Нет оружия")
    end
end

-- ⚔️ УБИЙСТВО
local function performKill()
    currentRole = getRole()
    
    if currentRole == "Murderer" then
        print("🔪 УБИВАЮ ВСЕХ!")
        
        -- Ищем нож
        local knife = player.Backpack:FindFirstChildWhichIsA("Tool") or character:FindFirstChildWhichIsA("Tool")
        
        if knife then
            -- Экипируем
            if knife.Parent == player.Backpack then
                character.Humanoid:EquipTool(knife)
            end
            
            task.wait(0.1)
            
            -- Активируем для каждого игрока
            local alivePlayers = getAlivePlayers()
            for _, otherPlayer in pairs(alivePlayers) do
                knife:Activate()
                task.wait(0.05)
            end
            
            print("✅ Атаковал " .. #alivePlayers .. " игроков!")
        else
            print("❌ Нож не найден!")
        end
        
    elseif currentRole == "Sheriff" then
        print("🔫 СТРЕЛЯЮ В УБИЙЦУ!")
        
        -- Ищем пистолет
        local gun = player.Backpack:FindFirstChildWhichIsA("Tool") or character:FindFirstChildWhichIsA("Tool")
        
        if gun then
            -- Экипируем
            if gun.Parent == player.Backpack then
                character.Humanoid:EquipTool(gun)
            end
            
            task.wait(0.1)
            
            -- Стреляем
            gun:Activate()
            print("✅ Выстрел произведён!")
        else
            print("❌ Пистолет не найден!")
        end
        
    else
        print("❌ Ты не Murderer и не Sheriff!")
    end
end

-- 🎮 КЛАВИША Q ДЛЯ УБИЙСТВА
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == KILL_KEY then
        performKill()
    end
end)

-- 🔄 АВТООБНОВЛЕНИЕ РОЛИ
task.spawn(function()
    while true do
        task.wait(1)
        
        local newRole = getRole()
        
        if newRole ~= currentRole then
            currentRole = newRole
            print("🔄 Роль изменилась: " .. currentRole)
            
            -- Перезапускаем телепорт
            startTeleport()
        end
    end
end)

-- 🔄 ОБНОВЛЕНИЕ ПРИ РЕСПАВНЕ
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    if teleportConnection then
        teleportConnection:Disconnect()
    end
    
    task.wait(2)  -- Ждём загрузки
    currentRole = getRole()
    print("🔄 Респавн! Роль: " .. currentRole)
    startTeleport()
end)

-- 🚀 ЗАПУСК
task.wait(2)  -- Ждём полной загрузки
currentRole = getRole()
print("🔥 MM2 AUTO KILL АКТИВИРОВАН!")
print("🎮 Роль: " .. currentRole)
print("⚔️ Нажми Q для убийства")
startTeleport()
