local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- State
local autoGunEnabled = false
local monitoring = false
local originalPosition = nil
local gunConnection = nil
local foundGuns = {} -- Кэш найденных пистолетов

-- Gun names в MM2 (разные варианты)
local gunNames = {
    "Gun", "Revolver", "Pistol", "Sheriff Gun", 
    "Classic Gun", "Steampunk Gun", "Ghost Gun",
    "Retro Gun", "Blue Gun", "Green Gun", "Red Gun"
}

-- Функция: Проверка, является ли объект пистолетом
local function isGun(obj)
    if not obj:IsA("Tool") then return false end
    
    local name = obj.Name
    for _, gunName in pairs(gunNames) do
        if name:find(gunName) or name:lower():find("gun") or name:lower():find("revolver") then
            return true
        end
    end
    return false
end

-- Функция: Обновить персонажа после respawn
local function updateCharacter()
    character = player.Character
    if character then
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    end
end

-- Функция: Подбор пистолета
local function pickupGun(gun)
    if not gun or not gun.Parent then return false end
    if foundGuns[gun] then return false end -- Уже пытались подобрать
    
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    -- Сохраняем позицию
    originalPosition = char.HumanoidRootPart.CFrame
    
    print("🔫 Найден пистолет: " .. gun.Name .. " - телепортируемся...")
    
    -- Телепорт к пистолету
    local gunPosition = gun.Handle and gun.Handle.CFrame or gun:FindFirstChild("Handle") and gun.Handle.CFrame
    if gunPosition then
        char.HumanoidRootPart.CFrame = gunPosition + Vector3.new(0, 3, 0)
        
        -- Ждём кадр для регистрации
        wait(0.1)
        
        -- Подбираем (несколько методов)
        pcall(function()
            -- Метод 1: Прямое присваивание
            gun.Parent = char
        end)
        
        pcall(function()
            -- Метод 2: Через Backpack
            gun.Parent = player.Backpack
        end)
        
        pcall(function()
            -- Метод 3: Активация Touched события
            if gun.Handle then
                gun.Handle.CFrame = char.HumanoidRootPart.CFrame
            end
        end)
        
        -- Ждём подбора
        wait(0.2)
        
        -- Возвращаемся обратно
        if originalPosition then
            char.HumanoidRootPart.CFrame = originalPosition
            print("✅ Пистолет подобран и вернулись обратно!")
        end
        
        foundGuns[gun] = true
        return true
    end
    
    return false
end

-- Функция: Мониторинг пистолетов в Workspace
local function monitorGuns()
    -- Проверяем уже существующие
    for _, obj in pairs(Workspace:GetChildren()) do
        if isGun(obj) and not foundGuns[obj] then
            spawn(function()
                pickupGun(obj)
            end)
        end
    end
    
    -- Мониторим новые
    gunConnection = Workspace.ChildAdded:Connect(function(child)
        if autoGunEnabled and isGun(child) and not foundGuns[child] then
            wait(0.1) -- Небольшая задержка для стабильности
            spawn(function()
                pickupGun(child)
            end)
        end
    end)
end

-- Функция: Поиск дропнутых пистолетов (альтернативный метод)
local function scanForDroppedGuns()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if isGun(obj) and not foundGuns[obj] then
            -- Проверяем, что пистолет на земле (не в инвентаре)
            local parent = obj.Parent
            if parent == Workspace or (parent and parent.Name ~= "Backpack" and not parent:FindFirstChild("Humanoid")) then
                spawn(function()
                    pickupGun(obj)
                end)
            end
        end
    end
end

-- Основная функция: Toggle Auto Gun Pickup
local function toggleAutoGun()
    autoGunEnabled = not autoGunEnabled
    
    if autoGunEnabled then
        updateCharacter()
        if not character then
            print("❌ Персонаж не найден!")
            autoGunEnabled = false
            return
        end
        
        -- Очищаем кэш
        foundGuns = {}
        
        -- Запускаем мониторинг
        monitorGuns()
        
        -- Дополнительный скан каждые 2 секунды
        spawn(function()
            while autoGunEnabled do
                scanForDroppedGuns()
                wait(2)
            end
        end)
        
        print("🔫 AUTO GUN PICKUP ВКЛЮЧЁН!")
        print("Будет автоматически подбирать пистолет и возвращать обратно")
        print("Мониторинг: Gun, Revolver, Sheriff Gun и др.")
    else
        -- Отключаем
        if gunConnection then
            gunConnection:Disconnect()
            gunConnection = nil
        end
        
        monitoring = false
        foundGuns = {}
        
        print("🛑 AUTO GUN PICKUP ВЫКЛЮЧЕН!")
    end
end

-- Функция: Принудительный поиск (если что-то пропустили)
local function forceGunScan()
    if not autoGunEnabled then
        print("⚠️ Auto Gun выключен!")
        return
    end
    
    print("🔍 Принудительный поиск пистолетов...")
    local found = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if isGun(obj) and not foundGuns[obj] then
            spawn(function()
                if pickupGun(obj) then
                    found = found + 1
                end
            end)
        end
    end
    
    if found == 0 then
        print("📭 Пистолеты не найдены в данный момент")
    else
        print("🎯 Найдено пистолетов: " .. found)
    end
end

-- Обработка клавиш
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        toggleAutoGun()
    elseif input.KeyCode == Enum.KeyCode.Home then
        forceGunScan()
    end
end)

-- Обработка respawn
player.CharacterAdded:Connect(function()
    wait(2)
    updateCharacter()
    if autoGunEnabled then
        print("👤 Respawn: Auto Gun обновлён для нового персонажа")
        foundGuns = {} -- Сброс кэша при respawn
    end
end)

-- Обработка выхода игроков (очистка кэша)
Players.PlayerRemoving:Connect(function()
    foundGuns = {}
end)

-- Улучшенная функция: Проверка ролей для определения смерти Sheriff
local function detectSherifficDeath()
    local sheriffPlayers = {}
    
    -- Находим всех Sheriff'ов
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local backpack = plr:FindFirstChild("Backpack")
            if backpack then
                for _, tool in pairs(backpack:GetChildren()) do
                    if isGun(tool) then
                        sheriffPlayers[plr] = true
                        break
                    end
                end
            end
        end
    end
    
    -- Мониторим их здоровье
    for sheriffPlayer, _ in pairs(sheriffPlayers) do
        if sheriffPlayer.Character and sheriffPlayer.Character:FindFirstChild("Humanoid") then
            local humanoid = sheriffPlayer.Character.Humanoid
            if humanoid.Health <= 0 then
                print("💀 Sheriff " .. sheriffPlayer.Name .. " убит! Ищем пистолет...")
                wait(0.5) -- Ждём дропа
                forceGunScan()
            end
        end
    end
end

-- Дополнительный мониторинг смерти Sheriff (каждые 3 сек)
spawn(function()
    while true do
        if autoGunEnabled then
            detectSherifficDeath()
        end
        wait(3)
    end
end)

-- Инициализация
wait(3)
print("Auto Gun Pickup загружен!")

-- Авто-включение для удобства
toggleAutoGun()
