--// Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Safe Mode
local safeMode = true
if safeMode then
    if RunService:IsStudio() or not game:IsLoaded() then return end
end

--// Estados
local aimbotEnabled = false
local espEnabled = false
local guiVisible = true
local antiLagEnabled = false
local showFPS = false
local hubPosition = Vector2.new(50, 50)
local frameVisible = false

--// Configurações
local aimbotSettings = {
    fov = 150,
    smoothness = 0.2
}

--// GUI
local function setupGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = tostring(math.random(100000, 999999))
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 280)
    frame.Position = UDim2.new(0, hubPosition.X, 0, hubPosition.Y)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Visible = true
    frame.Parent = gui

    local function createLabel(text, pos, size, fontSize, color)
        local label = Instance.new("TextLabel", frame)
        label.Size = size
        label.Position = pos
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = color or Color3.new(1, 1, 1)
        label.Font = Enum.Font.SourceSans
        label.TextSize = fontSize
        return label
    end

    local function createButton(text, yPos, callback)
        local button = Instance.new("TextButton", frame)
        button.Size = UDim2.new(1, -20, 0, 30)
        button.Position = UDim2.new(0, 10, 0, yPos)
        button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Font = Enum.Font.SourceSans
        button.TextSize = 16
        button.Text = text
        button.MouseButton1Click:Connect(callback)
    end

    createLabel("🎯 Aimbot + ESP Hub", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 30), 20, Color3.fromRGB(255, 0, 0))

    local statusLabel = createLabel("Status", UDim2.new(0, 10, 0, 250), UDim2.new(1, -20, 0, 20), 14)
    local fpsLabel = createLabel("FPS: N/A", UDim2.new(0, 10, 0, 230), UDim2.new(1, -20, 0, 20), 14, Color3.fromRGB(0, 255, 0))
    fpsLabel.Visible = false

    local function updateStatus()
        statusLabel.Text = string.format("Status: Aimbot %s | ESP %s | Anti-Lag %s",
            aimbotEnabled and "On" or "Off",
            espEnabled and "On" or "Off",
            antiLagEnabled and "On" or "Off")
    end

    local function applyAntiLag()
        aimbotSettings.smoothness = antiLagEnabled and 0.05 or 0.2
        if antiLagEnabled then espEnabled = false end
    end

    createButton("Ativar/Desativar Aimbot", 40, function()
        aimbotEnabled = not aimbotEnabled
        updateStatus()
    end)

    createButton("Ativar/Desativar ESP", 80, function()
        espEnabled = not espEnabled
        updateStatus()
    end)

    createButton("Ativar/Desativar Anti-Lag", 120, function()
        antiLagEnabled = not antiLagEnabled
        applyAntiLag()
        updateStatus()
    end)

    createButton("Mostrar/Ocultar FPS", 160, function()
        showFPS = not showFPS
        fpsLabel.Visible = showFPS
    end)

    -- Botão para fechar e abrir Hub
    local openButton = Instance.new("TextButton")
    openButton.Size = UDim2.new(0, 100, 0, 30)
    openButton.Position = UDim2.new(0, 10, 0, 10)
    openButton.Text = "Abrir Hub"
    openButton.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    openButton.TextColor3 = Color3.new(1, 1, 1)
    openButton.TextSize = 14
    openButton.Font = Enum.Font.SourceSansBold
    openButton.Visible = false
    openButton.Parent = gui

    createButton("Fechar Hub", 200, function()
        frame.Visible = false
        openButton.Visible = true
    end)

    openButton.MouseButton1Click:Connect(function()
        frame.Visible = true
        openButton.Visible = false
    end)

    updateStatus()
    return fpsLabel
end

local fpsLabel = setupGUI()

--// Cache de jogadores
local cachedPlayers = {}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        table.insert(cachedPlayers, p)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then table.insert(cachedPlayers, p) end
end)

Players.PlayerRemoving:Connect(function(p)
    for i, v in ipairs(cachedPlayers) do
        if v == p then table.remove(cachedPlayers, i) break end
    end
end)

--// Inimigos
local function getEnemies()
    local enemies = {}
    for _, player in ipairs(cachedPlayers) do
        local char = player.Character
        local humanoid = char and char:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            if player.Team ~= LocalPlayer.Team then
                table.insert(enemies, player)
            end
        end
    end
    return enemies
end

--// ESP
local function updateESP()
    for _, ador in ipairs(workspace:GetChildren()) do
        if ador:IsA("BoxHandleAdornment") and ador.Name == "ESP_BOX" then
            ador:Destroy()
        end
    end

    if espEnabled then
        for _, enemy in ipairs(getEnemies()) do
            local char = enemy.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "ESP_BOX"
                box.Size = Vector3.new(4, 6, 2)
                box.Color3 = Color3.fromRGB(255, 0, 0)
                box.AlwaysOnTop = true
                box.Adornee = char.HumanoidRootPart
                box.ZIndex = 5
                box.Transparency = 0.7
                box.Parent = workspace
            end
        end
    end
end

--// Aimbot
local function isVisible(enemy)
    local ray = Ray.new(Camera.CFrame.Position, (enemy.Character.HumanoidRootPart.Position - Camera.CFrame.Position).Unit * 100)
    local hit = workspace:FindPartOnRay(ray, LocalPlayer.Character)
    return hit and hit:IsDescendantOf(enemy.Character)
end

local function getClosestTarget()
    local closest, shortest = nil, aimbotSettings.fov
    local mouse = UserInputService:GetMouseLocation()

    for _, enemy in ipairs(getEnemies()) do
        local part = enemy.Character:FindFirstChild("Head") or enemy.Character:FindFirstChild("HumanoidRootPart")
        if part then
            local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
            if visible then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                if dist < shortest then
                    closest = part
                    shortest = dist
                end
            end
        end
    end
    return closest
end

local function smoothAimbot(target)
    local pos = target.Position
    local camPos = Camera.CFrame.Position
    local newCFrame = CFrame.lookAt(camPos, pos)
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, aimbotSettings.smoothness)
end

local function aimAtTarget()
    local closest = getClosestTarget()
    if closest then
        smoothAimbot(closest)
    end
end

--// Loop principal
RunService.Heartbeat:Connect(function()
    if aimbotEnabled then
        aimAtTarget()
    end

    if espEnabled then
        updateESP()
    end
end)

--// FPS
local lastTime, frames = tick(), 0
RunService.Heartbeat:Connect(function()
    frames += 1
    local now = tick()
    if now - lastTime >= 1 then
        if showFPS then
            fpsLabel.Text = "FPS: " .. frames
        end
        frames = 0
        lastTime = now
    end
end)
