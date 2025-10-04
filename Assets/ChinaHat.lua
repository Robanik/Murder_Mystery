local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerHats = {}
local lastPlayerCount = 0

-- Функция: RGB цвет
local function getRGB()
    local hue = (tick() * 1.5) % 1
    return Color3.fromHSV(hue, 1, 1)
end

-- Функция: Создать настоящий конус
local function createCone(plr)
    if not plr.Character or not plr.Character:FindFirstChild("Head") then return end
    
    -- Основание конуса (цилиндр)
    local base = Instance.new("Part")
    base.Name = "ChinaHatBase_" .. plr.Name
    base.Shape = Enum.PartType.Cylinder
    base.Size = Vector3.new(0.3, 3, 3)
    base.Material = Enum.Material.ForceField
    base.Anchored = true
    base.CanCollide = false
    base.TopSurface = Enum.SurfaceType.Smooth
    base.BottomSurface = Enum.SurfaceType.Smooth
    
    -- Верхняя часть (заостренная)
    local tip = Instance.new("Part")
    tip.Name = "ChinaHatTip"
    tip.Shape = Enum.PartType.Ball
    tip.Size = Vector3.new(0.5, 0.5, 0.5)
    tip.Material = Enum.Material.Neon
    tip.Anchored = true
    tip.CanCollide = false
    tip.Parent = base
    
    -- Средние секции для конической формы
    for i = 1, 3 do
        local section = Instance.new("Part")
        section.Name = "Section" .. i
        section.Shape = Enum.PartType.Cylinder
        local scale = 1 - (i * 0.25)
        section.Size = Vector3.new(0.2, 3 * scale, 3 * scale)
        section.Material = Enum.Material.ForceField
        section.Anchored = true
        section.CanCollide = false
        section.Parent = base
    end
    
    -- Эффект свечения
    local light = Instance.new("PointLight")
    light.Brightness = 1
    light.Range = 15
    light.Parent = base
    
    -- Дополнительное кольцо снизу
    local ring = Instance.new("Part")
    ring.Name = "Ring"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.15, 4, 4)
    ring.Material = Enum.Material.Neon
    ring.Anchored = true
    ring.CanCollide = false
    ring.Transparency = 0.7
    ring.Parent = base
    
    base.Parent = Workspace
    return base
end

-- Функция: Обновить шапку
local function updateHat(plr, hat)
    if not plr or not plr.Parent then return false end
    if not plr.Character or not plr.Character:FindFirstChild("Head") or not hat.Parent then
        return false
    end
    
    local head = plr.Character.Head
    local headPos = head.Position + Vector3.new(0, 4, 0)
    
    -- Вращение
    local rotation = tick() * 3
    hat.CFrame = CFrame.new(headPos) * CFrame.Angles(0, rotation, 0) * CFrame.Angles(0, 0, math.rad(90))
    
    -- RGB цвет для всех частей
    local color = getRGB()
    hat.Color = color
    
    if hat:FindFirstChild("PointLight") then
        hat.PointLight.Color = color
    end
    
    -- Обновляем все секции
    for _, child in pairs(hat:GetChildren()) do
        if child:IsA("Part") then
            child.Color = color
        end
    end
    
    -- Позиции секций (конус)
    if hat:FindFirstChild("ChinaHatTip") then
        hat.ChinaHatTip.CFrame = CFrame.new(headPos + Vector3.new(0, 1.5, 0))
    end
    
    for i = 1, 3 do
        local section = hat:FindFirstChild("Section" .. i)
        if section then
            local yOffset = 1 - (i * 0.4)
            section.CFrame = CFrame.new(headPos + Vector3.new(0, yOffset, 0)) * CFrame.Angles(0, rotation, math.rad(90))
        end
    end
    
    if hat:FindFirstChild("Ring") then
        hat.Ring.CFrame = CFrame.new(headPos - Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, rotation * 1.5, math.rad(90))
    end
    
    return true
