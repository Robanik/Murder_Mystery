local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ESP State
local esp = {
    enabled = false,
    boxes = true,
    health = true,
    lines = true,
    names = true,
    distance = true,
    chams = true,
}

-- Drawings storage
local drawings = {}
local connections = {}

-- Modern Color Palette (Hex colors for style)
local colors = {
    murderer = Color3.fromHex("#FF4757"), -- Красный (современный)
    sheriff = Color3.fromHex("#3742FA"),   -- Синий
    innocent = Color3.fromHex("#2ED573"),  -- Зелёный
    background = Color3.fromHex("#1A1A1A"), -- Тёмный фон
    text = Color3.fromHex("#FFFFFF"),      -- Белый текст
    accent = Color3.fromHex("#FFA502")     -- Акцент (оранжевый)
}

-- Animation variables
local time = 0
local pulseSpeed = 2

-- Utility Functions
local function lerp(a, b, t)
    return a + (b - a) * t
end

local function pulse(speed)
    return (math.sin(time * speed) + 1) / 2
end

-- Enhanced Role Detection for MM2
local function getPlayerRole(plr)
    if not plr.Character then return "innocent" end
    
    -- Check backpack for tools
    local backpack = plr:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("knife") or name:find("blade") then
                    return "murderer"
                elseif name:find("gun") or name:find("revolver") then
                    return "sheriff"
                end
            end
        end
    end
    
    -- Check held tool
    local tool = plr.Character:FindFirstChildOfClass("Tool")
    if tool then
        local name = tool.Name:lower()
        if name:find("knife") or name:find("blade") then
            return "murderer"
        elseif name:find("gun") or name:find("revolver") then
            return "sheriff"
        end
    end
    
    -- Fallback to team
    if plr.Team then
        local teamName = plr.Team.Name:lower()
        if teamName:find("murderer") then return "murderer" end
        if teamName:find("sheriff") then return "sheriff" end
    end
    
    return "innocent"
end

-- Get role color
local function getRoleColor(role)
    return colors[role] or colors.innocent
end

-- Create smooth box
local function createBox()
    local box = {}
    
    -- Main box (4 lines for rounded effect)
    box.outline = Drawing.new("Square")
    box.outline.Thickness = 2
    box.outline.Filled = false
    box.outline.Transparency = 0.8
    box.outline.Color = colors.text
    
    -- Inner glow
    box.glow = Drawing.new("Square")
    box.glow.Thickness = 1
    box.glow.Filled = false
    box.glow.Transparency = 0.3
    box.glow.Color = colors.accent
    
    return box
end

-- Create health bar
local function createHealthBar()
    local health = {}
    
    -- Background
    health.bg = Drawing.new("Square")
    health.bg.Filled = true
    health.bg.Color = colors.background
    health.bg.Transparency = 0.7
    health.bg.Thickness = 0
    
    -- Health fill
    health.fill = Drawing.new("Square")
    health.fill.Filled = true
    health.fill.Color = colors.innocent
    health.fill.Transparency = 0.8
    health.fill.Thickness = 0
    
    -- Health text
    health.text = Drawing.new("Text")
    health.text.Size = 12
    health.text.Font = 2
    health.text.Color = colors.text
    health.text.Outline = true
    health.text.Center = true
    
    return health
end

-- Create tracer line
local function createLine()
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = colors.text
    line.Transparency = 0.7
    return line
end

-- Create name text
local function createNameText()
    local text = Drawing.new("Text")
    text.Size = 14
    text.Font = 3 -- Bold
    text.Color = colors.text
    text.Outline = true
    text.Center = true
    return text
end

-- Create distance text
local function createDistanceText()
    local text = Drawing.new("Text")
    text.Size = 11
    text.Font = 2
    text.Color = colors.accent
    text.Outline = true
    text.Center = true
    return text
end

-- Main ESP creation
local function createESPForPlayer(plr)
    if plr == player then return end
    if drawings[plr] then return end
    
    local esp_data = {}
    
    if esp.boxes then
        esp_data.box = createBox()
    end
    
    if esp.health then
        esp_data.health = createHealthBar()
    end
    
    if esp.lines then
        esp_data.line = createLine()
    end
    
    if esp.names then
        esp_data.name = createNameText()
    end
    
    if esp.distance then
        esp_data.distance = createDistanceText()
    end
    
    drawings[plr] = esp_data
end

