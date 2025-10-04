local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Настройки
local TELEPORT_DISTANCE = 3
local AUTO_KILL_DELAY = 0.3  -- Задержка между авто-убийствами (секунды)

local currentRole = "Innocent"
local teleportConnection = nil
local autoKillConnection = nil
local lastKillTime = 0

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

-- ⚔️ АВТОМАТИЧЕСКОЕ УБИЙСТВО (для мобилок)
local function autoKill()
    local currentTime = tick()
    if currentTime - lastKillTime < AUTO_KILL_DELAY then return end
    
    currentRole = getRole()
    
    if currentRole == "Murderer" then
        -- Ищем нож
        local knife = nil
        for _, item in pairs(character:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("нож")) then
                knife = item
                break
            end
        end
        
        if not knife then
            for _, item in pairs(player.Backpack:GetChildren()) do
                if item:IsA("Tool") and (item.Name:lower():find("knife") or item.Name:lower():find("нож")) then
                    knife = item
                    character.Humanoid:EquipTool(knife)
                    break
                end
            end
        end
        
        if knife then
            local alivePlayers = getAlivePlayers()
            if #alivePlayers > 0 then
                knife:Activate()
                lastKillTime = currentTime
                print("🔪 Атака! Целей: " .. #alivePlayers)
            end
        end
        
    elseif currentRole == "Sheriff" then
        local murderer = findMurderer()
        if murderer then
            -- Ищем пистолет
            local gun = nil
            for _, item in pairs(character:GetChildren()) do
                if item:IsA("Tool") and (item.Name:lower():find("gun") or item.Name:lower():find("revolver")) then
                    gun = item
                    break
                end
            end
            
            if not gun then
                for _, item in pairs(player.Backpack:GetChildren()) do
                    if item:IsA("Tool") and (item.Name:lower():find("gun") or item.Name:lower():find("revolver")) then
                        gun = item
                        character.Humanoid:EquipTool(gun)
                        break
                    end
                end
            end
            
            if gun then
                gun:Activate()
                lastKillTime = currentTime
                print("🔫 Выстрел по убийце!")
            end
        end
    end
end

-- 📍 ЗАПУСК ТЕЛЕПОРТА + АВТО-УБИЙСТВА
local function startTeleport()
    -- Останавливаем старые соединения
    if teleportConnection then
        teleportConnection:Disconnect()
    end
    if autoKillConnection then
        autoKillConnection:Disconnect()
    end
    
    currentRole = getRole()
    
    if currentRole == "Murderer" then
        print("🔪 MURDERER: Телепортирую всех + АВТО-УБИЙСТВО!")
        
        -- Телепорт
        teleportConnection = RunService.Heartbeat:Connect(function()
            local alivePlayers = getAlivePlayers()
            local myPosition = humanoidRootPart.CFrame
            
            for i, otherPlayer in pairs(alivePlayers) do
                if otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local otherRoot = otherPlayer.Character.HumanoidRootPart
                    
                    local angle = (i / #alivePlayers) * math.pi * 2
                    local offsetX = math.cos(angle) * TELEPORT_DISTANCE
                    local offsetZ = math.sin(angle) * TELEPORT_DISTANCE
                    
                    otherRoot.CFrame = myPosition * CFrame.new(offsetX, 0, offsetZ)
                end
            end
        end)
        
        -- Авто-убийство
        autoKillConnection = RunService.Heartbeat:Connect(function()
            autoKill()
        end)
        
    elseif currentRole == "Sheriff" then
        print("🔫 SHERIFF: Телепортирую убийцу + АВТО-СТРЕЛЬБА!")
        
        -- Телепорт
        teleportConnection = RunService.Heartbeat:Connect(function()
            local murderer = findMurderer()
            if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
                local murdererRoot = murderer.Character.HumanoidRootPart
                local myPosition = humanoidRootPart.CFrame
                
                murdererRoot.CFrame = myPosition * CFrame.new(0, 0, -TELEPORT_DISTANCE)
            end
        end)
        
        -- Авто-стрельба
        autoKillConnection = RunService.Heartbeat:Connect(function()
            autoKill()
        end)
        
    else
        print("😐 INNOCENT: Нет оружия")
    end
end

-- 🔄 АВТООБНОВЛЕНИЕ РОЛИ
task.spawn(function()
    while true do
        task.wait(1)
        
        local newRole = getRole()
        
        if newRole ~= currentRole then
            currentRole = newRole
            print("🔄 Роль изменилась: " .. currentRole)
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
    if autoKillConnection then
        autoKillConnection:Disconnect()
    end
    
    task.wait(2)
    currentRole = getRole()
    print("🔄 Респавн! Роль: " .. currentRole)
    startTeleport()
end)

-- 🚀 ЗАПУСК
task.wait(2)
currentRole = getRole()
print("AUTO KILL АКТИВИРОВАН! | BT ROBANIK")
print("Играешь на мобилке!! загрузка.. готово")
print("🎮 Роль: " .. currentRole)
startTeleport()
