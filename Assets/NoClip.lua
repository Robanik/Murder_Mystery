-- MM2 - Noclip Function
-- 👻 Проходи сквозь стены и объекты
-- Features: Smooth noclip, auto toggle, collision restore
-- Toggle: DELETE для вкл/выкл
-- Author: Grok

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- State
local noclipEnabled = true
local noclipConnection = nil
local originalCollisions = {} -- Сохраняем оригинальные настройки коллизий

-- Функция: Обновить персонажа после respawn
local function updateCharacter()
    character = player.Character
    if character then
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    end
end

-- Функция: Сохранить оригинальные коллизии
local function saveOriginalCollisions()
    originalCollisions = {}
    if not character then return end
    
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            originalCollisions[part] = part.CanCollide
        end
    end
end

-- Функция: Восстановить оригинальные коллизии
local function restoreOriginalCollisions()
    if not character then return end
    
    for part, originalState in pairs(originalCollisions) do
        if part and part.Parent then
            part.CanCollide = originalState
        end
    end
    originalCollisions = {}
end

-- Функция: Включить noclip
local function enableNoclip()
    if not character then return end
    
    saveOriginalCollisions()
    
    -- Отключаем коллизии для всех частей
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = false
        end
    end
    
    -- Основной цикл noclip
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclipEnabled or not character then return end
        
        -- Поддерживаем отключенные коллизии
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = false
            end
        end
        
        -- HumanoidRootPart обрабатываем отдельно для более плавного noclip
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            humanoidRootPart.CanCollide = false
        end
    end)
    
    print("👻 NOCLIP ВКЛЮЧЁН! Проходи сквозь стены")
end

-- Функция: Выключить noclip
local function disableNoclip()
    -- Отключаем соединение
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    -- Восстанавливаем коллизии
    restoreOriginalCollisions()
    
    -- Дополнительная проверка для HumanoidRootPart
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CanCollide = false -- HRP обычно всегда false
    end
    
    print("🚪 NOCLIP ВЫКЛЮЧЕН! Коллизии восстановлены")
end

-- Основная функция: Toggle Noclip
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    
    updateCharacter()
    if not character then
        print("❌ Персонаж не найден!")
        noclipEnabled = false
        return
    end
    
    if noclipEnabled then
        enableNoclip()
    else
        disableNoclip()
    end
end

-- Функция: Быстрый noclip через стену (экстра фича)
local function quickPhaseThrough()
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local humanoidRootPart = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not humanoid then return end
    
    print("⚡ Быстрое прохождение через стену...")
    
    -- Временно отключаем коллизии
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    -- Двигаемся вперёд на 10 studs
    local lookDirection = humanoidRootPart.CFrame.LookVector
    humanoidRootPart.CFrame = humanoidRootPart.CFrame + (lookDirection * 10)
    
    -- Через секунду восстанавливаем коллизии (если noclip выключен)
    wait(1)
    if not noclipEnabled then
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
    
    print("✅ Прошёл через стену!")
end

-- Функция: Noclip для всех частей (включая аксессуары)
local function deepNoclip()
    if not character then return end
    
    -- Обрабатываем ВСЕ BasePart в персонаже (включая Hat, Accessory и т.д.)
    for _, descendant in pairs(character:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
            if noclipEnabled then
                descendant.CanCollide = false
            else
                -- Восстанавливаем (аксессуары обычно false, части тела true)
                if descendant.Parent:IsA("Accessory") or descendant.Parent:IsA("Hat") then
                    descendant.CanCollide = false
                else
                    descendant.CanCollide = true
                end
            end
        end
    end
end

-- Обработка клавиш
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.Delete then
        toggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.PageDown then
        quickPhaseThrough()
    elseif input.KeyCode == Enum.KeyCode.End then
        deepNoclip()
        print("🔄 Deep Noclip - все части обновлены")
    end
end)

-- Обработка добавления новых частей (аксессуары и т.д.)
local function onCharacterChildAdded(child)
    if not noclipEnabled then return end
    
    if child:IsA("Accessory") or child:IsA("Hat") then
        -- Для аксессуаров ждём загрузки Handle
        child.ChildAdded:Connect(function(part)
            if part.Name == "Handle" and part:IsA("BasePart") then
                part.CanCollide = false
            end
        end)
        
        -- Если Handle уже есть
        local handle = child:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then
            handle.CanCollide = false
        end
    elseif child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
        child.CanCollide = false
    end
end

-- Обработка respawn
player.CharacterAdded:Connect(function()
    wait(1)
    updateCharacter()
    
    if character then
        -- Подключаем мониторинг новых частей
        character.ChildAdded:Connect(onCharacterChildAdded)
        
        if noclipEnabled then
            print("👤 Respawn: Noclip восстановлен для нового персонажа")
            -- Переинициализируем noclip
            noclipEnabled = false
            toggleNoclip()
        end
    end
end)

-- Улучшенная функция: Noclip с анти-застреванием
local function antiStuckNoclip()
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local humanoidRootPart = character.HumanoidRootPart
    
    -- Проверяем, застрял ли игрок в объекте
    local ray = workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -5, 0))
    if ray and ray.Instance then
        -- Если находимся внутри объекта, поднимаемся вверх
        humanoidRootPart.CFrame = humanoidRootPart.CFrame + Vector3.new(0, 5, 0)
        print("🆙 Анти-застревание: поднят вверх")
    end
end

-- Дополнительный мониторинг (каждые 2 секунды)
spawn(function()
    while true do
        if noclipEnabled then
            deepNoclip() -- Поддерживаем noclip для всех частей
            antiStuckNoclip() -- Проверяем застревание
        end
        wait(2)
    end
end)

-- Инициализация
wait(2)
print("Noclip загружен!")

-- Подключаем мониторинг для текущего персонажа
if character then
    character.ChildAdded:Connect(onCharacterChildAdded)
end