-- Update ESP visuals
local function updateESP()
    time = time + RunService.Heartbeat:Wait()
    
    for plr, esp_data in pairs(drawings) do
        if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
            continue
        end
        
        local character = plr.Character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character.HumanoidRootPart
        local head = character:FindFirstChild("Head")
        
        if not humanoid or not head then continue end
        if humanoid.Health <= 0 then continue end
        
        -- Get positions
        local rootPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
        local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local legPos = camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
        
        if not onScreen then
            -- Hide all elements
            for _, element in pairs(esp_data) do
                if typeof(element) == "table" then
                    for _, sub in pairs(element) do
                        sub.Visible = false
                    end
                else
                    element.Visible = false
                end
            end
            continue
        end
        
        -- Get player data
        local role = getPlayerRole(plr)
        local roleColor = getRoleColor(role)
        local distance = math.floor((camera.CFrame.Position - rootPart.Position).Magnitude)
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        
        -- Calculate fade based on distance
        local fade = math.max(0.1, 1 - (distance / 500))
        
        -- Update box
        if esp_data.box then
            local boxWidth = 40
            local boxHeight = headPos.Y - legPos.Y
            
            esp_data.box.outline.Size = Vector2.new(boxWidth, boxHeight)
            esp_data.box.outline.Position = Vector2.new(rootPos.X - boxWidth/2, headPos.Y)
            esp_data.box.outline.Color = roleColor
            esp_data.box.outline.Transparency = 0.8 * fade
            esp_data.box.outline.Visible = true
            
            -- Animated glow
            local glowIntensity = pulse(pulseSpeed) * 0.5 + 0.3
            esp_data.box.glow.Size = Vector2.new(boxWidth + 2, boxHeight + 2)
            esp_data.box.glow.Position = Vector2.new(rootPos.X - boxWidth/2 - 1, headPos.Y - 1)
            esp_data.box.glow.Color = roleColor
            esp_data.box.glow.Transparency = 1 - glowIntensity * fade
            esp_data.box.glow.Visible = true
        end
        
        -- Update health bar
        if esp_data.health then
            local barWidth = 40
            local barHeight = 3
            local barX = rootPos.X - barWidth/2
            local barY = legPos.Y + 5
            
            -- Background
            esp_data.health.bg.Size = Vector2.new(barWidth, barHeight)
            esp_data.health.bg.Position = Vector2.new(barX, barY)
            esp_data.health.bg.Visible = true
            
            -- Health fill (animated width)
            local fillWidth = barWidth * healthPercent
            esp_data.health.fill.Size = Vector2.new(fillWidth, barHeight)
            esp_data.health.fill.Position = Vector2.new(barX, barY)
            esp_data.health.fill.Color = Color3.new(1 - healthPercent, healthPercent, 0):lerp(roleColor, 0.3)
            esp_data.health.fill.Visible = true
            
            -- Health text
            esp_data.health.text.Text = math.floor(humanoid.Health) .. " HP"
            esp_data.health.text.Position = Vector2.new(rootPos.X, barY + 10)
            esp_data.health.text.Color = roleColor
            esp_data.health.text.Transparency = 1 - fade
            esp_data.health.text.Visible = true
        end
        
        -- Update line
        if esp_data.line then
            local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            esp_data.line.From = screenCenter
            esp_data.line.To = Vector2.new(rootPos.X, legPos.Y)
            esp_data.line.Color = roleColor
            esp_data.line.Transparency = 1 - fade * 0.8
            esp_data.line.Visible = true
        end
        
        -- Update name
        if esp_data.name then
            local roleText = role:upper()
            if role == "murderer" then roleText = "MURDERER"
            elseif role == "sheriff" then roleText = "SHERIFF"
            else roleText = "INNOCENT" end
            
            esp_data.name.Text = plr.Name .. " [" .. roleText .. "]"
            esp_data.name.Position = Vector2.new(rootPos.X, headPos.Y - 15)
            esp_data.name.Color = roleColor
            esp_data.name.Transparency = 1 - fade
            esp_data.name.Visible = true
        end
        
        -- Update distance
        if esp_data.distance then
            esp_data.distance.Text = distance .. "m"
            esp_data.distance.Position = Vector2.new(rootPos.X, legPos.Y + 20)
            esp_data.distance.Color = colors.accent
            esp_data.distance.Transparency = 1 - fade
            esp_data.distance.Visible = true
        end
    end
end

-- Chams function
local function toggleChams(state)
    esp.chams = state
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == player or not plr.Character then continue end
        
        for _, part in pairs(plr.Character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                if state then
                    part.Material = Enum.Material.ForceField
                    part.Color = getRoleColor(getPlayerRole(plr))
                    part.Transparency = 0.3
                else
                    part.Material = Enum.Material.Plastic
                    part.Color = Color3.new(1, 1, 1)
                    part.Transparency = 0
                end
            end
        end
    end
end

-- Clear ESP for player
local function clearESP(plr)
    if drawings[plr] then
        for _, element in pairs(drawings[plr]) do
            if typeof(element) == "table" then
                for _, sub in pairs(element) do
                    sub:Remove()
                end
            else
                element:Remove()
            end
        end
        drawings[plr] = nil
    end
end

-- Clear all ESP
local function clearAllESP()
    for plr, _ in pairs(drawings) do
        clearESP(plr)
    end
    drawings = {}
end

-- Toggle ESP
local function toggleESP()
    esp.enabled = not esp.enabled
    
    if esp.enabled then
        -- Create ESP for all players
        for _, plr in pairs(Players:GetPlayers()) do
            createESPForPlayer(plr)
        end
        
        -- Start update loop
        connections.update = RunService.RenderStepped:Connect(updateESP)
        
        print("🎨 Beautiful ESP Enabled!")
        print("Roles: RED=Murderer, BLUE=Sheriff, GREEN=Innocent")
    else
        -- Clear everything
        if connections.update then
            connections.update:Disconnect()
        end
        clearAllESP()
        toggleChams(false)
        
        print("ESP Disabled")
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        toggleESP()
    elseif input.KeyCode == Enum.KeyCode.Home then
        toggleChams(not esp.chams)
        print("Chams: " .. (esp.chams and "ON" or "OFF"))
    end
end)

-- Player events
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if esp.enabled then
            wait(1)
            createESPForPlayer(plr)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    clearESP(plr)
end)

player.CharacterAdded:Connect(function()
    wait(2)
    if esp.enabled then
        clearAllESP()
        for _, plr in pairs(Players:GetPlayers()) do
            createESPForPlayer(plr)
        end
    end
end)

-- Auto-start
wait(3)
print("ESP Loaded! By Robanik")

-- Auto-enable ESP
toggleESP()