end

-- Функция: Создать шапку для игрока
local function addPlayerHat(plr)
    if plr == player then return end
    if playerHats[plr] then return end
    
    local hat = createCone(plr)
    if hat then
        playerHats[plr] = hat
        print("🌈 RGB China Hat добавлена для: " .. plr.Name)
    end
end

-- Функция: Удалить шапку
local function removePlayerHat(plr)
    if playerHats[plr] then
        playerHats[plr]:Destroy()
        playerHats[plr] = nil
        print("🗑️ China Hat удалена для: " .. plr.Name)
    end
end

-- Функция: Проверить всех игроков и синхронизировать шапки
local function syncPlayerHats()
    local currentPlayers = {}
    
    -- Получаем список текущих игроков
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            currentPlayers[plr] = true
        end
    end
    
    -- Удаляем шапки для игроков, которых больше нет
    for plr, hat in pairs(playerHats) do
        if not currentPlayers[plr] or not plr.Parent then
            removePlayerHat(plr)
        end
    end
    
    -- Добавляем шапки для новых игроков
    for plr, _ in pairs(currentPlayers) do
        if not playerHats[plr] and plr.Character and plr.Character:FindFirstChild("Head") then
            addPlayerHat(plr)
        end
    end
    
    -- Обновляем счётчик игроков
    local currentCount = #Players:GetPlayers() - 1 -- -1 для исключения себя
    if currentCount ~= lastPlayerCount then
        lastPlayerCount = currentCount
        print("👥 Игроков с China Hat: " .. currentCount)
    end
end

-- Основной цикл обновления
local function updateAllHats()
    for plr, hat in pairs(playerHats) do
        if not updateHat(plr, hat) then
            removePlayerHat(plr)
        end
    end
end

-- Функция: Принудительное обновление всех шапок
local function refreshAllHats()
    print("🔄 Принудительное обновление всех China Hat...")
    
    -- Очищаем все старые шапки
    for plr, hat in pairs(playerHats) do
        removePlayerHat(plr)
    end
    
    -- Создаём заново для всех игроков
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") then
            addPlayerHat(plr)
        end
    end
end

-- События игроков (улучшенные)
Players.PlayerAdded:Connect(function(plr)
    print("➕ Игрок зашёл: " .. plr.Name)
    
    plr.CharacterAdded:Connect(function()
        wait(1) -- Ждём полной загрузки персонажа
        if plr ~= player then
            addPlayerHat(plr)
        end
    end)
    
    -- Если персонаж уже есть
    if plr.Character then
        wait(1)
        addPlayerHat(plr)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    print("➖ Игрок вышел: " .. plr.Name)
    removePlayerHat(plr)
end)

-- Обработка собственного respawn
player.CharacterAdded:Connect(function()
    wait(2)
    print("👤 Твой respawn - обновляем все China Hat")
    refreshAllHats()
end)

-- Автозапуск
wait(3)
print("🌈 RGB China Hat ESP Auto-Started!")
print("Стильные RGB конусы с автообновлением игроков")

-- Создать шапки для всех текущих игроков
refreshAllHats()

-- Запустить основной цикл обновления (60 FPS)
RunService.Heartbeat:Connect(updateAllHats)

-- Запустить синхронизацию игроков (каждые 3 секунды)
spawn(function()
    while true do
        wait(3)
        syncPlayerHats()
    end
end)

-- Дополнительная проверка каждые 10 секунд (принудительная синхронизация)
spawn(function()
    while true do
        wait(10)
        
        -- Проверяем, что все игроки имеют шапки
        local missingHats = 0
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") then
                if not playerHats[plr] then
                    addPlayerHat(plr)
                    missingHats = missingHats + 1
                end
            end
        end
        
        if missingHats > 0 then
            print("🔧 Восстановлено " .. missingHats .. " China Hat")
        end
    end
end)
