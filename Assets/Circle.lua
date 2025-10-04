local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- ⚙️ НАСТРОЙКИ ОСНОВНОГО КРУГА
local BIG_COOLDOWN = 0.3  
local EFFECT_DURATION = 1  
local START_SIZE = 2  
local END_SIZE = 10  
local CENTER_COLOR = Color3.fromRGB(128, 128, 128)  
local EDGE_COLOR = Color3.fromRGB(255, 255, 255)  

-- ⚙️ НАСТРОЙКИ МАЛЕНЬКИХ КРУЖОЧКОВ
local SMALL_COOLDOWN = 0.08
local SMALL_START_SIZE = 0.4  
local SMALL_END_SIZE = 1.5  
local SMALL_DURATION = 0.7  

local playerData = {}

-- 💥 СОЗДАНИЕ ОСНОВНОГО КРУГА (прыжки/приземление)
local function createBigRipple(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = character.HumanoidRootPart
    
    -- Raycast вниз
    local rayOrigin = rootPart.Position
    local rayDirection = Vector3.new(0, -20, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {character}
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if not raycastResult then return end
    
    local floorPosition = raycastResult.Position
    
    -- Создаём Part
    local ripplePart = Instance.new("Part")
    ripplePart.Name = "BigRipple"
    ripplePart.Size = Vector3.new(START_SIZE, 0.1, START_SIZE)
    ripplePart.Position = floorPosition + Vector3.new(0, 0.06, 0)
    ripplePart.Anchored = true
    ripplePart.CanCollide = false
    ripplePart.Transparency = 1
    ripplePart.Material = Enum.Material.SmoothPlastic
    ripplePart.Parent = workspace
    
    -- SurfaceGui
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.AlwaysOnTop = true
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 100
    surfaceGui.Parent = ripplePart
    
    -- Frame круга
    local circleFrame = Instance.new("Frame")
    circleFrame.Size = UDim2.new(1, 0, 1, 0)
    circleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    circleFrame.BackgroundColor3 = CENTER_COLOR
    circleFrame.BackgroundTransparency = 0
    circleFrame.BorderSizePixel = 0
    circleFrame.Parent = surfaceGui
    
    -- UICorner
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0.5, 0)
    uiCorner.Parent = circleFrame
    
    -- Градиент
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, CENTER_COLOR),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(200, 200, 200)),
        ColorSequenceKeypoint.new(1, EDGE_COLOR)
    }
    uiGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.6, 0.3),
        NumberSequenceKeypoint.new(1, 0.9)
    }
    uiGradient.Parent = circleFrame
    
    -- Обводка
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = EDGE_COLOR
    uiStroke.Thickness = 4
    uiStroke.Transparency = 0
    uiStroke.Parent = circleFrame
    
    -- Анимации
    local tweenInfo = TweenInfo.new(EFFECT_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local sizeTween = TweenService:Create(ripplePart, tweenInfo, {Size = Vector3.new(END_SIZE, 0.1, END_SIZE)})
    local fadeTween = TweenService:Create(circleFrame, tweenInfo, {BackgroundTransparency = 1})
    local strokeTween = TweenService:Create(uiStroke, tweenInfo, {Transparency = 1})
    
    sizeTween:Play()
    fadeTween:Play()
    strokeTween:Play()
    
    game:GetService("Debris"):AddItem(ripplePart, EFFECT_DURATION + 0.5)
end

-- ✨ СОЗДАНИЕ МАЛЕНЬКИХ КРУЖОЧКОВ (ЯРКИЕ!)
local function createSmallCircle(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = character.HumanoidRootPart
    
    -- Raycast вниз
    local rayOrigin = rootPart.Position
    local rayDirection = Vector3.new(0, -20, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {character}
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if not raycastResult then return end
    
    local floorPosition = raycastResult.Position
    
    -- Рандомное смещение
    local randomOffset = Vector3.new(
        math.random(-10, 10) / 10,
        0,
        math.random(-10, 10) / 10
    )
    
    -- Маленький Part
    local smallPart = Instance.new("Part")
    smallPart.Name = "SmallRipple"
    smallPart.Size = Vector3.new(SMALL_START_SIZE, 0.05, SMALL_START_SIZE)
    smallPart.Position = floorPosition + randomOffset + Vector3.new(0, 0.07, 0)
    smallPart.Anchored = true
    smallPart.CanCollide = false
    smallPart.Transparency = 1
    smallPart.Parent = workspace
    
    -- SurfaceGui
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.AlwaysOnTop = true
    surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surfaceGui.PixelsPerStud = 120
    surfaceGui.Parent = smallPart
    
    -- Frame (ЯРКИЙ!)
    local circleFrame = Instance.new("Frame")
    circleFrame.Size = UDim2.new(1, 0, 1, 0)
    circleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    circleFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)  -- ЯРЧЕ! (было 220)
    circleFrame.BackgroundTransparency = 0  -- НЕПРОЗРАЧНЫЙ! (было 0)
    circleFrame.BorderSizePixel = 0
    circleFrame.Parent = surfaceGui
    
    -- Круглая форма
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0.5, 0)
    uiCorner.Parent = circleFrame
    
    -- Градиент (МЕНЕЕ ПРОЗРАЧНЫЙ!)
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),  -- Центр НЕПРОЗРАЧНЫЙ! (было 0.1)
        NumberSequenceKeypoint.new(0.7, 0.4),  -- Менее прозрачный
        NumberSequenceKeypoint.new(1, 0.7)  -- Края чуть прозрачные (было 0.8)
    }
    uiGradient.Parent = circleFrame
    
    -- Обводка (ЯРЧЕ!)
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(255, 255, 255)
    uiStroke.Thickness = 3  -- Потолще! (было 2)
    uiStroke.Transparency = 0  -- НЕПРОЗРАЧНАЯ! (было 0.2)
    uiStroke.Parent = circleFrame
    
    -- Анимации
    local tweenInfo = TweenInfo.new(SMALL_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local sizeTween = TweenService:Create(smallPart, tweenInfo, {Size = Vector3.new(SMALL_END_SIZE, 0.05, SMALL_END_SIZE)})
    local fadeTween = TweenService:Create(circleFrame, tweenInfo, {BackgroundTransparency = 1})
    local strokeTween = TweenService:Create(uiStroke, tweenInfo, {Transparency = 1})
    
    sizeTween:Play()
    fadeTween:Play()
    strokeTween:Play()
    
    game:GetService("Debris"):AddItem(smallPart, SMALL_DURATION + 0.3)
end

-- 🎮 УСТАНОВКА ЭФФЕКТА НА ПЕРСОНАЖА
local function setupCharacter(character)
    if playerData[character] then return end
    
    local humanoid = character:WaitForChild("Humanoid", 5)
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not humanoid or not rootPart then return end
    
    local charData = {
        lastBigTime = 0,
        lastSmallTime = 0,
        connections = {}
    }
    
    -- БОЛЬШОЙ круг на прыжок
    charData.connections.jumping = humanoid.Jumping:Connect(function()
        local now = tick()
        if now - charData.lastBigTime >= BIG_COOLDOWN then
            charData.lastBigTime = now
            createBigRipple(character)
        end
    end)
    
    -- БОЛЬШОЙ круг на приземление
    charData.connections.stateChanged = humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Landed then
            local now = tick()
            if now - charData.lastBigTime >= BIG_COOLDOWN then
                charData.lastBigTime = now
                createBigRipple(character)
            end
        end
    end)
    
    -- МАЛЕНЬКИЕ кружочки при ходьбе
    charData.connections.heartbeat = RunService.Heartbeat:Connect(function()
        if humanoid.MoveDirection.Magnitude > 0.1 then
            local now = tick()
            if now - charData.lastSmallTime >= SMALL_COOLDOWN then
                charData.lastSmallTime = now
                createSmallCircle(character)
            end
        end
    end)
    
    playerData[character] = charData
    print("✅ Эффект установлен на:", character.Name)
end

-- 🧹 ОЧИСТКА
local function cleanupCharacter(character)
    local charData = playerData[character]
    if not charData then return end
    
    for _, connection in pairs(charData.connections) do
        connection:Disconnect()
    end
    
    playerData[character] = nil
    print("🧹 Эффект удалён с:", character.Name)
end

-- 👤 УСТАНОВКА НА ИГРОКА
local function setupPlayer(player)
    if player.Character then
        setupCharacter(player.Character)
    end
    
    player.CharacterAdded:Connect(function(character)
        setupCharacter(character)
    end)
    
    player.CharacterRemoving:Connect(function(character)
        cleanupCharacter(character)
    end)
end

-- 🌍 УСТАНОВКА НА ВСЕХ
for _, player in pairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
    print("🎮 Новый игрок:", player.Name)
    setupPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    print("👋 Игрок вышел:", player.Name)
    if player.Character then
        cleanupCharacter(player.Character)
    end
end)
